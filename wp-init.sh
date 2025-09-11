#!/bin/bash
set -e

echo "Waiting for database to be ready..."
until wp db check --path=/var/www/html --allow-root; do
  sleep 5
done

if ! wp core is-installed --path=/var/www/html --allow-root; then
  echo "Installing WordPress..."
  wp core install \
    --url=http://localhost \
    --title="My WordPress Site" \
    --admin_user=admin \
    --admin_password=password \
    --admin_email=admin@example.com \
    --path=/var/www/html \
    --allow-root
fi

# 固定ページ Home と Blog を作成（存在しなければ）
if ! wp post list --post_type=page --pagename=home --format=ids --path=/var/www/html --allow-root | grep -q .; then
  wp post create --post_type=page --post_title=Home --post_status=publish --post_name=home --path=/var/www/html --allow-root
fi

if ! wp post list --post_type=page --pagename=blog --format=ids --path=/var/www/html --allow-root | grep -q .; then
  wp post create --post_type=page --post_title=Blog --post_status=publish --post_name=blog --path=/var/www/html --allow-root
fi

# ID を取得
HOME_ID=$(wp post list --post_type=page --pagename=home --format=ids --path=/var/www/html --allow-root)
BLOG_ID=$(wp post list --post_type=page --pagename=blog --format=ids --path=/var/www/html --allow-root)

# 表示設定
wp option update show_on_front page --path=/var/www/html --allow-root
wp option update page_on_front $HOME_ID --path=/var/www/html --allow-root
wp option update page_for_posts $BLOG_ID --path=/var/www/html --allow-root

# サンプルページ削除（Home, Blog は除外）
wp post delete $(wp post list --post_type=page --format=ids --path=/var/www/html --allow-root | grep -v -E "($HOME_ID|$BLOG_ID)") --force --allow-root || true

# パーマリンクを「投稿名」に設定
wp option update permalink_structure '/%postname%/' --path=/var/www/html --allow-root

echo "✅ WordPress initialization completed!"
