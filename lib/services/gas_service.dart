import 'dart:convert';
import 'package:flutter_forms_test/models/survey_template.dart';
import 'package:http/http.dart' as http;
import '../models/form_result.dart';

class GasService {
  final String webAppUrl;
  final String secret;
  final http.Client _client;
  GasService({
    required this.webAppUrl,
    required this.secret,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<FormResult> createSurvey(SurveyTemplate tpl) async {
    // 서버가 GET 기반으로 동작 중이면 아래처럼:
    final uri = Uri.parse(webAppUrl)
        .replace(queryParameters: {'action': 'create', 'secret': secret});

    final resp = await _client.get(uri);
    if (resp.statusCode != 200 ||
        !(resp.headers['content-type'] ?? '')
            .toLowerCase()
            .contains('application/json')) {
      throw Exception('GAS 실패: ${resp.statusCode}\n${resp.body}');
    }

    final json = (jsonDecode(resp.body) as Map).cast<String, dynamic>();
    if (json['error'] != null) {
      throw Exception('GAS 에러: ${json['error']}');
    }

    return FormResult(
      formId: (json['formId'] ?? '') as String,
      editUrl: json['editUrl'] as String?,
      liveUrl: json['liveUrl'] as String?,
      sheetUrl: json['sheetUrl'] as String?,
      sourceLabel: 'GAS',
    );
  }
}
