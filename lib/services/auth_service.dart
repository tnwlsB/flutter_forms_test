import 'dart:io' show Platform;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;

class AuthService {
  final List<String> scopes;
  final String? iosClientId;

  late final GoogleSignIn _gsign;
  GoogleSignInAccount? _user;

  AuthService({required this.scopes, this.iosClientId}) {
    _gsign = GoogleSignIn(
      scopes: scopes,
      clientId: (Platform.isIOS || Platform.isMacOS) ? iosClientId : null,
    );
  }

  Future<GoogleSignInAccount?> signIn() async {
    _user ??= await _gsign.signIn();
    return _user;
  }

  Future<auth.AuthClient> client() async {
    final acc = await signIn();
    if (acc == null) throw Exception('로그인이 취소되었습니다.');
    final headers = await acc.authHeaders;
    final bearer =
        (headers['Authorization'] ?? headers['authorization'])?.split(' ').last;
    if (bearer == null) throw Exception('토큰 획득 실패');
    final creds = auth.AccessCredentials(
      auth.AccessToken('Bearer', bearer,
          DateTime.now().toUtc().add(const Duration(minutes: 50))),
      null,
      scopes,
    );
    return auth.authenticatedClient(http.Client(), creds);
  }

  String? currentEmail() => _gsign.currentUser?.email;
}
