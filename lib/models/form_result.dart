class FormResult {
  final String formId;
  final String? editUrl;   // GAS(A안)에서만 주로 사용
  final String? liveUrl;   // 응답 URL
  final String? sheetUrl;  // GAS(A안) 응답 시트
  final String sourceLabel; // 'GAS' or 'Forms API'

  const FormResult({
    required this.formId,
    required this.sourceLabel,
    this.editUrl,
    this.liveUrl,
    this.sheetUrl,
  });
}
