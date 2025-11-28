# マルチテナント仕様書

## 概要

はちみつハブをマルチテナント対応のSaaSアプリとして再設計します。
特殊な配布方法を避け、一般的なApp Store/Play Store経由での配布を実現します。

## ビジネスモデル

### 料金プラン

| プラン | 月額料金 | 機能 |
|--------|---------|------|
| **無料プラン** | ¥0 | 基本的な注文管理、顧客管理、商品管理 |
| **プレミアムプラン** | ¥3,000 | 無料プラン + PDF請求書出力、高度な分析、データエクスポート |

### 機能制限

#### 無料プラン制限
- [ ] 月間注文数: 50件まで
- [ ] チームメンバー数: 3人まで
- [ ] データ保存期間: 6ヶ月
- [ ] PDF請求書出力: ✗
- [ ] CSVエクスポート: ✗
- [ ] 高度なレポート: ✗

#### プレミアムプラン
- [ ] 月間注文数: 無制限
- [ ] チームメンバー数: 無制限
- [ ] データ保存期間: 無期限
- [ ] PDF請求書出力: ✓
- [ ] CSVエクスポート: ✓
- [ ] 高度なレポート: ✓

## データ構造

### Firebaseコレクション構成

```
/users/{userId}
  - email: string
  - displayName: string
  - photoURL: string
  - createdAt: timestamp
  - subscriptionPlan: string ("free" | "premium")
  - subscriptionStatus: string ("active" | "canceled" | "expired")
  - subscriptionExpiresAt: timestamp
  - teams: array<string> // 所属チームIDのリスト
  - activeTeamId: string // 現在選択中のチーム

/teams/{teamId}
  - name: string
  - ownerId: string // チーム作成者のuserId
  - createdAt: timestamp
  - updatedAt: timestamp
  - memberCount: number
  - subscriptionPlan: string // チーム単位のサブスク
  - status: string ("active" | "suspended" | "deleted")
  - settings: map
    - timezone: string
    - currency: string
    - dateFormat: string

/team_members/{userId}
  - teamId: string
  - role: string ("owner" | "admin" | "member" | "readonly")
  - joinedAt: timestamp
  - invitedBy: string // 招待者のuserId
  - status: string ("active" | "pending" | "inactive")
  - permissions: array<string> // カスタム権限

/team_invitations/{invitationId}
  - teamId: string
  - inviterUserId: string
  - inviteeEmail: string
  - role: string
  - status: string ("pending" | "accepted" | "rejected" | "expired")
  - createdAt: timestamp
  - expiresAt: timestamp
  - invitationCode: string // 招待用のユニークコード

/team_data/{teamId}/customers/{customerId}
  - name: string
  - email: string
  - phone: string
  - address: map
  - customerType: string
  - taxType: string
  - notes: string
  - createdAt: timestamp
  - updatedAt: timestamp
  - createdBy: string // userId
  - status: string ("active" | "inactive")

/team_data/{teamId}/products/{productId}
  - name: string
  - price: number
  - unit: string
  - category: string
  - productType: string
  - description: string
  - taxRate: number
  - sku: string
  - status: string ("active" | "discontinued")
  - createdAt: timestamp
  - updatedAt: timestamp

/team_data/{teamId}/orders/{orderId}
  - orderNumber: string
  - customerId: string
  - customerName: string // 非正規化
  - orderDate: timestamp
  - deliveryDate: timestamp
  - items: array<map>
    - productId: string
    - productName: string
    - quantity: number
    - unitPrice: number
    - subtotal: number
  - subtotal: number
  - taxAmount: number
  - total: number
  - status: string ("draft" | "confirmed" | "delivered" | "invoiced" | "paid" | "canceled")
  - notes: string
  - createdAt: timestamp
  - updatedAt: timestamp
  - createdBy: string

/team_data/{teamId}/product_categories/{categoryId}
  - name: string
  - displayOrder: number
  - status: string

/team_data/{teamId}/product_types/{typeId}
  - name: string
  - displayOrder: number
  - status: string

/team_data/{teamId}/customer_types/{typeId}
  - name: string
  - displayOrder: number
  - status: string

/team_data/{teamId}/taxes/{taxId}
  - name: string
  - rate: number
  - isDefault: boolean
  - status: string

/subscriptions/{subscriptionId}
  - userId: string
  - teamId: string // どのチームのサブスクか
  - plan: string ("free" | "premium")
  - status: string ("active" | "canceled" | "past_due" | "expired")
  - startDate: timestamp
  - currentPeriodStart: timestamp
  - currentPeriodEnd: timestamp
  - canceledAt: timestamp
  - paymentMethod: string
  - stripeCustomerId: string // Stripe連携用
  - stripeSubscriptionId: string
```

## 認証・認可フロー

### 1. ユーザー登録

