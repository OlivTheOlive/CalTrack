#!/usr/bin/env python3
"""Build assets/opennutrition.sqlite from OpenNutrition TSV with optional cleaning.

Re-run when opennutrition-dataset-2025/opennutrition_foods.tsv updates.

By default this script imports every row from the TSV. With ``--clean`` it
applies a deterministic, rules-only filter that keeps only whole, non-branded
foods (fruits, vegetables, meats, fish, grains, legumes, nuts, dairy basics)
and removes duplicates (primarily by EAN-13).

Optionally, ``--llm-audit`` will send only the rows the rules cannot
confidently classify to a local LM Studio server (OpenAI-compatible API) so
you can iterate on the deny/allow lists. The LLM verdict is *not* used to
decide what gets shipped: the cleaned database stays deterministic.

Produces:
  - foods: catalog rows with per-100g macros and optional EAN
  - foods_fts: FTS5 index on food_id + searchable text (name + alternate names)

Requires Python 3.9+ (stdlib only).
"""

from __future__ import annotations

import argparse
import csv
import json
import random
import re
import sqlite3
import sys
import urllib.error
import urllib.request
from collections import Counter
from pathlib import Path

# ---------------------------------------------------------------------------
# Nutrition / search helpers (used by both clean and raw imports).
# ---------------------------------------------------------------------------


def nutrition_from_json(raw: str) -> tuple[float, float, float, float]:
    """Returns (kcal, protein, carbs, fat) per 100g.

    OpenNutrition stores total fat under the ``total_fat`` key (not ``fat``).
    Earlier versions of this importer only looked at ``fat``, which silently
    produced a database where every row had ``fat_100g = 0``. The
    ``total_fat`` key now wins, with ``fat`` kept as a fallback for any
    non-OpenNutrition shape we might import later.
    """
    if not raw or not raw.strip():
        return (0.0, 0.0, 0.0, 0.0)
    try:
        j = json.loads(raw)
    except json.JSONDecodeError:
        return (0.0, 0.0, 0.0, 0.0)
    kcal = float(j.get("calories") or 0)
    protein = float(j.get("protein") or 0)
    carbs = float(j.get("carbohydrates") or j.get("carbs") or 0)
    fat = float(j.get("total_fat") or j.get("fat") or 0)
    return (kcal, protein, carbs, fat)


def alternate_names_list(alternate_raw: str) -> list[str]:
    if not alternate_raw or not alternate_raw.strip():
        return []
    try:
        arr = json.loads(alternate_raw)
    except json.JSONDecodeError:
        return []
    if not isinstance(arr, list):
        return []
    return [a.strip() for a in arr if isinstance(a, str) and a.strip()]


def aliases_search_blob(name: str, alternate_raw: str) -> str:
    parts = [name.strip()]
    parts.extend(alternate_names_list(alternate_raw))
    return " ".join(parts)


def labels_list(labels_raw: str) -> list[str]:
    if not labels_raw or not labels_raw.strip():
        return []
    try:
        arr = json.loads(labels_raw)
    except json.JSONDecodeError:
        return []
    return [a.lower().strip() for a in arr if isinstance(a, str) and a.strip()]


# ---------------------------------------------------------------------------
# Whole-food classifier (rules only).
# ---------------------------------------------------------------------------

