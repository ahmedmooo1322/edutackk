class CountryOption {
  const CountryOption({required this.code, required this.nameEn, required this.nameAr, required this.dialCode, required this.educationSystem});

  final String code;
  final String nameEn;
  final String nameAr;
  final String dialCode;
  final String educationSystem;
}

class StageOption {
  const StageOption({required this.code, required this.nameEn, required this.nameAr, required this.minLevel, required this.maxLevel});

  final String code;
  final String nameEn;
  final String nameAr;
  final int minLevel;
  final int maxLevel;
}

const countryOptions = <CountryOption>[
  CountryOption(code: 'EG', nameEn: 'Egypt', nameAr: 'مصر', dialCode: '+20', educationSystem: 'egypt'),
  CountryOption(code: 'SA', nameEn: 'Saudi Arabia', nameAr: 'السعودية', dialCode: '+966', educationSystem: 'saudi'),
  CountryOption(code: 'AE', nameEn: 'United Arab Emirates', nameAr: 'الإمارات', dialCode: '+971', educationSystem: 'uae'),
  CountryOption(code: 'KW', nameEn: 'Kuwait', nameAr: 'الكويت', dialCode: '+965', educationSystem: 'general_arab'),
  CountryOption(code: 'QA', nameEn: 'Qatar', nameAr: 'قطر', dialCode: '+974', educationSystem: 'general_arab'),
  CountryOption(code: 'BH', nameEn: 'Bahrain', nameAr: 'البحرين', dialCode: '+973', educationSystem: 'general_arab'),
  CountryOption(code: 'OM', nameEn: 'Oman', nameAr: 'عمان', dialCode: '+968', educationSystem: 'general_arab'),
  CountryOption(code: 'JO', nameEn: 'Jordan', nameAr: 'الأردن', dialCode: '+962', educationSystem: 'general_arab'),
  CountryOption(code: 'LB', nameEn: 'Lebanon', nameAr: 'لبنان', dialCode: '+961', educationSystem: 'general_arab'),
  CountryOption(code: 'IQ', nameEn: 'Iraq', nameAr: 'العراق', dialCode: '+964', educationSystem: 'general_arab'),
  CountryOption(code: 'PS', nameEn: 'Palestine', nameAr: 'فلسطين', dialCode: '+970', educationSystem: 'general_arab'),
  CountryOption(code: 'MA', nameEn: 'Morocco', nameAr: 'المغرب', dialCode: '+212', educationSystem: 'general_arab'),
  CountryOption(code: 'DZ', nameEn: 'Algeria', nameAr: 'الجزائر', dialCode: '+213', educationSystem: 'general_arab'),
  CountryOption(code: 'TN', nameEn: 'Tunisia', nameAr: 'تونس', dialCode: '+216', educationSystem: 'general_arab'),
  CountryOption(code: 'LY', nameEn: 'Libya', nameAr: 'ليبيا', dialCode: '+218', educationSystem: 'general_arab'),
  CountryOption(code: 'SD', nameEn: 'Sudan', nameAr: 'السودان', dialCode: '+249', educationSystem: 'general_arab'),
  CountryOption(code: 'YE', nameEn: 'Yemen', nameAr: 'اليمن', dialCode: '+967', educationSystem: 'general_arab'),
];

const Map<String, List<StageOption>> stageOptionsBySystem = {
  'egypt': [
    StageOption(code: 'primary', nameEn: 'Primary', nameAr: 'المرحلة الابتدائية', minLevel: 1, maxLevel: 6),
    StageOption(code: 'prep', nameEn: 'Preparatory', nameAr: 'المرحلة الإعدادية', minLevel: 1, maxLevel: 3),
    StageOption(code: 'secondary', nameEn: 'Secondary', nameAr: 'المرحلة الثانوية', minLevel: 1, maxLevel: 3),
  ],
  'saudi': [
    StageOption(code: 'primary', nameEn: 'Primary', nameAr: 'المرحلة الابتدائية', minLevel: 1, maxLevel: 6),
    StageOption(code: 'intermediate', nameEn: 'Intermediate', nameAr: 'المرحلة المتوسطة', minLevel: 1, maxLevel: 3),
    StageOption(code: 'secondary', nameEn: 'Secondary', nameAr: 'المرحلة الثانوية', minLevel: 1, maxLevel: 3),
  ],
  'uae': [
    StageOption(code: 'cycle1', nameEn: 'Cycle 1', nameAr: 'الحلقة الأولى', minLevel: 1, maxLevel: 4),
    StageOption(code: 'cycle2', nameEn: 'Cycle 2', nameAr: 'الحلقة الثانية', minLevel: 5, maxLevel: 8),
    StageOption(code: 'cycle3', nameEn: 'Cycle 3', nameAr: 'الحلقة الثالثة', minLevel: 9, maxLevel: 12),
  ],
  'general_arab': [
    StageOption(code: 'primary', nameEn: 'Primary', nameAr: 'المرحلة الابتدائية', minLevel: 1, maxLevel: 6),
    StageOption(code: 'middle', nameEn: 'Middle', nameAr: 'المرحلة المتوسطة/الإعدادية', minLevel: 7, maxLevel: 9),
    StageOption(code: 'secondary', nameEn: 'Secondary', nameAr: 'المرحلة الثانوية', minLevel: 10, maxLevel: 12),
  ],
};

CountryOption countryByCode(String code) => countryOptions.firstWhere(
      (country) => country.code == code,
      orElse: () => countryOptions[0],
    );

String educationSystemForCountry(String code) => countryByCode(code).educationSystem;

List<StageOption> stagesForCountry(String countryCode) => stageOptionsBySystem[educationSystemForCountry(countryCode)] ?? stageOptionsBySystem['general_arab']!;

StageOption stageByCode(String code, {String countryCode = 'EG'}) => stagesForCountry(countryCode).firstWhere(
      (stage) => stage.code == code,
      orElse: () => stagesForCountry(countryCode)[0],
    );

String stageLabel(String code, String lang, {String countryCode = 'EG'}) {
  final stage = stageByCode(code, countryCode: countryCode);
  return lang == 'ar' ? stage.nameAr : stage.nameEn;
}

String gradeLabel(String stageCode, int level, String lang, {String countryCode = 'EG'}) {
  final stage = stageByCode(stageCode, countryCode: countryCode);
  final safeLevel = level.clamp(stage.minLevel, stage.maxLevel).toInt();
  if (lang == 'en') return '${stage.nameEn} Grade $safeLevel';
  const ordinals = ['الأول', 'الثاني', 'الثالث', 'الرابع', 'الخامس', 'السادس', 'السابع', 'الثامن', 'التاسع', 'العاشر', 'الحادي عشر', 'الثاني عشر'];
  return 'الصف ${ordinals[safeLevel - 1]}';
}

List<int> levelsForStage(String stageCode, {String countryCode = 'EG'}) {
  final stage = stageByCode(stageCode, countryCode: countryCode);
  return List<int>.generate(stage.maxLevel - stage.minLevel + 1, (i) => stage.minLevel + i);
}

// Backward-compatible list used by older screens.
const stageOptions = <StageOption>[
  StageOption(code: 'primary', nameEn: 'Primary', nameAr: 'المرحلة الابتدائية', minLevel: 1, maxLevel: 6),
  StageOption(code: 'prep', nameEn: 'Preparatory', nameAr: 'المرحلة الإعدادية', minLevel: 1, maxLevel: 3),
  StageOption(code: 'secondary', nameEn: 'Secondary', nameAr: 'المرحلة الثانوية', minLevel: 1, maxLevel: 3),
];
