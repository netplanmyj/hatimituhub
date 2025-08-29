# Google認証（firebase_auth, google_sign_in）導入手順

## 1. 必要パッケージの追加
`pubspec.yaml` に以下を追加し、`flutter pub get` を実行。

```yaml
dependencies:
  firebase_core: ^最新
  firebase_auth: ^最新
  google_sign_in: ^最新
```

## 2. Firebase Consoleでプロジェクト作成
- プロジェクトを新規作成
- Authentication > Sign-in method で「Google」を有効化

## 3. Google認証用ファイルの配置
- iOS: `GoogleService-Info.plist` を `ios/Runner/` に配置
- Android: `google-services.json` を `android/app/` に配置

## 4. iOSのInfo.plist設定
- `ios/Runner/Info.plist` に以下を追加
  - `REVERSED_CLIENT_ID`（GoogleService-Info.plistからコピー）
  - URL Scheme設定

例：
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.xxxxxxxx</string>
    </array>
  </dict>
</array>
```

## 5. AndroidのSHA-1登録
- Firebase ConsoleでSHA-1証明書を登録
- `google-services.json`を再ダウンロードして配置

## 6. main.dartの初期化・認証ロジック
- Firebase初期化
- Google認証ボタンの実装例

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

// Google認証処理例
Future<void> signInWithGoogle() async {
  final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
  if (googleUser == null) return;
  final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );
  await FirebaseAuth.instance.signInWithCredential(credential);
}
```

## 7. 動作確認・テスト
- 実機/シミュレーターでGoogleログインが成功するか確認
- エラー時はInfo.plistやBundle ID、Firebase Console設定を再確認

---

この手順でGoogle認証が導入できます。詳細なエラー対応や運用方針はプロジェクト状況に応じて追記してください。
