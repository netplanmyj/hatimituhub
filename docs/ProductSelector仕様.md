# ProductSelector ウィジェット仕様

## 概要
- 商品区分（type）で商品リストを絞り込み、商品・数量を選択できる共通UI部品。
- 注文入力・明細追加/編集など複数画面で再利用可能。

## プロパティ
- `productTypes`: Firestoreから取得した商品区分（List<DocumentSnapshot>）
- `products`: Firestoreから取得した商品リスト（List<DocumentSnapshot>）
- `initialTypeId`: 初期選択区分ID（String?）
- `initialProductId`: 初期選択商品ID（String?）
- `initialQuantity`: 初期数量（int）
- `onChanged`: 選択変更時コールバック `(typeId, productId, quantity)`

## UI構成
- 商品区分選択（Dropdown）
- 商品選択（区分で絞り込んだDropdown）
- 数量入力（TextField/Stepper等）

## 利用例
```dart
ProductSelector(
  productTypes: productTypes,
  products: products,
  initialTypeId: typeId,
  initialProductId: productId,
  initialQuantity: quantity,
  onChanged: (newTypeId, newProductId, newQuantity) {
    // 選択値の更新処理
  },
)
```

## 備考
- Firestoreのスキーマ（type, typeLabel等）に依存
- UI/ロジックは今後拡張可能