# Words that strongly imply a packaged/processed/recipe item we do NOT want
# to retain when the goal is "whole foods only".
DENY_TOKENS: tuple[str, ...] = (
    # Sweets / baked goods
    "cake", "cupcake", "cookie", "biscotti", "biscuit", "brownie", "pastry",
    "donut", "doughnut", "cinnamon roll", "eclair", "muffin", "scone",
    "pie", "tart", "cheesecake", "macaron", "macaroon", "tiramisu",
    "pudding", "custard", "mousse", "fudge", "candy", "candies", "lollipop",
    "marshmallow", "gummy", "jelly bean", "chocolate bar", "truffle",
    # Snacks / chips / crackers
    "chips", "doritos", "pretzel", "cracker", "crackers", "popcorn",
    "puff", "puffs", "tortilla chips", "potato chips", "rice cake",
    # Bread products that are typically packaged/branded variants
    "bagel", "donut", "croissant", "danish", "challah", "brioche",
    "ciabatta", "focaccia", "pita", "naan", "sandwich",
    "burger", "hot dog", "hotdog", "wrap",
    # Drinks & alcohol
    "soda", "cola", "energy drink", "sports drink", "wine", "beer",
    "cocktail", "liqueur", "whiskey", "vodka", "rum", "gin", "champagne",
    "spritz", "latte", "mocha", "frappuccino", "milkshake",
    # Sauces / dressings / spreads
    "sauce", "dressing", "mayo", "mayonnaise", "ketchup", "mustard",
    "syrup", "spread", "dip", "salsa", "hummus", "guacamole",
    # Frozen / ready meals / prepared
    "pizza", "lasagna", "ravioli", "burrito", "taco", "enchilada",
    "casserole", "soup", "stew", "curry", "chili", "noodles bowl",
    "pasta bowl", "ramen bowl",
    # Cereals / bars / mixes
    "cereal", "granola", "muesli", "protein bar", "energy bar",
    "snack bar", "fruit bar", "trail mix", "mix", "pancake mix",
    "waffle mix", "bread mix", "cake mix",
    # Restaurant-y / branded markers
    " by ", " brand", "®", "™", "©", "limited edition", "value pack",
    "family size",
    # Misc clearly-processed items
    "ice cream", "gelato", "sorbet", "frozen yogurt", "yogurt drink",
    "smoothie", "shake",
)

# Words that strongly imply a whole, non-branded food. We keep rows that
# match these even when no other signal fires.
ALLOW_TOKENS: tuple[str, ...] = (
    # Fruits
    "apple", "pear", "banana", "orange", "lemon", "lime", "grape", "grapes",
    "berry", "strawberry", "raspberry", "blueberry", "blackberry",
    "cranberry", "cherry", "peach", "plum", "apricot", "nectarine",
    "mango", "pineapple", "papaya", "kiwi", "watermelon", "cantaloupe",
    "honeydew", "melon", "fig", "date", "pomegranate", "guava",
    "passionfruit", "lychee", "persimmon", "tangerine", "clementine",
    # Vegetables
    "broccoli", "cauliflower", "cabbage", "spinach", "kale", "arugula",
    "lettuce", "chard", "collard", "bok choy", "asparagus", "carrot",
    "celery", "cucumber", "zucchini", "squash", "pumpkin", "eggplant",
    "tomato", "potato", "sweet potato", "yam", "onion", "garlic",
    "ginger", "turnip", "radish", "beet", "leek", "scallion", "shallot",
    "pepper", "bell pepper", "chili", "okra", "artichoke", "fennel",
    "mushroom", "corn", "peas",
    # Meats / poultry
    "chicken", "turkey", "duck", "beef", "veal", "lamb", "pork", "bacon",
    "ham", "ribs", "steak", "ground beef", "ground chicken",
    "ground turkey", "liver", "tongue",
    # Fish / seafood
    "salmon", "tuna", "trout", "cod", "halibut", "tilapia", "sardine",
    "anchovy", "mackerel", "herring", "haddock", "snapper", "bass",
    "swordfish", "shrimp", "prawn", "crab", "lobster", "scallop",
    "clam", "mussel", "oyster", "octopus", "squid", "calamari",
    # Eggs / dairy basics
    "egg", "eggs", "milk", "yogurt", "yoghurt", "kefir", "cottage cheese",
    "cream cheese", "ricotta", "feta", "mozzarella", "cheddar cheese",
    "parmesan", "butter",
    # Grains / starches (whole)
    "rice", "brown rice", "oats", "rolled oats", "barley", "quinoa",
    "millet", "buckwheat", "rye", "spelt", "farro", "bulgur", "amaranth",
    "couscous", "polenta", "pasta", "wheat",
    # Legumes / nuts / seeds
    "lentils", "chickpea", "chickpeas", "kidney bean", "black bean",
    "pinto bean", "navy bean", "lima bean", "soybean", "edamame", "tofu",
    "tempeh", "almond", "almonds", "walnut", "walnuts", "cashew",
    "cashews", "pecan", "pecans", "pistachio", "pistachios", "hazelnut",
    "hazelnuts", "peanut", "peanuts", "macadamia", "brazil nut",
    "sunflower seed", "pumpkin seed", "chia seed", "flax seed", "sesame",
    # Oils / vinegars (kept; users log oils)
    "olive oil", "canola oil", "sunflower oil", "avocado oil",
    "coconut oil", "sesame oil",
)

