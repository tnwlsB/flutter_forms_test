import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_forms_test/models/survery_template.dart';

/// Apps Script Web App URL (배포 후 발급된 URL로 교체)
const String GAS_WEBAPP_URL = 'https://script.google.com/macros/s/AKfycbxGjLzniNIeeWBIVHYbpIcAdJSDXASR1PRZVvSBEaPotJdxnW_-YNGbD48B0paWG-w6/exec';

class ScriptApi {

  final http.Client _client;
  ScriptApi({http.Client? client}) : _client = client ?? http.Client();
  /*
  /// 설문 생성 요청
  /// 반환: formId, editUrl, liveUrl, sheetUrl
  Future<Map<String, dynamic>> createSurvey(SurveyTemplate template,
      {String? secret}) async {
    final body = jsonEncode(template.toJson()..['secret'] = 'MY_SECRET');

    final resp = await _client.(
      Uri.parse(GAS_WEBAPP_URL),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'secret': 'MY_SECRET'}),
    );
    */
  Future<Map<String, dynamic>> createSurvey(SurveyTemplate template, {String? secret}) async {
    final uri = Uri.parse(GAS_WEBAPP_URL);
    final resp = await _client.get(uri);

    if (resp.statusCode != 200) {
      throw Exception('호출 실패: ${resp.statusCode}\n${resp.body}');
    }
    final ct = (resp.headers['content-type'] ?? '').toLowerCase();
    if (!ct.contains('application/json')) {
      throw Exception('JSON 아님 (${resp.statusCode})\n${resp.body.substring(0, 400)}');
    }
    final json = jsonDecode(resp.body);
    return (json as Map).cast<String, dynamic>();

/*
    final uri = Uri.parse(GAS_WEBAPP_URL);
    final bodyMap = template.toJson()..['secret'] = secret ?? 'MY_SECRET';
    final bodyJson = jsonEncode(bodyMap);

    print(bodyJson);

    final req = http.Request('GET', uri)
      ..headers['Content-Type'] = 'application/json'
      ..followRedirects = true
      ..maxRedirects = 5
      ..body = bodyJson;

    var resp = await _client.send(req).then(http.Response.fromStream);

    print(resp.statusCode);
    print(resp.headers);

    if (resp.isRedirect ||
        resp.statusCode == 301 ||
        resp.statusCode == 302 ||
        resp.statusCode == 303 ||
        resp.statusCode == 307 ||
        resp.statusCode == 308) {
      final loc = resp.headers['location'];
      if (loc != null && loc.isNotEmpty) {
        final getUri = Uri.parse(loc).replace(queryParameters: {
          ...Uri.parse(loc).queryParameters,
          'secret': secret,
          'action': 'create',
        });
        resp = await _client.get(getUri);
      }
    }


    if (resp.statusCode != 200) {
      throw Exception(
          '스크립트 호출 실패: ${resp.statusCode} ${resp.reasonPhrase}\n${resp.body}');
    }

    final ct = resp.headers['content-type'] ?? '';
    if (!ct.toLowerCase().contains('application/json')) {
      throw Exception('JSON 아님 (${resp.statusCode})\n${resp.body.substring(0, 400)}');
    }

    final json = jsonDecode(resp.body);
    if (json is Map<String, dynamic> && json['error'] != null) {
      throw Exception('스크립트 에러: ${json['error']}');
    }
    return (json as Map).cast<String, dynamic>();

   */
  }


}
