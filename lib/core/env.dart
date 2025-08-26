// 환경값 모음. 당장 상수로 시작하고, 나중에 flutter_dotenv로 바꿔도 됨.
class Env {
  /// iOS/macOS용 Google OAuth "iOS" Client ID
  static const String iosClientId =
      '498960306752-g253lj8mttamt9amkp8jullq70264rhg.apps.googleusercontent.com';

  /// Forms API 스코프
  static const List<String> scopes = <String>[
    'https://www.googleapis.com/auth/forms.body',
    'https://www.googleapis.com/auth/forms.responses.readonly',
  ];

  /// GAS Web App /exec URL (A안)
  static const String gasWebAppUrl =
      'https://script.google.com/macros/s/AKfycbxGjLzniNIeeWBIVHYbpIcAdJSDXASR1PRZVvSBEaPotJdxnW_-YNGbD48B0paWG-w6/exec';

  /// GAS 호출 시 간단 shared secret (선택)
  static const String gasSecret = 'MY_SECRET';
}
