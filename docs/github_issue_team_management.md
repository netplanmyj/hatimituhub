# [FEATURE] チーム管理機能の実装

## 📋 概要
現在の`/team_data/{userId}`構造を拡張し、真のマルチテナント対応チーム管理機能を段階的に実装する

## 🎯 背景・目的
- 現在は個人利用（userId = teamId）のみ対応
- 将来的に複数ユーザーでの協調作業を可能にしたい
- 課金モデル導入に向けた基盤整備

## 📊 現在の実装状況
✅ 完了済み
- FirestoreService による統一的なデータアクセス
- team_data/{teamId} 構造での個人単位データ分離
- 全CRUD操作のマルチテナント対応

## 🚀 実装計画

### Phase 1: 基本チーム機能 (MVP) 🥇
**目標**: 1ユーザー1チームでの運用開始

**新規データ構造**:
```
/teams/{teamId}/
  - name: string (重複不可)
  - ownerId: string 
  - createdAt: timestamp
  - memberCount: number
  - status: "active" | "inactive"

/team_members/{userId}/
  - teamId: string
  - role: "owner" | "member"
  - joinedAt: timestamp
```

**実装タスク**:
- [ ] チーム作成API
- [ ] チーム名重複チェック機能  
- [ ] ユーザー⇔チーム関連付け管理
- [ ] チーム情報表示UI
- [ ] 既存ユーザーの自動移行機能

**制約**:
- 1ユーザー = 1チーム所属のみ
- チーム作成は1回限り
- メンバー招待機能は非実装

### Phase 2: チームメンバー管理 🥈  
**目標**: 複数ユーザーでの協調作業

**新規機能**:
- [ ] 招待リンク生成・管理
- [ ] メール招待機能
- [ ] メンバー一覧・削除機能
- [ ] 役割・権限管理

**データ構造拡張**:
```
/team_invitations/{invitationId}/
  - teamId: string
  - inviterUserId: string  
  - inviteeEmail: string
  - status: "pending" | "accepted" | "rejected"
  - expiresAt: timestamp
```

### Phase 3: 課金・複数チーム対応 🥉
**目標**: 収益化とスケール対応

**機能**:
- [ ] フリープラン: 1チーム制限
- [ ] 有料プラン: 複数チーム対応  
- [ ] チーム切り替えUI
- [ ] プラン管理機能

## 🛠 技術実装詳細

### FirestoreService拡張案
```dart
class FirestoreService {
  // 後方互換性を維持しつつ拡張
  static String? get currentTeamId => getCurrentUserTeamId();
  
  // 新規メソッド
  static Future<String?> createTeam(String teamName) async { ... }
  static Future<List<Team>> getUserTeams(String userId) async { ... }
  static Future<bool> isTeamNameAvailable(String name) async { ... }
}
```

### マイグレーション戦略
1. **既存データ保持**: `/team_data/{userId}` はそのまま維持
2. **自動チーム作成**: 既存ユーザーに「{ユーザー名}のチーム」を自動生成
3. **段階的移行**: 新機能は opt-in で段階的に有効化

## ⚠️ リスク・課題

### 技術的リスク
- 大量データ移行時のパフォーマンス影響
- 既存機能への予期しない副作用

### 運用リスク  
- チーム名の不正利用・スパム対策
- データ誤削除の防止策

### ビジネスリスク
- 課金機能完成までの収益化計画
- フリープラン制限の適切なバランス

## 🎯 成功基準

### Phase 1
- [ ] 既存ユーザーが無停止でチーム機能を利用開始
- [ ] チーム作成・表示機能が正常動作
- [ ] パフォーマンス劣化なし

### Phase 2  
- [ ] チーム招待・参加フローが完動
- [ ] メンバー管理機能が安定運用
- [ ] 権限制御が適切に動作

### Phase 3
- [ ] 複数チーム切り替えが円滑
- [ ] 課金システムとの統合完了
- [ ] スケーラビリティの確保

## 📅 想定スケジュール
- **Phase 1**: 2-3週間 (設計1週間 + 実装2週間)
- **Phase 2**: 3-4週間 (招待機能複雑のため)  
- **Phase 3**: 4-6週間 (課金統合含む)

## 🔗 関連Issue・PR
- 関連する設計ドキュメント: `docs/team_management_specification.md`
- FirestoreService実装: (既存実装済み)

## 📝 補足事項
- UI/UXデザインは別途検討が必要
- メール送信機能の選定・実装が必要 (Phase 2)
- 課金システムの選定・統合が必要 (Phase 3)

---
**Priority**: High  
**Complexity**: High  
**Labels**: `enhancement`, `team-feature`, `multi-tenant`, `backend`
