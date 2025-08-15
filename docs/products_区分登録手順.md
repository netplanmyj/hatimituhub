# Firestore productsコレクション 区分コード登録手順

## 概要
`products` コレクションには区分コード（type）のみ登録し、区分名は `types` コレクションで管理します。

## productsコレクションへの追加方法
1. Firebaseコンソールで「Firestore Database」を開く
2. 左メニューから `products` コレクションを選択
3. 「ドキュメントを追加」ボタンをクリック
4. 必要なフィールドを入力
   - `name`（文字列）: 商品名
   - `price`（数値）: 価格
   - `createdAt`（タイムスタンプ）: 登録日時
   - `type`（数値）: 区分コード（例: 1）
5. 「保存」

## 区分名の管理方法
区分名（typeLabel）は `types` コレクションで管理します。詳細は `types_コレクション作成手順.md` を参照してください。

---

この手順で区分コード付きの商品データをFirestoreに登録できます。
