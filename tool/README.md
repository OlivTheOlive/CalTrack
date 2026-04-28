# Tool scripts

## `opennutrition_import.py`

Builds the bundled food database `assets/opennutrition.sqlite` from the
upstream OpenNutrition TSV export.

### Inputs

Place (or symlink) the upstream dataset folder so the TSV lives at:

```
opennutrition-dataset-2025/opennutrition_foods.tsv
```

### Outputs

- `assets/opennutrition.sqlite` (default) — a SQLite database with two
tables consumed by `[lib/data/opennutrition_catalog.dart](../lib/data/opennutrition_catalog.dart)`:
  - `foods (id, name, ean, kcal_100g, protein_100g, carbs_100g, fat_100g)`
  - `foods_fts (food_id, search_text)` — FTS5 index over `name`
  plus alternate names, used by the app's offline search.

### Common usage

Raw import (every row that has an id+name passes; sanity bounds + EAN
dedupe still apply):

```bash
python3 tool/opennutrition_import.py
```

Cleaned import (recommended for shipped builds — keeps only whole,
non-branded foods and removes duplicates):

```bash
python3 tool/opennutrition_import.py \
  --clean \
  --report tool/opennutrition_clean_report.json \
  --ambiguous-csv tool/opennutrition_ambiguous.csv
```

### What `--clean` does

1. **Type gate** — only rows where `type=everyday` are eligible (the
  upstream dataset uses `everyday | grocery | prepared | restaurant`;
   ~96% of rows are branded `grocery` items and are dropped).
2. **Name rules**:
  - Reject rows whose name matches any **deny token** (e.g. `cake`,
   `cookie`, `pie`, `chips`, `sauce`, `pizza`, `wine`, `protein bar`,
   `cereal`, `granola`, `ice cream`, `frozen`, `mix`, …). Deny wins
   over allow, so "Cherry Pie" still drops.
  - Accept rows whose name matches any **allow token** (e.g. `apple`,
  `chicken`, `salmon`, `rice`, `oats`, `lentils`, `almond`,
  `yogurt`, …).
  - Otherwise mark the row as **borderline** — it is kept but logged
  to the report (and to `--ambiguous-csv`) for human or LLM review.
3. **Sanity bounds** on macros per 100g (configurable):
  - `--min-kcal` (default 0)
  - `--max-kcal` (default 1000)
  - `--max-macro-g` (default 110)
4. **Dedupe**:
  - Primary key: normalized **EAN-13**. Higher-quality row wins on
   collisions (shorter name, allow-token match, non-zero macros).
  - Fallback for rows without EAN: normalized name (lowercase, single
  spaces, alphanumerics).

The shipped database stays **deterministic**: the LLM audit (below) is
informational only.

### Optional: LM Studio ambiguity audit

If you have a local OpenAI-compatible server running (e.g. LM Studio at
`http://192.168.86.199:1234` with `gemma-4-e4b`), you can ask it to
classify the borderline rows and write its verdict into the report and
the ambiguous CSV:

```bash
python3 tool/opennutrition_import.py \
  --clean \
  --report tool/opennutrition_clean_report.json \
  --ambiguous-csv tool/opennutrition_ambiguous.csv \
  --llm-audit \
  --llm-base-url http://192.168.86.199:1234 \
  --llm-model gemma-4-e4b \
  --llm-timeout-seconds 10 \
  --llm-sample-rate 1.0 \
  --llm-max-rows 0
```

Notes:

- The LLM is asked to return strict JSON of the form
`{"verdict": "whole_food" | "branded_or_processed" | "unsure",   "confidence": 0..1, "rationale": "short"}`.
- Network/timeout/parse errors are non-fatal: each failed call is
counted under `llm_audit_failed` in the report.
- Use `--llm-sample-rate 0.1` and/or `--llm-max-rows 200` to keep
audits fast while you iterate on the deny/allow lists.
- The audit results are advisory: review the CSV, then add rules and
re-run.

### Validation

After a build, sanity-check the resulting database:

```bash
python3 - <<'PY'
import sqlite3
con = sqlite3.connect('assets/opennutrition.sqlite')
print('rows :', con.execute('SELECT COUNT(*) FROM foods').fetchone()[0])
print('with ean:', con.execute('SELECT COUNT(*) FROM foods WHERE ean IS NOT NULL').fetchone()[0])
for r in con.execute('SELECT name FROM foods ORDER BY RANDOM() LIMIT 10'):
    print(' -', r[0])
PY
```

Then in the app, do an offline catalog search and a barcode scan to
spot-check.

### Troubleshooting

- "Missing TSV": the script defaults to
`opennutrition-dataset-2025/opennutrition_foods.tsv`. Use `--tsv` to
point elsewhere.
- "Permission denied" writing to `assets/opennutrition.sqlite`: the
asset is replaced atomically; close any IDE tools that might hold a
lock and re-run.

