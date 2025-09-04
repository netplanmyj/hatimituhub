# チーム運用実装 - 追加考慮事項

## 🔐 セキュリティ考慮事項

### 認証・認可
- **チーム所属確認**: 各API呼び出し時にユーザーのチーム所属を検証
- **権限ベースアクセス**: 読み取り専用メンバーのデータ変更を防止
- **CORS設定**: Web版での適切なオリジン制限

### データ保護
- **個人情報の分離**: チーム間での個人情報漏洩防止
- **監査ログ**: 重要な操作（メンバー追加・削除）のログ記録
- **バックアップ**: チーム削除時の誤操作対策

## 🎨 UI/UX設計要件

### チーム切り替え
- **ヘッダーでの現在チーム表示**: 「○○チーム」の明確な表示
- **切り替えドロップダウン**: Phase 3での複数チーム対応
- **チーム色分け**: 視覚的な区別（オプション）

### チーム管理画面
```
/team/settings/
├── チーム情報編集
├── メンバー管理
├── 招待リンク管理
└── チーム削除
```

### 権限表示
- **編集不可要素のグレーアウト**: 読み取り専用メンバー向け
- **権限不足時の明確なメッセージ**: 「編集権限がありません」

## 📊 Firestoreセキュリティルール

### 現在のルール拡張案
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // チーム基本情報
    match /teams/{teamId} {
      allow read, write: if isTeamMember(teamId);
    }
    
    // チームメンバー情報
    match /team_members/{userId} {
      allow read: if isTeamMember(resource.data.teamId);
      allow write: if isTeamOwner(resource.data.teamId);
    }
    
    // チームデータ（既存）
    match /team_data/{teamId}/{document=**} {
      allow read, write: if isTeamMember(teamId);
    }
    
    // 招待機能
    match /team_invitations/{invitationId} {
      allow create: if isTeamOwner(resource.data.teamId);
      allow read, update: if isTeamOwner(resource.data.teamId) 
                          || request.auth.token.email == resource.data.inviteeEmail;
    }
    
    // ヘルパー関数
    function isTeamMember(teamId) {
      return exists(/databases/$(database)/documents/team_members/$(request.auth.uid)) &&
             get(/databases/$(database)/documents/team_members/$(request.auth.uid)).data.teamId == teamId;
    }
    
    function isTeamOwner(teamId) {
      return isTeamMember(teamId) &&
             get(/databases/$(database)/documents/team_members/$(request.auth.uid)).data.role == 'owner';
    }
  }
}
```

## 📈 パフォーマンス最適化

### インデックス戦略
```javascript
// 必要なインデックス
team_members: [teamId, role]
teams: [ownerId]
team_invitations: [teamId, status]
team_data/{teamId}/orders: [customerId, orderDate] // 既存
```

### キャッシュ戦略
- **チーム情報**: ローカルストレージでキャッシュ
- **メンバー一覧**: メモリキャッシュ（5分間）
- **権限情報**: セッション間キャッシュ

## 🔄 段階的移行戦略

### Phase 0: 準備段階
1. **フィーチャーフラグ実装**: チーム機能のON/OFF切り替え
2. **既存データの検証**: team_data構造の整合性確認
3. **バックアップ**: 移行前の完全バックアップ

### Phase 1: ソフトローンチ  
1. **限定ユーザーでのβテスト**: 10-20ユーザーで先行テスト
2. **既存機能への影響確認**: 注文・顧客管理機能の動作確認
3. **パフォーマンス監視**: レスポンス時間の計測

### Phase 2: 段階的展開
1. **新規ユーザー優先**: 新規登録ユーザーから新機能適用
2. **既存ユーザーのオプトイン**: 希望者のみ新機能有効化
3. **フィードバック収集**: ユーザビリティの改善点収集

## 🧪 テスト戦略

### 単体テスト
```dart
// FirestoreServiceのテスト例
test('チーム作成機能', () async {
  final teamId = await FirestoreService.createTeam('テストチーム');
  expect(teamId, isNotNull);
  expect(await FirestoreService.isTeamNameAvailable('テストチーム'), false);
});

test('メンバー招待機能', () async {
  final invitation = await TeamInvitationService.inviteMember(
    'test@example.com', 
    'teamId123'
  );
  expect(invitation.status, equals('pending'));
});
```

### 統合テスト
- **チーム作成→メンバー招待→承諾**: 一連のフローテスト
- **権限制御**: 各役割での操作可能範囲テスト
- **データ分離**: チーム間でのデータアクセス制限テスト

### E2Eテスト
```dart
// Flutterドライバーでのテスト例
test('チーム管理フロー', () async {
  await driver.tap(find.byValueKey('create_team_button'));
  await driver.enterText(find.byValueKey('team_name_field'), 'E2Eテストチーム');
  await driver.tap(find.byValueKey('create_button'));
  expect(await driver.getText(find.byValueKey('current_team')), 'E2Eテストチーム');
});
```

## 📋 運用監視項目

### メトリクス
- **チーム作成数**: 日次・月次での作成数推移
- **招待成功率**: 送信数に対する参加完了率  
- **チーム利用率**: アクティブチーム数の割合
- **エラー率**: API呼び出しのエラー発生率

### アラート設定
- **異常なチーム作成**: 短時間での大量作成検知
- **招待メール送信失敗**: メール送信エラーの監視
- **データアクセスエラー**: 権限エラーの急増検知

## 💰 課金モデル検討

### フリープラン制限案
- **チーム数**: 1個まで
- **メンバー数**: 3人まで  
- **データ保存期間**: 6ヶ月
- **月間取引数**: 100件まで

### 有料プラン機能案
- **チーム数**: 無制限
- **メンバー数**: 無制限
- **データ保存**: 無期限
- **月間取引数**: 無制限
- **高度な権限管理**: 細かい権限設定
- **監査ログ**: 詳細な操作履歴

---
**更新日**: 2024年9月4日  
**ステータス**: 設計検討中
