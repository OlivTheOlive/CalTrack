enum NutrientKey {
  // Macronutrients
  kcal,
  totalFatG,
  saturatedFatG,
  transFatG,
  monounsaturatedFatG,
  polyunsaturatedFatG,
  cholesterolMg,
  totalCarbsG,
  dietaryFiberG,
  solubleFiberG,
  insolubleFiberG,
  totalSugarsG,
  addedSugarsG,
  sugarAlcoholsG,
  proteinG,

  // Minerals
  calciumMg,
  ironMg,
  magnesiumMg,
  phosphorusMg,
  potassiumMg,
  sodiumMg,
  zincMg,
  copperMg,
  manganeseMg,
  seleniumUg,
  chromiumUg,
  molybdenumUg,
  chlorideMg,
  fluorideMg,
  iodineUg,

  // Vitamins
  vitaminARaeUg,
  vitaminAIu,
  betaCaroteneUg,
  alphaCaroteneUg,
  vitaminB1ThiaminMg,
  vitaminB2RiboflavinMg,
  vitaminB3NiacinMg,
  vitaminB5PantothenicAcidMg,
  vitaminB6PyridoxineMg,
  vitaminB7BiotinUg,
  vitaminB9FolateDfeUg,
  folicAcidUg,
  vitaminB12CobalaminUg,
  vitaminCMg,
  vitaminD2D3Ug,
  vitaminDIu,
  vitaminEAlphaTocopherolMg,
  vitaminKPhylloquinoneUg,
  vitaminK2MenaquinoneUg,
  cholineMg,

  // Fatty Acids
  omega3TotalG,
  ePA,
  dHA,
  aLA,
  omega6TotalG,
  linoleicAcidG,
  arachidonicAcidG,

  // Amino Acids
  tryptophanG,
  threonineG,
  isoleucineG,
  leucineG,
  lysineG,
  methionineG,
  cystineG,
  phenylalanineG,
  tyrosineG,
  valineG,
  arginineG,
  histidineG,
  alanineG,
  asparticAcidG,
  glutamicAcidG,
  glycineG,
  prolineG,
  serineG,
}

enum NutrientCategory {
  macro,
  subMacro,
  mineral,
  vitamin,
  fattyAcid,
  aminoAcid,
}

class NutrientInfo {
  const NutrientInfo({
    required this.key,
    required this.displayName,
    required this.unit,
    required this.category,
  });

  final NutrientKey key;
  final String displayName;
  final String unit;
  final NutrientCategory category;
}