DENY_REGEX = re.compile(
    "|".join(re.escape(tok) for tok in sorted(DENY_TOKENS, key=len, reverse=True)),
    re.IGNORECASE,
)
ALLOW_REGEX = re.compile(
    r"\b(" + "|".join(re.escape(tok) for tok in sorted(ALLOW_TOKENS, key=len, reverse=True)) + r")\b",
    re.IGNORECASE,
)


def classify_name(name: str) -> tuple[str, list[str], list[str]]:
    """Return (verdict, deny_hits, allow_hits) for a single name string.

    verdict is one of:
      - "whole_food"            : allow-only match
      - "branded_or_processed"  : deny match (even when allow also matches,
                                  e.g. "Cherry Pie" -> drop because of "pie")
      - "borderline"            : neither allow nor deny matched. The
                                  deterministic pipeline keeps these
                                  conservatively (after the type filter)
                                  and logs them for optional LLM audit.
    """
    deny_hits = sorted(set(m.group(0).lower() for m in DENY_REGEX.finditer(name)))
    allow_hits = sorted(set(m.group(0).lower() for m in ALLOW_REGEX.finditer(name)))
    if deny_hits:
        # Deny wins over allow: "Cherry Pie" is still a pie.
        return "branded_or_processed", deny_hits, allow_hits
    if allow_hits:
        return "whole_food", deny_hits, allow_hits
    return "borderline", deny_hits, allow_hits


# ---------------------------------------------------------------------------
# Sanity bounds for nutrition values per 100g.
# ---------------------------------------------------------------------------


def macros_within_bounds(
    kcal: float,
    protein: float,
    carbs: float,
    fat: float,
    *,
    min_kcal: float,
    max_kcal: float,
    max_macro_g: float,
) -> tuple[bool, str | None]:
    if kcal < 0 or protein < 0 or carbs < 0 or fat < 0:
        return False, "negative_macro"
    if kcal < min_kcal:
        return False, "kcal_below_min"
    if kcal > max_kcal:
        return False, "kcal_above_max"
    if protein > max_macro_g or carbs > max_macro_g or fat > max_macro_g:
        return False, "macro_above_max"
    return True, None


# ---------------------------------------------------------------------------
# LM Studio (OpenAI-compatible) ambiguity audit.
# ---------------------------------------------------------------------------


SYSTEM_PROMPT = (
    "You classify food entries as either a whole, single-ingredient food "
    "(fruits, vegetables, meats, fish, eggs, grains, legumes, nuts, basic "
    "dairy, plain oils) or a branded/processed/recipe item. Be conservative: "
    "if a food has been turned into a dish, snack, dessert, baked good, "
    "drink, sauce, dressing, or branded product, it is NOT a whole food. "
    "Reply with strict JSON only."
)


def llm_audit_one(
    *,
    base_url: str,
    model: str,
    name: str,
    deny_hits: list[str],
    allow_hits: list[str],
    timeout_seconds: float,
) -> dict | None:
    """Send a single borderline row to LM Studio and return the verdict dict.

    Returns None on any error so the pipeline keeps running.
    """
    url = base_url.rstrip("/") + "/v1/chat/completions"
    user_prompt = (
        f"Food name: {name}\n"
        f"Heuristic deny hits: {deny_hits}\n"
        f"Heuristic allow hits: {allow_hits}\n"
        "Reply with JSON: "
        '{"verdict": "whole_food" | "branded_or_processed" | "unsure", '
        '"confidence": 0..1, "rationale": "short"}'
    )
    body = json.dumps(
        {
            "model": model,
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": user_prompt},
            ],
            "temperature": 0.0,
            "max_tokens": 200,
        }
    ).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout_seconds) as resp:
            data = json.loads(resp.read().decode("utf-8", errors="replace"))
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError, OSError):
        return None
    try:
        content = data["choices"][0]["message"]["content"]
    except (KeyError, IndexError, TypeError):
        return None
    return parse_llm_verdict(content)


