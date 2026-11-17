import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../l10n/tx.dart';

/// Kullanıcıya gösterilebilecek, yumuşak dilli hata. Metin Türkçe kaynaktır;
/// [message] gösterim anında kullanıcının diline çevrilir.
class AuthFailure implements Exception {
  const AuthFailure(this.messageTr, [this.args = const {}]);
  final String messageTr;
  final Map<String, Object?> args;
  String get message => tx(messageTr, args);
  @override
  String toString() => message;
}

/// Firebase Auth + Google Sign-In (v7) + Apple Sign-In servis katmanı.
///
/// Neden Google'ın kendi seçim paneli görünüyor? Google, şifrenin üçüncü
/// taraf uygulamaların kendi ekranlarında istenmesini GÜVENLİK gereği yasaklar
/// (bu kimlik avı sayılır ve uygulama mağazadan kaldırılır). Kimlik doğrulama
/// Android'in Credential Manager panelinde tek dokunuşla yapılır; kayıt
/// sürecinin geri kalanı (takma ad, avatar, alanlar, rıza) tamamen Haven'ın
/// kendi ekranlarındadır.
///
/// Android notu: google_sign_in 7, web istemci kimliğini `google-services.json`
/// içinden üretilen `default_web_client_id` kaynağından otomatik okur.
class AuthService {
  AuthService(this._auth);

  final FirebaseAuth _auth;
  Future<void>? _googleInit;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> _ensureGoogleInit() => _googleInit ??= GoogleSignIn.instance.initialize();

  /// Kullanıcı paneli kapatırsa `null` döner (hata değil, vazgeçme).
  Future<UserCredential?> signInWithGoogle() async {
    final credential = await _googleCredential();
    if (credential == null) return null;
    return _auth.signInWithCredential(credential);
  }

  /// iOS'ta native Apple girişi. App Store kuralı (4.8): iOS'ta Google ile
  /// giriş sunuyorsan Apple ile giriş de sunmalısın.
  Future<UserCredential?> signInWithApple() async {
    final provider = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');
    try {
      return await _auth.signInWithProvider(provider);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'canceled' || e.code == 'web-context-canceled') return null;
      debugPrint('Apple giriş hatası: ${e.code} ${e.message}');
      throw const AuthFailure('Apple ile giriş şu an tamamlanamadı. Biraz sonra tekrar dener misin?');
    }
  }

  Future<void> signOut() async {
    try {
      await _ensureGoogleInit();
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  /// Google Play ve App Store, uygulama içi hesap silmeyi ZORUNLU tutar.
  /// Firestore verisi bundan önce silinmelidir (HavenRepository.deleteAllUserData).
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') {
        throw AuthFailure('Hesap silinemedi ({code}). Lütfen tekrar dene.', {'code': e.code});
      }
      final isApple = user.providerData.any((p) => p.providerId == 'apple.com');
      if (isApple) {
        await user.reauthenticateWithProvider(AppleAuthProvider());
      } else {
        final credential = await _googleCredential();
        if (credential == null) return;
        await user.reauthenticateWithCredential(credential);
      }
      await user.delete();
    }
    await signOut();
  }

  Future<OAuthCredential?> _googleCredential() async {
    await _ensureGoogleInit();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) throw const AuthFailure('Google kimlik bilgisi alınamadı.');
      return GoogleAuthProvider.credential(idToken: idToken);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      debugPrint('Google giriş hatası: ${e.code} ${e.description}');
      throw const AuthFailure('Google ile giriş şu an tamamlanamadı. Biraz sonra tekrar dener misin?');
    }
  }
}
