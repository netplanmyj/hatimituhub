import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:io' show Platform;
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ランダムなnonceを生成
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// 文字列のSHA-256ハッシュを計算
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Apple Sign-In が利用可能かチェック
  Future<bool> isAppleSignInAvailable() async {
    if (!Platform.isIOS) {
      debugPrint('🍎 Apple Sign-In: iOS以外のため利用不可');
      return false;
    }

    try {
      final isAvailable = await SignInWithApple.isAvailable();
      debugPrint('🍎 Apple Sign-In 利用可否: $isAvailable');
      return isAvailable;
    } catch (e) {
      debugPrint('❌ Apple Sign-In チェックエラー: $e');
      return false;
    }
  }

  /// Apple Sign-In
  Future<UserCredential?> signInWithApple() async {
    try {
      debugPrint('🍎 Apple Sign-In: 開始');

      // ランダムなnonceを生成
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Apple認証リクエスト（nonceを含める）
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      debugPrint('🍎 Apple Sign-In: 認証情報取得成功');

      // OAuthCredential を作成（rawNonceを含める）
      // Note: authorizationCodeはサーバー側のトークン交換用のため、ここでは使用しない
      final oauthCredential = OAuthProvider(
        "apple.com",
      ).credential(idToken: appleCredential.identityToken, rawNonce: rawNonce);

      // Firebaseにサインイン
      final userCredential = await _auth.signInWithCredential(oauthCredential);

      debugPrint('🍎 Apple Sign-In: Firebase認証成功');

      // 初回サインイン時に表示名を設定
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        final displayName = _buildDisplayName(
          appleCredential.givenName,
          appleCredential.familyName,
        );

        if (displayName != null) {
          await userCredential.user?.updateDisplayName(displayName);
          debugPrint('🍎 Apple Sign-In: 表示名設定 - $displayName');
        }
      }

      return userCredential;
    } catch (e) {
      debugPrint('❌ Apple Sign-In エラー: $e');
      return null;
    }
  }

  /// Apple認証から取得した名前を整形
  String? _buildDisplayName(String? givenName, String? familyName) {
    if (givenName == null && familyName == null) return null;

    final parts = <String>[];
    if (familyName != null) parts.add(familyName);
    if (givenName != null) parts.add(givenName);

    return parts.isEmpty ? null : parts.join(' ');
  }

  /// Google Sign-In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint('🔐 Google Sign-In: 開始');

      // Google認証
      final googleUser = await GoogleSignIn.instance.authenticate();

      debugPrint('🔐 Google Sign-In: Google認証成功');

      // Google Auth認証情報取得
      final googleAuth = googleUser.authentication;

      // Firebase認証情報作成
      // Note: google_sign_in 7.x ではaccessTokenは直接取得できないため、idTokenのみを使用
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Firebaseにサインイン
      final userCredential = await _auth.signInWithCredential(credential);

      debugPrint('🔐 Google Sign-In: Firebase認証成功');

      return userCredential;
    } catch (e) {
      debugPrint('❌ Google Sign-In エラー: $e');
      return null;
    }
  }

  /// サインアウト
  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn.instance.signOut();
    debugPrint('👋 サインアウト完了');
  }

  /// 現在のユーザー
  User? get currentUser => _auth.currentUser;

  /// 認証状態のストリーム
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
