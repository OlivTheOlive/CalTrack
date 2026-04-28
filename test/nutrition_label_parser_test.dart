import 'dart:ui';

import 'package:caltrack/core/nutrition_label_parser.dart';
import 'package:caltrack/data/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

Rect r(double x, double y) => Rect.fromLTWH(x, y, 10, 10);

void main() {
  test('parseNutritionLabelFromLines extracts core fields', () {
    final res = parseNutritionLabelFromLines([
      OcrLine(text: 'Serving size 55 g', box: r(0, 0)),
      OcrLine(text: 'Calories 230', box: r(0, 10)),
      OcrLine(text: 'Total Fat 8g', box: r(0, 20)),
      OcrLine(text: 'Total Carbohydrate 37g', box: r(0, 30)),
      OcrLine(text: 'Total Sugars 12g', box: r(0, 40)),
      OcrLine(text: 'Dietary Fiber 4g', box: r(0, 50)),
      OcrLine(text: 'Protein 6g', box: r(0, 60)),
    ]);

    expect(res.draft.servingSize, 55);
    expect(res.draft.servingUnit, ServingUnit.g);
    expect(res.draft.calories, 230);
    expect(res.draft.fatG, 8);
    expect(res.draft.carbsG, 37);
    expect(res.draft.sugarG, 12);
    expect(res.draft.fiberG, 4);
    expect(res.draft.proteinG, 6);
    expect(res.fields, contains(NutritionField.calories));
    expect(res.fields[NutritionField.protein]!.box, r(0, 60));
  });

  test('parseNutritionLabelFromLines handles comma decimals', () {
    final res = parseNutritionLabelFromLines([
      OcrLine(text: 'Serving size 250 ml', box: r(0, 0)),
      OcrLine(text: 'Total Fat 3,5 g', box: r(0, 10)),
    ]);
    expect(res.draft.servingSize, 250);
    expect(res.draft.servingUnit, ServingUnit.ml);
    expect(res.draft.fatG, closeTo(3.5, 0.0001));
  });

  test('Canadian English cereal label: "Per 1 cup (30 g)"', () {
    final res = parseNutritionLabelFromLines([
      OcrLine(text: 'Nutrition Facts', box: r(0, 0)),
      OcrLine(text: 'Per 1 cup (30 g)', box: r(0, 10)),
      OcrLine(text: 'Calories 120', box: r(0, 20)),
      OcrLine(text: 'Fat 1.5 g 2 %', box: r(0, 30)),
      OcrLine(text: 'Carbohydrate 25 g 8 %', box: r(0, 40)),
      OcrLine(text: 'Fibre 3 g 11 %', box: r(0, 50)),
      OcrLine(text: 'Sugars 6 g', box: r(0, 60)),
      OcrLine(text: 'Protein 3 g', box: r(0, 70)),
    ]);

    expect(res.draft.servingSize, 30);
    expect(res.draft.servingUnit, ServingUnit.g);
    expect(res.draft.calories, 120);
    expect(res.draft.fatG, closeTo(1.5, 0.0001));
    expect(res.draft.carbsG, 25);
    expect(res.draft.fiberG, 3);
    expect(res.draft.sugarG, 6);
    expect(res.draft.proteinG, 3);
  });

  test('Canadian French cereal label: "pour 1 tasse (30 g)"', () {
    final res = parseNutritionLabelFromLines([
      OcrLine(text: 'Valeur nutritive', box: r(0, 0)),
      OcrLine(text: 'pour 1 tasse (30 g)', box: r(0, 10)),
      OcrLine(text: 'Calories 120', box: r(0, 20)),
      OcrLine(text: 'Lipides 1,5 g 2 %', box: r(0, 30)),
      OcrLine(text: 'Glucides 25 g 8 %', box: r(0, 40)),
      OcrLine(text: 'Fibres 3 g 11 %', box: r(0, 50)),
      OcrLine(text: 'Sucres 6 g', box: r(0, 60)),
      OcrLine(text: 'Protéines 3 g', box: r(0, 70)),
    ]);

    expect(res.draft.servingSize, 30);
    expect(res.draft.servingUnit, ServingUnit.g);
    expect(res.draft.calories, 120);
    expect(res.draft.fatG, closeTo(1.5, 0.0001));
    expect(res.draft.carbsG, 25);
    expect(res.draft.fiberG, 3);
    expect(res.draft.sugarG, 6);
    expect(res.draft.proteinG, 3);
  });

  test('Bilingual beverage label picks mL serving', () {
    final res = parseNutritionLabelFromLines([
      OcrLine(text: 'Per 250 mL / pour 250 ml', box: r(0, 0)),
      OcrLine(text: 'Calories 110', box: r(0, 10)),
      OcrLine(text: 'Fat / Lipides 0 g', box: r(0, 20)),
    ]);

    expect(res.draft.servingSize, 250);
    expect(res.draft.servingUnit, ServingUnit.ml);
    expect(res.draft.calories, 110);
    expect(res.draft.fatG, 0);
  });

  test('Vertical layout: serving header on its own line', () {
    final res = parseNutritionLabelFromLines([
      OcrLine(text: 'Serving size', box: r(0, 0)),
      OcrLine(text: '1 cup (30 g)', box: r(0, 10)),
      OcrLine(text: 'Calories', box: r(0, 20)),
      OcrLine(text: '230', box: r(0, 30)),
    ]);

    expect(res.draft.servingSize, 30);
    expect(res.draft.servingUnit, ServingUnit.g);
    expect(res.draft.calories, 230);
  });

  test('Macros ignore %DV and other companion numbers', () {
    final res = parseNutritionLabelFromLines([
      OcrLine(text: 'Serving size 100 g', box: r(0, 0)),
      OcrLine(text: 'Total Fat 8 g 12 %', box: r(0, 10)),
      OcrLine(text: 'Total Carbohydrate 37 g 13 %', box: r(0, 20)),
      OcrLine(text: 'Protein 6 g 12 %', box: r(0, 30)),
    ]);

    expect(res.draft.fatG, 8);
    expect(res.draft.carbsG, 37);
    expect(res.draft.proteinG, 6);
  });

  test('Yogurt-style serving "Per 175 g (3/4 cup)"', () {
    final res = parseNutritionLabelFromLines([
      OcrLine(text: 'Per 175 g (3/4 cup)', box: r(0, 0)),
      OcrLine(text: 'Calories 100', box: r(0, 10)),
    ]);

    expect(res.draft.servingSize, 175);
    expect(res.draft.servingUnit, ServingUnit.g);
    expect(res.draft.calories, 100);
  });
}

