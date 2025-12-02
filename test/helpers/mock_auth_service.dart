import 'package:firebase_auth/firebase_auth.dart';
import 'package:hatimituhub/services/auth_service.dart';

/// テスト用AuthServiceのモック
class MockAuthService implements AuthService {
  @override
  Future<bool> isAppleSignInAvailable() async => false;

  @override
  Future<UserCredential?> signInWithApple() async => null;

  @override
  Future<UserCredential?> signInWithGoogle() async => null;

  @override
  Future<void> signOut() async {}

  @override
  User? get currentUser => null;

  @override
  Stream<User?> get authStateChanges => Stream.value(null);
}

/// テスト用Userのモック
class MockUser implements User {
  @override
  String? get displayName => 'テストユーザー';

  @override
  String? get email => 'test@example.com';

  @override
  String? get photoURL => null;

  // 必要なgetterのみ実装。他はthrow UnimplementedErrorでOK。
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
