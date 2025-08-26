import 'dart:convert';
import 'package:flutter_forms_test/core/env.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_forms_test/models/survey_template.dart';

class ScriptApi {

  final http.Client _client;
  ScriptApi({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> createSurvey(SurveyTemplate template, {String? secret}) async {
    final uri = Uri.parse(Env.gasWebAppUrl);
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
  }


}
