// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProfilesTable extends Profiles with TableInfo<$ProfilesTable, Profile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _sexMeta = const VerificationMeta('sex');
  @override
  late final GeneratedColumn<String> sex = GeneratedColumn<String>(
    'sex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _birthDateMillisMeta = const VerificationMeta(
    'birthDateMillis',
  );
  @override
  late final GeneratedColumn<int> birthDateMillis = GeneratedColumn<int>(
    'birth_date_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ageBandMaxYearsMeta = const VerificationMeta(
    'ageBandMaxYears',
  );
  @override
  late final GeneratedColumn<int> ageBandMaxYears = GeneratedColumn<int>(
    'age_band_max_years',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heightCmMeta = const VerificationMeta(
    'heightCm',
  );
  @override
  late final GeneratedColumn<double> heightCm = GeneratedColumn<double>(
    'height_cm',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activityLevelMeta = const VerificationMeta(
    'activityLevel',
  );
  @override
  late final GeneratedColumn<int> activityLevel = GeneratedColumn<int>(
    'activity_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightUnitMeta = const VerificationMeta(
    'weightUnit',
  );
  @override
  late final GeneratedColumn<String> weightUnit = GeneratedColumn<String>(
    'weight_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinPctMeta = const VerificationMeta(
    'proteinPct',
  );
  @override
  late final GeneratedColumn<int> proteinPct = GeneratedColumn<int>(
    'protein_pct',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbsPctMeta = const VerificationMeta(
    'carbsPct',
  );
  @override
  late final GeneratedColumn<int> carbsPct = GeneratedColumn<int>(
    'carbs_pct',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatPctMeta = const VerificationMeta('fatPct');
  @override
  late final GeneratedColumn<int> fatPct = GeneratedColumn<int>(
    'fat_pct',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reminderWeekdayMeta = const VerificationMeta(
    'reminderWeekday',
  );
  @override
  late final GeneratedColumn<int> reminderWeekday = GeneratedColumn<int>(
    'reminder_weekday',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reminderHourMeta = const VerificationMeta(
    'reminderHour',
  );
  @override
  late final GeneratedColumn<int> reminderHour = GeneratedColumn<int>(
    'reminder_hour',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reminderMinuteMeta = const VerificationMeta(
    'reminderMinute',
  );
  @override
  late final GeneratedColumn<int> reminderMinute = GeneratedColumn<int>(
    'reminder_minute',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _onboardingCompletedMeta =
      const VerificationMeta('onboardingCompleted');
  @override
  late final GeneratedColumn<bool> onboardingCompleted = GeneratedColumn<bool>(
    'onboarding_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("onboarding_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dailyCalorieTargetMeta =
      const VerificationMeta('dailyCalorieTarget');
  @override
  late final GeneratedColumn<double> dailyCalorieTarget =
      GeneratedColumn<double>(
        'daily_calorie_target',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sex,
    birthDateMillis,
    ageBandMaxYears,
    heightCm,
    activityLevel,
    weightUnit,
    proteinPct,
    carbsPct,
    fatPct,
    reminderWeekday,
    reminderHour,
    reminderMinute,
    onboardingCompleted,
    dailyCalorieTarget,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Profile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sex')) {
      context.handle(
        _sexMeta,
        sex.isAcceptableOrUnknown(data['sex']!, _sexMeta),
      );
    } else if (isInserting) {
      context.missing(_sexMeta);
    }
    if (data.containsKey('birth_date_millis')) {
      context.handle(
        _birthDateMillisMeta,
        birthDateMillis.isAcceptableOrUnknown(
          data['birth_date_millis']!,
          _birthDateMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_birthDateMillisMeta);
    }
    if (data.containsKey('age_band_max_years')) {
      context.handle(
        _ageBandMaxYearsMeta,
        ageBandMaxYears.isAcceptableOrUnknown(
          data['age_band_max_years']!,
          _ageBandMaxYearsMeta,
        ),
      );
    }
    if (data.containsKey('height_cm')) {
      context.handle(
        _heightCmMeta,
        heightCm.isAcceptableOrUnknown(data['height_cm']!, _heightCmMeta),
      );
    } else if (isInserting) {
      context.missing(_heightCmMeta);
    }
    if (data.containsKey('activity_level')) {
      context.handle(
        _activityLevelMeta,
        activityLevel.isAcceptableOrUnknown(
          data['activity_level']!,
          _activityLevelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activityLevelMeta);
    }
    if (data.containsKey('weight_unit')) {
      context.handle(
        _weightUnitMeta,
        weightUnit.isAcceptableOrUnknown(data['weight_unit']!, _weightUnitMeta),
      );
    } else if (isInserting) {
      context.missing(_weightUnitMeta);
    }
    if (data.containsKey('protein_pct')) {
      context.handle(
        _proteinPctMeta,
        proteinPct.isAcceptableOrUnknown(data['protein_pct']!, _proteinPctMeta),
      );
    } else if (isInserting) {
      context.missing(_proteinPctMeta);
    }
    if (data.containsKey('carbs_pct')) {
      context.handle(
        _carbsPctMeta,
        carbsPct.isAcceptableOrUnknown(data['carbs_pct']!, _carbsPctMeta),
      );
    } else if (isInserting) {
      context.missing(_carbsPctMeta);
    }
    if (data.containsKey('fat_pct')) {
      context.handle(
        _fatPctMeta,
        fatPct.isAcceptableOrUnknown(data['fat_pct']!, _fatPctMeta),
      );
    } else if (isInserting) {
      context.missing(_fatPctMeta);
    }
    if (data.containsKey('reminder_weekday')) {
      context.handle(
        _reminderWeekdayMeta,
        reminderWeekday.isAcceptableOrUnknown(
          data['reminder_weekday']!,
          _reminderWeekdayMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reminderWeekdayMeta);
    }
    if (data.containsKey('reminder_hour')) {
      context.handle(
        _reminderHourMeta,
        reminderHour.isAcceptableOrUnknown(
          data['reminder_hour']!,
          _reminderHourMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reminderHourMeta);
    }
    if (data.containsKey('reminder_minute')) {
      context.handle(
        _reminderMinuteMeta,
        reminderMinute.isAcceptableOrUnknown(
          data['reminder_minute']!,
          _reminderMinuteMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reminderMinuteMeta);
    }
    if (data.containsKey('onboarding_completed')) {
      context.handle(
        _onboardingCompletedMeta,
        onboardingCompleted.isAcceptableOrUnknown(
          data['onboarding_completed']!,
          _onboardingCompletedMeta,
        ),
      );
    }
    if (data.containsKey('daily_calorie_target')) {
      context.handle(
        _dailyCalorieTargetMeta,
        dailyCalorieTarget.isAcceptableOrUnknown(
          data['daily_calorie_target']!,
          _dailyCalorieTargetMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Profile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Profile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sex'],
      )!,
      birthDateMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}birth_date_millis'],
      )!,
      ageBandMaxYears: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}age_band_max_years'],
      ),
      heightCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}height_cm'],
      )!,
      activityLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}activity_level'],
      )!,
      weightUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weight_unit'],
      )!,
      proteinPct: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}protein_pct'],
      )!,
      carbsPct: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}carbs_pct'],
      )!,
      fatPct: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fat_pct'],
      )!,
      reminderWeekday: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_weekday'],
      )!,
      reminderHour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_hour'],
      )!,
      reminderMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_minute'],
      )!,
      onboardingCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}onboarding_completed'],
      )!,
      dailyCalorieTarget: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}daily_calorie_target'],
      ),
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class Profile extends DataClass implements Insertable<Profile> {
  final int id;
  final String sex;
  final int birthDateMillis;

  /// Upper bound of the user's age band (years). Preferred input to TDEE
  /// math; older rows may have it null and fall back to [birthDateMillis].
  final int? ageBandMaxYears;
  final double heightCm;
  final int activityLevel;
  final String weightUnit;
  final int proteinPct;
  final int carbsPct;
  final int fatPct;
  final int reminderWeekday;
  final int reminderHour;
  final int reminderMinute;
  final bool onboardingCompleted;
  final double? dailyCalorieTarget;
  const Profile({
    required this.id,
    required this.sex,
    required this.birthDateMillis,
    this.ageBandMaxYears,
    required this.heightCm,
    required this.activityLevel,
    required this.weightUnit,
    required this.proteinPct,
    required this.carbsPct,
    required this.fatPct,
    required this.reminderWeekday,
    required this.reminderHour,
    required this.reminderMinute,
    required this.onboardingCompleted,
    this.dailyCalorieTarget,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sex'] = Variable<String>(sex);
    map['birth_date_millis'] = Variable<int>(birthDateMillis);
    if (!nullToAbsent || ageBandMaxYears != null) {
      map['age_band_max_years'] = Variable<int>(ageBandMaxYears);
    }
    map['height_cm'] = Variable<double>(heightCm);
    map['activity_level'] = Variable<int>(activityLevel);
    map['weight_unit'] = Variable<String>(weightUnit);
    map['protein_pct'] = Variable<int>(proteinPct);
    map['carbs_pct'] = Variable<int>(carbsPct);
    map['fat_pct'] = Variable<int>(fatPct);
    map['reminder_weekday'] = Variable<int>(reminderWeekday);
    map['reminder_hour'] = Variable<int>(reminderHour);
    map['reminder_minute'] = Variable<int>(reminderMinute);
    map['onboarding_completed'] = Variable<bool>(onboardingCompleted);
    if (!nullToAbsent || dailyCalorieTarget != null) {
      map['daily_calorie_target'] = Variable<double>(dailyCalorieTarget);
    }
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      sex: Value(sex),
      birthDateMillis: Value(birthDateMillis),
      ageBandMaxYears: ageBandMaxYears == null && nullToAbsent
          ? const Value.absent()
          : Value(ageBandMaxYears),
      heightCm: Value(heightCm),
      activityLevel: Value(activityLevel),
      weightUnit: Value(weightUnit),
      proteinPct: Value(proteinPct),
      carbsPct: Value(carbsPct),
      fatPct: Value(fatPct),
      reminderWeekday: Value(reminderWeekday),
      reminderHour: Value(reminderHour),
      reminderMinute: Value(reminderMinute),
      onboardingCompleted: Value(onboardingCompleted),
      dailyCalorieTarget: dailyCalorieTarget == null && nullToAbsent
          ? const Value.absent()
          : Value(dailyCalorieTarget),
    );
  }

  factory Profile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Profile(
      id: serializer.fromJson<int>(json['id']),
      sex: serializer.fromJson<String>(json['sex']),
      birthDateMillis: serializer.fromJson<int>(json['birthDateMillis']),
      ageBandMaxYears: serializer.fromJson<int?>(json['ageBandMaxYears']),
      heightCm: serializer.fromJson<double>(json['heightCm']),
      activityLevel: serializer.fromJson<int>(json['activityLevel']),
      weightUnit: serializer.fromJson<String>(json['weightUnit']),
      proteinPct: serializer.fromJson<int>(json['proteinPct']),
      carbsPct: serializer.fromJson<int>(json['carbsPct']),
      fatPct: serializer.fromJson<int>(json['fatPct']),
      reminderWeekday: serializer.fromJson<int>(json['reminderWeekday']),
      reminderHour: serializer.fromJson<int>(json['reminderHour']),
      reminderMinute: serializer.fromJson<int>(json['reminderMinute']),
      onboardingCompleted: serializer.fromJson<bool>(
        json['onboardingCompleted'],
      ),
      dailyCalorieTarget: serializer.fromJson<double?>(
        json['dailyCalorieTarget'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sex': serializer.toJson<String>(sex),
      'birthDateMillis': serializer.toJson<int>(birthDateMillis),
      'ageBandMaxYears': serializer.toJson<int?>(ageBandMaxYears),
      'heightCm': serializer.toJson<double>(heightCm),
      'activityLevel': serializer.toJson<int>(activityLevel),
      'weightUnit': serializer.toJson<String>(weightUnit),
      'proteinPct': serializer.toJson<int>(proteinPct),
      'carbsPct': serializer.toJson<int>(carbsPct),
      'fatPct': serializer.toJson<int>(fatPct),
      'reminderWeekday': serializer.toJson<int>(reminderWeekday),
      'reminderHour': serializer.toJson<int>(reminderHour),
      'reminderMinute': serializer.toJson<int>(reminderMinute),
      'onboardingCompleted': serializer.toJson<bool>(onboardingCompleted),
      'dailyCalorieTarget': serializer.toJson<double?>(dailyCalorieTarget),
    };
  }

  Profile copyWith({
    int? id,
    String? sex,
    int? birthDateMillis,
    Value<int?> ageBandMaxYears = const Value.absent(),
    double? heightCm,
    int? activityLevel,
    String? weightUnit,
    int? proteinPct,
    int? carbsPct,
    int? fatPct,
    int? reminderWeekday,
    int? reminderHour,
    int? reminderMinute,
    bool? onboardingCompleted,
    Value<double?> dailyCalorieTarget = const Value.absent(),
  }) => Profile(
    id: id ?? this.id,
    sex: sex ?? this.sex,
    birthDateMillis: birthDateMillis ?? this.birthDateMillis,
    ageBandMaxYears: ageBandMaxYears.present
        ? ageBandMaxYears.value
        : this.ageBandMaxYears,
    heightCm: heightCm ?? this.heightCm,
    activityLevel: activityLevel ?? this.activityLevel,
    weightUnit: weightUnit ?? this.weightUnit,
    proteinPct: proteinPct ?? this.proteinPct,
    carbsPct: carbsPct ?? this.carbsPct,
    fatPct: fatPct ?? this.fatPct,
    reminderWeekday: reminderWeekday ?? this.reminderWeekday,
    reminderHour: reminderHour ?? this.reminderHour,
    reminderMinute: reminderMinute ?? this.reminderMinute,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    dailyCalorieTarget: dailyCalorieTarget.present
        ? dailyCalorieTarget.value
        : this.dailyCalorieTarget,
  );
  Profile copyWithCompanion(ProfilesCompanion data) {
    return Profile(
      id: data.id.present ? data.id.value : this.id,
      sex: data.sex.present ? data.sex.value : this.sex,
      birthDateMillis: data.birthDateMillis.present
          ? data.birthDateMillis.value
          : this.birthDateMillis,
      ageBandMaxYears: data.ageBandMaxYears.present
          ? data.ageBandMaxYears.value
          : this.ageBandMaxYears,
      heightCm: data.heightCm.present ? data.heightCm.value : this.heightCm,
      activityLevel: data.activityLevel.present
          ? data.activityLevel.value
          : this.activityLevel,
      weightUnit: data.weightUnit.present
          ? data.weightUnit.value
          : this.weightUnit,
      proteinPct: data.proteinPct.present
          ? data.proteinPct.value
          : this.proteinPct,
      carbsPct: data.carbsPct.present ? data.carbsPct.value : this.carbsPct,
      fatPct: data.fatPct.present ? data.fatPct.value : this.fatPct,
      reminderWeekday: data.reminderWeekday.present
          ? data.reminderWeekday.value
          : this.reminderWeekday,
      reminderHour: data.reminderHour.present
          ? data.reminderHour.value
          : this.reminderHour,
      reminderMinute: data.reminderMinute.present
          ? data.reminderMinute.value
          : this.reminderMinute,
      onboardingCompleted: data.onboardingCompleted.present
          ? data.onboardingCompleted.value
          : this.onboardingCompleted,
      dailyCalorieTarget: data.dailyCalorieTarget.present
          ? data.dailyCalorieTarget.value
          : this.dailyCalorieTarget,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('id: $id, ')
          ..write('sex: $sex, ')
          ..write('birthDateMillis: $birthDateMillis, ')
          ..write('ageBandMaxYears: $ageBandMaxYears, ')
          ..write('heightCm: $heightCm, ')
          ..write('activityLevel: $activityLevel, ')
          ..write('weightUnit: $weightUnit, ')
          ..write('proteinPct: $proteinPct, ')
          ..write('carbsPct: $carbsPct, ')
          ..write('fatPct: $fatPct, ')
          ..write('reminderWeekday: $reminderWeekday, ')
          ..write('reminderHour: $reminderHour, ')
          ..write('reminderMinute: $reminderMinute, ')
          ..write('onboardingCompleted: $onboardingCompleted, ')
          ..write('dailyCalorieTarget: $dailyCalorieTarget')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sex,
    birthDateMillis,
    ageBandMaxYears,
    heightCm,
    activityLevel,
    weightUnit,
    proteinPct,
    carbsPct,
    fatPct,
    reminderWeekday,
    reminderHour,
    reminderMinute,
    onboardingCompleted,
    dailyCalorieTarget,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.id == this.id &&
          other.sex == this.sex &&
          other.birthDateMillis == this.birthDateMillis &&
          other.ageBandMaxYears == this.ageBandMaxYears &&
          other.heightCm == this.heightCm &&
          other.activityLevel == this.activityLevel &&
          other.weightUnit == this.weightUnit &&
          other.proteinPct == this.proteinPct &&
          other.carbsPct == this.carbsPct &&
          other.fatPct == this.fatPct &&
          other.reminderWeekday == this.reminderWeekday &&
          other.reminderHour == this.reminderHour &&
          other.reminderMinute == this.reminderMinute &&
          other.onboardingCompleted == this.onboardingCompleted &&
          other.dailyCalorieTarget == this.dailyCalorieTarget);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<int> id;
  final Value<String> sex;
  final Value<int> birthDateMillis;
  final Value<int?> ageBandMaxYears;
  final Value<double> heightCm;
  final Value<int> activityLevel;
  final Value<String> weightUnit;
  final Value<int> proteinPct;
  final Value<int> carbsPct;
  final Value<int> fatPct;
  final Value<int> reminderWeekday;
  final Value<int> reminderHour;
  final Value<int> reminderMinute;
  final Value<bool> onboardingCompleted;
  final Value<double?> dailyCalorieTarget;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.sex = const Value.absent(),
    this.birthDateMillis = const Value.absent(),
    this.ageBandMaxYears = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.activityLevel = const Value.absent(),
    this.weightUnit = const Value.absent(),
    this.proteinPct = const Value.absent(),
    this.carbsPct = const Value.absent(),
    this.fatPct = const Value.absent(),
    this.reminderWeekday = const Value.absent(),
    this.reminderHour = const Value.absent(),
    this.reminderMinute = const Value.absent(),
    this.onboardingCompleted = const Value.absent(),
    this.dailyCalorieTarget = const Value.absent(),
  });
  ProfilesCompanion.insert({
    this.id = const Value.absent(),
    required String sex,
    required int birthDateMillis,
    this.ageBandMaxYears = const Value.absent(),
    required double heightCm,
    required int activityLevel,
    required String weightUnit,
    required int proteinPct,
    required int carbsPct,
    required int fatPct,
    required int reminderWeekday,
    required int reminderHour,
    required int reminderMinute,
    this.onboardingCompleted = const Value.absent(),
    this.dailyCalorieTarget = const Value.absent(),
  }) : sex = Value(sex),
       birthDateMillis = Value(birthDateMillis),
       heightCm = Value(heightCm),
       activityLevel = Value(activityLevel),
       weightUnit = Value(weightUnit),
       proteinPct = Value(proteinPct),
       carbsPct = Value(carbsPct),
       fatPct = Value(fatPct),
       reminderWeekday = Value(reminderWeekday),
       reminderHour = Value(reminderHour),
       reminderMinute = Value(reminderMinute);
  static Insertable<Profile> custom({
    Expression<int>? id,
    Expression<String>? sex,
    Expression<int>? birthDateMillis,
    Expression<int>? ageBandMaxYears,
    Expression<double>? heightCm,
    Expression<int>? activityLevel,
    Expression<String>? weightUnit,
    Expression<int>? proteinPct,
    Expression<int>? carbsPct,
    Expression<int>? fatPct,
    Expression<int>? reminderWeekday,
    Expression<int>? reminderHour,
    Expression<int>? reminderMinute,
    Expression<bool>? onboardingCompleted,
    Expression<double>? dailyCalorieTarget,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sex != null) 'sex': sex,
      if (birthDateMillis != null) 'birth_date_millis': birthDateMillis,
      if (ageBandMaxYears != null) 'age_band_max_years': ageBandMaxYears,
      if (heightCm != null) 'height_cm': heightCm,
      if (activityLevel != null) 'activity_level': activityLevel,
      if (weightUnit != null) 'weight_unit': weightUnit,
      if (proteinPct != null) 'protein_pct': proteinPct,
      if (carbsPct != null) 'carbs_pct': carbsPct,
      if (fatPct != null) 'fat_pct': fatPct,
      if (reminderWeekday != null) 'reminder_weekday': reminderWeekday,
      if (reminderHour != null) 'reminder_hour': reminderHour,
      if (reminderMinute != null) 'reminder_minute': reminderMinute,
      if (onboardingCompleted != null)
        'onboarding_completed': onboardingCompleted,
      if (dailyCalorieTarget != null)
        'daily_calorie_target': dailyCalorieTarget,
    });
  }

  ProfilesCompanion copyWith({
    Value<int>? id,
    Value<String>? sex,
    Value<int>? birthDateMillis,
    Value<int?>? ageBandMaxYears,
    Value<double>? heightCm,
    Value<int>? activityLevel,
    Value<String>? weightUnit,
    Value<int>? proteinPct,
    Value<int>? carbsPct,
    Value<int>? fatPct,
    Value<int>? reminderWeekday,
    Value<int>? reminderHour,
    Value<int>? reminderMinute,
    Value<bool>? onboardingCompleted,
    Value<double?>? dailyCalorieTarget,
  }) {
    return ProfilesCompanion(
      id: id ?? this.id,
      sex: sex ?? this.sex,
      birthDateMillis: birthDateMillis ?? this.birthDateMillis,
      ageBandMaxYears: ageBandMaxYears ?? this.ageBandMaxYears,
      heightCm: heightCm ?? this.heightCm,
      activityLevel: activityLevel ?? this.activityLevel,
      weightUnit: weightUnit ?? this.weightUnit,
      proteinPct: proteinPct ?? this.proteinPct,
      carbsPct: carbsPct ?? this.carbsPct,
      fatPct: fatPct ?? this.fatPct,
      reminderWeekday: reminderWeekday ?? this.reminderWeekday,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      dailyCalorieTarget: dailyCalorieTarget ?? this.dailyCalorieTarget,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sex.present) {
      map['sex'] = Variable<String>(sex.value);
    }
    if (birthDateMillis.present) {
      map['birth_date_millis'] = Variable<int>(birthDateMillis.value);
    }
    if (ageBandMaxYears.present) {
      map['age_band_max_years'] = Variable<int>(ageBandMaxYears.value);
    }
    if (heightCm.present) {
      map['height_cm'] = Variable<double>(heightCm.value);
    }
    if (activityLevel.present) {
      map['activity_level'] = Variable<int>(activityLevel.value);
    }
    if (weightUnit.present) {
      map['weight_unit'] = Variable<String>(weightUnit.value);
    }
    if (proteinPct.present) {
      map['protein_pct'] = Variable<int>(proteinPct.value);
    }
    if (carbsPct.present) {
      map['carbs_pct'] = Variable<int>(carbsPct.value);
    }
    if (fatPct.present) {
      map['fat_pct'] = Variable<int>(fatPct.value);
    }
    if (reminderWeekday.present) {
      map['reminder_weekday'] = Variable<int>(reminderWeekday.value);
    }
    if (reminderHour.present) {
      map['reminder_hour'] = Variable<int>(reminderHour.value);
    }
    if (reminderMinute.present) {
      map['reminder_minute'] = Variable<int>(reminderMinute.value);
    }
    if (onboardingCompleted.present) {
      map['onboarding_completed'] = Variable<bool>(onboardingCompleted.value);
    }
    if (dailyCalorieTarget.present) {
      map['daily_calorie_target'] = Variable<double>(dailyCalorieTarget.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('sex: $sex, ')
          ..write('birthDateMillis: $birthDateMillis, ')
          ..write('ageBandMaxYears: $ageBandMaxYears, ')
          ..write('heightCm: $heightCm, ')
          ..write('activityLevel: $activityLevel, ')
          ..write('weightUnit: $weightUnit, ')
          ..write('proteinPct: $proteinPct, ')
          ..write('carbsPct: $carbsPct, ')
          ..write('fatPct: $fatPct, ')
          ..write('reminderWeekday: $reminderWeekday, ')
          ..write('reminderHour: $reminderHour, ')
          ..write('reminderMinute: $reminderMinute, ')
          ..write('onboardingCompleted: $onboardingCompleted, ')
          ..write('dailyCalorieTarget: $dailyCalorieTarget')
          ..write(')'))
        .toString();
  }
}

