class StageOption {
  const StageOption({required this.code, required this.nameEn, required this.nameAr, required this.maxLevel});

  final String code;
  final String nameEn;
  final String nameAr;
  final int maxLevel;
}

// Primary is intentionally hidden/disabled for now.
const stageOptions = <StageOption>[
  StageOption(code: 'prep', nameEn: 'Preparatory', nameAr: 'المرحلة الاعدادية', maxLevel: 3),
  StageOption(code: 'secondary', nameEn: 'Secondary', nameAr: 'المرحلة الثانوية', maxLevel: 3),
];

StageOption stageByCode(String code) => stageOptions.firstWhere(
      (stage) => stage.code == code,
      orElse: () => stageOptions[0],
    );

String stageLabel(String code, String lang) {
  final stage = stageByCode(code);
  return lang == 'ar' ? stage.nameAr : stage.nameEn;
}

String gradeLabel(String stageCode, int level, String lang) {
  final stage = stageByCode(stageCode);
  final safeLevel = level.clamp(1, stage.maxLevel).toInt();
  if (lang == 'en') {
    return '${stage.nameEn} Grade $safeLevel';
  }
  const ordinals = ['الاول', 'الثاني', 'الثالث'];
  final suffix = stageCode == 'secondary' ? 'الثانوي' : 'الاعدادي';
  return 'الصف ${ordinals[safeLevel - 1]} $suffix';
}

List<int> levelsForStage(String stageCode) {
  final max = stageByCode(stageCode).maxLevel;
  return List<int>.generate(max, (i) => i + 1);
}