def parse_llm_verdict(content: str) -> dict | None:
    """Best-effort parse of a JSON object embedded in [content]."""
    content = content.strip()
    # Allow models that wrap JSON in markdown fences.
    if content.startswith("```"):
        content = re.sub(r"^```[a-zA-Z]*\n?", "", content)
        content = re.sub(r"\n?```$", "", content)
    try:
        obj = json.loads(content)
    except json.JSONDecodeError:
        # Fallback: extract the first {...} block.
        m = re.search(r"\{.*\}", content, flags=re.DOTALL)
        if not m:
            return None
        try:
            obj = json.loads(m.group(0))
        except json.JSONDecodeError:
            return None
    if not isinstance(obj, dict):
        return None
    verdict = obj.get("verdict")
    if verdict not in {"whole_food", "branded_or_processed", "unsure"}:
        return None
    return {
        "verdict": verdict,
        "confidence": float(obj.get("confidence") or 0.0),
        "rationale": str(obj.get("rationale") or "").strip(),
    }


# ---------------------------------------------------------------------------
# Cleaning pipeline.
# ---------------------------------------------------------------------------


# Normalized type values we keep when --clean is enabled. Even with
# --keep-branded the script still requires usable nutrition.
DEFAULT_KEEP_TYPES: frozenset[str] = frozenset({"everyday"})


def normalize_name_for_dedupe(s: str) -> str:
    s = s.lower().strip()
    s = re.sub(r"\s+", " ", s)
    s = re.sub(r"[^\w\s,]", "", s)
    return s


def score_row_quality(row: dict, *, allow_hits: list[str], deny_hits: list[str]) -> int:
    """Higher is better. Used to pick the best representative when deduping."""
    score = 0
    name: str = row["name"]
    score += 5 if allow_hits else 0
    score -= 5 * len(deny_hits)
    score -= len(name)  # shorter names usually win
    nutr = row["nutrition"]
    if all(v > 0 for v in nutr):
        score += 3
    return score