class $GoalsTable extends Goals with TableInfo<$GoalsTable, Goal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _targetWeightKgMeta = const VerificationMeta(
    'targetWeightKg',
  );
  @override
  late final GeneratedColumn<double> targetWeightKg = GeneratedColumn<double>(
    'target_weight_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weeklyChangeKgPerWeekMeta =
      const VerificationMeta('weeklyChangeKgPerWeek');
  @override
  late final GeneratedColumn<double> weeklyChangeKgPerWeek =
      GeneratedColumn<double>(
        'weekly_change_kg_per_week',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    targetWeightKg,
    weeklyChangeKgPerWeek,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<Goal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('target_weight_kg')) {
      context.handle(
        _targetWeightKgMeta,
        targetWeightKg.isAcceptableOrUnknown(
          data['target_weight_kg']!,
          _targetWeightKgMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetWeightKgMeta);
    }
    if (data.containsKey('weekly_change_kg_per_week')) {
      context.handle(
        _weeklyChangeKgPerWeekMeta,
        weeklyChangeKgPerWeek.isAcceptableOrUnknown(
          data['weekly_change_kg_per_week']!,
          _weeklyChangeKgPerWeekMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_weeklyChangeKgPerWeekMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Goal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Goal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      targetWeightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_weight_kg'],
      )!,
      weeklyChangeKgPerWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weekly_change_kg_per_week'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }
}

class Goal extends DataClass implements Insertable<Goal> {
  final int id;
  final double targetWeightKg;
  final double weeklyChangeKgPerWeek;
  final String status;
  const Goal({
    required this.id,
    required this.targetWeightKg,
    required this.weeklyChangeKgPerWeek,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['target_weight_kg'] = Variable<double>(targetWeightKg);
    map['weekly_change_kg_per_week'] = Variable<double>(weeklyChangeKgPerWeek);
    map['status'] = Variable<String>(status);
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      targetWeightKg: Value(targetWeightKg),
      weeklyChangeKgPerWeek: Value(weeklyChangeKgPerWeek),
      status: Value(status),
    );
  }

  factory Goal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Goal(
      id: serializer.fromJson<int>(json['id']),
      targetWeightKg: serializer.fromJson<double>(json['targetWeightKg']),
      weeklyChangeKgPerWeek: serializer.fromJson<double>(
        json['weeklyChangeKgPerWeek'],
      ),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'targetWeightKg': serializer.toJson<double>(targetWeightKg),
      'weeklyChangeKgPerWeek': serializer.toJson<double>(weeklyChangeKgPerWeek),
      'status': serializer.toJson<String>(status),
    };
  }

  Goal copyWith({
    int? id,
    double? targetWeightKg,
    double? weeklyChangeKgPerWeek,
    String? status,
  }) => Goal(
    id: id ?? this.id,
    targetWeightKg: targetWeightKg ?? this.targetWeightKg,
    weeklyChangeKgPerWeek: weeklyChangeKgPerWeek ?? this.weeklyChangeKgPerWeek,
    status: status ?? this.status,
  );
  Goal copyWithCompanion(GoalsCompanion data) {
    return Goal(
      id: data.id.present ? data.id.value : this.id,
      targetWeightKg: data.targetWeightKg.present
          ? data.targetWeightKg.value
          : this.targetWeightKg,
      weeklyChangeKgPerWeek: data.weeklyChangeKgPerWeek.present
          ? data.weeklyChangeKgPerWeek.value
          : this.weeklyChangeKgPerWeek,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Goal(')
          ..write('id: $id, ')
          ..write('targetWeightKg: $targetWeightKg, ')
          ..write('weeklyChangeKgPerWeek: $weeklyChangeKgPerWeek, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, targetWeightKg, weeklyChangeKgPerWeek, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Goal &&
          other.id == this.id &&
          other.targetWeightKg == this.targetWeightKg &&
          other.weeklyChangeKgPerWeek == this.weeklyChangeKgPerWeek &&
          other.status == this.status);
}

class GoalsCompanion extends UpdateCompanion<Goal> {
  final Value<int> id;
  final Value<double> targetWeightKg;
  final Value<double> weeklyChangeKgPerWeek;
  final Value<String> status;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.targetWeightKg = const Value.absent(),
    this.weeklyChangeKgPerWeek = const Value.absent(),
    this.status = const Value.absent(),
  });
  GoalsCompanion.insert({
    this.id = const Value.absent(),
    required double targetWeightKg,
    required double weeklyChangeKgPerWeek,
    required String status,
  }) : targetWeightKg = Value(targetWeightKg),
       weeklyChangeKgPerWeek = Value(weeklyChangeKgPerWeek),
       status = Value(status);
  static Insertable<Goal> custom({
    Expression<int>? id,
    Expression<double>? targetWeightKg,
    Expression<double>? weeklyChangeKgPerWeek,
    Expression<String>? status,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (targetWeightKg != null) 'target_weight_kg': targetWeightKg,
      if (weeklyChangeKgPerWeek != null)
        'weekly_change_kg_per_week': weeklyChangeKgPerWeek,
      if (status != null) 'status': status,
    });
  }

  GoalsCompanion copyWith({
    Value<int>? id,
    Value<double>? targetWeightKg,
    Value<double>? weeklyChangeKgPerWeek,
    Value<String>? status,
  }) {
    return GoalsCompanion(
      id: id ?? this.id,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      weeklyChangeKgPerWeek:
          weeklyChangeKgPerWeek ?? this.weeklyChangeKgPerWeek,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (targetWeightKg.present) {
      map['target_weight_kg'] = Variable<double>(targetWeightKg.value);
    }
    if (weeklyChangeKgPerWeek.present) {
      map['weekly_change_kg_per_week'] = Variable<double>(
        weeklyChangeKgPerWeek.value,
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsCompanion(')
          ..write('id: $id, ')
          ..write('targetWeightKg: $targetWeightKg, ')
          ..write('weeklyChangeKgPerWeek: $weeklyChangeKgPerWeek, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }
}

class $WeightEntriesTable extends WeightEntries
    with TableInfo<$WeightEntriesTable, WeightEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeightEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, recordedAt, weightKg, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weight_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeightEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    } else if (isInserting) {
      context.missing(_weightKgMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeightEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeightEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $WeightEntriesTable createAlias(String alias) {
    return $WeightEntriesTable(attachedDatabase, alias);
  }
}

class WeightEntry extends DataClass implements Insertable<WeightEntry> {
  final int id;
  final DateTime recordedAt;
  final double weightKg;
  final String? note;
  const WeightEntry({
    required this.id,
    required this.recordedAt,
    required this.weightKg,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['weight_kg'] = Variable<double>(weightKg);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  WeightEntriesCompanion toCompanion(bool nullToAbsent) {
    return WeightEntriesCompanion(
      id: Value(id),
      recordedAt: Value(recordedAt),
      weightKg: Value(weightKg),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory WeightEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeightEntry(
      id: serializer.fromJson<int>(json['id']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      weightKg: serializer.fromJson<double>(json['weightKg']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'weightKg': serializer.toJson<double>(weightKg),
      'note': serializer.toJson<String?>(note),
    };
  }

  WeightEntry copyWith({
    int? id,
    DateTime? recordedAt,
    double? weightKg,
    Value<String?> note = const Value.absent(),
  }) => WeightEntry(
    id: id ?? this.id,
    recordedAt: recordedAt ?? this.recordedAt,
    weightKg: weightKg ?? this.weightKg,
    note: note.present ? note.value : this.note,
  );
  WeightEntry copyWithCompanion(WeightEntriesCompanion data) {
    return WeightEntry(
      id: data.id.present ? data.id.value : this.id,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeightEntry(')
          ..write('id: $id, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('weightKg: $weightKg, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, recordedAt, weightKg, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeightEntry &&
          other.id == this.id &&
          other.recordedAt == this.recordedAt &&
          other.weightKg == this.weightKg &&
          other.note == this.note);
}

class WeightEntriesCompanion extends UpdateCompanion<WeightEntry> {
  final Value<int> id;
  final Value<DateTime> recordedAt;
  final Value<double> weightKg;
  final Value<String?> note;
  const WeightEntriesCompanion({
    this.id = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.note = const Value.absent(),
  });
  WeightEntriesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime recordedAt,
    required double weightKg,
    this.note = const Value.absent(),
  }) : recordedAt = Value(recordedAt),
       weightKg = Value(weightKg);
  static Insertable<WeightEntry> custom({
    Expression<int>? id,
    Expression<DateTime>? recordedAt,
    Expression<double>? weightKg,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (weightKg != null) 'weight_kg': weightKg,
      if (note != null) 'note': note,
    });
  }

  WeightEntriesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? recordedAt,
    Value<double>? weightKg,
    Value<String?>? note,
  }) {
    return WeightEntriesCompanion(
      id: id ?? this.id,
      recordedAt: recordedAt ?? this.recordedAt,
      weightKg: weightKg ?? this.weightKg,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeightEntriesCompanion(')
          ..write('id: $id, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('weightKg: $weightKg, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $FoodPrefsTable extends FoodPrefs
    with TableInfo<$FoodPrefsTable, FoodPref> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoodPrefsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _foodKeyMeta = const VerificationMeta(
    'foodKey',
  );
  @override
  late final GeneratedColumn<String> foodKey = GeneratedColumn<String>(
    'food_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _treatAsLiquidMeta = const VerificationMeta(
    'treatAsLiquid',
  );
  @override
  late final GeneratedColumn<bool> treatAsLiquid = GeneratedColumn<bool>(
    'treat_as_liquid',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("treat_as_liquid" IN (0, 1))',
    ),
  );
  static const VerificationMeta _savedServingAmountMeta =
      const VerificationMeta('savedServingAmount');
  @override
  late final GeneratedColumn<double> savedServingAmount =
      GeneratedColumn<double>(
        'saved_serving_amount',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _savedServingUnitMeta = const VerificationMeta(
    'savedServingUnit',
  );
  @override
  late final GeneratedColumn<String> savedServingUnit = GeneratedColumn<String>(
    'saved_serving_unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    foodKey,
    treatAsLiquid,
    savedServingAmount,
    savedServingUnit,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'food_prefs';
  @override
  VerificationContext validateIntegrity(
    Insertable<FoodPref> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('food_key')) {
      context.handle(
        _foodKeyMeta,
        foodKey.isAcceptableOrUnknown(data['food_key']!, _foodKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_foodKeyMeta);
    }
    if (data.containsKey('treat_as_liquid')) {
      context.handle(
        _treatAsLiquidMeta,
        treatAsLiquid.isAcceptableOrUnknown(
          data['treat_as_liquid']!,
          _treatAsLiquidMeta,
        ),
      );
    }
    if (data.containsKey('saved_serving_amount')) {
      context.handle(
        _savedServingAmountMeta,
        savedServingAmount.isAcceptableOrUnknown(
          data['saved_serving_amount']!,
          _savedServingAmountMeta,
        ),
      );
    }
    if (data.containsKey('saved_serving_unit')) {
      context.handle(
        _savedServingUnitMeta,
        savedServingUnit.isAcceptableOrUnknown(
          data['saved_serving_unit']!,
          _savedServingUnitMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {foodKey};
  @override
  FoodPref map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FoodPref(
      foodKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_key'],
      )!,
      treatAsLiquid: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}treat_as_liquid'],
      ),
      savedServingAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}saved_serving_amount'],
      ),
      savedServingUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}saved_serving_unit'],
      ),
    );
  }

  @override
  $FoodPrefsTable createAlias(String alias) {
    return $FoodPrefsTable(attachedDatabase, alias);
  }
}

class FoodPref extends DataClass implements Insertable<FoodPref> {
  /// Stable key for a food. For catalog foods: `cat:<id>`. For custom:
  /// `cus:<id>`. Fallback: `name:<lowercased name>`.
  final String foodKey;

  /// If null, use the catalog's default; otherwise override.
  final bool? treatAsLiquid;

  /// Saved “serving” quick-select amount.
  final double? savedServingAmount;

  /// 'g' | 'ml'
  final String? savedServingUnit;
  const FoodPref({
    required this.foodKey,
    this.treatAsLiquid,
    this.savedServingAmount,
    this.savedServingUnit,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['food_key'] = Variable<String>(foodKey);
    if (!nullToAbsent || treatAsLiquid != null) {
      map['treat_as_liquid'] = Variable<bool>(treatAsLiquid);
    }
    if (!nullToAbsent || savedServingAmount != null) {
      map['saved_serving_amount'] = Variable<double>(savedServingAmount);
    }
    if (!nullToAbsent || savedServingUnit != null) {
      map['saved_serving_unit'] = Variable<String>(savedServingUnit);
    }
    return map;
  }

  FoodPrefsCompanion toCompanion(bool nullToAbsent) {
    return FoodPrefsCompanion(
      foodKey: Value(foodKey),
      treatAsLiquid: treatAsLiquid == null && nullToAbsent
          ? const Value.absent()
          : Value(treatAsLiquid),
      savedServingAmount: savedServingAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(savedServingAmount),
      savedServingUnit: savedServingUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(savedServingUnit),
    );
  }

  factory FoodPref.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FoodPref(
      foodKey: serializer.fromJson<String>(json['foodKey']),
      treatAsLiquid: serializer.fromJson<bool?>(json['treatAsLiquid']),
      savedServingAmount: serializer.fromJson<double?>(
        json['savedServingAmount'],
      ),
      savedServingUnit: serializer.fromJson<String?>(json['savedServingUnit']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'foodKey': serializer.toJson<String>(foodKey),
      'treatAsLiquid': serializer.toJson<bool?>(treatAsLiquid),
      'savedServingAmount': serializer.toJson<double?>(savedServingAmount),
      'savedServingUnit': serializer.toJson<String?>(savedServingUnit),
    };
  }

  FoodPref copyWith({
    String? foodKey,
    Value<bool?> treatAsLiquid = const Value.absent(),
    Value<double?> savedServingAmount = const Value.absent(),
    Value<String?> savedServingUnit = const Value.absent(),
  }) => FoodPref(
    foodKey: foodKey ?? this.foodKey,
    treatAsLiquid: treatAsLiquid.present
        ? treatAsLiquid.value
        : this.treatAsLiquid,
    savedServingAmount: savedServingAmount.present
        ? savedServingAmount.value
        : this.savedServingAmount,
    savedServingUnit: savedServingUnit.present
        ? savedServingUnit.value
        : this.savedServingUnit,
  );
  FoodPref copyWithCompanion(FoodPrefsCompanion data) {
    return FoodPref(
      foodKey: data.foodKey.present ? data.foodKey.value : this.foodKey,
      treatAsLiquid: data.treatAsLiquid.present
          ? data.treatAsLiquid.value
          : this.treatAsLiquid,
      savedServingAmount: data.savedServingAmount.present
          ? data.savedServingAmount.value
          : this.savedServingAmount,
      savedServingUnit: data.savedServingUnit.present
          ? data.savedServingUnit.value
          : this.savedServingUnit,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FoodPref(')
          ..write('foodKey: $foodKey, ')
          ..write('treatAsLiquid: $treatAsLiquid, ')
          ..write('savedServingAmount: $savedServingAmount, ')
          ..write('savedServingUnit: $savedServingUnit')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(foodKey, treatAsLiquid, savedServingAmount, savedServingUnit);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoodPref &&
          other.foodKey == this.foodKey &&
          other.treatAsLiquid == this.treatAsLiquid &&
          other.savedServingAmount == this.savedServingAmount &&
          other.savedServingUnit == this.savedServingUnit);
}

class FoodPrefsCompanion extends UpdateCompanion<FoodPref> {
  final Value<String> foodKey;
  final Value<bool?> treatAsLiquid;
  final Value<double?> savedServingAmount;
  final Value<String?> savedServingUnit;
  final Value<int> rowid;
  const FoodPrefsCompanion({
    this.foodKey = const Value.absent(),
    this.treatAsLiquid = const Value.absent(),
    this.savedServingAmount = const Value.absent(),
    this.savedServingUnit = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FoodPrefsCompanion.insert({
    required String foodKey,
    this.treatAsLiquid = const Value.absent(),
    this.savedServingAmount = const Value.absent(),
    this.savedServingUnit = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : foodKey = Value(foodKey);
  static Insertable<FoodPref> custom({
    Expression<String>? foodKey,
    Expression<bool>? treatAsLiquid,
    Expression<double>? savedServingAmount,
    Expression<String>? savedServingUnit,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (foodKey != null) 'food_key': foodKey,
      if (treatAsLiquid != null) 'treat_as_liquid': treatAsLiquid,
      if (savedServingAmount != null)
        'saved_serving_amount': savedServingAmount,
      if (savedServingUnit != null) 'saved_serving_unit': savedServingUnit,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FoodPrefsCompanion copyWith({
    Value<String>? foodKey,
    Value<bool?>? treatAsLiquid,
    Value<double?>? savedServingAmount,
    Value<String?>? savedServingUnit,
    Value<int>? rowid,
  }) {
    return FoodPrefsCompanion(
      foodKey: foodKey ?? this.foodKey,
      treatAsLiquid: treatAsLiquid ?? this.treatAsLiquid,
      savedServingAmount: savedServingAmount ?? this.savedServingAmount,
      savedServingUnit: savedServingUnit ?? this.savedServingUnit,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (foodKey.present) {
      map['food_key'] = Variable<String>(foodKey.value);
    }
    if (treatAsLiquid.present) {
      map['treat_as_liquid'] = Variable<bool>(treatAsLiquid.value);
    }
    if (savedServingAmount.present) {
      map['saved_serving_amount'] = Variable<double>(savedServingAmount.value);
    }
    if (savedServingUnit.present) {
      map['saved_serving_unit'] = Variable<String>(savedServingUnit.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodPrefsCompanion(')
          ..write('foodKey: $foodKey, ')
          ..write('treatAsLiquid: $treatAsLiquid, ')
          ..write('savedServingAmount: $savedServingAmount, ')
          ..write('savedServingUnit: $savedServingUnit, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomFoodsTable extends CustomFoods
    with TableInfo<$CustomFoodsTable, CustomFood> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomFoodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _servingSizeMeta = const VerificationMeta(
    'servingSize',
  );
  @override
  late final GeneratedColumn<double> servingSize = GeneratedColumn<double>(
    'serving_size',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _servingUnitMeta = const VerificationMeta(
    'servingUnit',
  );
  @override
  late final GeneratedColumn<String> servingUnit = GeneratedColumn<String>(
    'serving_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _caloriesMeta = const VerificationMeta(
    'calories',
  );
  @override
  late final GeneratedColumn<double> calories = GeneratedColumn<double>(
    'calories',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  @override
  late final GeneratedColumn<double> fatG = GeneratedColumn<double>(
    'fat_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbsGMeta = const VerificationMeta('carbsG');
  @override
  late final GeneratedColumn<double> carbsG = GeneratedColumn<double>(
    'carbs_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sugarGMeta = const VerificationMeta('sugarG');
  @override
  late final GeneratedColumn<double> sugarG = GeneratedColumn<double>(
    'sugar_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fiberGMeta = const VerificationMeta('fiberG');
  @override
  late final GeneratedColumn<double> fiberG = GeneratedColumn<double>(
    'fiber_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinGMeta = const VerificationMeta(
    'proteinG',
  );
  @override
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
    'protein_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    brand,
    barcode,
    servingSize,
    servingUnit,
    calories,
    fatG,
    carbsG,
    sugarG,
    fiberG,
    proteinG,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_foods';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomFood> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('serving_size')) {
      context.handle(
        _servingSizeMeta,
        servingSize.isAcceptableOrUnknown(
          data['serving_size']!,
          _servingSizeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_servingSizeMeta);
    }
    if (data.containsKey('serving_unit')) {
      context.handle(
        _servingUnitMeta,
        servingUnit.isAcceptableOrUnknown(
          data['serving_unit']!,
          _servingUnitMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_servingUnitMeta);
    }
    if (data.containsKey('calories')) {
      context.handle(
        _caloriesMeta,
        calories.isAcceptableOrUnknown(data['calories']!, _caloriesMeta),
      );
    } else if (isInserting) {
      context.missing(_caloriesMeta);
    }
    if (data.containsKey('fat_g')) {
      context.handle(
        _fatGMeta,
        fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta),
      );
    } else if (isInserting) {
      context.missing(_fatGMeta);
    }
    if (data.containsKey('carbs_g')) {
      context.handle(
        _carbsGMeta,
        carbsG.isAcceptableOrUnknown(data['carbs_g']!, _carbsGMeta),
      );
    } else if (isInserting) {
      context.missing(_carbsGMeta);
    }
    if (data.containsKey('sugar_g')) {
      context.handle(
        _sugarGMeta,
        sugarG.isAcceptableOrUnknown(data['sugar_g']!, _sugarGMeta),
      );
    } else if (isInserting) {
      context.missing(_sugarGMeta);
    }
    if (data.containsKey('fiber_g')) {
      context.handle(
        _fiberGMeta,
        fiberG.isAcceptableOrUnknown(data['fiber_g']!, _fiberGMeta),
      );
    } else if (isInserting) {
      context.missing(_fiberGMeta);
    }
    if (data.containsKey('protein_g')) {
      context.handle(
        _proteinGMeta,
        proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta),
      );
    } else if (isInserting) {
      context.missing(_proteinGMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomFood map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomFood(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      ),
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      servingSize: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}serving_size'],
      )!,
      servingUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}serving_unit'],
      )!,
      calories: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}calories'],
      )!,
      fatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_g'],
      )!,
      carbsG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs_g'],
      )!,
      sugarG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sugar_g'],
      )!,
      fiberG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fiber_g'],
      )!,
      proteinG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_g'],
      )!,
    );
  }

  @override
  $CustomFoodsTable createAlias(String alias) {
    return $CustomFoodsTable(attachedDatabase, alias);
  }
}

class CustomFood extends DataClass implements Insertable<CustomFood> {
  final int id;

  /// Required display name, e.g. "Greek yogurt".
  final String name;

  /// Optional, e.g. "Chobani".
  final String? brand;

  /// Optional, normalized digits (EAN-13 if present).
  final String? barcode;

  /// Serving size amount (in [servingUnit]).
  final double servingSize;

  /// 'g' | 'ml'
  final String servingUnit;

  /// Nutrition per serving.
  final double calories;
  final double fatG;
  final double carbsG;
  final double sugarG;
  final double fiberG;
  final double proteinG;
  const CustomFood({
    required this.id,
    required this.name,
    this.brand,
    this.barcode,
    required this.servingSize,
    required this.servingUnit,
    required this.calories,
    required this.fatG,
    required this.carbsG,
    required this.sugarG,
    required this.fiberG,
    required this.proteinG,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    map['serving_size'] = Variable<double>(servingSize);
    map['serving_unit'] = Variable<String>(servingUnit);
    map['calories'] = Variable<double>(calories);
    map['fat_g'] = Variable<double>(fatG);
    map['carbs_g'] = Variable<double>(carbsG);
    map['sugar_g'] = Variable<double>(sugarG);
    map['fiber_g'] = Variable<double>(fiberG);
    map['protein_g'] = Variable<double>(proteinG);
    return map;
  }

  CustomFoodsCompanion toCompanion(bool nullToAbsent) {
    return CustomFoodsCompanion(
      id: Value(id),
      name: Value(name),
      brand: brand == null && nullToAbsent
          ? const Value.absent()
          : Value(brand),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      servingSize: Value(servingSize),
      servingUnit: Value(servingUnit),
      calories: Value(calories),
      fatG: Value(fatG),
      carbsG: Value(carbsG),
      sugarG: Value(sugarG),
      fiberG: Value(fiberG),
      proteinG: Value(proteinG),
    );
  }

  factory CustomFood.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomFood(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      brand: serializer.fromJson<String?>(json['brand']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      servingSize: serializer.fromJson<double>(json['servingSize']),
      servingUnit: serializer.fromJson<String>(json['servingUnit']),
      calories: serializer.fromJson<double>(json['calories']),
      fatG: serializer.fromJson<double>(json['fatG']),
      carbsG: serializer.fromJson<double>(json['carbsG']),
      sugarG: serializer.fromJson<double>(json['sugarG']),
      fiberG: serializer.fromJson<double>(json['fiberG']),
      proteinG: serializer.fromJson<double>(json['proteinG']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'brand': serializer.toJson<String?>(brand),
      'barcode': serializer.toJson<String?>(barcode),
      'servingSize': serializer.toJson<double>(servingSize),
      'servingUnit': serializer.toJson<String>(servingUnit),
      'calories': serializer.toJson<double>(calories),
      'fatG': serializer.toJson<double>(fatG),
      'carbsG': serializer.toJson<double>(carbsG),
      'sugarG': serializer.toJson<double>(sugarG),
      'fiberG': serializer.toJson<double>(fiberG),
      'proteinG': serializer.toJson<double>(proteinG),
    };
  }

  CustomFood copyWith({
    int? id,
    String? name,
    Value<String?> brand = const Value.absent(),
    Value<String?> barcode = const Value.absent(),
    double? servingSize,
    String? servingUnit,
    double? calories,
    double? fatG,
    double? carbsG,
    double? sugarG,
    double? fiberG,
    double? proteinG,
  }) => CustomFood(
    id: id ?? this.id,
    name: name ?? this.name,
    brand: brand.present ? brand.value : this.brand,
    barcode: barcode.present ? barcode.value : this.barcode,
    servingSize: servingSize ?? this.servingSize,
    servingUnit: servingUnit ?? this.servingUnit,
    calories: calories ?? this.calories,
    fatG: fatG ?? this.fatG,
    carbsG: carbsG ?? this.carbsG,
    sugarG: sugarG ?? this.sugarG,
    fiberG: fiberG ?? this.fiberG,
    proteinG: proteinG ?? this.proteinG,
  );
  CustomFood copyWithCompanion(CustomFoodsCompanion data) {
    return CustomFood(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      brand: data.brand.present ? data.brand.value : this.brand,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      servingSize: data.servingSize.present
          ? data.servingSize.value
          : this.servingSize,
      servingUnit: data.servingUnit.present
          ? data.servingUnit.value
          : this.servingUnit,
      calories: data.calories.present ? data.calories.value : this.calories,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
      carbsG: data.carbsG.present ? data.carbsG.value : this.carbsG,
      sugarG: data.sugarG.present ? data.sugarG.value : this.sugarG,
      fiberG: data.fiberG.present ? data.fiberG.value : this.fiberG,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomFood(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('barcode: $barcode, ')
          ..write('servingSize: $servingSize, ')
          ..write('servingUnit: $servingUnit, ')
          ..write('calories: $calories, ')
          ..write('fatG: $fatG, ')
          ..write('carbsG: $carbsG, ')
          ..write('sugarG: $sugarG, ')
          ..write('fiberG: $fiberG, ')
          ..write('proteinG: $proteinG')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    brand,
    barcode,
    servingSize,
    servingUnit,
    calories,
    fatG,
    carbsG,
    sugarG,
    fiberG,
    proteinG,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomFood &&
          other.id == this.id &&
          other.name == this.name &&
          other.brand == this.brand &&
          other.barcode == this.barcode &&
          other.servingSize == this.servingSize &&
          other.servingUnit == this.servingUnit &&
          other.calories == this.calories &&
          other.fatG == this.fatG &&
          other.carbsG == this.carbsG &&
          other.sugarG == this.sugarG &&
          other.fiberG == this.fiberG &&
          other.proteinG == this.proteinG);
}

class CustomFoodsCompanion extends UpdateCompanion<CustomFood> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> brand;
  final Value<String?> barcode;
  final Value<double> servingSize;
  final Value<String> servingUnit;
  final Value<double> calories;
  final Value<double> fatG;
  final Value<double> carbsG;
  final Value<double> sugarG;
  final Value<double> fiberG;
  final Value<double> proteinG;
  const CustomFoodsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.brand = const Value.absent(),
    this.barcode = const Value.absent(),
    this.servingSize = const Value.absent(),
    this.servingUnit = const Value.absent(),
    this.calories = const Value.absent(),
    this.fatG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.sugarG = const Value.absent(),
    this.fiberG = const Value.absent(),
    this.proteinG = const Value.absent(),
  });
  CustomFoodsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.brand = const Value.absent(),
    this.barcode = const Value.absent(),
    required double servingSize,
    required String servingUnit,
    required double calories,
    required double fatG,
    required double carbsG,
    required double sugarG,
    required double fiberG,
    required double proteinG,
  }) : name = Value(name),
       servingSize = Value(servingSize),
       servingUnit = Value(servingUnit),
       calories = Value(calories),
       fatG = Value(fatG),
       carbsG = Value(carbsG),
       sugarG = Value(sugarG),
       fiberG = Value(fiberG),
       proteinG = Value(proteinG);
  static Insertable<CustomFood> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? brand,
    Expression<String>? barcode,
    Expression<double>? servingSize,
    Expression<String>? servingUnit,
    Expression<double>? calories,
    Expression<double>? fatG,
    Expression<double>? carbsG,
    Expression<double>? sugarG,
    Expression<double>? fiberG,
    Expression<double>? proteinG,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (brand != null) 'brand': brand,
      if (barcode != null) 'barcode': barcode,
      if (servingSize != null) 'serving_size': servingSize,
      if (servingUnit != null) 'serving_unit': servingUnit,
      if (calories != null) 'calories': calories,
      if (fatG != null) 'fat_g': fatG,
      if (carbsG != null) 'carbs_g': carbsG,
      if (sugarG != null) 'sugar_g': sugarG,
      if (fiberG != null) 'fiber_g': fiberG,
      if (proteinG != null) 'protein_g': proteinG,
    });
  }

  CustomFoodsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? brand,
    Value<String?>? barcode,
    Value<double>? servingSize,
    Value<String>? servingUnit,
    Value<double>? calories,
    Value<double>? fatG,
    Value<double>? carbsG,
    Value<double>? sugarG,
    Value<double>? fiberG,
    Value<double>? proteinG,
  }) {
    return CustomFoodsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      barcode: barcode ?? this.barcode,
      servingSize: servingSize ?? this.servingSize,
      servingUnit: servingUnit ?? this.servingUnit,
      calories: calories ?? this.calories,
      fatG: fatG ?? this.fatG,
      carbsG: carbsG ?? this.carbsG,
      sugarG: sugarG ?? this.sugarG,
      fiberG: fiberG ?? this.fiberG,
      proteinG: proteinG ?? this.proteinG,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (servingSize.present) {
      map['serving_size'] = Variable<double>(servingSize.value);
    }
    if (servingUnit.present) {
      map['serving_unit'] = Variable<String>(servingUnit.value);
    }
    if (calories.present) {
      map['calories'] = Variable<double>(calories.value);
    }
    if (fatG.present) {
      map['fat_g'] = Variable<double>(fatG.value);
    }
    if (carbsG.present) {
      map['carbs_g'] = Variable<double>(carbsG.value);
    }
    if (sugarG.present) {
      map['sugar_g'] = Variable<double>(sugarG.value);
    }
    if (fiberG.present) {
      map['fiber_g'] = Variable<double>(fiberG.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<double>(proteinG.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomFoodsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('barcode: $barcode, ')
          ..write('servingSize: $servingSize, ')
          ..write('servingUnit: $servingUnit, ')
          ..write('calories: $calories, ')
          ..write('fatG: $fatG, ')
          ..write('carbsG: $carbsG, ')
          ..write('sugarG: $sugarG, ')
          ..write('fiberG: $fiberG, ')
          ..write('proteinG: $proteinG')
          ..write(')'))
        .toString();
  }
}

class $FoodLogEntriesTable extends FoodLogEntries
    with TableInfo<$FoodLogEntriesTable, FoodLogEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoodLogEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _loggedAtMeta = const VerificationMeta(
    'loggedAt',
  );
  @override
  late final GeneratedColumn<DateTime> loggedAt = GeneratedColumn<DateTime>(
    'logged_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _catalogFoodIdMeta = const VerificationMeta(
    'catalogFoodId',
  );
  @override
  late final GeneratedColumn<String> catalogFoodId = GeneratedColumn<String>(
    'catalog_food_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customFoodIdMeta = const VerificationMeta(
    'customFoodId',
  );
  @override
  late final GeneratedColumn<int> customFoodId = GeneratedColumn<int>(
    'custom_food_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gramsMeta = const VerificationMeta('grams');
  @override
  late final GeneratedColumn<double> grams = GeneratedColumn<double>(
    'grams',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kcalMeta = const VerificationMeta('kcal');
  @override
  late final GeneratedColumn<double> kcal = GeneratedColumn<double>(
    'kcal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinGMeta = const VerificationMeta(
    'proteinG',
  );
  @override
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
    'protein_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbsGMeta = const VerificationMeta('carbsG');
  @override
  late final GeneratedColumn<double> carbsG = GeneratedColumn<double>(
    'carbs_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sugarGMeta = const VerificationMeta('sugarG');
  @override
  late final GeneratedColumn<double> sugarG = GeneratedColumn<double>(
    'sugar_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _fiberGMeta = const VerificationMeta('fiberG');
  @override
  late final GeneratedColumn<double> fiberG = GeneratedColumn<double>(
    'fiber_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  @override
  late final GeneratedColumn<double> fatG = GeneratedColumn<double>(
    'fat_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    loggedAt,
    source,
    catalogFoodId,
    customFoodId,
    displayName,
    grams,
    kcal,
    proteinG,
    carbsG,
    sugarG,
    fiberG,
    fatG,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'food_log_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<FoodLogEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('logged_at')) {
      context.handle(
        _loggedAtMeta,
        loggedAt.isAcceptableOrUnknown(data['logged_at']!, _loggedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_loggedAtMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('catalog_food_id')) {
      context.handle(
        _catalogFoodIdMeta,
        catalogFoodId.isAcceptableOrUnknown(
          data['catalog_food_id']!,
          _catalogFoodIdMeta,
        ),
      );
    }
    if (data.containsKey('custom_food_id')) {
      context.handle(
        _customFoodIdMeta,
        customFoodId.isAcceptableOrUnknown(
          data['custom_food_id']!,
          _customFoodIdMeta,
        ),
      );
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('grams')) {
      context.handle(
        _gramsMeta,
        grams.isAcceptableOrUnknown(data['grams']!, _gramsMeta),
      );
    } else if (isInserting) {
      context.missing(_gramsMeta);
    }
    if (data.containsKey('kcal')) {
      context.handle(
        _kcalMeta,
        kcal.isAcceptableOrUnknown(data['kcal']!, _kcalMeta),
      );
    } else if (isInserting) {
      context.missing(_kcalMeta);
    }
    if (data.containsKey('protein_g')) {
      context.handle(
        _proteinGMeta,
        proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta),
      );
    } else if (isInserting) {
      context.missing(_proteinGMeta);
    }
    if (data.containsKey('carbs_g')) {
      context.handle(
        _carbsGMeta,
        carbsG.isAcceptableOrUnknown(data['carbs_g']!, _carbsGMeta),
      );
    } else if (isInserting) {
      context.missing(_carbsGMeta);
    }
    if (data.containsKey('sugar_g')) {
      context.handle(
        _sugarGMeta,
        sugarG.isAcceptableOrUnknown(data['sugar_g']!, _sugarGMeta),
      );
    }
    if (data.containsKey('fiber_g')) {
      context.handle(
        _fiberGMeta,
        fiberG.isAcceptableOrUnknown(data['fiber_g']!, _fiberGMeta),
      );
    }
    if (data.containsKey('fat_g')) {
      context.handle(
        _fatGMeta,
        fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta),
      );
    } else if (isInserting) {
      context.missing(_fatGMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FoodLogEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FoodLogEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      loggedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}logged_at'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      catalogFoodId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}catalog_food_id'],
      ),
      customFoodId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}custom_food_id'],
      ),
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      grams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grams'],
      )!,
      kcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kcal'],
      )!,
      proteinG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_g'],
      )!,
      carbsG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs_g'],
      )!,
      sugarG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sugar_g'],
      )!,
      fiberG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fiber_g'],
      )!,
      fatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_g'],
      )!,
    );
  }

  @override
  $FoodLogEntriesTable createAlias(String alias) {
    return $FoodLogEntriesTable(attachedDatabase, alias);
  }
}

class FoodLogEntry extends DataClass implements Insertable<FoodLogEntry> {
  final int id;
  final DateTime loggedAt;
  final String source;
  final String? catalogFoodId;
  final int? customFoodId;
  final String displayName;
  final double grams;
  final double kcal;
  final double proteinG;
  final double carbsG;
  final double sugarG;
  final double fiberG;
  final double fatG;
  const FoodLogEntry({
    required this.id,
    required this.loggedAt,
    required this.source,
    this.catalogFoodId,
    this.customFoodId,
    required this.displayName,
    required this.grams,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.sugarG,
    required this.fiberG,
    required this.fatG,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['logged_at'] = Variable<DateTime>(loggedAt);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || catalogFoodId != null) {
      map['catalog_food_id'] = Variable<String>(catalogFoodId);
    }
    if (!nullToAbsent || customFoodId != null) {
      map['custom_food_id'] = Variable<int>(customFoodId);
    }
    map['display_name'] = Variable<String>(displayName);
    map['grams'] = Variable<double>(grams);
    map['kcal'] = Variable<double>(kcal);
    map['protein_g'] = Variable<double>(proteinG);
    map['carbs_g'] = Variable<double>(carbsG);
    map['sugar_g'] = Variable<double>(sugarG);
    map['fiber_g'] = Variable<double>(fiberG);
    map['fat_g'] = Variable<double>(fatG);
    return map;
  }

  FoodLogEntriesCompanion toCompanion(bool nullToAbsent) {
    return FoodLogEntriesCompanion(
      id: Value(id),
      loggedAt: Value(loggedAt),
      source: Value(source),
      catalogFoodId: catalogFoodId == null && nullToAbsent
          ? const Value.absent()
          : Value(catalogFoodId),
      customFoodId: customFoodId == null && nullToAbsent
          ? const Value.absent()
          : Value(customFoodId),
      displayName: Value(displayName),
      grams: Value(grams),
      kcal: Value(kcal),
      proteinG: Value(proteinG),
      carbsG: Value(carbsG),
      sugarG: Value(sugarG),
      fiberG: Value(fiberG),
      fatG: Value(fatG),
    );
  }

  factory FoodLogEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FoodLogEntry(
      id: serializer.fromJson<int>(json['id']),
      loggedAt: serializer.fromJson<DateTime>(json['loggedAt']),
      source: serializer.fromJson<String>(json['source']),
      catalogFoodId: serializer.fromJson<String?>(json['catalogFoodId']),
      customFoodId: serializer.fromJson<int?>(json['customFoodId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      grams: serializer.fromJson<double>(json['grams']),
      kcal: serializer.fromJson<double>(json['kcal']),
      proteinG: serializer.fromJson<double>(json['proteinG']),
      carbsG: serializer.fromJson<double>(json['carbsG']),
      sugarG: serializer.fromJson<double>(json['sugarG']),
      fiberG: serializer.fromJson<double>(json['fiberG']),
      fatG: serializer.fromJson<double>(json['fatG']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'loggedAt': serializer.toJson<DateTime>(loggedAt),
      'source': serializer.toJson<String>(source),
      'catalogFoodId': serializer.toJson<String?>(catalogFoodId),
      'customFoodId': serializer.toJson<int?>(customFoodId),
      'displayName': serializer.toJson<String>(displayName),
      'grams': serializer.toJson<double>(grams),
      'kcal': serializer.toJson<double>(kcal),
      'proteinG': serializer.toJson<double>(proteinG),
      'carbsG': serializer.toJson<double>(carbsG),
      'sugarG': serializer.toJson<double>(sugarG),
      'fiberG': serializer.toJson<double>(fiberG),
      'fatG': serializer.toJson<double>(fatG),
    };
  }

  FoodLogEntry copyWith({
    int? id,
    DateTime? loggedAt,
    String? source,
    Value<String?> catalogFoodId = const Value.absent(),
    Value<int?> customFoodId = const Value.absent(),
    String? displayName,
    double? grams,
    double? kcal,
    double? proteinG,
    double? carbsG,
    double? sugarG,
    double? fiberG,
    double? fatG,
  }) => FoodLogEntry(
    id: id ?? this.id,
    loggedAt: loggedAt ?? this.loggedAt,
    source: source ?? this.source,
    catalogFoodId: catalogFoodId.present
        ? catalogFoodId.value
        : this.catalogFoodId,
    customFoodId: customFoodId.present ? customFoodId.value : this.customFoodId,
    displayName: displayName ?? this.displayName,
    grams: grams ?? this.grams,
    kcal: kcal ?? this.kcal,
    proteinG: proteinG ?? this.proteinG,
    carbsG: carbsG ?? this.carbsG,
    sugarG: sugarG ?? this.sugarG,
    fiberG: fiberG ?? this.fiberG,
    fatG: fatG ?? this.fatG,
  );
  FoodLogEntry copyWithCompanion(FoodLogEntriesCompanion data) {
    return FoodLogEntry(
      id: data.id.present ? data.id.value : this.id,
      loggedAt: data.loggedAt.present ? data.loggedAt.value : this.loggedAt,
      source: data.source.present ? data.source.value : this.source,
      catalogFoodId: data.catalogFoodId.present
          ? data.catalogFoodId.value
          : this.catalogFoodId,
      customFoodId: data.customFoodId.present
          ? data.customFoodId.value
          : this.customFoodId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      grams: data.grams.present ? data.grams.value : this.grams,
      kcal: data.kcal.present ? data.kcal.value : this.kcal,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      carbsG: data.carbsG.present ? data.carbsG.value : this.carbsG,
      sugarG: data.sugarG.present ? data.sugarG.value : this.sugarG,
      fiberG: data.fiberG.present ? data.fiberG.value : this.fiberG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FoodLogEntry(')
          ..write('id: $id, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('source: $source, ')
          ..write('catalogFoodId: $catalogFoodId, ')
          ..write('customFoodId: $customFoodId, ')
          ..write('displayName: $displayName, ')
          ..write('grams: $grams, ')
          ..write('kcal: $kcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('sugarG: $sugarG, ')
          ..write('fiberG: $fiberG, ')
          ..write('fatG: $fatG')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    loggedAt,
    source,
    catalogFoodId,
    customFoodId,
    displayName,
    grams,
    kcal,
    proteinG,
    carbsG,
    sugarG,
    fiberG,
    fatG,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoodLogEntry &&
          other.id == this.id &&
          other.loggedAt == this.loggedAt &&
          other.source == this.source &&
          other.catalogFoodId == this.catalogFoodId &&
          other.customFoodId == this.customFoodId &&
          other.displayName == this.displayName &&
          other.grams == this.grams &&
          other.kcal == this.kcal &&
          other.proteinG == this.proteinG &&
          other.carbsG == this.carbsG &&
          other.sugarG == this.sugarG &&
          other.fiberG == this.fiberG &&
          other.fatG == this.fatG);
}

class FoodLogEntriesCompanion extends UpdateCompanion<FoodLogEntry> {
  final Value<int> id;
  final Value<DateTime> loggedAt;
  final Value<String> source;
  final Value<String?> catalogFoodId;
  final Value<int?> customFoodId;
  final Value<String> displayName;
  final Value<double> grams;
  final Value<double> kcal;
  final Value<double> proteinG;
  final Value<double> carbsG;
  final Value<double> sugarG;
  final Value<double> fiberG;
  final Value<double> fatG;
  const FoodLogEntriesCompanion({
    this.id = const Value.absent(),
    this.loggedAt = const Value.absent(),
    this.source = const Value.absent(),
    this.catalogFoodId = const Value.absent(),
    this.customFoodId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.grams = const Value.absent(),
    this.kcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.sugarG = const Value.absent(),
    this.fiberG = const Value.absent(),
    this.fatG = const Value.absent(),
  });
  FoodLogEntriesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime loggedAt,
    required String source,
    this.catalogFoodId = const Value.absent(),
    this.customFoodId = const Value.absent(),
    required String displayName,
    required double grams,
    required double kcal,
    required double proteinG,
    required double carbsG,
    this.sugarG = const Value.absent(),
    this.fiberG = const Value.absent(),
    required double fatG,
  }) : loggedAt = Value(loggedAt),
       source = Value(source),
       displayName = Value(displayName),
       grams = Value(grams),
       kcal = Value(kcal),
       proteinG = Value(proteinG),
       carbsG = Value(carbsG),
       fatG = Value(fatG);
  static Insertable<FoodLogEntry> custom({
    Expression<int>? id,
    Expression<DateTime>? loggedAt,
    Expression<String>? source,
    Expression<String>? catalogFoodId,
    Expression<int>? customFoodId,
    Expression<String>? displayName,
    Expression<double>? grams,
    Expression<double>? kcal,
    Expression<double>? proteinG,
    Expression<double>? carbsG,
    Expression<double>? sugarG,
    Expression<double>? fiberG,
    Expression<double>? fatG,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (loggedAt != null) 'logged_at': loggedAt,
      if (source != null) 'source': source,
      if (catalogFoodId != null) 'catalog_food_id': catalogFoodId,
      if (customFoodId != null) 'custom_food_id': customFoodId,
      if (displayName != null) 'display_name': displayName,
      if (grams != null) 'grams': grams,
      if (kcal != null) 'kcal': kcal,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbsG != null) 'carbs_g': carbsG,
      if (sugarG != null) 'sugar_g': sugarG,
      if (fiberG != null) 'fiber_g': fiberG,
      if (fatG != null) 'fat_g': fatG,
    });
  }

  FoodLogEntriesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? loggedAt,
    Value<String>? source,
    Value<String?>? catalogFoodId,
    Value<int?>? customFoodId,
    Value<String>? displayName,
    Value<double>? grams,
    Value<double>? kcal,
    Value<double>? proteinG,
    Value<double>? carbsG,
    Value<double>? sugarG,
    Value<double>? fiberG,
    Value<double>? fatG,
  }) {
    return FoodLogEntriesCompanion(
      id: id ?? this.id,
      loggedAt: loggedAt ?? this.loggedAt,
      source: source ?? this.source,
      catalogFoodId: catalogFoodId ?? this.catalogFoodId,
      customFoodId: customFoodId ?? this.customFoodId,
      displayName: displayName ?? this.displayName,
      grams: grams ?? this.grams,
      kcal: kcal ?? this.kcal,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      sugarG: sugarG ?? this.sugarG,
      fiberG: fiberG ?? this.fiberG,
      fatG: fatG ?? this.fatG,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (loggedAt.present) {
      map['logged_at'] = Variable<DateTime>(loggedAt.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (catalogFoodId.present) {
      map['catalog_food_id'] = Variable<String>(catalogFoodId.value);
    }
    if (customFoodId.present) {
      map['custom_food_id'] = Variable<int>(customFoodId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (grams.present) {
      map['grams'] = Variable<double>(grams.value);
    }
    if (kcal.present) {
      map['kcal'] = Variable<double>(kcal.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<double>(proteinG.value);
    }
    if (carbsG.present) {
      map['carbs_g'] = Variable<double>(carbsG.value);
    }
    if (sugarG.present) {
      map['sugar_g'] = Variable<double>(sugarG.value);
    }
    if (fiberG.present) {
      map['fiber_g'] = Variable<double>(fiberG.value);
    }
    if (fatG.present) {
      map['fat_g'] = Variable<double>(fatG.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodLogEntriesCompanion(')
          ..write('id: $id, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('source: $source, ')
          ..write('catalogFoodId: $catalogFoodId, ')
          ..write('customFoodId: $customFoodId, ')
          ..write('displayName: $displayName, ')
          ..write('grams: $grams, ')
          ..write('kcal: $kcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('sugarG: $sugarG, ')
          ..write('fiberG: $fiberG, ')
          ..write('fatG: $fatG')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $GoalsTable goals = $GoalsTable(this);
  late final $WeightEntriesTable weightEntries = $WeightEntriesTable(this);
  late final $FoodPrefsTable foodPrefs = $FoodPrefsTable(this);
  late final $CustomFoodsTable customFoods = $CustomFoodsTable(this);
  late final $FoodLogEntriesTable foodLogEntries = $FoodLogEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    profiles,
    goals,
    weightEntries,
    foodPrefs,
    customFoods,
    foodLogEntries,
  ];
}

typedef $$ProfilesTableCreateCompanionBuilder =
    ProfilesCompanion Function({
      Value<int> id,
      required String sex,
      required int birthDateMillis,
      Value<int?> ageBandMaxYears,
      required double heightCm,
      required int activityLevel,
      required String weightUnit,
      required int proteinPct,
      required int carbsPct,
      required int fatPct,
      required int reminderWeekday,
      required int reminderHour,
      required int reminderMinute,
      Value<bool> onboardingCompleted,
      Value<double?> dailyCalorieTarget,
    });
typedef $$ProfilesTableUpdateCompanionBuilder =
    ProfilesCompanion Function({
      Value<int> id,
      Value<String> sex,
      Value<int> birthDateMillis,
      Value<int?> ageBandMaxYears,
      Value<double> heightCm,
      Value<int> activityLevel,
      Value<String> weightUnit,
      Value<int> proteinPct,
      Value<int> carbsPct,
      Value<int> fatPct,
      Value<int> reminderWeekday,
      Value<int> reminderHour,
      Value<int> reminderMinute,
      Value<bool> onboardingCompleted,
      Value<double?> dailyCalorieTarget,
    });

class $$ProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get birthDateMillis => $composableBuilder(
    column: $table.birthDateMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ageBandMaxYears => $composableBuilder(
    column: $table.ageBandMaxYears,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get activityLevel => $composableBuilder(
    column: $table.activityLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weightUnit => $composableBuilder(
    column: $table.weightUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get proteinPct => $composableBuilder(
    column: $table.proteinPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get carbsPct => $composableBuilder(
    column: $table.carbsPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fatPct => $composableBuilder(
    column: $table.fatPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderWeekday => $composableBuilder(
    column: $table.reminderWeekday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderHour => $composableBuilder(
    column: $table.reminderHour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderMinute => $composableBuilder(
    column: $table.reminderMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get onboardingCompleted => $composableBuilder(
    column: $table.onboardingCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get dailyCalorieTarget => $composableBuilder(
    column: $table.dailyCalorieTarget,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get birthDateMillis => $composableBuilder(
    column: $table.birthDateMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ageBandMaxYears => $composableBuilder(
    column: $table.ageBandMaxYears,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get activityLevel => $composableBuilder(
    column: $table.activityLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weightUnit => $composableBuilder(
    column: $table.weightUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get proteinPct => $composableBuilder(
    column: $table.proteinPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get carbsPct => $composableBuilder(
    column: $table.carbsPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fatPct => $composableBuilder(
    column: $table.fatPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderWeekday => $composableBuilder(
    column: $table.reminderWeekday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderHour => $composableBuilder(
    column: $table.reminderHour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderMinute => $composableBuilder(
    column: $table.reminderMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get onboardingCompleted => $composableBuilder(
    column: $table.onboardingCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get dailyCalorieTarget => $composableBuilder(
    column: $table.dailyCalorieTarget,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sex =>
      $composableBuilder(column: $table.sex, builder: (column) => column);

  GeneratedColumn<int> get birthDateMillis => $composableBuilder(
    column: $table.birthDateMillis,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ageBandMaxYears => $composableBuilder(
    column: $table.ageBandMaxYears,
    builder: (column) => column,
  );

  GeneratedColumn<double> get heightCm =>
      $composableBuilder(column: $table.heightCm, builder: (column) => column);

  GeneratedColumn<int> get activityLevel => $composableBuilder(
    column: $table.activityLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get weightUnit => $composableBuilder(
    column: $table.weightUnit,
    builder: (column) => column,
  );

  GeneratedColumn<int> get proteinPct => $composableBuilder(
    column: $table.proteinPct,
    builder: (column) => column,
  );

  GeneratedColumn<int> get carbsPct =>
      $composableBuilder(column: $table.carbsPct, builder: (column) => column);

  GeneratedColumn<int> get fatPct =>
      $composableBuilder(column: $table.fatPct, builder: (column) => column);

  GeneratedColumn<int> get reminderWeekday => $composableBuilder(
    column: $table.reminderWeekday,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderHour => $composableBuilder(
    column: $table.reminderHour,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderMinute => $composableBuilder(
    column: $table.reminderMinute,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get onboardingCompleted => $composableBuilder(
    column: $table.onboardingCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<double> get dailyCalorieTarget => $composableBuilder(
    column: $table.dailyCalorieTarget,
    builder: (column) => column,
  );
}

class $$ProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfilesTable,
          Profile,
          $$ProfilesTableFilterComposer,
          $$ProfilesTableOrderingComposer,
          $$ProfilesTableAnnotationComposer,
          $$ProfilesTableCreateCompanionBuilder,
          $$ProfilesTableUpdateCompanionBuilder,
          (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
          Profile,
          PrefetchHooks Function()
        > {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sex = const Value.absent(),
                Value<int> birthDateMillis = const Value.absent(),
                Value<int?> ageBandMaxYears = const Value.absent(),
                Value<double> heightCm = const Value.absent(),
                Value<int> activityLevel = const Value.absent(),
                Value<String> weightUnit = const Value.absent(),
                Value<int> proteinPct = const Value.absent(),
                Value<int> carbsPct = const Value.absent(),
                Value<int> fatPct = const Value.absent(),
                Value<int> reminderWeekday = const Value.absent(),
                Value<int> reminderHour = const Value.absent(),
                Value<int> reminderMinute = const Value.absent(),
                Value<bool> onboardingCompleted = const Value.absent(),
                Value<double?> dailyCalorieTarget = const Value.absent(),
              }) => ProfilesCompanion(
                id: id,
                sex: sex,
                birthDateMillis: birthDateMillis,
                ageBandMaxYears: ageBandMaxYears,
                heightCm: heightCm,
                activityLevel: activityLevel,
                weightUnit: weightUnit,
                proteinPct: proteinPct,
                carbsPct: carbsPct,
                fatPct: fatPct,
                reminderWeekday: reminderWeekday,
                reminderHour: reminderHour,
                reminderMinute: reminderMinute,
                onboardingCompleted: onboardingCompleted,
                dailyCalorieTarget: dailyCalorieTarget,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sex,
                required int birthDateMillis,
                Value<int?> ageBandMaxYears = const Value.absent(),
                required double heightCm,
                required int activityLevel,
                required String weightUnit,
                required int proteinPct,
                required int carbsPct,
                required int fatPct,
                required int reminderWeekday,
                required int reminderHour,
                required int reminderMinute,
                Value<bool> onboardingCompleted = const Value.absent(),
                Value<double?> dailyCalorieTarget = const Value.absent(),
              }) => ProfilesCompanion.insert(
                id: id,
                sex: sex,
                birthDateMillis: birthDateMillis,
                ageBandMaxYears: ageBandMaxYears,
                heightCm: heightCm,
                activityLevel: activityLevel,
                weightUnit: weightUnit,
                proteinPct: proteinPct,
                carbsPct: carbsPct,
                fatPct: fatPct,
                reminderWeekday: reminderWeekday,
                reminderHour: reminderHour,
                reminderMinute: reminderMinute,
                onboardingCompleted: onboardingCompleted,
                dailyCalorieTarget: dailyCalorieTarget,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfilesTable,
      Profile,
      $$ProfilesTableFilterComposer,
      $$ProfilesTableOrderingComposer,
      $$ProfilesTableAnnotationComposer,
      $$ProfilesTableCreateCompanionBuilder,
      $$ProfilesTableUpdateCompanionBuilder,
      (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
      Profile,
      PrefetchHooks Function()
    >;
typedef $$GoalsTableCreateCompanionBuilder =
    GoalsCompanion Function({
      Value<int> id,
      required double targetWeightKg,
      required double weeklyChangeKgPerWeek,
      required String status,
    });
typedef $$GoalsTableUpdateCompanionBuilder =
    GoalsCompanion Function({
      Value<int> id,
      Value<double> targetWeightKg,
      Value<double> weeklyChangeKgPerWeek,
      Value<String> status,
    });

class $$GoalsTableFilterComposer extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetWeightKg => $composableBuilder(
    column: $table.targetWeightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weeklyChangeKgPerWeek => $composableBuilder(
    column: $table.weeklyChangeKgPerWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetWeightKg => $composableBuilder(
    column: $table.targetWeightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weeklyChangeKgPerWeek => $composableBuilder(
    column: $table.weeklyChangeKgPerWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get targetWeightKg => $composableBuilder(
    column: $table.targetWeightKg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get weeklyChangeKgPerWeek => $composableBuilder(
    column: $table.weeklyChangeKgPerWeek,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$GoalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GoalsTable,
          Goal,
          $$GoalsTableFilterComposer,
          $$GoalsTableOrderingComposer,
          $$GoalsTableAnnotationComposer,
          $$GoalsTableCreateCompanionBuilder,
          $$GoalsTableUpdateCompanionBuilder,
          (Goal, BaseReferences<_$AppDatabase, $GoalsTable, Goal>),
          Goal,
          PrefetchHooks Function()
        > {
  $$GoalsTableTableManager(_$AppDatabase db, $GoalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double> targetWeightKg = const Value.absent(),
                Value<double> weeklyChangeKgPerWeek = const Value.absent(),
                Value<String> status = const Value.absent(),
              }) => GoalsCompanion(
                id: id,
                targetWeightKg: targetWeightKg,
                weeklyChangeKgPerWeek: weeklyChangeKgPerWeek,
                status: status,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required double targetWeightKg,
                required double weeklyChangeKgPerWeek,
                required String status,
              }) => GoalsCompanion.insert(
                id: id,
                targetWeightKg: targetWeightKg,
                weeklyChangeKgPerWeek: weeklyChangeKgPerWeek,
                status: status,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GoalsTable,
      Goal,
      $$GoalsTableFilterComposer,
      $$GoalsTableOrderingComposer,
      $$GoalsTableAnnotationComposer,
      $$GoalsTableCreateCompanionBuilder,
      $$GoalsTableUpdateCompanionBuilder,
      (Goal, BaseReferences<_$AppDatabase, $GoalsTable, Goal>),
      Goal,
      PrefetchHooks Function()
    >;
typedef $$WeightEntriesTableCreateCompanionBuilder =
    WeightEntriesCompanion Function({
      Value<int> id,
      required DateTime recordedAt,
      required double weightKg,
      Value<String?> note,
    });
typedef $$WeightEntriesTableUpdateCompanionBuilder =
    WeightEntriesCompanion Function({
      Value<int> id,
      Value<DateTime> recordedAt,
      Value<double> weightKg,
      Value<String?> note,
    });

class $$WeightEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $WeightEntriesTable> {
  $$WeightEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeightEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $WeightEntriesTable> {
  $$WeightEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeightEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeightEntriesTable> {
  $$WeightEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$WeightEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeightEntriesTable,
          WeightEntry,
          $$WeightEntriesTableFilterComposer,
          $$WeightEntriesTableOrderingComposer,
          $$WeightEntriesTableAnnotationComposer,
          $$WeightEntriesTableCreateCompanionBuilder,
          $$WeightEntriesTableUpdateCompanionBuilder,
          (
            WeightEntry,
            BaseReferences<_$AppDatabase, $WeightEntriesTable, WeightEntry>,
          ),
          WeightEntry,
          PrefetchHooks Function()
        > {
  $$WeightEntriesTableTableManager(_$AppDatabase db, $WeightEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeightEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeightEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeightEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<double> weightKg = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => WeightEntriesCompanion(
                id: id,
                recordedAt: recordedAt,
                weightKg: weightKg,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime recordedAt,
                required double weightKg,
                Value<String?> note = const Value.absent(),
              }) => WeightEntriesCompanion.insert(
                id: id,
                recordedAt: recordedAt,
                weightKg: weightKg,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeightEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeightEntriesTable,
      WeightEntry,
      $$WeightEntriesTableFilterComposer,
      $$WeightEntriesTableOrderingComposer,
      $$WeightEntriesTableAnnotationComposer,
      $$WeightEntriesTableCreateCompanionBuilder,
      $$WeightEntriesTableUpdateCompanionBuilder,
      (
        WeightEntry,
        BaseReferences<_$AppDatabase, $WeightEntriesTable, WeightEntry>,
      ),
      WeightEntry,
      PrefetchHooks Function()
    >;
typedef $$FoodPrefsTableCreateCompanionBuilder =
    FoodPrefsCompanion Function({
      required String foodKey,
      Value<bool?> treatAsLiquid,
      Value<double?> savedServingAmount,
      Value<String?> savedServingUnit,
      Value<int> rowid,
    });
typedef $$FoodPrefsTableUpdateCompanionBuilder =
    FoodPrefsCompanion Function({
      Value<String> foodKey,
      Value<bool?> treatAsLiquid,
      Value<double?> savedServingAmount,
      Value<String?> savedServingUnit,
      Value<int> rowid,
    });

class $$FoodPrefsTableFilterComposer
    extends Composer<_$AppDatabase, $FoodPrefsTable> {
  $$FoodPrefsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get foodKey => $composableBuilder(
    column: $table.foodKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get treatAsLiquid => $composableBuilder(
    column: $table.treatAsLiquid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get savedServingAmount => $composableBuilder(
    column: $table.savedServingAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get savedServingUnit => $composableBuilder(
    column: $table.savedServingUnit,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FoodPrefsTableOrderingComposer
    extends Composer<_$AppDatabase, $FoodPrefsTable> {
  $$FoodPrefsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get foodKey => $composableBuilder(
    column: $table.foodKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get treatAsLiquid => $composableBuilder(
    column: $table.treatAsLiquid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get savedServingAmount => $composableBuilder(
    column: $table.savedServingAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get savedServingUnit => $composableBuilder(
    column: $table.savedServingUnit,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoodPrefsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoodPrefsTable> {
  $$FoodPrefsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get foodKey =>
      $composableBuilder(column: $table.foodKey, builder: (column) => column);

  GeneratedColumn<bool> get treatAsLiquid => $composableBuilder(
    column: $table.treatAsLiquid,
    builder: (column) => column,
  );

  GeneratedColumn<double> get savedServingAmount => $composableBuilder(
    column: $table.savedServingAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get savedServingUnit => $composableBuilder(
    column: $table.savedServingUnit,
    builder: (column) => column,
  );
}

class $$FoodPrefsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoodPrefsTable,
          FoodPref,
          $$FoodPrefsTableFilterComposer,
          $$FoodPrefsTableOrderingComposer,
          $$FoodPrefsTableAnnotationComposer,
          $$FoodPrefsTableCreateCompanionBuilder,
          $$FoodPrefsTableUpdateCompanionBuilder,
          (FoodPref, BaseReferences<_$AppDatabase, $FoodPrefsTable, FoodPref>),
          FoodPref,
          PrefetchHooks Function()
        > {
  $$FoodPrefsTableTableManager(_$AppDatabase db, $FoodPrefsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoodPrefsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoodPrefsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoodPrefsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> foodKey = const Value.absent(),
                Value<bool?> treatAsLiquid = const Value.absent(),
                Value<double?> savedServingAmount = const Value.absent(),
                Value<String?> savedServingUnit = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoodPrefsCompanion(
                foodKey: foodKey,
                treatAsLiquid: treatAsLiquid,
                savedServingAmount: savedServingAmount,
                savedServingUnit: savedServingUnit,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String foodKey,
                Value<bool?> treatAsLiquid = const Value.absent(),
                Value<double?> savedServingAmount = const Value.absent(),
                Value<String?> savedServingUnit = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoodPrefsCompanion.insert(
                foodKey: foodKey,
                treatAsLiquid: treatAsLiquid,
                savedServingAmount: savedServingAmount,
                savedServingUnit: savedServingUnit,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FoodPrefsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoodPrefsTable,
      FoodPref,
      $$FoodPrefsTableFilterComposer,
      $$FoodPrefsTableOrderingComposer,
      $$FoodPrefsTableAnnotationComposer,
      $$FoodPrefsTableCreateCompanionBuilder,
      $$FoodPrefsTableUpdateCompanionBuilder,
      (FoodPref, BaseReferences<_$AppDatabase, $FoodPrefsTable, FoodPref>),
      FoodPref,
      PrefetchHooks Function()
    >;
typedef $$CustomFoodsTableCreateCompanionBuilder =
    CustomFoodsCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> brand,
      Value<String?> barcode,
      required double servingSize,
      required String servingUnit,
      required double calories,
      required double fatG,
      required double carbsG,
      required double sugarG,
      required double fiberG,
      required double proteinG,
    });
typedef $$CustomFoodsTableUpdateCompanionBuilder =
    CustomFoodsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> brand,
      Value<String?> barcode,
      Value<double> servingSize,
      Value<String> servingUnit,
      Value<double> calories,
      Value<double> fatG,
      Value<double> carbsG,
      Value<double> sugarG,
      Value<double> fiberG,
      Value<double> proteinG,
    });

class $$CustomFoodsTableFilterComposer
    extends Composer<_$AppDatabase, $CustomFoodsTable> {
  $$CustomFoodsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get servingSize => $composableBuilder(
    column: $table.servingSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get servingUnit => $composableBuilder(
    column: $table.servingUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sugarG => $composableBuilder(
    column: $table.sugarG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fiberG => $composableBuilder(
    column: $table.fiberG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomFoodsTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomFoodsTable> {
  $$CustomFoodsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get servingSize => $composableBuilder(
    column: $table.servingSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get servingUnit => $composableBuilder(
    column: $table.servingUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sugarG => $composableBuilder(
    column: $table.sugarG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fiberG => $composableBuilder(
    column: $table.fiberG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomFoodsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomFoodsTable> {
  $$CustomFoodsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<double> get servingSize => $composableBuilder(
    column: $table.servingSize,
    builder: (column) => column,
  );

  GeneratedColumn<String> get servingUnit => $composableBuilder(
    column: $table.servingUnit,
    builder: (column) => column,
  );

  GeneratedColumn<double> get calories =>
      $composableBuilder(column: $table.calories, builder: (column) => column);

  GeneratedColumn<double> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);

  GeneratedColumn<double> get carbsG =>
      $composableBuilder(column: $table.carbsG, builder: (column) => column);

  GeneratedColumn<double> get sugarG =>
      $composableBuilder(column: $table.sugarG, builder: (column) => column);

  GeneratedColumn<double> get fiberG =>
      $composableBuilder(column: $table.fiberG, builder: (column) => column);

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);
}

class $$CustomFoodsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomFoodsTable,
          CustomFood,
          $$CustomFoodsTableFilterComposer,
          $$CustomFoodsTableOrderingComposer,
          $$CustomFoodsTableAnnotationComposer,
          $$CustomFoodsTableCreateCompanionBuilder,
          $$CustomFoodsTableUpdateCompanionBuilder,
          (
            CustomFood,
            BaseReferences<_$AppDatabase, $CustomFoodsTable, CustomFood>,
          ),
          CustomFood,
          PrefetchHooks Function()
        > {
  $$CustomFoodsTableTableManager(_$AppDatabase db, $CustomFoodsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomFoodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomFoodsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomFoodsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<double> servingSize = const Value.absent(),
                Value<String> servingUnit = const Value.absent(),
                Value<double> calories = const Value.absent(),
                Value<double> fatG = const Value.absent(),
                Value<double> carbsG = const Value.absent(),
                Value<double> sugarG = const Value.absent(),
                Value<double> fiberG = const Value.absent(),
                Value<double> proteinG = const Value.absent(),
              }) => CustomFoodsCompanion(
                id: id,
                name: name,
                brand: brand,
                barcode: barcode,
                servingSize: servingSize,
                servingUnit: servingUnit,
                calories: calories,
                fatG: fatG,
                carbsG: carbsG,
                sugarG: sugarG,
                fiberG: fiberG,
                proteinG: proteinG,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> brand = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                required double servingSize,
                required String servingUnit,
                required double calories,
                required double fatG,
                required double carbsG,
                required double sugarG,
                required double fiberG,
                required double proteinG,
              }) => CustomFoodsCompanion.insert(
                id: id,
                name: name,
                brand: brand,
                barcode: barcode,
                servingSize: servingSize,
                servingUnit: servingUnit,
                calories: calories,
                fatG: fatG,
                carbsG: carbsG,
                sugarG: sugarG,
                fiberG: fiberG,
                proteinG: proteinG,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomFoodsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomFoodsTable,
      CustomFood,
      $$CustomFoodsTableFilterComposer,
      $$CustomFoodsTableOrderingComposer,
      $$CustomFoodsTableAnnotationComposer,
      $$CustomFoodsTableCreateCompanionBuilder,
      $$CustomFoodsTableUpdateCompanionBuilder,
      (
        CustomFood,
        BaseReferences<_$AppDatabase, $CustomFoodsTable, CustomFood>,
      ),
      CustomFood,
      PrefetchHooks Function()
    >;
typedef $$FoodLogEntriesTableCreateCompanionBuilder =
    FoodLogEntriesCompanion Function({
      Value<int> id,
      required DateTime loggedAt,
      required String source,
      Value<String?> catalogFoodId,
      Value<int?> customFoodId,
      required String displayName,
      required double grams,
      required double kcal,
      required double proteinG,
      required double carbsG,
      Value<double> sugarG,
      Value<double> fiberG,
      required double fatG,
    });
typedef $$FoodLogEntriesTableUpdateCompanionBuilder =
    FoodLogEntriesCompanion Function({
      Value<int> id,
      Value<DateTime> loggedAt,
      Value<String> source,
      Value<String?> catalogFoodId,
      Value<int?> customFoodId,
      Value<String> displayName,
      Value<double> grams,
      Value<double> kcal,
      Value<double> proteinG,
      Value<double> carbsG,
      Value<double> sugarG,
      Value<double> fiberG,
      Value<double> fatG,
    });

class $$FoodLogEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $FoodLogEntriesTable> {
  $$FoodLogEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get catalogFoodId => $composableBuilder(
    column: $table.catalogFoodId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get customFoodId => $composableBuilder(
    column: $table.customFoodId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kcal => $composableBuilder(
    column: $table.kcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sugarG => $composableBuilder(
    column: $table.sugarG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fiberG => $composableBuilder(
    column: $table.fiberG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FoodLogEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $FoodLogEntriesTable> {
  $$FoodLogEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get catalogFoodId => $composableBuilder(
    column: $table.catalogFoodId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get customFoodId => $composableBuilder(
    column: $table.customFoodId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kcal => $composableBuilder(
    column: $table.kcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sugarG => $composableBuilder(
    column: $table.sugarG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fiberG => $composableBuilder(
    column: $table.fiberG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoodLogEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoodLogEntriesTable> {
  $$FoodLogEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get loggedAt =>
      $composableBuilder(column: $table.loggedAt, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get catalogFoodId => $composableBuilder(
    column: $table.catalogFoodId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get customFoodId => $composableBuilder(
    column: $table.customFoodId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get grams =>
      $composableBuilder(column: $table.grams, builder: (column) => column);

  GeneratedColumn<double> get kcal =>
      $composableBuilder(column: $table.kcal, builder: (column) => column);

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<double> get carbsG =>
      $composableBuilder(column: $table.carbsG, builder: (column) => column);

  GeneratedColumn<double> get sugarG =>
      $composableBuilder(column: $table.sugarG, builder: (column) => column);

  GeneratedColumn<double> get fiberG =>
      $composableBuilder(column: $table.fiberG, builder: (column) => column);

  GeneratedColumn<double> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);
}

class $$FoodLogEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoodLogEntriesTable,
          FoodLogEntry,
          $$FoodLogEntriesTableFilterComposer,
          $$FoodLogEntriesTableOrderingComposer,
          $$FoodLogEntriesTableAnnotationComposer,
          $$FoodLogEntriesTableCreateCompanionBuilder,
          $$FoodLogEntriesTableUpdateCompanionBuilder,
          (
            FoodLogEntry,
            BaseReferences<_$AppDatabase, $FoodLogEntriesTable, FoodLogEntry>,
          ),
          FoodLogEntry,
          PrefetchHooks Function()
        > {
  $$FoodLogEntriesTableTableManager(
    _$AppDatabase db,
    $FoodLogEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoodLogEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoodLogEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoodLogEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> loggedAt = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> catalogFoodId = const Value.absent(),
                Value<int?> customFoodId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<double> grams = const Value.absent(),
                Value<double> kcal = const Value.absent(),
                Value<double> proteinG = const Value.absent(),
                Value<double> carbsG = const Value.absent(),
                Value<double> sugarG = const Value.absent(),
                Value<double> fiberG = const Value.absent(),
                Value<double> fatG = const Value.absent(),
              }) => FoodLogEntriesCompanion(
                id: id,
                loggedAt: loggedAt,
                source: source,
                catalogFoodId: catalogFoodId,
                customFoodId: customFoodId,
                displayName: displayName,
                grams: grams,
                kcal: kcal,
                proteinG: proteinG,
                carbsG: carbsG,
                sugarG: sugarG,
                fiberG: fiberG,
                fatG: fatG,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime loggedAt,
                required String source,
                Value<String?> catalogFoodId = const Value.absent(),
                Value<int?> customFoodId = const Value.absent(),
                required String displayName,
                required double grams,
                required double kcal,
                required double proteinG,
                required double carbsG,
                Value<double> sugarG = const Value.absent(),
                Value<double> fiberG = const Value.absent(),
                required double fatG,
              }) => FoodLogEntriesCompanion.insert(
                id: id,
                loggedAt: loggedAt,
                source: source,
                catalogFoodId: catalogFoodId,
                customFoodId: customFoodId,
                displayName: displayName,
                grams: grams,
                kcal: kcal,
                proteinG: proteinG,
                carbsG: carbsG,
                sugarG: sugarG,
                fiberG: fiberG,
                fatG: fatG,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FoodLogEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoodLogEntriesTable,
      FoodLogEntry,
      $$FoodLogEntriesTableFilterComposer,
      $$FoodLogEntriesTableOrderingComposer,
      $$FoodLogEntriesTableAnnotationComposer,
      $$FoodLogEntriesTableCreateCompanionBuilder,
      $$FoodLogEntriesTableUpdateCompanionBuilder,
      (
        FoodLogEntry,
        BaseReferences<_$AppDatabase, $FoodLogEntriesTable, FoodLogEntry>,
      ),
      FoodLogEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db, _db.goals);
  $$WeightEntriesTableTableManager get weightEntries =>
      $$WeightEntriesTableTableManager(_db, _db.weightEntries);
  $$FoodPrefsTableTableManager get foodPrefs =>
      $$FoodPrefsTableTableManager(_db, _db.foodPrefs);
  $$CustomFoodsTableTableManager get customFoods =>
      $$CustomFoodsTableTableManager(_db, _db.customFoods);
  $$FoodLogEntriesTableTableManager get foodLogEntries =>
      $$FoodLogEntriesTableTableManager(_db, _db.foodLogEntries);
}
