# Firebase開発用プロジェクト移行ガイド

## 目的
開発用Firebaseプロジェクトを `honeysales-9fc34` から `hatimituhub-dev` に移行し、本番用 `hatimituhub` との名称の一貫性を確保する。

## 現状
- **開発環境（dev）**: `honeysales-9fc34`（旧名称）
- **本番環境（prod）**: `hatimituhub`

## 移行後
- **開発環境（dev）**: `hatimituhub-dev`（新規作成）
- **本番環境（prod）**: `hatimituhub`（変更なし）

---

## 移行手順

### ステップ 1: 新しいFirebaseプロジェクトを作成

1. [Firebase Console](https://console.firebase.google.com/) にアクセス
2. 「プロジェクトを追加」をクリック
3. プロジェクト名: **`hatimituhub-dev`** と入力
4. Googleアナリティクス: 任意で設定（推奨: 有効化して本番と同じアカウントを使用）
5. 「プロジェクトを作成」をクリック

### ステップ 2: Androidアプリを登録

1. Firebaseプロジェクトのトップページで「Androidアプリを追加」をクリック
2. 以下の情報を入力：
   - **Androidパッケージ名**: `jp.netplan.android.hatimituhub.dev`
   - **アプリのニックネーム**: `はちみつハブ (Dev/Android)`
   - **デバッグ用の署名証明書SHA-1**: （開発中は任意）
3. 「アプリを登録」をクリック
4. **`google-services.json`** をダウンロード
5. ダウンロードしたファイルを以下に配置：
   ```
   android/app/src/dev/google-services.json
   ```

### ステップ 3: iOSアプリを登録

1. Firebaseプロジェクトのトップページで「iOSアプリを追加」をクリック
2. 以下の情報を入力：
   - **iOSバンドルID**: `jp.netplan.ios.hatimituhub.dev`
   - **アプリのニックネーム**: `はちみつハブ (Dev/iOS)`
   - **App Store ID**: （空欄でOK）
3. 「アプリを登録」をクリック
4. **`GoogleService-Info.plist`** をダウンロード
5. ダウンロードしたファイルを以下に配置（既存のファイルを置き換え）：
   ```
   ios/Runner/GoogleService-Info-Dev.plist
   ```

### ステップ 4: Firebaseサービスを有効化

#### 4.1 Authentication（認証）
1. Firebase Console > Authentication > 「始める」をクリック
2. 「Sign-in method」タブで以下の認証プロバイダを有効化：

**Google Sign-In**
1. 「Google」を選択
2. 有効化して、以下を入力：
   - **プロジェクトの公開名**: `はちみつハブ (開発版)`
   - **プロジェクトのサポートメール**: 自分のメールアドレス
3. 「保存」をクリック

**Apple Sign-In**（App Store審査に必須）
1. 「Apple」を選択
2. 有効化する
3. 「保存」をクリック

> **Note**: Appleのガイドラインにより、他のサードパーティ認証を提供する場合、「Sign in with Apple」の実装が必須です。

#### 4.2 Firestore Database
1. Firebase Console > Firestore Database > 「データベースを作成」をクリック
2. **データベースID**: デフォルトの `(default)` のまま（変更不要）
3. ロケーション: **`asia-northeast1`**（東京）を選択
4. セキュリティルール: **「テストモードで開始」** を選択（後で本番用ルールに変更）
5. 「次へ」→「有効にする」をクリック

#### 4.3 セキュリティルールの設定
Firestore Database > ルール タブで以下を設定：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 認証済みユーザーのみアクセス可能（開発用の基本ルール）
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**ルールのテスト（推奨）**:
1. 右上の「**開発とテスト**」ボタンをクリック
2. 「ルールシミュレーター」で以下をテスト：
   - **認証済み**: `request.auth != null` → ✅ 読み取り/書き込み許可
   - **未認証**: `request.auth == null` → ❌ 読み取り/書き込み拒否
3. 問題なければ「**公開**」ボタンでルールをデプロイ

**注意**: 本番環境のセキュリティルールとは異なります。開発環境は認証済みユーザーなら全アクセス可能な簡易版です。

#### 4.4 Cloud Storage（使用している場合）
1. Firebase Console > Storage > 「始める」をクリック
2. セキュリティルール: 「本番モードで開始」を選択
3. ロケーション: **`asia-northeast1`**（東京）
4. 「完了」をクリック

### ステップ 5: Apple Developer での設定（iOS App Store審査に必須）

#### 5.1 Sign in with Apple を有効化
1. [Apple Developer](https://developer.apple.com/account/) にアクセス
2. Certificates, Identifiers & Profiles > Identifiers を選択
3. 該当する App ID（`jp.netplan.ios.hatimituhub.dev`）を選択
4. Capabilities で **「Sign in with Apple」** にチェックを入れる
5. 「Save」をクリック

#### 5.2 Service ID の作成（必要な場合）
Webアプリでも認証する場合は Service ID を作成します（モバイルアプリのみの場合は不要）。

### ステップ 6: FlutterFire CLI で設定を更新

プロジェクトルートで以下のコマンドを実行：

```bash
# FlutterFire CLI がインストールされていない場合
dart pub global activate flutterfire_cli

# 新しいFirebaseプロジェクトで設定を再生成
flutterfire configure --project=hatimituhub-dev
```

**対話形式で以下を選択：**
- プロジェクト: `hatimituhub-dev` を選択
- プラットフォーム: `android`, `ios` を選択（Space キーで選択、Enter で確定）
- ファイルを上書きするか聞かれたら: `y` (Yes)

これにより `lib/firebase_options.dart` が自動更新されます。

### ステップ 7: データ移行（必要な場合のみ）

既存の `honeysales-9fc34` からテストデータを移行する場合：

#### 方法1: 手動でエクスポート/インポート
1. [旧プロジェクトのFirebase Console](https://console.firebase.google.com/project/honeysales-9fc34/firestore)
2. Firestore Database > 「エクスポート」タブ
3. Cloud Storage バケットを指定してエクスポート
4. 新プロジェクトで「インポート」からエクスポートしたデータをインポート

#### 方法2: gcloud CLI を使用
```bash
# 認証
gcloud auth login

# エクスポート
gcloud firestore export gs://honeysales-9fc34.appspot.com/firestore-export \
  --project=honeysales-9fc34

# インポート
gcloud firestore import gs://honeysales-9fc34.appspot.com/firestore-export \
  --project=hatimituhub-dev
```

**推奨**: 開発環境は新規データで開始し、必要に応じて手動でテストデータを作成する方が安全です。

### ステップ 8: 動作確認

```bash
# クリーンビルド
flutter clean
flutter pub get

# iOS の場合、Podも更新
cd ios
pod install
cd ..

# 開発環境で実行
flutter run --flavor dev --dart-define=FLAVOR=dev
```

#### 確認項目
- ✅ アプリが起動する
- ✅ Google認証でログインできる
- ✅ Apple認証でログインできる（iOSデバイスのみ）
- ✅ Firestoreへの読み書きができる
- ✅ アプリ名が「はちみつハブ (Dev)」と表示される
- ✅ エラーログに `honeysales` の文字列が出ていない

---

## トラブルシューティング

### エラー: "FirebaseOptions have not been configured"
**原因**: FlutterFire CLI が正しく実行されていない

**解決策**:
```bash
flutterfire configure --project=hatimituhub-dev
# プラットフォーム選択で android, ios を必ず選ぶ
```

### エラー: "google-services.json が見つからない"
**原因**: ファイルの配置場所が間違っている

**正しい配置場所**:
```
android/app/src/dev/google-services.json  ← 開発用
android/app/src/prod/google-services.json ← 本番用
```

### エラー: "GoogleService-Info.plist が見つからない"
**原因**: ファイル名が間違っている、または配置場所が違う

**正しいファイル名と配置**:
```
ios/Runner/GoogleService-Info-Dev.plist   ← 開発用
ios/Runner/GoogleService-Info-Prod.plist  ← 本番用
```

### Google Sign-In がエラーになる
**原因**: OAuth 2.0 クライアント ID が設定されていない

**解決策**:
1. Firebase Console > Authentication > 設定 タブ
2. 「Google」プロバイダの設定を開く
3. 「Web SDK の構成」セクションの Web クライアント ID をコピー
4. Google Cloud Console で OAuth 同意画面を設定
5. iOS の場合、`REVERSED_CLIENT_ID` が Info.plist に追加されているか確認

### Google Sign-In で「honeysales に移動」と表示される
**原因**: `Info.plist` に旧プロジェクトの OAuth クライアント ID が残っている、またはGoogle Cloud Consoleのアプリ名が更新されていない

**解決策（iOS）**:
1. `ios/Runner/Info.plist` を確認
2. `GIDClientID` と `CFBundleURLSchemes` の値を新プロジェクトのものに更新:
   ```xml
   <key>GIDClientID</key>
   <string>947749136128-hofb2cde3t1bm1f3qt444rr229vlf1jm.apps.googleusercontent.com</string>
   <key>CFBundleURLSchemes</key>
   <array>
       <string>com.googleusercontent.apps.947749136128-hofb2cde3t1bm1f3qt444rr229vlf1jm</string>
   </array>
   ```
3. [Google Cloud Console](https://console.cloud.google.com/) にアクセス
4. プロジェクト `hatimituhub-dev` を選択
5. APIs & Services > OAuth 同意画面
6. **アプリケーション名**を `はちみつハブ (開発版)` に変更
7. 「保存して次へ」をクリック
8. アプリを再起動

### ビルドエラー: "Duplicate class found"
**原因**: キャッシュの問題

**解決策**:
```bash
flutter clean
cd android
./gradlew clean
cd ..
flutter pub get
```

---

## 移行後の確認チェックリスト

- [x] 新しいFirebaseプロジェクト `hatimituhub-dev` が作成されている
- [x] Android/iOSアプリが登録されている
- [x] Authentication（Google, Apple）が有効化されている
- [x] Firestore Database が作成されている
- [x] セキュリティルールが設定されている
- [x] `google-services.json` が正しい場所に配置されている
- [x] `GoogleService-Info-Dev.plist` が正しい場所に配置されている
- [x] `firebase_options.dart` が更新されている
- [x] `Info.plist` の OAuth クライアント ID が更新されている
- [x] Google Cloud Console のアプリ名が更新されている
- [x] 開発環境でアプリが起動する
- [x] Google認証でログインできる（「はちみつハブ（開発版）に移動」と表示）
- [x] Apple認証でログインできる（シミュレータで確認）
- [x] Firestoreの読み書きができる（商品マスタ、注文入力で確認済み）

---

## 旧プロジェクト（honeysales-9fc34）の扱い

移行完了後、旧プロジェクトは以下のように扱います：

1. **即座に削除しない**: 1〜2週間は残しておく
2. **データのバックアップ**: 必要なデータをエクスポートしておく
3. **段階的に削除**:
   - まず、新環境での動作が安定していることを確認
   - その後、Firebase Console から削除

**削除手順**:
1. Firebase Console > プロジェクト設定 > 全般
2. 一番下の「プロジェクトを削除」をクリック
3. プロジェクトIDを入力して確認

---

## 関連ドキュメント

- [FLAVORS.md](./FLAVORS.md) - Flavor設定の詳細
- [Firebase_Firestore_導入手順.md](./Firebase_Firestore_導入手順.md) - Firestoreの初期設定
- [Google認証導入手順.md](./Google認証導入手順.md) - Google Sign-In設定

---

## 移行完了日

- 移行実施日: 2025年12月2日
- 移行作業者: 完了
- 動作確認完了: ✅

## 移行完了の確認事項

以下が正常に動作していることを確認済み：
- ✅ 新プロジェクト `hatimituhub-dev` への切り替え完了
- ✅ Google Sign-In で「はちみつハブ（開発版）に移動」と表示
- ✅ アプリ名「はちみつハブ (Dev)」の表示
- ✅ Firebase設定ファイルの配置
- ✅ OAuth クライアント ID の更新

## 次のステップ

1. **実際にログイン・データ操作をテスト**
   - Google 認証でログイン
   - Firestore へのデータ保存・読み込み
   - 各機能の動作確認

2. **Apple Sign-In のテスト**（実機が必要）
   - 実機で Apple 認証を試す
   - Apple Developer の設定を確認

3. **旧プロジェクト（honeysales-9fc34）の削除**
   - 1〜2週間動作を確認後、削除を検討

