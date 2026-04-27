#!/usr/bin/env python3
"""Build assets/opennutrition.sqlite from OpenNutrition TSV.

Re-run when opennutrition-dataset-2025/opennutrition_foods.tsv updates.

Produces:
  - foods: catalog rows with per-100g macros and optional EAN
  - foods_fts: FTS5 index on food_id + searchable text (name + alternate names)

Requires Python 3.9+ (stdlib only).
"""

from __future__ import annotations

import argparse
import csv
import json
import sqlite3
import sys
from pathlib import Path


def nutrition_from_json(raw: str) -> tuple[float, float, float, float]:
    """Returns (kcal, protein, carbs, fat) per 100g."""
    if not raw or not raw.strip():
        return (0.0, 0.0, 0.0, 0.0)
    try:
        j = json.loads(raw)
    except json.JSONDecodeError:
        return (0.0, 0.0, 0.0, 0.0)
    kcal = float(j.get("calories") or 0)
    protein = float(j.get("protein") or 0)
    carbs = float(j.get("carbohydrates") or j.get("carbs") or 0)
    fat = float(j.get("fat") or 0)
    return (kcal, protein, carbs, fat)


def aliases_search_blob(name: str, alternate_raw: str) -> str:
    parts = [name.strip()]
    if alternate_raw and alternate_raw.strip():
        try:
            arr = json.loads(alternate_raw)
            if isinstance(arr, list):
                for a in arr:
                    if isinstance(a, str) and a.strip():
                        parts.append(a.strip())
        except json.JSONDecodeError:
            pass
    return " ".join(parts)


def main() -> int:
    root = Path(__file__).resolve().parent.parent
    default_tsv = root / "opennutrition-dataset-2025" / "opennutrition_foods.tsv"
    default_out = root / "assets" / "opennutrition.sqlite"

    ap = argparse.ArgumentParser(description="OpenNutrition TSV → SQLite")
    ap.add_argument("--tsv", type=Path, default=default_tsv)
    ap.add_argument("--out", type=Path, default=default_out)
    args = ap.parse_args()

    if not args.tsv.is_file():
        print(f"Missing TSV: {args.tsv}", file=sys.stderr)
        return 1

    args.out.parent.mkdir(parents=True, exist_ok=True)
    if args.out.exists():
        args.out.unlink()

    conn = sqlite3.connect(str(args.out))
    # DELETE journal keeps a single .sqlite file for Flutter assets (no -wal/-shm).
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

    insert_food = """
        INSERT INTO foods (id, name, ean, kcal_100g, protein_100g, carbs_100g, fat_100g)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    """
    insert_fts = """
        INSERT INTO foods_fts (food_id, search_text) VALUES (?, ?)
    """

    batch_foods: list[tuple] = []
    batch_fts: list[tuple] = []
    batch_size = 5000
    count = 0

    with args.tsv.open("r", encoding="utf-8", errors="replace", newline="") as f:
        reader = csv.DictReader(f, delimiter="\t")
        for row in reader:
            fid = (row.get("id") or "").strip()
            name = (row.get("name") or "").strip()
            if not fid or not name:
                continue
            ean = (row.get("ean_13") or "").strip() or None
            kcal, p, c, fa = nutrition_from_json(row.get("nutrition_100g") or "")
            search = aliases_search_blob(name, row.get("alternate_names") or "")
            batch_foods.append((fid, name, ean, kcal, p, c, fa))
            batch_fts.append((fid, search))
            count += 1
            if len(batch_foods) >= batch_size:
                conn.executemany(insert_food, batch_foods)
                conn.executemany(insert_fts, batch_fts)
                batch_foods.clear()
                batch_fts.clear()

    if batch_foods:
        conn.executemany(insert_food, batch_foods)
        conn.executemany(insert_fts, batch_fts)

    conn.execute("ANALYZE")
    conn.commit()
    conn.close()

    print(f"Wrote {count} foods to {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
