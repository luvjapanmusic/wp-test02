#!/bin/bash
set -e

# Docker コンテナ名
CONTAINER_NAME="wordpress"

# Codespaces URL の自動取得
if [ -n "$GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN" ]; then
    WP_URL="http://localhost:8000"
    echo "Using internal URL: $WP_URL"
else
    WP_URL="http://localhost"
fi

# WordPress コンテナに入って wp コマンドを実行する関数
wp() {
    docker compose exec $CONTAINER_NAME wp "$@"
}

# WordPress が未インストールなら自動インストール
if ! wp core is-installed --allow-root; then
    echo "Installing WordPress..."
    wp core download --locale=ja --allow-root
    wp config create \
        --dbname=wordpress \
        --dbuser=root \
        --dbpass=root \
        --dbhost=db \
        --allow-root
    wp db create --allow-root
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

# Astraテーマインストールと有効化
if ! wp theme is-installed astra --allow-root; then
    echo "Installing Astra theme..."
    wp theme install astra --activate --allow-root
fi

# Astra 子テーマ作成
CHILD_THEME_DIR="./wordpress/wp-content/themes/astra-child"
if [ ! -d "$CHILD_THEME_DIR" ]; then
    echo "Creating Astra child theme..."
    mkdir "$CHILD_THEME_DIR"
    cat > "$CHILD_THEME_DIR/style.css" <<EOL
/*
Theme Name: Astra Child
Template: astra
Text Domain: astra-child
*/
EOL

    cat > "$CHILD_THEME_DIR/functions.php" <<'EOL'
<?php
add_action( 'wp_enqueue_scripts', function() {
    wp_enqueue_style( 'astra-parent-style', get_template_directory_uri() . '/style.css' );
} );
EOL

    wp theme activate astra-child --allow-root
fi

# Elementor 最新版インストールと有効化
if ! wp plugin is-installed elementor --allow-root; then
    echo "Installing Elementor plugin..."
    wp plugin install elementor --activate --allow-root
fi

echo "WordPress initialized successfully!"