def main() -> int:
    root = Path(__file__).resolve().parent.parent
    default_tsv = root / "opennutrition-dataset-2025" / "opennutrition_foods.tsv"
    default_out = root / "assets" / "opennutrition.sqlite"

    ap = argparse.ArgumentParser(description="OpenNutrition TSV -> SQLite")
    ap.add_argument("--tsv", type=Path, default=default_tsv)
    ap.add_argument("--out", type=Path, default=default_out)

    # Cleaning
    ap.add_argument(
        "--clean",
        action="store_true",
        help="Apply rules-only cleaning (whole-food filter, EAN dedupe, sanity).",
    )
    ap.add_argument(
        "--keep-branded",
        action="store_true",
        help="Debug: keep all rows regardless of type/name rules (still applies sanity).",
    )
    ap.add_argument(
        "--report",
        type=Path,
        default=None,
        help="Write a JSON report of cleaning decisions/counts to this path.",
    )
    ap.add_argument(
        "--ambiguous-csv",
        type=Path,
        default=None,
        help="Write borderline rows (name/ean/heuristics/[llm verdict]) to a CSV here.",
    )
    ap.add_argument("--min-kcal", type=float, default=0.0)
    ap.add_argument("--max-kcal", type=float, default=1000.0)
    ap.add_argument("--max-macro-g", type=float, default=110.0)

    # LM Studio audit
    ap.add_argument(
        "--llm-audit",
        action="store_true",
        help="Send borderline rows to a local LM Studio (OpenAI-compatible) server "
             "to flag ambiguous entries for review.",
    )
    ap.add_argument("--llm-base-url", type=str, default="http://192.168.86.199:1234")
    ap.add_argument("--llm-model", type=str, default="gemma-4-e4b")
    ap.add_argument("--llm-timeout-seconds", type=float, default=10.0)
    ap.add_argument("--llm-sample-rate", type=float, default=1.0)
    ap.add_argument(
        "--llm-max-rows",
        type=int,
        default=0,
        help="Hard cap on borderline rows sent to the LLM (0 = no cap).",
    )

    args = ap.parse_args()

    if not args.tsv.is_file():
        print(f"Missing TSV: {args.tsv}", file=sys.stderr)
        return 1

    args.out.parent.mkdir(parents=True, exist_ok=True)
    if args.out.exists():
        args.out.unlink()

    conn = sqlite3.connect(str(args.out))
    conn.execute("PRAGMA journal_mode=DELETE")
    conn.execute("PRAGMA synchronous=NORMAL")

    conn.executescript(
        """
        CREATE TABLE foods (
          id TEXT PRIMARY KEY NOT NULL,
          name TEXT NOT NULL,
          ean TEXT,
          kcal_100g REAL NOT NULL,
          protein_100g REAL NOT NULL,
          carbs_100g REAL NOT NULL,
          fat_100g REAL NOT NULL
        );

        CREATE INDEX idx_foods_ean ON foods(ean) WHERE ean IS NOT NULL AND length(ean) > 0;

        CREATE VIRTUAL TABLE foods_fts USING fts5(
          food_id UNINDEXED,
          search_text,
          tokenize = 'unicode61 remove_diacritics 1'
        );
        """
    )

    insert_food = (
        "INSERT INTO foods (id, name, ean, kcal_100g, protein_100g, carbs_100g, fat_100g) "
        "VALUES (?, ?, ?, ?, ?, ?, ?)"
    )
    insert_fts = "INSERT INTO foods_fts (food_id, search_text) VALUES (?, ?)"

    counters: Counter[str] = Counter()
    deny_token_counts: Counter[str] = Counter()
    type_counts: Counter[str] = Counter()
    rejected_samples: dict[str, list[str]] = {}

    borderline_rows: list[dict] = []
    by_ean: dict[str, dict] = {}
    by_name: dict[str, dict] = {}

    rng = random.Random(0xC417)

    def remember_sample(reason: str, name: str) -> None:
        bucket = rejected_samples.setdefault(reason, [])
        if len(bucket) < 8:
            bucket.append(name)

    with args.tsv.open("r", encoding="utf-8", errors="replace", newline="") as f:
        reader = csv.DictReader(f, delimiter="\t")
        for row in reader:
            counters["input"] += 1
            fid = (row.get("id") or "").strip()
            name = (row.get("name") or "").strip()
            ftype = (row.get("type") or "").strip().lower()
            type_counts[ftype or "<missing>"] += 1
            if not fid or not name:
                counters["dropped_missing_required"] += 1
                remember_sample("missing_required", name)
                continue

            ean = (row.get("ean_13") or "").strip() or None
            kcal, p, c, fa = nutrition_from_json(row.get("nutrition_100g") or "")

            sane, sane_reason = macros_within_bounds(
                kcal, p, c, fa,
                min_kcal=args.min_kcal,
                max_kcal=args.max_kcal,
                max_macro_g=args.max_macro_g,
            )
            if not sane:
                counters["dropped_sanity"] += 1
                counters[f"sanity__{sane_reason}"] += 1
                remember_sample(f"sanity__{sane_reason}", name)
                continue

            apply_rules = args.clean and not args.keep_branded

            if apply_rules and ftype not in DEFAULT_KEEP_TYPES:
                counters["dropped_type"] += 1
                counters[f"type__{ftype or 'missing'}"] += 1
                remember_sample(f"type__{ftype or 'missing'}", name)
                continue

            verdict, deny_hits, allow_hits = classify_name(name)
            for hit in deny_hits:
                deny_token_counts[hit] += 1

            if apply_rules and verdict == "branded_or_processed":
                counters["dropped_name_rules"] += 1
                remember_sample("name_rules", name)
                continue

            search = aliases_search_blob(name, row.get("alternate_names") or "")

            entry = {
                "id": fid,
                "name": name,
                "ean": ean,
                "nutrition": (kcal, p, c, fa),
                "search": search,
                "type": ftype,
                "verdict": verdict,
                "deny_hits": deny_hits,
                "allow_hits": allow_hits,
                "labels": labels_list(row.get("labels") or ""),
            }

            if apply_rules and verdict == "borderline":
                # Track for optional LLM audit; still keep them by default
                # because the user asked for whole-foods only and the
                # deterministic pass already removed type=grocery and
                # explicit deny matches.
                borderline_rows.append(entry)

            if ean:
                existing = by_ean.get(ean)
                if existing is None:
                    by_ean[ean] = entry
                else:
                    counters["dedup_ean_collision"] += 1
                    keep = entry if score_row_quality(entry, allow_hits=entry["allow_hits"], deny_hits=entry["deny_hits"]) > score_row_quality(existing, allow_hits=existing["allow_hits"], deny_hits=existing["deny_hits"]) else existing
                    by_ean[ean] = keep
            else:
                key = normalize_name_for_dedupe(name)
                existing = by_name.get(key)
                if existing is None:
                    by_name[key] = entry
                else:
                    counters["dedup_name_collision"] += 1
                    keep = entry if score_row_quality(entry, allow_hits=entry["allow_hits"], deny_hits=entry["deny_hits"]) > score_row_quality(existing, allow_hits=existing["allow_hits"], deny_hits=existing["deny_hits"]) else existing
                    by_name[key] = keep

    retained: list[dict] = list(by_ean.values()) + list(by_name.values())

    # Optional LLM audit pass (does not change retained set).
    audit_rows: list[dict] = []
    if args.llm_audit and borderline_rows:
        sample = borderline_rows
        if 0 < args.llm_sample_rate < 1.0:
            sample = [r for r in sample if rng.random() < args.llm_sample_rate]
        if args.llm_max_rows and len(sample) > args.llm_max_rows:
            sample = sample[: args.llm_max_rows]
        for entry in sample:
            verdict = llm_audit_one(
                base_url=args.llm_base_url,
                model=args.llm_model,
                name=entry["name"],
                deny_hits=entry["deny_hits"],
                allow_hits=entry["allow_hits"],
                timeout_seconds=args.llm_timeout_seconds,
            )
            audit_rows.append(
                {
                    "id": entry["id"],
                    "name": entry["name"],
                    "ean": entry["ean"],
                    "deny_hits": entry["deny_hits"],
                    "allow_hits": entry["allow_hits"],
                    "llm_verdict": (verdict or {}).get("verdict"),
                    "llm_confidence": (verdict or {}).get("confidence"),
                    "llm_rationale": (verdict or {}).get("rationale"),
                }
            )
            if verdict is None:
                counters["llm_audit_failed"] += 1
            else:
                counters[f"llm_verdict__{verdict['verdict']}"] += 1

    # Insert retained foods + FTS rows.
    batch_foods: list[tuple] = []
    batch_fts: list[tuple] = []
    batch_size = 5000
    for entry in retained:
        kcal, p, c, fa = entry["nutrition"]
        batch_foods.append((entry["id"], entry["name"], entry["ean"], kcal, p, c, fa))
        batch_fts.append((entry["id"], entry["search"]))
        if len(batch_foods) >= batch_size:
            conn.executemany(insert_food, batch_foods)
            conn.executemany(insert_fts, batch_fts)
            batch_foods.clear()
            batch_fts.clear()
    if batch_foods:
        conn.executemany(insert_food, batch_foods)
        conn.executemany(insert_fts, batch_fts)

    counters["retained"] = len(retained)
    conn.execute("ANALYZE")
    conn.commit()
    conn.close()

    # Reports & artifacts
    if args.report is not None:
        report = {
            "input_tsv": str(args.tsv),
            "output_sqlite": str(args.out),
            "clean": args.clean,
            "keep_branded": args.keep_branded,
            "type_counts": dict(type_counts),
            "counters": dict(counters),
            "top_deny_tokens": deny_token_counts.most_common(40),
            "rejected_samples": rejected_samples,
            "audit_rows_count": len(audit_rows),
        }
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, indent=2, ensure_ascii=False))
        print(f"Wrote report to {args.report}")

    if args.ambiguous_csv is not None and (borderline_rows or audit_rows):
        args.ambiguous_csv.parent.mkdir(parents=True, exist_ok=True)
        with args.ambiguous_csv.open("w", encoding="utf-8", newline="") as fh:
            w = csv.writer(fh)
            w.writerow([
                "id", "name", "ean", "deny_hits", "allow_hits",
                "llm_verdict", "llm_confidence", "llm_rationale",
            ])
            audited_by_id = {a["id"]: a for a in audit_rows}
            for entry in borderline_rows:
                a = audited_by_id.get(entry["id"], {})
                w.writerow([
                    entry["id"],
                    entry["name"],
                    entry["ean"] or "",
                    "|".join(entry["deny_hits"]),
                    "|".join(entry["allow_hits"]),
                    a.get("llm_verdict") or "",
                    a.get("llm_confidence") or "",
                    a.get("llm_rationale") or "",
                ])
        print(f"Wrote borderline rows to {args.ambiguous_csv}")

    print(
        f"Wrote {counters['retained']} foods to {args.out} "
        f"(input={counters['input']}, dropped_type={counters.get('dropped_type', 0)}, "
        f"dropped_name_rules={counters.get('dropped_name_rules', 0)}, "
        f"dropped_sanity={counters.get('dropped_sanity', 0)}, "
        f"dedup_ean={counters.get('dedup_ean_collision', 0)}, "
        f"dedup_name={counters.get('dedup_name_collision', 0)}, "
        f"borderline={len(borderline_rows)}, audited={len(audit_rows)})"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
