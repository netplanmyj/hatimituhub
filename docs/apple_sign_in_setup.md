# Apple Sign-In 実装ガイド

## 概要
App Storeの審査ガイドラインにより、他のサードパーティ認証（Google Sign-Inなど）を提供する場合、「Sign in with Apple」の実装が必須です。

## 必要なパッケージ

```yaml
dependencies:
  firebase_auth: ^6.0.1
  sign_in_with_apple: ^6.1.3
  crypto: ^3.0.6  # nonce生成のため必要
```

---

## Firebase での設定

### 1. Authentication で Apple を有効化

1. [Firebase Console](https://console.firebase.google.com/) > プロジェクトを選択
2. Authentication > Sign-in method タブ
3. 「Apple」を選択
4. 有効にする
5. 「保存」をクリック

---

## Apple Developer での設定

### 1. App ID で Sign in with Apple を有効化

1. [Apple Developer](https://developer.apple.com/account/) にアクセス
2. **Certificates, Identifiers & Profiles** を選択
3. **Identifiers** を選択
4. 該当する App ID を選択:
   - 開発環境: `jp.netplan.ios.hatimituhub.dev`
   - 本番環境: `jp.netplan.ios.hatimituhub`
5. **Capabilities** セクションで **「Sign in with Apple」** にチェック
6. 「Save」をクリック

### 2. Xcode プロジェクトで Sign in with Apple を有効化

1. `ios/Runner.xcworkspace` を Xcode で開く
2. Runner を選択 > Signing & Capabilities タブ
3. 「+ Capability」をクリック
4. **「Sign in with Apple」** を追加
5. 開発環境と本番環境の両方の Configuration で有効化されていることを確認

---

## Flutter での実装

### 1. 認証サービスの実装

`lib/services/auth_service.dart` に Apple Sign-In の処理を追加:

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:io' show Platform;
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

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

  // Apple Sign-In が利用可能かチェック
  Future<bool> isAppleSignInAvailable() async {
    if (!Platform.isIOS) return false;
    return await SignInWithApple.isAvailable();
  }

  // Apple Sign-In
  Future<UserCredential?> signInWithApple() async {
    try {
      // ランダムなnonceを生成（セキュリティ対策）
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

      // OAuthCredential を作成（rawNonceを含める）
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      // Firebaseにサインイン
      final userCredential = await _auth.signInWithCredential(oauthCredential);

      // 初回サインイン時に表示名を設定
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        final displayName = _buildDisplayName(
          appleCredential.givenName,
          appleCredential.familyName,
        );
        
        if (displayName != null) {
          await userCredential.user?.updateDisplayName(displayName);
        }
      }

      return userCredential;
    } catch (e) {
      debugPrint('❌ Apple Sign-In エラー: $e');
      return null;
    }
  }

  // Apple認証から取得した名前を整形
  String? _buildDisplayName(String? givenName, String? familyName) {
    if (givenName == null && familyName == null) return null;
    
    final parts = <String>[];
    if (familyName != null) parts.add(familyName);
    if (givenName != null) parts.add(givenName);
    
    return parts.isEmpty ? null : parts.join(' ');
  }

  // 既存のGoogle Sign-In
  Future<UserCredential?> signInWithGoogle() async {
    // ... 既存の実装
  }

  // サインアウト
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 現在のユーザー
  User? get currentUser => _auth.currentUser;

  // 認証状態のストリーム
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
```

### 2. UI にサインインボタンを追加

`lib/initial_setup_page.dart` や認証画面に Apple Sign-In ボタンを追加:

```dart
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'services/auth_service.dart';

class InitialSetupPage extends StatefulWidget {
  // ... 既存のコード
}

class _InitialSetupPageState extends State<InitialSetupPage> {
  final AuthService _authService = AuthService();
  bool _isAppleSignInAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkAppleSignInAvailability();
  }

  Future<void> _checkAppleSignInAvailability() async {
    final isAvailable = await _authService.isAppleSignInAvailable();
    setState(() {
      _isAppleSignInAvailable = isAvailable;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ログイン')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google Sign-In ボタン
            ElevatedButton.icon(
              onPressed: _handleGoogleSignIn,
              icon: const Icon(Icons.login),
              label: const Text('Google でサインイン'),
            ),
            
            const SizedBox(height: 16),
            
            // Apple Sign-In ボタン（iOS のみ表示）
            if (_isAppleSignInAvailable)
              SignInWithAppleButton(
                onPressed: _handleAppleSignIn,
                text: 'Apple でサインイン',
                height: 50,
                borderRadius: BorderRadius.circular(8),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    final userCredential = await _authService.signInWithGoogle();
    if (userCredential != null && mounted) {
      // サインイン成功時の処理
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _handleAppleSignIn() async {
    final userCredential = await _authService.signInWithApple();
    if (userCredential != null && mounted) {
      // サインイン成功時の処理
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // エラー処理
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Apple サインインに失敗しました')),
      );
    }
  }
}
```

---

## テスト方法

### 1. シミュレータでのテスト
iOS シミュレータでは Sign in with Apple をテストできません。実機でテストする必要があります。

### 2. 実機でのテスト

```bash
# 開発環境でビルド
flutter run --flavor dev --dart-define=FLAVOR=dev -d <デバイスID>
```

#### テスト手順
1. アプリを起動
2. 「Apple でサインイン」ボタンをタップ
3. Apple ID でサインイン（Face ID / Touch ID を使用）
4. 初回は名前とメールの共有を許可
5. Firebaseにユーザーが作成されることを確認

---

## トラブルシューティング

### エラー: "Sign in with Apple is not supported"

**原因**: iOS シミュレータで実行している

**解決策**: 実機でテストしてください

---

### エラー: "Invalid client ID"

**原因**: Apple Developer で App ID の設定が完了していない

**解決策**:
1. Apple Developer > Identifiers で App ID を確認
2. Sign in with Apple が有効になっているか確認
3. Xcode で Signing & Capabilities に Sign in with Apple が追加されているか確認

---

### エラー: "The operation couldn't be completed"

**原因**: Bundle Identifier が一致していない

**解決策**:
1. Xcode の Bundle Identifier を確認: `jp.netplan.ios.hatimituhub.dev` または `jp.netplan.ios.hatimituhub`
2. Apple Developer の App ID と一致しているか確認
3. Firebase の iOS アプリ設定で Bundle ID が正しいか確認

---

### 初回サインイン後に名前が取得できない

**原因**: Apple は初回サインイン時のみ名前を提供

**解決策**:
1. 設定 > Apple ID > パスワードとセキュリティ > Apple でサインイン
2. アプリを選択して「サインインの停止」
3. 再度アプリでサインイン（初回として扱われる）

---

## セキュリティ上の注意

### 1. Nonce によるリプレイアタック対策
上記の実装では、ランダムなnonceを生成し、そのSHA-256ハッシュをAppleに送信することで、リプレイアタック（認証トークンの再利用）を防止しています。これはFirebaseの推奨する実装方法です。

### 2. メールアドレスの取り扱い
Apple Sign-In では、ユーザーがメールアドレスを非公開にすることができます。その場合、`privaterelay.appleid.com` のリレーメールが提供されます。

### 3. ユーザー識別子
Apple が提供する `userIdentifier` は永続的に同じ値が保証されていますが、アプリごとに異なります。

### 4. 取り消し処理
ユーザーが「設定」アプリから Apple サインインを取り消した場合、アプリ側でもログアウト処理を実装する必要があります。

---

## App Store 審査のポイント

### 審査で確認される項目
1. ✅ Google Sign-In と同じ位置・優先度で Apple Sign-In ボタンが表示されている
2. ✅ Apple Sign-In ボタンのデザインがガイドラインに準拠している
3. ✅ 実際に Apple Sign-In でログインできる
4. ✅ ログイン後、アプリの全機能が正常に動作する

### Apple のガイドライン
- [Sign in with Apple のヒューマンインターフェイスガイドライン](https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple)
- App Store Review Guidelines 4.8: Sign in with Apple

---

## 関連ドキュメント

- [firebase_migration_to_hatimituhub-dev.md](./firebase_migration_to_hatimituhub-dev.md) - Firebase移行ガイド
- [Google認証導入手順.md](./Google認証導入手順.md) - Google Sign-In設定
- [Firebase_Firestore_導入手順.md](./Firebase_Firestore_導入手順.md) - Firestore設定

---

## 実装完了チェックリスト

- [ ] `sign_in_with_apple` パッケージをインストール
- [ ] Firebase で Apple 認証を有効化
- [ ] Apple Developer で App ID に Sign in with Apple を追加
- [ ] Xcode で Sign in with Apple Capability を追加
- [ ] `AuthService` に Apple Sign-In メソッドを実装
- [ ] UI に Apple Sign-In ボタンを追加
- [ ] 実機でテストして動作確認
- [ ] Google Sign-In と同じ位置にボタンを配置
- [ ] エラーハンドリングを実装
- [ ] 本番環境でも同様の設定を実施