```
1. Googleアカウントでサインイン (Firebase Authentication)
2. 新規ユーザーの場合:
   a. /users/{userId} ドキュメント作成
   b. デフォルトチーム作成 (チーム名: "{displayName}のチーム")
   c. /teams/{teamId} ドキュメント作成
   d. /team_members/{userId} ドキュメント作成 (role: "owner")
   e. 無料プランで開始 (subscriptionPlan: "free")
3. 既存ユーザーの場合:
   a. 最後に使用したチームを activeTeamId として設定
```

### 2. チーム作成

```
1. ユーザーが新規チーム作成をリクエスト
2. プラン制限チェック:
   - 無料プラン: 1チームのみ
   - プレミアムプラン: 無制限
3. チーム作成:
   - /teams/{newTeamId} 作成
   - /team_members/{userId} 更新 (新チームに紐付け)
   - activeTeamId を新チームに設定
```

### 3. チームメンバー招待

```
1. オーナー/管理者が招待リンク生成
2. /team_invitations/{invitationId} 作成
3. 招待メール送信 (オプション)
4. 被招待者が招待コードでアクセス
5. 承諾で /team_members/{userId} 作成
6. チームのmemberCount インクリメント
```

## Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ヘルパー関数
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function getUserData() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
    }
    
    function getTeamMember() {
      return get(/databases/$(database)/documents/team_members/$(request.auth.uid)).data;
    }
    
    function isTeamMember(teamId) {
      return isAuthenticated() && 
             exists(/databases/$(database)/documents/team_members/$(request.auth.uid)) &&
             getTeamMember().teamId == teamId &&
             getTeamMember().status == 'active';
    }
    
    function isTeamOwner(teamId) {
      return isTeamMember(teamId) && getTeamMember().role == 'owner';
    }
    
    function isTeamAdmin(teamId) {
      return isTeamMember(teamId) && 
             (getTeamMember().role == 'owner' || getTeamMember().role == 'admin');
    }
    
    function hasWritePermission(teamId) {
      return isTeamMember(teamId) && 
             getTeamMember().role != 'readonly';
    }
    
    // ユーザー情報
    match /users/{userId} {
      allow read: if isAuthenticated() && request.auth.uid == userId;
      allow create: if isAuthenticated() && request.auth.uid == userId;
      allow update: if isAuthenticated() && request.auth.uid == userId;
      allow delete: if false; // ユーザー削除は管理機能で対応
    }
    
    // チーム情報
    match /teams/{teamId} {
      allow read: if isTeamMember(teamId);
      allow create: if isAuthenticated();
      allow update: if isTeamAdmin(teamId);
      allow delete: if isTeamOwner(teamId);
    }
    
    // チームメンバー
    match /team_members/{userId} {
      allow read: if isAuthenticated() && 
                     (request.auth.uid == userId || isTeamMember(resource.data.teamId));
      allow create: if isAuthenticated();
      allow update: if isTeamAdmin(resource.data.teamId);
      allow delete: if isTeamOwner(resource.data.teamId);
    }
    
    // チーム招待
    match /team_invitations/{invitationId} {
      allow read: if isAuthenticated() && 
                     (isTeamMember(resource.data.teamId) || 
                      request.auth.token.email == resource.data.inviteeEmail);
      allow create: if isTeamAdmin(request.resource.data.teamId);
      allow update: if isTeamAdmin(resource.data.teamId) ||
                       request.auth.token.email == resource.data.inviteeEmail;
      allow delete: if isTeamAdmin(resource.data.teamId);
    }
    
    // チームデータ（顧客、商品、注文など）
    match /team_data/{teamId}/{document=**} {
      allow read: if isTeamMember(teamId);
      allow write: if hasWritePermission(teamId);
    }
    
    // サブスクリプション
    match /subscriptions/{subscriptionId} {
      allow read: if isAuthenticated() && 
                     (resource.data.userId == request.auth.uid ||
                      isTeamOwner(resource.data.teamId));
      allow write: if false; // サーバー側（Cloud Functions）のみ更新可能
    }
  }
}
```

## サブスクリプション管理

### Stripe連携

1. **プラン選択**: ユーザーがプレミアムプランを選択
2. **Stripe Checkout**: Stripe Checkoutセッション作成
3. **支払い完了**: Webhookで /subscriptions 更新
4. **機能アンロック**: subscriptionStatus を確認して機能制限解除

### Cloud Functions (例)

```javascript
// Stripe Webhookハンドラー
exports.handleStripeWebhook = functions.https.onRequest(async (req, res) => {
  const event = req.body;
  
  switch (event.type) {
    case 'checkout.session.completed':
      // サブスクリプション作成
      await createSubscription(event.data.object);
      break;
    case 'customer.subscription.updated':
      // サブスクリプション更新
      await updateSubscription(event.data.object);
      break;
    case 'customer.subscription.deleted':
      // サブスクリプションキャンセル
      await cancelSubscription(event.data.object);
      break;
  }
  
  res.json({received: true});
});
```

## 機能制限の実装

### アプリ内チェック

```dart
class SubscriptionService {
  static Future<bool> isPremiumUser() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;
    
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    
    return userDoc.data()?['subscriptionPlan'] == 'premium' &&
           userDoc.data()?['subscriptionStatus'] == 'active';
  }
  
  static Future<bool> canCreateOrder() async {
    if (await isPremiumUser()) return true;
    
    // 無料プラン: 月間50件制限
    final teamId = await getCurrentTeamId();
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    
    final ordersCount = await FirebaseFirestore.instance
        .collection('team_data')
        .doc(teamId)
        .collection('orders')
        .where('createdAt', isGreaterThanOrEqualTo: startOfMonth)
        .count()
        .get();
    
    return ordersCount.count! < 50;
  }
  
  static Future<bool> canExportPDF() async {
    return await isPremiumUser();
  }
}
```

## マイグレーション計画

### 既存ユーザーの移行

現在のデータ構造: `/team_data/{userId}/...`
新しい構造: `/team_data/{teamId}/...`

#### 移行手順

1. **準備**:
   - Cloud Functionsで一括移行スクリプト作成
   - バックアップ取得

2. **移行処理**:
```javascript
// 既存ユーザーのteamId = userId として移行
for (const user of existingUsers) {
  // チーム作成（teamId = userId）
  await createTeam(user.uid, `${user.displayName}のチーム`);
  
  // team_members 作成
  await createTeamMember(user.uid, user.uid, 'owner');
  
  // データパスは変更なし（teamId = userId のため）
}
```

3. **検証**:
   - 移行後のデータ整合性チェック
   - 各機能の動作確認

## 実装フェーズ

### Phase 1: 基本マルチテナント対応（MVP）
**目標**: 1ユーザー1チームでの運用開始

- [ ] ユーザー登録時のチーム自動作成
- [ ] チーム情報表示
- [ ] activeTeamId ベースのデータアクセス
- [ ] Firestore Security Rules 更新
- [ ] 既存ユーザーの自動移行

### Phase 2: チーム管理機能
**目標**: 複数ユーザーでのチーム運用

- [ ] メンバー招待機能
- [ ] 招待承諾/拒否
- [ ] メンバー一覧表示
- [ ] 権限管理（オーナー/管理者/メンバー/読取のみ）
- [ ] メンバー削除

### Phase 3: サブスクリプション機能
**目標**: 有料プラン導入

- [ ] Stripe連携
- [ ] プラン選択画面
- [ ] 支払い処理
- [ ] 機能制限の実装
- [ ] サブスク管理画面（解約・プラン変更）

### Phase 4: 追加機能
**目標**: プレミアム機能の充実

- [ ] PDF請求書出力（プレミアム限定）
- [ ] CSVエクスポート（プレミアム限定）
- [ ] 高度なレポート・分析
- [ ] データバックアップ・リストア

## UI/UX設計

### チーム切り替えUI

```
AppBar
  ├── チーム名表示（現在のチーム）
  ├── チーム切り替えドロップダウン（Phase 2以降）
  └── 設定メニュー
       ├── チーム設定
       ├── メンバー管理
       └── サブスクリプション管理
