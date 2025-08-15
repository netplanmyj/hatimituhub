# Firebase Firestore 導入手順

## 1. Firebaseプロジェクト作成
1. [Firebaseコンソール](https://console.firebase.google.com/) にアクセス
2. 「プロジェクトを追加」をクリック
3. プロジェクト名を入力し「続行」
4. Googleアナリティクスは任意で有効化し「プロジェクトを作成」

## 2. Firestore有効化
1. Firebaseコンソール左メニュー「Firestore Database」を選択
2. 「データベースを作成」をクリック
3. 「テストモード」を選択（開発時は推奨）
4. リージョンを選択し「有効化」

## 3. サンプルデータ登録
1. Firestore Database画面で「コレクションを開始」
2. コレクションIDに `products` を入力
3. ドキュメントIDは自動生成でOK
4. 以下のフィールドを追加
   - `name`（文字列）: 商品名
   - `price`（数値）: 価格
   - `createdAt`（タイムスタンプ）: 登録日時
5. 「保存」

## 4. Flutterアプリ連携
1. Firebaseプロジェクトの「プロジェクト設定」→「アプリ追加」からFlutterアプリを登録
2. `google-services.json`（Android）や`GoogleService-Info.plist`（iOS）をダウンロードし、所定の場所に配置
3. Flutterパッケージ追加
   ```sh
   flutter pub add firebase_core cloud_firestore
   ```
4. アプリ初期化・Firestoreからデータ取得実装

---

この手順でFirebase Firestoreの導入とサンプルデータ登録ができます。
