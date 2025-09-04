# チーム管理機能 仕様書

## 概要
現在の`/team_data/{userId}`構造から、真のマルチテナント対応に向けたチーム管理機能の実装仕様

## 現在の実装状況
- `teamId = userId`として個人単位でのデータ分離は完了
- FirestoreServiceによる統一的なアクセス制御を実装済み
- 基本的なCRUD操作は全てteam_data構造に対応済み

## 段階的実装計画

### フェーズ1: 基本チーム機能（MVP）
**目標**: 1ユーザー1チームでの運用開始

#### 1.1 データ構造設計
```
/teams/{teamId}/
  - name: string (チーム名)
  - createdAt: timestamp
  - updatedAt: timestamp
  - ownerId: string (作成者のuserId)
  - memberCount: number
  - status: string (active/inactive)

/team_members/{userId}/
  - teamId: string
  - role: string (owner/member)
  - joinedAt: timestamp
  - status: string (active/pending/inactive)

/team_data/{teamId}/
  - customers/
  - products/
  - orders/
  (既存構造を維持)
```

#### 1.2 必要な機能
- [ ] チーム作成機能
- [ ] チーム名の重複チェック
- [ ] ユーザーのチーム所属状況管理
- [ ] チーム情報表示

#### 1.3 制限事項
- 1ユーザーは1チームのみ所属可能
- チーム作成は1ユーザー1回のみ
- チームメンバー追加機能は非実装（将来実装予定）

### フェーズ2: チームメンバー管理機能
**目標**: 複数ユーザーでのチーム運用

#### 2.1 招待機能
- [ ] メールアドレスによる招待
- [ ] 招待リンクの生成・管理
- [ ] 招待承認・拒否機能

#### 2.2 メンバー管理
- [ ] メンバー一覧表示
- [ ] メンバーの役割管理（オーナー/メンバー）
- [ ] メンバー削除機能
- [ ] 権限管理（データ編集権限など）

#### 2.3 データ構造拡張
```
/team_invitations/{invitationId}/
  - teamId: string
  - inviterUserId: string
  - inviteeEmail: string
  - status: string (pending/accepted/rejected/expired)
  - createdAt: timestamp
  - expiresAt: timestamp

/team_members/{userId}/
  - permissions: array<string> (read/write/admin)
  - invitedBy: string
```

### フェーズ3: 課金・制限管理機能
**目標**: 有料プランでの複数チーム対応

#### 3.1 プラン管理
- [ ] フリープラン: 1チームのみ
- [ ] 有料プラン: 複数チーム対応
- [ ] チーム数制限の実装

#### 3.2 データ構造拡張
```
/user_subscriptions/{userId}/
  - planType: string (free/paid)
  - maxTeams: number
  - currentTeams: number
  - subscriptionStatus: string

/users/{userId}/
  - teams: array<string> (所属チームIDのリスト)
  - activeTeamId: string (現在選択中のチーム)
```

## 実装上の考慮事項

### セキュリティ
- チームデータへのアクセス制御
- メンバー権限の適切な管理
- 招待機能でのスパム対策

### パフォーマンス
- チーム切り替え時のデータ読み込み最適化
- 大規模チームでのメンバー管理効率化

### ユーザビリティ
- チーム作成・参加フローの簡潔化
- 現在のチーム表示
- チーム切り替えUI

## マイグレーション計画

### 既存ユーザーの移行
1. 現在の`/team_data/{userId}`をそのまま維持
2. `userId`をベースにした自動チーム作成
3. チーム名は「{ユーザー名}のチーム」として自動生成

### FirestoreServiceの拡張
```dart
class FirestoreService {
  // 現在の実装を維持しつつ拡張
  static String? get currentTeamId => getCurrentUserTeamId();
  
  static String? getCurrentUserTeamId() {
    // 将来的にはユーザーの選択中チームIDを返す
    // 現在は userId をそのまま返す（後方互換性）
    return FirebaseAuth.instance.currentUser?.uid;
  }
  
  // 新規追加予定のメソッド
  static Future<List<String>> getUserTeams(String userId) async { ... }
  static Future<void> switchTeam(String teamId) async { ... }
  static Future<bool> createTeam(String teamName) async { ... }
}
```

## リスク・課題

### 技術的リスク
- 大量のデータ移行時のパフォーマンス影響
- 既存機能への影響範囲

### 運用リスク
- チーム名の重複管理
- 不正なチーム作成・参加の防止
- データの誤削除防止

### ビジネスリスク
- 課金機能実装までのマネタイズ計画
- フリープランの制限バランス

## 実装優先順位

### 高優先度（フェーズ1）
1. チーム基本機能実装
2. 既存ユーザーの自動移行機能
3. チーム作成・表示UI

### 中優先度（フェーズ2）
1. メンバー招待機能
2. 権限管理機能
3. チーム管理UI

### 低優先度（フェーズ3）
1. 複数チーム対応
2. 課金機能統合
3. 高度な権限制御

## 関連課題
- UI/UX設計
- 課金システム統合
- メール送信機能
- プッシュ通知機能

---
**更新日**: 2024年9月4日  
**作成者**: AI Assistant  
**レビュー待ち**: 要件確認・優先順位調整
