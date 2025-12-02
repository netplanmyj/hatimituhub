# Flutter Flavors 設定ガイド

## 概要
このプロジェクトは開発環境（dev）と本番環境（prod）の2つのFlavorで構成されています。

## Firebase プロジェクト構成

- **開発環境（dev）**: `hatimituhub-dev`
- **本番環境（prod）**: `hatimituhub`

## 開発環境（dev）での実行方法

### Android
```bash
flutter run --flavor dev --dart-define=FLAVOR=dev
```

### iOS
```bash
flutter run --flavor dev --dart-define=FLAVOR=dev --xcconfig=ios/Flutter/Dev.xcconfig
```

## 本番環境（prod）での実行方法

### Android
```bash
flutter run --flavor prod --dart-define=FLAVOR=prod
```

### iOS
```bash
flutter run --flavor prod --dart-define=FLAVOR=prod --xcconfig=ios/Flutter/Prod.xcconfig
```

## ビルド方法

### Android APK（開発版）
```bash
flutter build apk --flavor dev --dart-define=FLAVOR=dev
```

### Android APK（本番版）
```bash
flutter build apk --flavor prod --dart-define=FLAVOR=prod
```

### iOS（開発版）
```bash
flutter build ios --flavor dev --dart-define=FLAVOR=dev --xcconfig=ios/Flutter/Dev.xcconfig
```

### iOS（本番版）
```bash
flutter build ios --flavor prod --dart-define=FLAVOR=prod --xcconfig=ios/Flutter/Prod.xcconfig
```

## 本番用Firebaseプロジェクトのセットアップ手順

### 1. Firebaseプロジェクトを作成
1. [Firebase Console](https://console.firebase.google.com/) にアクセス
2. 「プロジェクトを追加」をクリック
3. プロジェクト名を入力（`hatimituhub` = 本番用、または既に作成済み）
4. Googleアナリティクスは任意で設定
5. プロジェクトを作成

### 2. Androidアプリを登録
1. Firebaseプロジェクトの設定画面で「Androidアプリを追加」をクリック
2. パッケージ名: `jp.netplan.android.hatimituhub`
3. アプリのニックネーム: `はちみつハブ (Android)`
4. SHA-1証明書フィンガープリントを追加（リリースビルド用）
5. `google-services.json` をダウンロード
6. ダウンロードしたファイルを `android/app/src/prod/google-services.json` に配置

### 3. iOSアプリを登録
1. Firebaseプロジェクトの設定画面で「iOSアプリを追加」をクリック
2. バンドルID: `jp.netplan.ios.hatimituhub`
3. アプリのニックネーム: `はちみつハブ (iOS)`
4. App Store ID: （後で設定可能）
5. `GoogleService-Info.plist` をダウンロード
6. ダウンロードしたファイルを `ios/Runner/GoogleService-Info-Prod.plist` として配置

### 4. Firebaseサービスを有効化
1. **Authentication**: 
   - Google認証を有効化
   - 開発環境と同じ認証プロバイダを設定
   
2. **Firestore Database**:
   - データベースを作成（テストモードまたは本番モード）
   - セキュリティルールを設定
   
3. **Cloud Storage**:
   - ストレージを有効化
   - セキュリティルールを設定

### 5. FlutterFire CLI で設定を更新

プロジェクトルートで以下のコマンドを実行して `firebase_options.dart` を自動生成:

```bash
# FlutterFire CLI がインストールされていない場合
dart pub global activate flutterfire_cli

# Firebaseプロジェクトの設定を生成
flutterfire configure --project=hatimituhub
```

対話形式でプラットフォーム（android, ios）を選択すると、自動的に設定ファイルが更新されます。

## Bundle Identifier / Package Name

### 開発環境（dev）
- **iOS**: `jp.netplan.ios.hatimituhub.dev`
- **Android**: `jp.netplan.android.hatimituhub.dev`

### 本番環境（prod）
- **iOS**: `jp.netplan.ios.hatimituhub`
- **Android**: `jp.netplan.android.hatimituhub`

## アプリ名

- **開発版**: `はちみつハブ (Dev)`
- **本番版**: `はちみつハブ`

## データ移行

開発環境から本番環境にデータを移行する場合:

1. Firebaseコンソールで開発環境のデータをエクスポート
2. 本番環境にインポート
3. または、アプリ内でデータ移行機能を実装

## ストア審査について

### 審査申請の推奨フロー
1. 本番用Firebaseプロジェクトを作成・設定
2. 本番環境（prod）でアプリをビルド
3. App Store / Google Play Console に本番版をアップロード
4. 審査を受ける（データは空または最小限のテストデータ）
5. 審査通過後、開発環境のデータを本番環境に移行
6. 正式リリース

## トラブルシューティング

### Firebaseの初期化に失敗する場合
- 設定ファイル（`google-services.json` / `GoogleService-Info.plist`）が正しい場所にあるか確認
- Bundle ID / Package Name が一致しているか確認

### ビルドエラーが発生する場合
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
```

## VS Code での実行設定

`.vscode/launch.json` を作成して、VS Codeから簡単に環境を切り替えられます:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Dev (開発環境)",
      "request": "launch",
      "type": "dart",
      "program": "lib/main.dart",
      "args": [
        "--flavor",
        "dev",
        "--dart-define=FLAVOR=dev"
      ]
    },
    {
      "name": "Prod (本番環境)",
      "request": "launch",
      "type": "dart",
      "program": "lib/main.dart",
      "args": [
        "--flavor",
        "prod",
        "--dart-define=FLAVOR=prod"
      ]
    }
  ]
}
```
