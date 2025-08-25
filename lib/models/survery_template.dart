class SurveyTemplate {
  final String title;
  final String? description;
  final bool collectEmail;
  final bool shuffleQuestions;
  final String? confirmationMessage;
  final String? destinationSpreadsheetId; // 기존 스프레드시트에 연결하려면 지정
  final List<SurveyItem> items;

  SurveyTemplate({
    required this.title,
    this.description,
    this.collectEmail = true,
    this.shuffleQuestions = false,
    this.confirmationMessage,
    this.destinationSpreadsheetId,
    this.items = const [],
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    if (description != null) 'description': description,
    'collectEmail': collectEmail,
    'shuffleQuestions': shuffleQuestions,
    if (confirmationMessage != null) 'confirmationMessage': confirmationMessage,
    if (destinationSpreadsheetId != null)
      'destinationSpreadsheetId': destinationSpreadsheetId,
    'items': items.map((e) => e.toJson()).toList(),
  };

  static SurveyTemplate sample() {
    return SurveyTemplate(
      title: '고객만족도 설문(Flutter)',
      description: '약 2~3분 소요됩니다.',
      collectEmail: true,
      shuffleQuestions: false,
      items: [
        SurveyItem.mc(
          title: '서비스 만족도',
          required: true,
          options: ['매우만족', '만족', '보통', '불만족'],
        ),
        SurveyItem.text(
          title: '이메일을 남겨주세요',
          required: true,
          validation: TextValidation.email,
        ),
        SurveyItem.checkbox(
          title: '주로 사용하는 기능(복수선택)',
          required: true,
          options: ['검색', '통계', '내보내기'],
        ),
        SurveyItem.scale(
          title: '재이용 의향(1~5)',
          boundsMin: 1,
          boundsMax: 5,
          lowLabel: '낮음',
          highLabel: '높음',
          required: true,
        ),
        SurveyItem.paragraph(title: '개선이 필요한 점을 자유롭게 적어주세요'),
        SurveyItem.date(title: '최근 방문일'),
      ],
    );
  }
}

enum ItemType { mc, checkbox, text, paragraph, scale, date, time }
enum TextValidation { none, email, number }

class SurveyItem {
  final ItemType type;
  final String title;
  final bool required;
  final List<String> options; // mc/checkbox
  final TextValidation validation; // text
  final int? boundsMin; // scale
  final int? boundsMax; // scale
  final String? lowLabel; // scale
  final String? highLabel; // scale

  SurveyItem._({
    required this.type,
    required this.title,
    required this.required,
    this.options = const [],
    this.validation = TextValidation.none,
    this.boundsMin,
    this.boundsMax,
    this.lowLabel,
    this.highLabel,
  });

  factory SurveyItem.mc({
    required String title,
    required bool required,
    required List<String> options,
  }) =>
      SurveyItem._(
        type: ItemType.mc,
        title: title,
        required: required,
        options: options,
      );

  factory SurveyItem.checkbox({
    required String title,
    required bool required,
    required List<String> options,
  }) =>
      SurveyItem._(
        type: ItemType.checkbox,
        title: title,
        required: required,
        options: options,
      );

  factory SurveyItem.text({
    required String title,
    bool required = false,
    TextValidation validation = TextValidation.none,
  }) =>
      SurveyItem._(
        type: ItemType.text,
        title: title,
        required: required,
        validation: validation,
      );

  factory SurveyItem.paragraph({required String title, bool required = false}) =>
      SurveyItem._(type: ItemType.paragraph, title: title, required: required);

  factory SurveyItem.scale({
    required String title,
    bool required = false,
    required int boundsMin,
    required int boundsMax,
    String? lowLabel,
    String? highLabel,
  }) =>
      SurveyItem._(
        type: ItemType.scale,
        title: title,
        required: required,
        boundsMin: boundsMin,
        boundsMax: boundsMax,
        lowLabel: lowLabel,
        highLabel: highLabel,
      );

  factory SurveyItem.date({required String title, bool required = false}) =>
      SurveyItem._(type: ItemType.date, title: title, required: required);

  factory SurveyItem.time({required String title, bool required = false}) =>
      SurveyItem._(type: ItemType.time, title: title, required: required);

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'title': title,
      'required': required,
    };
    switch (type) {
      case ItemType.mc:
        map['type'] = 'MC';
        map['options'] = options;
        break;
      case ItemType.checkbox:
        map['type'] = 'CHECKBOX';
        map['options'] = options;
        break;
      case ItemType.text:
        map['type'] = 'TEXT';
        if (validation == TextValidation.email) map['validation'] = 'EMAIL';
        if (validation == TextValidation.number) map['validation'] = 'NUMBER';
        break;
      case ItemType.paragraph:
        map['type'] = 'PARAGRAPH';
        break;
      case ItemType.scale:
        map['type'] = 'SCALE';
        map['bounds'] = [boundsMin, boundsMax];
        if (lowLabel != null && highLabel != null) {
          map['labels'] = [lowLabel, highLabel];
        }
        break;
      case ItemType.date:
        map['type'] = 'DATE';
        break;
      case ItemType.time:
        map['type'] = 'TIME';
        break;
    }
    return map;
  }
}
