# はちみつハブ (Hatimituhub)

マルチテナント対応の販売管理アプリ

## 概要

はちみつハブは、農家や小規模事業者向けの汎用的な販売管理アプリです。
顧客管理、商品管理、注文管理、請求書発行機能を備えています。

### 主な機能

- 🔐 Googleアカウント認証
- 👥 チーム管理（マルチテナント対応）
- 📦 商品管理（カテゴリ・区分管理）
- 👤 顧客管理（顧客区分・税区分）
- 📝 注文管理（ページネーション対応）
- 📄 PDF請求書出力（プレミアムプラン）
- 📊 データエクスポート（プレミアムプラン）

## 料金プラン

| プラン | 月額 | 特徴 |
|--------|------|------|
| **無料** | ¥0 | 月間50件の注文、基本機能利用可 |
| **プレミアム** | ¥3,000 | 無制限の注文、PDF出力、高度な分析 |

## 技術スタック

- **フレームワーク**: Flutter 3.35.7+
- **認証**: Firebase Authentication
- **データベース**: Cloud Firestore
- **状態管理**: Provider
- **PDF生成**: pdf, printing パッケージ
- **決済**: Stripe (予定)

## プロジェクト構成

```
lib/
├── main.dart                 # アプリエントリーポイント
├── flavor_config.dart        # 環境設定（dev/prod）
├── firebase_options.dart     # Firebase設定
├── models/                   # データモデル
├── services/                 # ビジネスロジック
│   ├── firestore_service.dart
│   ├── auth_service.dart
│   └── invoice_service.dart
├── widgets/                  # 再利用可能なウィジェット
└── *.dart                    # 各画面

docs/
├── multitenancy_specification.md   # マルチテナント仕様書
├── FLAVORS.md                      # 環境管理ガイド
├── generic_order_app_design.md     # 汎用化設計
└── ...                             # その他ドキュメント
```

## セットアップ

### 前提条件

- Flutter 3.35.7以上
- Dart 3.9.2以上
- Firebase プロジェクト（dev/prod）

### 環境構築

1. リポジトリをクローン:
```bash
git clone https://github.com/netplanmyj/hatimituhub.git
cd hatimituhub
```

2. 依存関係をインストール:
```bash
flutter pub get
```

3. Firebase設定:
   - `docs/FLAVORS.md` を参照してFirebaseプロジェクトを設定

4. iOS依存関係 (macOS):
```bash
cd ios && pod install && cd ..
```

### 実行方法

#### 開発環境（dev）
```bash
# Android
flutter run --flavor dev --dart-define=FLAVOR=dev

# iOS
flutter run --flavor dev --dart-define=FLAVOR=dev
```

#### 本番環境（prod）
```bash
# Android
flutter run --flavor prod --dart-define=FLAVOR=prod

# iOS
flutter run --flavor prod --dart-define=FLAVOR=prod
```

### テスト

```bash
flutter test
```

## 開発ガイドライン

### ブランチ戦略

- `main`: 本番環境用
- `develop`: 開発環境用（廃止予定）
- `feature/*`: 新機能開発
- `fix/*`: バグ修正
- `chore/*`: リファクタリング・ドキュメント更新

### コミットメッセージ

Conventional Commits形式を推奨:
```
feat: 新機能追加
fix: バグ修正
docs: ドキュメント更新
chore: その他の変更
test: テスト追加・修正
```

### Pull Request

- CI（GitHub Actions）が自動実行
- Copilot Code Reviewが自動実行
- 全テスト通過後にマージ可能

## ドキュメント

詳細な仕様やガイドは `docs/` を参照:

- [マルチテナント仕様](docs/multitenancy_specification.md) - データ構造、認証フロー、サブスク管理
- [環境管理](docs/FLAVORS.md) - dev/prod環境の切り替え方法
- [汎用化設計](docs/generic_order_app_design.md) - 他業種への展開方針
- [リリースチェックリスト](docs/release_checklist.md) - App Store/Play Store配布手順

## 貢献

このプロジェクトへの貢献を歓迎します！

1. このリポジトリをフォーク
2. フィーチャーブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット (`git commit -m 'feat: Add amazing feature'`)
4. ブランチにプッシュ (`git push origin feature/amazing-feature`)
5. Pull Requestを作成

## ライセンス

このプロジェクトはプライベートリポジトリです。無断での使用・配布を禁止します。

## 連絡先

- Issue: [GitHub Issues](https://github.com/netplanmyj/hatimituhub/issues)
- Email: （必要に応じて記載）

---

**現在のステータス**: Phase 1実装中（マルチテナント基本機能）
**最終更新**: 2025年11月28日
