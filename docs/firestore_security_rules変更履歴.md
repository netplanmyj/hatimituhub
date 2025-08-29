# Firestoreセキュリティルール変更履歴

---

## 変更前（初期設定）
```firestore
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    // このルールは30日間のみ有効で、誰でも全データにアクセス可能
    match /{document=**} {
      allow read, write: if request.time < timestamp.date(2025, 9, 13);
    }
  }
}
```

- 認証不要で全データの読み書きが可能
- テスト・開発初期用
- 期限後は全アクセスが拒否される

---

## 変更後（安全運用用）
```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // ユーザー情報
    match /users/{userId} {
      allow read, update, delete: if request.auth.uid == userId;
      allow create: if request.auth.uid != null;
    }
    // チームデータ（個人チーム運用時は teamId = userId）
    match /team_data/{teamId}/{subCollection=**} {
      allow read, write: if request.auth.uid == teamId;
    }
  }
}
```

- 認証済みユーザーのみアクセス可能
- 自分のユーザー情報・自分のチームデータのみ読み書き可能
- その他のデータはアクセス不可
- 本番運用・個人チーム/チーム共有運用に対応

---

## 注意事項
- ルール変更後は未認証ユーザーはFirestoreにアクセスできません
- アプリ側でFirebase Authenticationによる認証が必須
- ルール変更直後は必ずアプリの動作確認を行うこと