const nutrientInfoMap = <NutrientKey, NutrientInfo>{
  // Macronutrients
  NutrientKey.kcal: NutrientInfo(
    key: NutrientKey.kcal,
    displayName: 'Calories',
    unit: 'kcal',
    category: NutrientCategory.macro,
  ),
  NutrientKey.totalFatG: NutrientInfo(
    key: NutrientKey.totalFatG,
    displayName: 'Total Fat',
    unit: 'g',
    category: NutrientCategory.macro,
  ),
  NutrientKey.saturatedFatG: NutrientInfo(
    key: NutrientKey.saturatedFatG,
    displayName: 'Saturated Fat',
    unit: 'g',
    category: NutrientCategory.subMacro,
  ),
  NutrientKey.transFatG: NutrientInfo(
    key: NutrientKey.transFatG,
    displayName: 'Trans Fat',
    unit: 'g',
    category: NutrientCategory.subMacro,
  ),
  NutrientKey.monounsaturatedFatG: NutrientInfo(
    key: NutrientKey.monounsaturatedFatG,
    displayName: 'Monounsaturated Fat',
    unit: 'g',
    category: NutrientCategory.subMacro,
  ),
  NutrientKey.polyunsaturatedFatG: NutrientInfo(
    key: NutrientKey.polyunsaturatedFatG,
    displayName: 'Polyunsaturated Fat',
    unit: 'g',
    category: NutrientCategory.subMacro,
  ),
  NutrientKey.cholesterolMg: NutrientInfo(
    key: NutrientKey.cholesterolMg,
    displayName: 'Cholesterol',
    unit: 'mg',
    category: NutrientCategory.subMacro,
  ),
  NutrientKey.totalCarbsG: NutrientInfo(
    key: NutrientKey.totalCarbsG,
    displayName: 'Total Carbohydrates',
    unit: 'g',
    category: NutrientCategory.macro,
  ),
  NutrientKey.dietaryFiberG: NutrientInfo(
    key: NutrientKey.dietaryFiberG,
    displayName: 'Dietary Fiber',
    unit: 'g',
    category: NutrientCategory.subMacro,
  ),
  NutrientKey.solubleFiberG: NutrientInfo(
    key: NutrientKey.solubleFiberG,
    displayName: 'Soluble Fiber',
    unit: 'g',
    category: NutrientCategory.subMacro,
  ),
  NutrientKey.insolubleFiberG: NutrientInfo(
    key: NutrientKey.insolubleFiberG,
    displayName: 'Insoluble Fiber',
    unit: 'g',
    category: NutrientCategory.subMacro,
  ),
  NutrientKey.totalSugarsG: NutrientInfo(
    key: NutrientKey.totalSugarsG,
    displayName: 'Total Sugars',
    unit: 'g',
    category: NutrientCategory.subMacro,
  ),
  NutrientKey.addedSugarsG: NutrientInfo(
    key: NutrientKey.addedSugarsG,
    displayName: 'Added Sugars',
    unit: 'g',
    category: NutrientCategory.subMacro,
  ),
  NutrientKey.sugarAlcoholsG: NutrientInfo(
    key: NutrientKey.sugarAlcoholsG,
    displayName: 'Sugar Alcohols',
    unit: 'g',
    category: NutrientCategory.subMacro,
  ),
  NutrientKey.proteinG: NutrientInfo(
    key: NutrientKey.proteinG,
    displayName: 'Protein',
    unit: 'g',
    category: NutrientCategory.macro,
  ),

  // Minerals
  NutrientKey.calciumMg: NutrientInfo(
    key: NutrientKey.calciumMg,
    displayName: 'Calcium',
    unit: 'mg',
    category: NutrientCategory.mineral,
  ),
  NutrientKey.ironMg: NutrientInfo(
    key: NutrientKey.ironMg,
    displayName: 'Iron',
    unit: 'mg',
    category: NutrientCategory.mineral,
  ),
  NutrientKey.magnesiumMg: NutrientInfo(
    key: NutrientKey.magnesiumMg,
    displayName: 'Magnesium',
    unit: 'mg',
    category: NutrientCategory.mineral,
  ),
  NutrientKey.phosphorusMg: NutrientInfo(
    key: NutrientKey.phosphorusMg,
    displayName: 'Phosphorus',
    unit: 'mg',
    category: NutrientCategory.mineral,
  ),
  NutrientKey.potassiumMg: NutrientInfo(
    key: NutrientKey.potassiumMg,
    displayName: 'Potassium',
    unit: 'mg',
    category: NutrientCategory.mineral,
  ),
  NutrientKey.sodiumMg: NutrientInfo(
    key: NutrientKey.sodiumMg,
    displayName: 'Sodium',
    unit: 'mg',
    category: NutrientCategory.mineral,
  ),
  NutrientKey.zincMg: NutrientInfo(
    key: NutrientKey.zincMg,
    displayName: 'Zinc',
    unit: 'mg',
    category: NutrientCategory.mineral,
  ),
  NutrientKey.copperMg: NutrientInfo(
    key: NutrientKey.copperMg,
    displayName: 'Copper',
    unit: 'mg',
    category: NutrientCategory.mineral,
  ),
  NutrientKey.manganeseMg: NutrientInfo(
    key: NutrientKey.manganeseMg,
    displayName: 'Manganese',
    unit: 'mg',
    category: NutrientCategory.mineral,
  ),
  NutrientKey.seleniumUg: NutrientInfo(
    key: NutrientKey.seleniumUg,
    displayName: 'Selenium',
    unit: '\u00b5g',
    category: NutrientCategory.mineral,
  ),
  NutrientKey.chromiumUg: NutrientInfo(
    key: NutrientKey.chromiumUg,
    displayName: 'Chromium',
    unit: '\u00b5g',
    category: NutrientCategory.mineral,
  ),
  NutrientKey.molybdenumUg: NutrientInfo(
    key: NutrientKey.molybdenumUg,
    displayName: 'Molybdenum',
    unit: '\u00b5g',
    category: NutrientCategory.mineral,
  ),
  NutrientKey.chlorideMg: NutrientInfo(
    key: NutrientKey.chlorideMg,
    displayName: 'Chloride',
    unit: 'mg',
    category: NutrientCategory.mineral,
  ),
  NutrientKey.fluorideMg: NutrientInfo(
    key: NutrientKey.fluorideMg,
    displayName: 'Fluoride',
    unit: 'mg',
    category: NutrientCategory.mineral,
  ),
  NutrientKey.iodineUg: NutrientInfo(
    key: NutrientKey.iodineUg,
    displayName: 'Iodine',
    unit: '\u00b5g',
    category: NutrientCategory.mineral,
  ),

  // Vitamins
  NutrientKey.vitaminARaeUg: NutrientInfo(
    key: NutrientKey.vitaminARaeUg,
    displayName: 'Vitamin A (RAE)',
    unit: '\u00b5g',
    category: NutrientCategory.vitamin,
  ),
  NutrientKey.vitaminAIu: NutrientInfo(
    key: NutrientKey.vitaminAIu,
    displayName: 'Vitamin A (IU)',
    unit: 'IU',
    category: NutrientCategory.vitamin,
  ),
  NutrientKey.betaCaroteneUg: NutrientInfo(
    key: NutrientKey.betaCaroteneUg,
    displayName: 'Beta-Carotene',
    unit: '\u00b5g',
    category: NutrientCategory.vitamin,
  ),
  NutrientKey.alphaCaroteneUg: NutrientInfo(
    key: NutrientKey.alphaCaroteneUg,
    displayName: 'Alpha-Carotene',
    unit: '\u00b5g',
    category: NutrientCategory.vitamin,
  ),
  NutrientKey.vitaminB1ThiaminMg: NutrientInfo(
    key: NutrientKey.vitaminB1ThiaminMg,
    displayName: 'Vitamin B1 (Thiamin)',
    unit: 'mg',
    category: NutrientCategory.vitamin,
  ),
  NutrientKey.vitaminB2RiboflavinMg: NutrientInfo(
    key: NutrientKey.vitaminB2RiboflavinMg,
    displayName: 'Vitamin B2 (Riboflavin)',
    unit: 'mg',
    category: NutrientCategory.vitamin,
  ),
  NutrientKey.vitaminB3NiacinMg: NutrientInfo(
    key: NutrientKey.vitaminB3NiacinMg,
    displayName: 'Vitamin B3 (Niacin)',
    unit: 'mg',
    category: NutrientCategory.vitamin,
  ),
  NutrientKey.vitaminB5PantothenicAcidMg: NutrientInfo(
    key: NutrientKey.vitaminB5PantothenicAcidMg,
    displayName: 'Vitamin B5 (Pantothenic Acid)',
    unit: 'mg',
    category: NutrientCategory.vitamin,
  ),
  NutrientKey.vitaminB6PyridoxineMg: NutrientInfo(
    key: NutrientKey.vitaminB6PyridoxineMg,
    displayName: 'Vitamin B6 (Pyridoxine)',
    unit: 'mg',
    category: NutrientCategory.vitamin,
  ),
  NutrientKey.vitaminB7BiotinUg: NutrientInfo(
    key: NutrientKey.vitaminB7BiotinUg,
    displayName: 'Vitamin B7 (Biotin)',
    unit: '\u00b5g',
    category: NutrientCategory.vitamin,
  ),
  NutrientKey.vitaminB9FolateDfeUg: NutrientInfo(
    key: NutrientKey.vitaminB9FolateDfeUg,
    displayName: 'Vitamin B9 (Folate / DFE)',
    unit: '\u00b5g',
    category: NutrientCategory.vitamin,
  ),
  NutrientKey.folicAcidUg: NutrientInfo(
    key: NutrientKey.folicAcidUg,
    displayName: 'Folic Acid',
    unit: '\u00b5g',
    category: NutrientCategory.vitamin,
  ),
  NutrientKey.vitaminB12CobalaminUg: NutrientInfo(
    key: NutrientKey.vitaminB12CobalaminUg,
    displayName: 'Vitamin B12 (Cobalamin)',
    unit: '\u00b5g',
    category: NutrientCategory.vitamin,
  ),
  NutrientKey.vitaminCMg: NutrientInfo(
    key: NutrientKey.vitaminCMg,
    displayName: 'Vitamin C (Ascorbic Acid)',
    unit: 'mg',
    category: NutrientCategory.vitamin,
  ),
  NutrientKey.vitaminD2D3Ug: NutrientInfo(
    key: NutrientKey.vitaminD2D3Ug,
    displayName: 'Vitamin D (D2 + D3)',
    unit: '\u00b5g',
    category: NutrientCategory.vitamin,
  ),
  NutrientKey.vitaminDIu: NutrientInfo(
    key: NutrientKey.vitaminDIu,
    displayName: 'Vitamin D (IU)',
    unit: 'IU',
    category: NutrientCategory.vitamin,
  ),
  NutrientKey.vitaminEAlphaTocopherolMg: NutrientInfo(
    key: NutrientKey.vitaminEAlphaTocopherolMg,
    displayName: 'Vitamin E (Alpha-Tocopherol)',
    unit: 'mg',
    category: NutrientCategory.vitamin,
  ),
  NutrientKey.vitaminKPhylloquinoneUg: NutrientInfo(
    key: NutrientKey.vitaminKPhylloquinoneUg,
    displayName: 'Vitamin K (Phylloquinone)',
    unit: '\u00b5g',
    category: NutrientCategory.vitamin,
  ),
  NutrientKey.vitaminK2MenaquinoneUg: NutrientInfo(
    key: NutrientKey.vitaminK2MenaquinoneUg,
    displayName: 'Vitamin K2 (Menaquinone)',
    unit: '\u00b5g',
    category: NutrientCategory.vitamin,
  ),
  NutrientKey.cholineMg: NutrientInfo(
    key: NutrientKey.cholineMg,
    displayName: 'Choline',
    unit: 'mg',
    category: NutrientCategory.vitamin,
  ),

  // Fatty Acids
  NutrientKey.omega3TotalG: NutrientInfo(
    key: NutrientKey.omega3TotalG,
    displayName: 'Omega-3 (Total)',
    unit: 'g',
    category: NutrientCategory.fattyAcid,
  ),
  NutrientKey.ePA: NutrientInfo(
    key: NutrientKey.ePA,
    displayName: 'EPA (Eicosapentaenoic Acid)',
    unit: 'g',
    category: NutrientCategory.fattyAcid,
  ),
  NutrientKey.dHA: NutrientInfo(
    key: NutrientKey.dHA,
    displayName: 'DHA (Docosahexaenoic Acid)',
    unit: 'g',
    category: NutrientCategory.fattyAcid,
  ),
  NutrientKey.aLA: NutrientInfo(
    key: NutrientKey.aLA,
    displayName: 'ALA (Alpha-Linolenic Acid)',
    unit: 'g',
    category: NutrientCategory.fattyAcid,
  ),
  NutrientKey.omega6TotalG: NutrientInfo(
    key: NutrientKey.omega6TotalG,
    displayName: 'Omega-6 (Total)',
    unit: 'g',
    category: NutrientCategory.fattyAcid,
  ),
  NutrientKey.linoleicAcidG: NutrientInfo(
    key: NutrientKey.linoleicAcidG,
    displayName: 'Linoleic Acid',
    unit: 'g',
    category: NutrientCategory.fattyAcid,
  ),
  NutrientKey.arachidonicAcidG: NutrientInfo(
    key: NutrientKey.arachidonicAcidG,
    displayName: 'Arachidonic Acid',
    unit: 'g',
    category: NutrientCategory.fattyAcid,
  ),

  // Amino Acids
  NutrientKey.tryptophanG: NutrientInfo(
    key: NutrientKey.tryptophanG,
    displayName: 'Tryptophan',
    unit: 'g',
    category: NutrientCategory.aminoAcid,
  ),
  NutrientKey.threonineG: NutrientInfo(
    key: NutrientKey.threonineG,
    displayName: 'Threonine',
    unit: 'g',
    category: NutrientCategory.aminoAcid,
  ),
  NutrientKey.isoleucineG: NutrientInfo(
    key: NutrientKey.isoleucineG,
    displayName: 'Isoleucine',
    unit: 'g',
    category: NutrientCategory.aminoAcid,
  ),
  NutrientKey.leucineG: NutrientInfo(
    key: NutrientKey.leucineG,
    displayName: 'Leucine',
    unit: 'g',
    category: NutrientCategory.aminoAcid,
  ),
  NutrientKey.lysineG: NutrientInfo(
    key: NutrientKey.lysineG,
    displayName: 'Lysine',
    unit: 'g',
    category: NutrientCategory.aminoAcid,
  ),
  NutrientKey.methionineG: NutrientInfo(
    key: NutrientKey.methionineG,
    displayName: 'Methionine',
    unit: 'g',
    category: NutrientCategory.aminoAcid,
  ),
  NutrientKey.cystineG: NutrientInfo(
    key: NutrientKey.cystineG,
    displayName: 'Cystine',
    unit: 'g',
    category: NutrientCategory.aminoAcid,
  ),
  NutrientKey.phenylalanineG: NutrientInfo(
    key: NutrientKey.phenylalanineG,
    displayName: 'Phenylalanine',
    unit: 'g',
    category: NutrientCategory.aminoAcid,
  ),
  NutrientKey.tyrosineG: NutrientInfo(
    key: NutrientKey.tyrosineG,
    displayName: 'Tyrosine',
    unit: 'g',
    category: NutrientCategory.aminoAcid,
  ),
  NutrientKey.valineG: NutrientInfo(
    key: NutrientKey.valineG,
    displayName: 'Valine',
    unit: 'g',
    category: NutrientCategory.aminoAcid,
  ),
  NutrientKey.arginineG: NutrientInfo(
    key: NutrientKey.arginineG,
    displayName: 'Arginine',
    unit: 'g',
    category: NutrientCategory.aminoAcid,
  ),
  NutrientKey.histidineG: NutrientInfo(
    key: NutrientKey.histidineG,
    displayName: 'Histidine',
    unit: 'g',
    category: NutrientCategory.aminoAcid,
  ),
  NutrientKey.alanineG: NutrientInfo(
    key: NutrientKey.alanineG,
    displayName: 'Alanine',
    unit: 'g',
    category: NutrientCategory.aminoAcid,
  ),
  NutrientKey.asparticAcidG: NutrientInfo(
    key: NutrientKey.asparticAcidG,
    displayName: 'Aspartic Acid',
    unit: 'g',
    category: NutrientCategory.aminoAcid,
  ),
  NutrientKey.glutamicAcidG: NutrientInfo(
    key: NutrientKey.glutamicAcidG,
    displayName: 'Glutamic Acid',
    unit: 'g',
    category: NutrientCategory.aminoAcid,
  ),
  NutrientKey.glycineG: NutrientInfo(
    key: NutrientKey.glycineG,
    displayName: 'Glycine',
    unit: 'g',
    category: NutrientCategory.aminoAcid,
  ),
  NutrientKey.prolineG: NutrientInfo(
    key: NutrientKey.prolineG,
    displayName: 'Proline',
    unit: 'g',
    category: NutrientCategory.aminoAcid,
  ),
  NutrientKey.serineG: NutrientInfo(
    key: NutrientKey.serineG,
    displayName: 'Serine',
    unit: 'g',
    category: NutrientCategory.aminoAcid,
  ),
};

