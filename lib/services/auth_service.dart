import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _a = FirebaseAuth.instance;
  static int? _resendToken;

  /// Sends the SMS code. On some Android phones the code is read
  /// automatically; the auth-state listener then takes the user forward.
  static Future<void> sendCode({
    required String phone,
    required void Function(String verificationId) onCodeSent,
    required void Function(String message) onError,
  }) async {
    await _a.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      forceResendingToken: _resendToken,
      verificationCompleted: (cred) async {
        try {
          await _a.signInWithCredential(cred);
        } catch (e) {
          onError(e.toString());
        }
      },
      verificationFailed: (e) => onError(e.message ?? e.code),
      codeSent: (vid, token) {
        _resendToken = token;
        onCodeSent(vid);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  static Future<void> verify(String verificationId, String code) async {
    final cred = PhoneAuthProvider.credential(
        verificationId: verificationId, smsCode: code);
    await _a.signInWithCredential(cred);
  }

  static Future<void> signOut() => _a.signOut();
}
