import 'package:googleapis/forms/v1.dart' as forms;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import '../models/form_result.dart';
import '../core/retry.dart';

class FormsService {
  final auth.AuthClient client;
  FormsService(this.client);

  Future<FormResult> createBasicForm() async {
    final api = forms.FormsApi(client);

    // 1) 빈 폼 생성
    final created = await retry(() => api.forms.create(
      forms.Form(info: forms.Info(title: '고객만족도 설문 (사용자 소유)')),
    ));
    final formId = created.formId!;

    // 2) 문항 추가
    await retry(() => api.forms.batchUpdate(
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
                  question: forms.Question(
                    textQuestion: forms.TextQuestion(paragraph: false),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      formId,
    ));

    // 3) 링크 확보
    final got = await retry(() => api.forms.get(formId));
    return FormResult(
      formId: formId,
      liveUrl: got.responderUri, // 응답 URL
      editUrl: null,             // Forms API는 편집 URL을 기본 미반환
      sheetUrl: null,
      sourceLabel: 'Forms API',
    );
  }

  Future<List<forms.FormResponse>> listResponses(String formId) async {
    final api = forms.FormsApi(client);

    final all = <forms.FormResponse>[];
    String? token;
    do {
      final out = await retry(() => api.forms.responses
          .list(formId, pageSize: 50, pageToken: token));
      all.addAll(out.responses ?? const []);
      token = out.nextPageToken;
    } while (token != null && token.isNotEmpty);

    return all;
  }
}
