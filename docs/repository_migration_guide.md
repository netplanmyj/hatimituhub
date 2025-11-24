# リポジトリPublic化のための移行ガイド

## 背景
現在のリポジトリにはGit履歴に個人のメールアドレス（user@example.com）が含まれているため、完全にクリーンにするには新しいリポジトリへの移行を推奨します。

## オプション1: 新規リポジトリ作成（推奨）

### 手順

1. **新しいGitHub Publicリポジトリを作成**
   - Repository name: `hatimituhub-public` など
   - Public設定
   - 初期化なし（README等を作成しない）

2. **現在のコードを新しいリポジトリにプッシュ**
```bash
# 一時的なクローンを作成（履歴なし）
cd /tmp
mkdir hatimituhub-clean
cd hatimituhub-clean

# 現在のコードをコピー（.gitを除外）
rsync -av --exclude='.git' /Users/uedakazuaki/GitHub/Flutter/hatimituhub/ .

# 新しいGitリポジトリとして初期化
git init
git add .
git commit -m "Initial commit"

# 新しいリモートリポジトリに接続
git remote add origin https://github.com/netplanmyj/hatimituhub-public.git
git branch -M main
git push -u origin main
```

3. **GitHub Settings確認**
   - Issues/PRテンプレート再設定
   - Branch protection rules設定
   - GitHub Actions secrets設定（必要に応じて）

### メリット
- ✅ 完全にクリーンな履歴
- ✅ 個人情報が一切含まれない
- ✅ 最新のコードのみで軽量

### デメリット
- ❌ 既存のissues/PR履歴は移行不可
- ❌ コミット履歴が失われる

---

## オプション2: 履歴を書き換え（非推奨）

`git filter-repo`で作者情報を書き換える方法もありますが:

```bash
# 注意: これは危険な操作です
git filter-repo --email-callback '
  return b"info@example.com" if email == b"kazuaki.ueda@gmail.com" else email
'
```

### デメリット
- ⚠️ すべてのコミットハッシュが変更される
- ⚠️ 既存のブランチ/PR/issuesの参照が壊れる
- ⚠️ force pushが必要（協力者がいる場合問題）
- ⚠️ 完全に元に戻せない

---

## オプション3: そのままPublic化（最も簡単）

### 前提
- Gitコミット履歴の作者情報は**技術的に問題なし**
- メールアドレスは既にGitHubプロフィールで公開されている
- 個人を特定する機密情報（住所、電話番号、パスワード等）は含まれていない

### 確認済み事項
- ✅ コード内に実際の顧客データなし（フィールド名のみ）
- ✅ Firebase API Keys（Web APIキーは公開OK）
- ✅ パスワード/秘密鍵なし
- ✅ `.gitignore`で適切に保護

### 手順
```bash
# GitHubでリポジトリ設定 → Settings → Danger Zone → Change visibility → Make public
```

---

## 推奨: オプション1（新規リポジトリ）

個人のメールアドレスを完全に削除したい場合は、新しいリポジトリを作成するのが最も安全で確実です。

## 最終チェックリスト

Public化前に以下を確認:

### コード
- [ ] `.env`ファイルが`.gitignore`に含まれている
- [ ] API秘密鍵/トークンがハードコードされていない
- [ ] `google-services.json`等の設定ファイル（Web APIキーのみなら問題なし）
- [ ] 実際の顧客データがコードに含まれていない

### Git履歴
- [ ] `git log --all -p | grep -E '(password|secret|private_key|token)'` で機密情報を検索
- [ ] テストデータに実在の個人情報が含まれていないか確認

### GitHub
- [ ] Issues/PRに個人情報が含まれていないか確認
- [ ] Discussionsに機密情報がないか確認
- [ ] Actionsのログに機密情報が出力されていないか確認

### Firebase
- [ ] Firebase Securityルールが適切に設定されている
- [ ] 本番環境のAPIキーが適切に制限されている（HTTPリファラー、バンドルID等）
- [ ] Firestoreに実データがある場合、公開リポジトリとの紐付けに問題ないか確認

---

## まとめ

**最も安全な方法**: 新規リポジトリ作成（オプション1）を推奨します。

理由:
- Git履歴から個人のメールアドレスを完全に削除可能
- クリーンなコミット履歴でスタート
- 意図しない情報漏洩のリスクがゼロ

必要に応じて、古いprivateリポジトリはアーカイブとして保持できます。