/// Health Canada Daily Values (ages 4+) for nutrition labelling.
/// Values in the unit of the respective nutrient.
/// Extended with US DRI / adequate intake values for nutrients without
/// a published Canadian daily value.
const dailyValues = <NutrientKey, double>{
  NutrientKey.kcal: 2000,
  NutrientKey.totalFatG: 75,
  NutrientKey.saturatedFatG: 20,
  NutrientKey.transFatG: 0,
  NutrientKey.monounsaturatedFatG: 20,
  NutrientKey.polyunsaturatedFatG: 13,
  NutrientKey.cholesterolMg: 300,
  NutrientKey.totalCarbsG: 300,
  NutrientKey.dietaryFiberG: 28,
  NutrientKey.solubleFiberG: 7,
  NutrientKey.insolubleFiberG: 21,
  NutrientKey.totalSugarsG: 100,
  NutrientKey.addedSugarsG: 50,
  NutrientKey.sugarAlcoholsG: 10,
  NutrientKey.proteinG: 50,
  NutrientKey.calciumMg: 1300,
  NutrientKey.ironMg: 18,
  NutrientKey.magnesiumMg: 420,
  NutrientKey.phosphorusMg: 1250,
  NutrientKey.potassiumMg: 3400,
  NutrientKey.sodiumMg: 2300,
  NutrientKey.zincMg: 11,
  NutrientKey.copperMg: 0.9,
  NutrientKey.manganeseMg: 2.3,
  NutrientKey.seleniumUg: 55,
  NutrientKey.chromiumUg: 35,
  NutrientKey.molybdenumUg: 45,
  NutrientKey.chlorideMg: 2300,
  NutrientKey.fluorideMg: 4,
  NutrientKey.iodineUg: 150,
  NutrientKey.vitaminARaeUg: 900,
  NutrientKey.vitaminAIu: 3000,
  NutrientKey.betaCaroteneUg: 3000,
  NutrientKey.alphaCaroteneUg: 600,
  NutrientKey.vitaminB1ThiaminMg: 1.2,
  NutrientKey.vitaminB2RiboflavinMg: 1.3,
  NutrientKey.vitaminB3NiacinMg: 16,
  NutrientKey.vitaminB5PantothenicAcidMg: 5,
  NutrientKey.vitaminB6PyridoxineMg: 1.7,
  NutrientKey.vitaminB7BiotinUg: 30,
  NutrientKey.vitaminB9FolateDfeUg: 400,
  NutrientKey.folicAcidUg: 400,
  NutrientKey.vitaminB12CobalaminUg: 2.4,
  NutrientKey.vitaminCMg: 90,
  NutrientKey.vitaminD2D3Ug: 20,
  NutrientKey.vitaminDIu: 800,
  NutrientKey.vitaminEAlphaTocopherolMg: 15,
  NutrientKey.vitaminKPhylloquinoneUg: 120,
  NutrientKey.vitaminK2MenaquinoneUg: 45,
  NutrientKey.cholineMg: 550,
  NutrientKey.omega3TotalG: 1.6,
  NutrientKey.ePA: 0.25,
  NutrientKey.dHA: 0.25,
  NutrientKey.aLA: 1.6,
  NutrientKey.omega6TotalG: 17,
  NutrientKey.linoleicAcidG: 17,
  NutrientKey.arachidonicAcidG: 0.5,
  NutrientKey.tryptophanG: 0.28,
  NutrientKey.threonineG: 1.05,
  NutrientKey.isoleucineG: 1.4,
  NutrientKey.leucineG: 2.73,
  NutrientKey.lysineG: 2.1,
  NutrientKey.methionineG: 0.728,
  NutrientKey.cystineG: 0.287,
  NutrientKey.phenylalanineG: 1.75,
  NutrientKey.tyrosineG: 1.75,
  NutrientKey.valineG: 1.82,
  NutrientKey.arginineG: 2.5,
  NutrientKey.histidineG: 0.7,
  NutrientKey.alanineG: 2.0,
  NutrientKey.asparticAcidG: 2.5,
  NutrientKey.glutamicAcidG: 5.0,
  NutrientKey.glycineG: 1.5,
  NutrientKey.prolineG: 2.0,
  NutrientKey.serineG: 1.5,
};

