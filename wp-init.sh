#!/bin/bash
set -e

# DB 接続待機
echo "Waiting for database..."
until wp db check >/dev/null 2>&1; do
  sleep 3
done

# WordPress が未インストールなら自動インストール
if ! wp core is-installed >/dev/null 2>&1; then
  wp core install \
    --url="https://automatic-waffle-4pgpq9qrxw3jv4p-8000.app.github.dev" \
    --title="My WP Site" \
    --admin_user="admin" \
    --admin_password="admin123" \
    --admin_email="admin@example.com"
fi

# 固定ページ作成
HOME_PAGE_ID=$(wp post create --post_type=page --post_title='Home' --post_status=publish --porcelain)
BLOG_PAGE_ID=$(wp post create --post_type=page --post_title='Blog' --post_status=publish --porcelain)

# フロントページ設定
wp option update show_on_front 'page'
wp option update page_on_front "$HOME_PAGE_ID"
wp option update page_for_posts "$BLOG_PAGE_ID"

# パーマリンクを「投稿名」に設定
wp rewrite structure '/%postname%/' --hard
wp rewrite flush --hard

echo "WordPress initial setup completed!"
