#!/bin/bash
set -e

WP_PATH=/var/www/html

# WordPress がまだ存在しない場合にダウンロード
if [ ! -f "$WP_PATH/wp-config.php" ]; then
    echo "Downloading WordPress..."
    wp core download --path="$WP_PATH"
fi

# WordPress のセットアップ（DB接続情報は environment で自動設定）
if ! wp core is-installed --path="$WP_PATH"; then
    echo "Installing WordPress..."
    wp core install \
      --url="http://localhost" \
      --title="My WordPress Site" \
      --admin_user="admin" \
      --admin_password="password" \
      --admin_email="admin@example.com" \
      --path="$WP_PATH"
fi

# Home と Blog ページ作成
if [ $(wp post list --post_type=page --format=ids --path="$WP_PATH" | wc -l) -eq 0 ]; then
    echo "Creating Home and Blog pages..."
    HOME_ID=$(wp post create --post_type=page --post_title=Home --post_status=publish --post_name=home --porcelain --path="$WP_PATH")
    BLOG_ID=$(wp post create --post_type=page --post_title=Blog --post_status=publish --post_name=blog --porcelain --path="$WP_PATH")
    wp option update show_on_front page --path="$WP_PATH"
    wp option update page_on_front "$HOME_ID" --path="$WP_PATH"
    wp option update page_for_posts "$BLOG_ID" --path="$WP_PATH"
fi

# パーマリンクを「投稿名」に設定
wp rewrite structure '/%postname%/' --hard --path="$WP_PATH"

echo "WordPress initialization completed."
exec "$@"
