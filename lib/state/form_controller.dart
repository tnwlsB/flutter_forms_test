
import 'package:flutter/foundation.dart';
import 'package:flutter_forms_test/main_bk.dart';
import 'package:flutter_forms_test/models/survey_template.dart';
import 'package:flutter_forms_test/services/auth_service.dart';
import 'package:flutter_forms_test/services/form_service.dart';
import 'package:flutter_forms_test/services/gas_service.dart';



class FormController extends ChangeNotifier {
  final GasService gas;
  final AuthService auth;
  FormController({required this.gas, required this.auth});

  FormResult? gasResult;
  FormResult? formsResult;
  String status = '대기 중…';
  bool loading = false;

  Future<void> createWithGAS() async {
    _busy('A안(GAS) 생성 중…');
    try {
      gasResult = (await gas.createSurvey(SurveyTemplate.sample())) as FormResult?;
      _ok('성공 ✅ A안 생성 완료');
    } catch (e) { _fail(e); }
  }

  Future<void> createWithForms() async {
    _busy('B안(Forms API) 생성 중…');
    try {
      final client = await auth.client();
      formsResult = (await FormsService(client).createBasicForm()) as FormResult?;
      _ok('성공 ✅ B안 생성 완료');
    } catch (e) { _fail(e); }
  }

  Future<String> fetchResponses(String formId) async {
    _busy('응답 조회 중…');
    try {
      final client = await auth.client();
      final list = await FormsService(client).listResponses(formId);
      final lines = <String>['총 ${list.length}개의 응답'];
      for (final r in list) {
        lines.add('- ${r.responseId ?? "(id없음)"} @ ${r.createTime ?? ""}');
        r.answers?.forEach((qid, ans) {
          final texts = ans.textAnswers?.answers?.map((a)=>a.value ?? '').where((s)=>s.isNotEmpty).toList() ?? [];
          if (texts.isNotEmpty) lines.add('   · $qid: ${texts.join(", ")}');
        });
      }
      _ok('조회 성공 ✅\n${lines.join("\n")}');
      return lines.join('\n');
    } catch (e) { _fail(e); return '오류: $e'; }
  }

  void _busy(String s){ loading = true; status = s; notifyListeners(); }
  void _ok(String s){ loading = false; status = s; notifyListeners(); }
  void _fail(Object e){ loading = false; status = '실패 ❌\n$e'; notifyListeners(); }
}
