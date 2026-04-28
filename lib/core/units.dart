// Internal storage uses metric (kg, cm). Display uses user preference.

const double kgPerLb = 0.45359237;
const double cmPerInch = 2.54;

double kgToLb(double kg) => kg / kgPerLb;

double lbToKg(double lb) => lb * kgPerLb;

double cmToInches(double cm) => cm / cmPerInch;

double inchesToCm(double inches) => inches * cmPerInch;

enum WeightUnit {
  kg,
  lb;

  String get shortLabel => name;

  static WeightUnit fromStored(String value) =>
      WeightUnit.values.byName(value);
}
