#!/bin/bash
set -e

# Docker コンテナ名
CONTAINER_NAME="wordpress"

# Codespaces の自動発行 URL
if [ -n "$CODESPACE_NAME" ]; then
    WP_URL="https://${CODESPACE_NAME}-8000.app.github.dev/"
else
    WP_URL="http://localhost"
fi

echo "Using URL: $WP_URL"

# WordPress コンテナに入って実行する関数
wp() {
    docker compose exec $CONTAINER_NAME wp "$@"
}

# WordPress が未インストールなら自動インストール
if ! wp core is-installed --allow-root; then
    echo "Installing WordPress..."
    wp core install \
        --url="$WP_URL" \
        --title="My Site" \
        --admin_user="admin" \
        --admin_password="password" \
        --admin_email="admin@example.com" \
        --skip-email \
        --allow-root
fi

# 固定ページ作成
PAGES=("Home" "Blog")
for PAGE in "${PAGES[@]}"; do
    if ! wp post list --post_type=page --field=post_title | grep -qx "$PAGE"; then
        wp post create --post_type=page --post_title="$PAGE" --post_status=publish --allow-root
    fi
done

# フロントページ設定
HOME_ID=$(wp post list --post_type=page --field=ID --title="Home" --allow-root)
BLOG_ID=$(wp post list --post_type=page --field=ID --title="Blog" --allow-root)
wp option update show_on_front 'page' --allow-root
wp option update page_on_front $HOME_ID --allow-root
wp option update page_for_posts $BLOG_ID --allow-root

# パーマリンクを「投稿名」に設定
wp rewrite structure '/%postname%/' --hard --allow-root

echo "WordPress initialized successfully!"
