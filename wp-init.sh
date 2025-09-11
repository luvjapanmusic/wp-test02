#!/bin/bash
set -e

# Docker コンテナ名
CONTAINER_NAME="wordpress"

# Codespaces URL の自動取得
if [ -n "$GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN" ]; then
    WP_URL="https://$GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN"
else
    WP_URL="http://localhost"
fi

echo "Using URL: $WP_URL"

# WordPress コンテナに入って wp コマンドを実行する関数
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

    # 日本語に設定
    wp language core install ja --activate --allow-root
else
    echo "WordPress is already installed. Skipping installation."
fi

# Astra テーマインストール＆子テーマ作成
if ! wp theme is-installed astra --allow-root; then
    wp theme install astra --activate --allow-root
fi

CHILD_THEME_DIR=$(wp theme path astra-child --allow-root 2>/dev/null || echo "")
if [ -z "$CHILD_THEME_DIR" ]; then
    echo "Creating Astra child theme..."
    wp scaffold child-theme astra-child --parent_theme=astra --activate --allow-root
else
    echo "Astra child theme already exists. Activating..."
    wp theme activate astra-child --allow-root
fi

# Elementor プラグインインストール＆有効化
if ! wp plugin is-installed elementor --allow-root; then
    wp plugin install elementor --activate --allow-root
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