/// DRI Tolerable Upper Intake Levels (UL) for adults 19+.
/// null = no established UL.
const upperLimits = <NutrientKey, double?>{
  NutrientKey.vitaminARaeUg: 3000,
  NutrientKey.vitaminD2D3Ug: 100,
  NutrientKey.vitaminEAlphaTocopherolMg: 1000,
  NutrientKey.vitaminB3NiacinMg: 35,
  NutrientKey.vitaminB6PyridoxineMg: 100,
  NutrientKey.vitaminB9FolateDfeUg: 1000,
  NutrientKey.vitaminCMg: 2000,
  NutrientKey.cholineMg: 3500,
  NutrientKey.calciumMg: 2500,
  NutrientKey.ironMg: 45,
  NutrientKey.magnesiumMg: 350,
  NutrientKey.phosphorusMg: 4000,
  NutrientKey.zincMg: 40,
  NutrientKey.copperMg: 10,
  NutrientKey.seleniumUg: 400,
  NutrientKey.iodineUg: 1100,
  NutrientKey.manganeseMg: 11,
  NutrientKey.molybdenumUg: 2000,
  NutrientKey.fluorideMg: 10,
  NutrientKey.chlorideMg: 3600,
  NutrientKey.vitaminB5PantothenicAcidMg: null,
  NutrientKey.vitaminB7BiotinUg: null,
  NutrientKey.vitaminB12CobalaminUg: null,
  NutrientKey.vitaminKPhylloquinoneUg: null,
  NutrientKey.vitaminB1ThiaminMg: null,
  NutrientKey.vitaminB2RiboflavinMg: null,
  NutrientKey.sodiumMg: null,
  NutrientKey.potassiumMg: null,
  NutrientKey.chromiumUg: null,
  NutrientKey.totalFatG: null,
  NutrientKey.saturatedFatG: null,
  NutrientKey.transFatG: null,
  NutrientKey.cholesterolMg: null,
  NutrientKey.totalCarbsG: null,
  NutrientKey.dietaryFiberG: null,
  NutrientKey.totalSugarsG: null,
  NutrientKey.proteinG: null,
};

const nutrientCategoryLabels = <NutrientCategory, String>{
  NutrientCategory.macro: 'Macronutrients',
  NutrientCategory.subMacro: 'Sub-Macronutrients',
  NutrientCategory.mineral: 'Minerals',
  NutrientCategory.vitamin: 'Vitamins',
  NutrientCategory.fattyAcid: 'Fatty Acids',
  NutrientCategory.aminoAcid: 'Amino Acids',
};

const nutrientCategoryOrder = [
  NutrientCategory.macro,
  NutrientCategory.subMacro,
  NutrientCategory.mineral,
  NutrientCategory.vitamin,
  NutrientCategory.fattyAcid,
  NutrientCategory.aminoAcid,
];

List<NutrientKey> nutrientsInCategory(NutrientCategory category) {
  return nutrientInfoMap.entries
      .where((e) => e.value.category == category)
      .map((e) => e.key)
      .toList();
}

extension NutrientKeyDisplay on NutrientKey {
  NutrientInfo get info => nutrientInfoMap[this]!;
  String get displayName => info.displayName;
  String get unit => info.unit;
  NutrientCategory get category => info.category;
  double? get dailyValue => dailyValues[this];
  double? get upperLimit => upperLimits[this];
}