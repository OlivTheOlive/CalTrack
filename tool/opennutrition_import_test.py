"""Smoke tests for tool/opennutrition_import.py parsing helpers.

Run with: ``python3 tool/opennutrition_import_test.py``
These are intentionally stdlib-only so CI doesn't need pytest just for
these checks.
"""

from __future__ import annotations

import sys
from pathlib import Path

_here = Path(__file__).resolve().parent
sys.path.insert(0, str(_here))

from opennutrition_import import (  # type: ignore  # noqa: E402
    nutrition_from_json,
    serving_from_json,
)


def _assert_eq(actual, expected, label: str) -> None:
    if actual != expected:
        raise AssertionError(f"{label}: expected {expected!r}, got {actual!r}")


def test_nutrition_from_json_basic() -> None:
    raw = '{"calories": 143, "protein": 12.6, "carbohydrates": 1.1, "total_fat": 9.5, "dietary_fiber": 0.4, "total_sugars": 1.5}'
    _assert_eq(
        nutrition_from_json(raw),
        (143.0, 12.6, 1.1, 9.5, 0.4, 1.5),
        "nutrition_from_json with fiber+sugar",
    )


def test_nutrition_from_json_empty() -> None:
    _assert_eq(nutrition_from_json(""), (0.0, 0.0, 0.0, 0.0, 0.0, 0.0), "empty")
    _assert_eq(nutrition_from_json("not json"), (0.0, 0.0, 0.0, 0.0, 0.0, 0.0), "bad json")


def test_serving_from_json_large_egg() -> None:
    raw = (
        '{"common": {"unit": "large egg", "quantity": 1}, '
        '"metric": {"unit": "g", "quantity": 50}}'
    )
    _assert_eq(serving_from_json(raw), ("large egg", 50.0), "large egg")


def test_serving_from_json_multi_quantity() -> None:
    raw = (
        '{"common": {"unit": "quail eggs", "quantity": 5}, '
        '"metric": {"unit": "g", "quantity": 45}}'
    )
    _assert_eq(
        serving_from_json(raw),
        ("5 quail eggs", 45.0),
        "5 quail eggs",
    )


def test_serving_from_json_non_gram_unit_dropped() -> None:
    # Only gram metrics are trusted; anything else returns None grams.
    raw = (
        '{"common": {"unit": "cup", "quantity": 1}, '
        '"metric": {"unit": "ml", "quantity": 240}}'
    )
    _assert_eq(serving_from_json(raw), ("cup", None), "ml rejected")


def test_serving_from_json_missing() -> None:
    _assert_eq(serving_from_json(""), (None, None), "empty serving")
    _assert_eq(serving_from_json("{}"), (None, None), "empty object")


if __name__ == "__main__":
    test_nutrition_from_json_basic()
    test_nutrition_from_json_empty()
    test_serving_from_json_large_egg()
    test_serving_from_json_multi_quantity()
    test_serving_from_json_non_gram_unit_dropped()
    test_serving_from_json_missing()
    print("all importer parser tests passed")
