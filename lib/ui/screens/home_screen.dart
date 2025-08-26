import 'package:flutter/material.dart';
import 'package:flutter_forms_test/core/env.dart';
import 'package:flutter_forms_test/models/survey_template.dart';
import 'package:flutter_forms_test/services/auth_service.dart';
import 'package:flutter_forms_test/services/form_service.dart';
import 'package:flutter_forms_test/services/gas_service.dart';
import 'package:flutter_forms_test/ui/widgets/form_select_sheet.dart';
import 'package:flutter_forms_test/ui/widgets/link_title.dart';

import '../../models/form_result.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // A안
  late final GasService _gas =
  GasService(webAppUrl: Env.gasWebAppUrl, secret: Env.gasSecret);
  FormResult? _gasResult;

  // B안
  late final AuthService _auth =
  AuthService(scopes: Env.scopes, iosClientId: Env.iosClientId);
  FormResult? _formsResult;

  // 상태
  String _status = '대기 중…';
  bool _loading = false;

  void _setStatus(String s) => setState(() => _status = s);

  // A안: GAS로 생성
  Future<void> _createWithGAS() async {
    setState(() {
      _loading = true;
      _gasResult = null;
      _setStatus('A안(GAS) 생성 중…');
    });
    try {
      final tpl = SurveyTemplate.sample();
      _gasResult = await _gas.createSurvey(tpl);
      _setStatus('성공 ✅ (A안 생성 완료)');
    } catch (e) {
      _setStatus('실패 ❌ (A안)\n$e');
    } finally {
      setState(() => _loading = false);
    }
  }

  // B안: Forms API로 사용자 소유 생성
  Future<void> _createWithForms() async {
    setState(() {
      _loading = true;
      _formsResult = null;
      _setStatus('B안(Forms API) 생성 중…');
    });
    try {
      final client = await _auth.client();
      _formsResult = await FormsService(client).createBasicForm();
      _setStatus('성공 ✅ (B안 생성 완료)');
    } catch (e) {
      _setStatus('실패 ❌ (B안)\n$e');
    } finally {
      setState(() => _loading = false);
    }
  }

  // 응답 조회(B안 API 사용 / A/B 선택)
  Future<void> _fetchResponses() async {
    final picked =
    await showFormSelectSheet(context, forms: _formsResult, gas: _gasResult);
    if (picked == null) return;

    setState(() {
      _loading = true;
      _setStatus('응답 조회 중…');
    });
    try {
      final client = await _auth.client();
      final api = FormsService(client);

      final list = await api.listResponses(picked);
      final lines = <String>['총 ${list.length}개의 응답'];
      for (final r in list) {
        lines.add('- ${r.responseId ?? "(id없음)"} @ ${r.createTime ?? ""}');
        r.answers?.forEach((qid, ans) {
          final texts = ans.textAnswers?.answers
              ?.map((a) => a.value ?? '')
              .where((s) => s.isNotEmpty)
              .toList() ??
              const <String>[];
          if (texts.isNotEmpty) {
            lines.add('   · $qid: ${texts.join(", ")}');
          }
        });
      }
      _setStatus('조회 성공 ✅\n${lines.join('\n')}');
    } catch (e) {
      _setStatus('응답 조회 실패 ❌\n$e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _auth.currentEmail() ?? '(미로그인)';
    return Scaffold(
      appBar: AppBar(title: const Text('Google 설문 (GAS & Forms API)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(spacing: 8, runSpacing: 8, children: [
              FilledButton.icon(
                onPressed: _loading ? null : _createWithForms,
                icon: const Icon(Icons.person_add),
                label: const Text('설문 생성(사용자 소유, B안)'),
              ),
              FilledButton.icon(
                onPressed: _loading ? null : _createWithGAS,
                icon: const Icon(Icons.play_arrow),
                label: const Text('샘플 설문 생성(GAS, A안)'),
              ),
              FilledButton.icon(
                onPressed: _loading ? null : _fetchResponses,
                icon: const Icon(Icons.download),
                label: const Text('응답 받기 (폼 선택)'),
              ),
            ]),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('현재 사용자: $email'),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _status,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            const Divider(height: 24),
            if (_formsResult != null) _resultCard('B안 결과(사용자 소유)', _formsResult!),
            if (_gasResult != null) _resultCard('A안 결과(GAS)', _gasResult!),
          ],
        ),
      ),
    );
  }

  Widget _resultCard(String title, FormResult r) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SelectableText('formId: ${r.formId}'),
        LinkTile(label: '응답 URL', url: r.liveUrl),
        LinkTile(label: '편집 URL', url: r.editUrl),
        LinkTile(label: '응답 시트 URL', url: r.sheetUrl),
      ]),
    ),
  );
}
