import 'dart:convert';
import 'package:flutter_forms_test/core/env.dart';
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

  Future<FormResult> createSurvey(SurveyTemplate template) async {
    final base = Uri.parse(Env.gasWebAppUrl);

    final payload = jsonEncode({
      'secret': Env.gasSecret,
      'template': template.toJson(),
    });

    // 1) 우선 POST
    final resp = await _client.post(
      base,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: payload,
    );

    // 1-1) 성공(200 + JSON)
    if (_isJson(resp)) {
      return _parse(resp.body);
    }

    // 1-2) 302/301 → Location 따라가기
    if (resp.statusCode == 302 || resp.statusCode == 301) {
      final loc = resp.headers['location'];
      if (loc == null) {
        throw Exception('GAS 302인데 Location 없음');
      }

      // Location에 template/secret이 누락될 수 있어 → 원래 쿼리 파라미터를 합쳐서 재요청
      final redirected = Uri.parse(loc);
      final merged = redirected.replace(
        queryParameters: {
          // 원래 Location 쿼리 보존
          ...redirected.queryParameters,
          // 누락 시 보강
          'secret': redirected.queryParameters['secret'] ?? Env.gasSecret,
          'template': redirected.queryParameters['template'] ??
              jsonEncode(template.toJson()),
        },
      );

      final r2 = await _client.get(
        merged,
        headers: {'Accept': 'application/json'},
      );

      if (_isJson(r2)) {
        return _parse(r2.body);
      }

      // 디버깅에 도움되도록 헤더/앞부분 출력
      throw Exception(
          'GAS GET 폴백 실패: ${r2.statusCode}\nheaders: ${r2.headers}\n'
              '${r2.body.substring(0, r2.body.length > 400 ? 400 : r2.body.length)}');
    }

    // 1-3) 그 외 에러
    throw Exception(
        'GAS 호출 실패: ${resp.statusCode}\nheaders: ${resp.headers}\n'
            '${resp.body.substring(0, resp.body.length > 400 ? 400 : resp.body.length)}');
  }

  bool _isJson(http.Response r) {
    final ct = (r.headers['content-type'] ?? '').toLowerCase();
    return r.statusCode == 200 && ct.contains('application/json');
  }

  FormResult _parse(String body) {
    final json = jsonDecode(body);
    if (json is Map && json['error'] != null) {
      throw Exception('GAS 에러: ${json['error']}');
    }
    final m = (json as Map).cast<String, dynamic>();
    return FormResult(
      formId: m['formId'] as String,
      liveUrl: m['liveUrl'] as String?,
      editUrl: m['editUrl'] as String?,
      sheetUrl: m['sheetUrl'] as String?,
      sourceLabel: 'GAS',
    );
  }
}
