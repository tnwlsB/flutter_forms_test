import 'dart:math';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// A안(GAS)
import 'models/survery_template.dart';
import 'services/script_api.dart';

// 공통/Forms API(B안)
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:googleapis/forms/v1.dart' as forms;

/// ====== 공통 상수 ======
const _scopes = <String>[
  'https://www.googleapis.com/auth/forms.body',
  'https://www.googleapis.com/auth/forms.responses.readonly',
];
// iOS/macOS용 OAuth 클라이언트 ID (콘솔의 iOS 유형 클라이언트 ID)
const _clientId = '498960306752-g253lj8mttamt9amkp8jullq70264rhg.apps.googleusercontent.com';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google 설문 생성 (GAS & Forms API)',
      theme: ThemeData(useMaterial3: true),
      home: const HomePage(),
    );
  }
}

/// 결과 모델을 간단히 통일(A/B 공용)
class FormResult {
  final String formId;
  final String? editUrl;
  final String? liveUrl;
  final String? sheetUrl;     // A안에서만 보통 존재
  final String sourceLabel;   // "GAS" or "Forms API"

  const FormResult({
    required this.formId,
    required this.sourceLabel,
    this.editUrl,
    this.liveUrl,
    this.sheetUrl,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// A안(GAS)
  final _gasApi = ScriptApi();
  FormResult? _gasResult;

  /// B안(Forms API)
  final GoogleSignIn _google = GoogleSignIn(
    scopes: _scopes,
    clientId: (Platform.isIOS || Platform.isMacOS) ? _clientId : null,
  );
  GoogleSignInAccount? _user;
  FormResult? _formsResult;

  /// 공통 상태
  String _status = '대기 중…';
  bool _loading = false;

  void _setStatus(String s) => setState(() => _status = s);

  // ===================== 공통: AuthClient =====================
  Future<auth.AuthClient> _getAuthClient() async {
    final account = _user ?? await _google.signIn();
    if (account == null) throw Exception('로그인 취소됨');

    // google_sign_in 의 헤더에서 Bearer 추출 → googleapis_auth 래핑
    final headers = await account.authHeaders;
    final bearer = (headers['Authorization'] ?? headers['authorization'])?.split(' ').last;
    if (bearer == null) throw Exception('토큰 획득 실패');

    final creds = auth.AccessCredentials(
      auth.AccessToken('Bearer', bearer, DateTime.now().toUtc().add(const Duration(minutes: 50))),
      null,
      _scopes,
    );
    return auth.authenticatedClient(http.Client(), creds);
  }

  // ===================== A안: GAS로 샘플 설문 생성 =====================
  Future<void> _createFormWithGAS() async {
    setState(() {
      _loading = true;
      _gasResult = null;
      _setStatus('(GAS) 설문 생성 요청 중…');
    });
    try {
      final tpl = SurveyTemplate.sample();
      final res = await _gasApi.createSurvey(tpl, secret: 'MY_SECRET');

      // GAS 반환 키와 공용 모델 매핑
      final r = FormResult(
        formId: (res['formId'] ?? '') as String,
        editUrl: res['editUrl'] as String?,
        liveUrl: res['liveUrl'] as String?,
        sheetUrl: res['sheetUrl'] as String?,
        sourceLabel: 'GAS',
      );

      setState(() {
        _gasResult = r;
        _setStatus('성공 ✅ (GAS 폼 생성 완료)');
      });
    } catch (e) {
      _setStatus('실패 ❌ (GAS 폼)\n$e');
    } finally {
      setState(() => _loading = false);
    }
  }

  // ===================== B안: Forms API로 사용자 소유 설문 생성 =====================
  Future<void> _createFormViaFormsApi() async {
    setState(() {
      _loading = true;
      _formsResult = null;
      _setStatus('B안(Forms API) 설문 생성 중…');
    });
    try {
      _user ??= await _google.signIn();
      final client = await _getAuthClient();
      final api = forms.FormsApi(client);

      // 1) 빈 폼 생성
      final created = await api.forms.create(
        forms.Form(info: forms.Info(title: '고객만족도 설문 (사용자 소유)')),
      );
      final formId = created.formId!;

      // 2) 문항 추가 (batchUpdate)
      await api.forms.batchUpdate(
        forms.BatchUpdateFormRequest(
          includeFormInResponse: true,
          requests: [
            forms.Request(
              createItem: forms.CreateItemRequest(
                location: forms.Location(index: 0),
                item: forms.Item(
                  title: '서비스 만족도는?',
                  questionItem: forms.QuestionItem(
                    question: forms.Question(
                      required: true,
                      choiceQuestion: forms.ChoiceQuestion(
                        type: 'RADIO',
                        options: [
                          forms.Option(value: '매우만족'),
                          forms.Option(value: '만족'),
                          forms.Option(value: '보통'),
                          forms.Option(value: '불만족'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            forms.Request(
              createItem: forms.CreateItemRequest(
                location: forms.Location(index: 1),
                item: forms.Item(
                  title: '개선이 필요한 점(단답형)',
                  questionItem: forms.QuestionItem(
                    question: forms.Question(textQuestion: forms.TextQuestion(paragraph: false)),
                  ),
                ),
              ),
            ),
          ],
        ),
        formId,
      );

      // 3) 링크 확보
      final got = await api.forms.get(formId);
      final responder = got.responderUri; // 응답 URL

      setState(() {
        _formsResult = FormResult(
          formId: formId,
          editUrl: '',
          liveUrl: responder,
          sheetUrl: null,
          sourceLabel: 'Forms API',
        );
        _setStatus('성공 ✅ (사용자 소유 폼 생성 완료)');
      });
    } catch (e) {
      _setStatus('실패 ❌ (사용자 소유 폼)\n$e');
    } finally {
      setState(() => _loading = false);
    }
  }

  // ===================== B안: Forms API로 응답 조회 =====================
  Future<void> _fetchResponsesViaFormsApi({required String formId}) async {
    setState(() {
      _loading = true;
      _setStatus('응답 조회 중…');
    });

    try {
      _user ??= await _google.signIn();
      final client = await _getAuthClient();
      final api = forms.FormsApi(client);

      final res = await api.forms.responses.list(formId, pageSize: 50);
      final responses = res.responses ?? <forms.FormResponse>[];

      final lines = <String>['총 ${responses.length}개의 응답'];
      for (final r in responses) {
        lines.add('- ${r.responseId ?? "(id없음)"} @ ${r.createTime ?? ""}');
        // 답변 내용 요약(선택)
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

  // ===================== 공통 UI 헬퍼 =====================
  Widget _linkTile(String label, String? url) {
    if (url == null || url.isEmpty) return const SizedBox.shrink();
    return ListTile(
      dense: true,
      title: Text(label),
      subtitle: Text(url, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.open_in_new),
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
    );
  }

  Widget _resultCard(String title, FormResult? r) {
    if (r == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$title (${r.sourceLabel})', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SelectableText('formId: ${r.formId}'),
            const SizedBox(height: 8),
            _linkTile('편집 URL', r.editUrl),
            _linkTile('응답 URL', r.liveUrl),
            _linkTile('응답 시트 URL', r.sheetUrl),
          ],
        ),
      ),
    );
  }

  Future<String?> _pickFormForResponses() async {
    // 선택 후보 구성
    final candidates = <Map<String, String>>[];

    if (_formsResult?.formId != null && _formsResult!.formId.isNotEmpty) {
      candidates.add({
        'label': '사용자 소유',
        'formId': _formsResult!.formId,
        'url': _formsResult!.liveUrl ?? '',
      });
    }
    if (_gasResult?.formId != null && _gasResult!.formId.isNotEmpty) {
      candidates.add({
        'label': 'GAS 생성',
        'formId': _gasResult!.formId,
        'url': _gasResult!.liveUrl ?? '',
      });
    }

    if (candidates.isEmpty) {
      _setStatus('선택할 폼이 없습니다. 먼저 폼을 생성하세요.');
      return null;
    }

    return showModalBottomSheet<String>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text('응답 조회할 폼 선택'),
                subtitle: Text('GAS / 사용자 소유 중 선택'),
              ),
              for (final c in candidates)
                ListTile(
                  leading: const Icon(Icons.insert_drive_file),
                  title: Text(c['label']!),
                  subtitle: Text(
                    c['url']!.isEmpty ? 'formId: ${c['formId']}' : c['url']!,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => Navigator.of(ctx).pop(c['formId']),
                ),
            ],
          ),
        );
      },
    );
  }


  // ===================== 화면 =====================
  @override
  Widget build(BuildContext context) {
    final email = _user?.email ?? '(미로그인)';
    return Scaffold(
      appBar: AppBar(title: const Text('Google 설문 생성 (GAS & Forms API)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(spacing: 8, runSpacing: 8, children: [
              FilledButton.icon(
                onPressed: _loading ? null : () async {
                  try {
                    _user = await _google.signIn();
                    _setStatus('로그인 성공: $email');
                  } catch (e) {
                    _setStatus('로그인 실패: $e');
                  }
                },
                icon: const Icon(Icons.login),
                label: const Text('Google 로그인'),
              ),
              FilledButton.icon(
                onPressed: _loading ? null : _createFormViaFormsApi,
                icon: const Icon(Icons.person_add),
                label: const Text('설문 생성(사용자 소유)'),
              ),
              FilledButton.icon(
                onPressed: _loading ? null : _createFormWithGAS,
                icon: const Icon(Icons.play_arrow),
                label: const Text('샘플 설문 생성(GAS)'),
              ),
              FilledButton.icon(
                onPressed: _loading ? null : () async {
                  final pickedFormId = await _pickFormForResponses();
                  if (pickedFormId != null ){
                    await _fetchResponsesViaFormsApi(formId : pickedFormId);
                  }
                },
                icon: const Icon(Icons.download),
                label: const Text('응답 받기 (Forms API)'),
              ),
            ]),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '상태: $_status\n현재 사용자: $email',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            const Divider(height: 24),
            Expanded(
              child: ListView(
                children: [
                  _resultCard('(사용자 소유)', _formsResult),
                  _resultCard('(GAS)', _gasResult),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
