# TestFlight配布手順（iOS/iPadOS）

## 1. Apple Developer登録・App Store Connect準備
- Apple Developer Program（有料）に登録済みであること
- App Store Connectでアプリの新規プロジェクトを作成

## 2. 証明書・プロビジョニングプロファイルの準備
- Xcodeで「Distribution」用の証明書・プロファイルを作成

## 3. リリースビルドの作成
```sh
flutter build ipa --release
```
- XcodeでRunner.xcworkspaceを開き、Archiveビルドを作成

## 4. TestFlightへアップロード
- Xcode Organizerから「Distribute App」→「App Store Connect」→「Upload」
- または `flutter build ipa` で生成したipaをTransporterアプリでアップロード

## 5. TestFlightでテスターを招待
- App Store Connectの「TestFlight」タブで「外部テスター」または「内部テスター」にテスターのメールアドレスを登録
- 招待メールが送信されるので、テスターはTestFlightアプリ経由でインストール

## 6. テスト・フィードバック
- テスターはTestFlightアプリからアプリをインストールし、フィードバックを送信可能

---

### 注意点
- 初回アップロード時はAppleの簡易審査（通常1日以内）が入ります
- テスト用でもプライバシーポリシーURLが必要です（ダミーでも可）
- TestFlightの有効期間は90日間、最大100人まで招待可能

---

### 参考リンク
- [Apple公式 TestFlightガイド](https://developer.apple.com/testflight/)
- [Flutter公式 iOSリリース手順](https://docs.flutter.dev/deployment/ios)
