class SurveyTemplate {
  final String title;
  final String? description;
  final bool collectEmail;
  final bool shuffleQuestions;
  final bool? showProgress;
  final bool? isQuiz;
  final String? confirmationMessage;

  final List<SurveyItem> items;

  SurveyTemplate({
    required this.title,
    this.description,
    this.collectEmail = false,
    this.shuffleQuestions = false,
    this.showProgress,
    this.isQuiz,
    this.confirmationMessage,
    required this.items,
  });

  factory SurveyTemplate.sample() => SurveyTemplate(
    title: '고객만족도 설문(Flutter)',
    description: '약 2~3분 소요됩니다.',
    collectEmail: true,
    shuffleQuestions: false,
    confirmationMessage: '응답 감사합니다!',
    items: [
      SurveyItem.mc(
        title: '서비스 만족도',
        required: true,
        options: ['매우만족', '만족', '보통', '불만족'],
      ),
      SurveyItem.text(
        title: '이메일을 남겨주세요',
        required: true,
        validation: 'EMAIL',
      ),
      SurveyItem.checkbox(
        title: '주로 사용하는 기능(복수선택)',
        required: true,
        options: ['검색', '통계', '내보내기'],
      ),
      SurveyItem.scale(
        title: '재이용 의향(1~5)',
        required: true,
        bounds: const [1, 5],
        labels: const ['낮음', '높음'],
      ),
      SurveyItem.paragraph(title: '자유 의견', required: false),
      SurveyItem.date(title: '최근 방문일', required: false),
    ],
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'collectEmail': collectEmail,
    'shuffleQuestions': shuffleQuestions,
    if (showProgress != null) 'showProgress': showProgress,
    if (isQuiz != null) 'isQuiz': isQuiz,
    if (confirmationMessage != null)
      'confirmationMessage': confirmationMessage,
    'items': items.map((e) => e.toJson()).toList(),
  };
}

class SurveyItem {
  final String type; // MC, CHECKBOX, DROPDOWN, TEXT, PARAGRAPH, SCALE, DATE, TIME, DATETIME, SECTION
  final String title;
  final bool required;
  final List<String>? options;
  final bool? shuffle;
  final List<int>? bounds;
  final List<String>? labels;
  final String? validation;

  SurveyItem({
    required this.type,
    required this.title,
    required this.required,
    this.options,
    this.shuffle,
    this.bounds,
    this.labels,
    this.validation,
  });

  factory SurveyItem.mc({
    required String title,
    required bool required,
    required List<String> options,
    bool? shuffle,
  }) =>
      SurveyItem(
        type: 'MC',
        title: title,
        required: required,
        options: options,
        shuffle: shuffle,
      );

  factory SurveyItem.checkbox({
    required String title,
    required bool required,
    required List<String> options,
    bool? shuffle,
  }) =>
      SurveyItem(
        type: 'CHECKBOX',
        title: title,
        required: required,
        options: options,
        shuffle: shuffle,
      );

  factory SurveyItem.dropdown({
    required String title,
    required bool required,
    required List<String> options,
  }) =>
      SurveyItem(type: 'DROPDOWN', title: title, required: required, options: options);

  factory SurveyItem.text({
    required String title,
    required bool required,
    String? validation, // EMAIL | NUMBER | URL
  }) =>
      SurveyItem(type: 'TEXT', title: title, required: required, validation: validation);

  factory SurveyItem.paragraph({
    required String title,
    required bool required,
  }) =>
      SurveyItem(type: 'PARAGRAPH', title: title, required: required);

  factory SurveyItem.scale({
    required String title,
    required bool required,
    required List<int> bounds, // [min, max]
    List<String>? labels, // [left, right]
  }) =>
      SurveyItem(
        type: 'SCALE',
        title: title,
        required: required,
        bounds: bounds,
        labels: labels,
      );

  factory SurveyItem.date({required String title, required bool required}) =>
      SurveyItem(type: 'DATE', title: title, required: required);

  Map<String, dynamic> toJson() => {
    'type': type,
    'title': title,
    'required': required,
    if (options != null) 'options': options,
    if (shuffle != null) 'shuffle': shuffle,
    if (bounds != null) 'bounds': bounds,
    if (labels != null) 'labels': labels,
    if (validation != null) 'validation': validation,
  };
}