```

### プラン表示

```
無料プラン:
  - バッジ表示: "FREE"
  - 制限表示: "今月の注文数: 23/50"
  - アップグレードボタン

プレミアムプラン:
  - バッジ表示: "PREMIUM"
  - 制限なし表示: "無制限"
```

## セキュリティ考慮事項

1. **データ分離**: チーム間でのデータ漏洩防止
2. **権限制御**: 役割に応じた適切なアクセス制限
3. **監査ログ**: 重要操作の記録
4. **不正利用防止**: サブスクキャンセル後の機能制限

## パフォーマンス最適化

1. **インデックス**:
   - `team_members`: [teamId, status]
   - `team_data/{teamId}/orders`: [customerId, orderDate]
   - `team_invitations`: [teamId, status]

2. **キャッシュ**:
   - チーム情報: ローカルストレージ
   - サブスク状態: メモリキャッシュ

## リリース計画

### Phase 1リリース（MVP）
- ターゲット: 2025年12月
- 内容: 基本マルチテナント対応、無料プランのみ

### Phase 2リリース
- ターゲット: 2026年1月
- 内容: チーム管理機能追加

### Phase 3リリース（収益化）
- ターゲット: 2026年2月
- 内容: サブスクリプション機能、プレミアムプラン開始

---

**作成日**: 2025年11月28日
**ステータス**: レビュー待ち
**関連Issue**: #107
