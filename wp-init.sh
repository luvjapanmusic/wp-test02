#!/bin/bash
set -e

# Docker コンテナ名
CONTAINER_NAME="wordpress"

# WordPress URL（Codespaces 内部アクセス用）
WP_URL="http://localhost:8000"

echo "Using internal URL: $WP_URL"

# WordPress コンテナに入って wp コマンドを実行する関数
wp() {
    docker compose exec $CONTAINER_NAME wp "$@"
}

# wp-config.php がない場合のみ作成
if [ ! -f ./wordpress/wp-config.php ]; then
    echo "Creating wp-config.php..."
    wp config create \
        --dbname=wordpress \
        --dbuser=root \
        --dbpass=root \
        --dbhost=db \
        --locale=ja \
        --skip-check \
        --allow-root
fi

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
    if ! wp post list --post_type=page --field=post_title --allow-root | grep -qx "$PAGE"; then
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

# Astra テーマと子テーマ作成
if ! wp theme is-installed astra --allow-root; then
    echo "Installing Astra theme..."
    wp theme install astra --activate --allow-root
fi

if ! wp theme is-installed astra-child --allow-root; then
    echo "Creating Astra child theme..."
    wp theme generate-child astra astra-child --activate --allow-root
fi

# Elementor プラグインを最新バージョンでインストール
if ! wp plugin is-installed elementor --allow-root; then
    echo "Installing Elementor plugin..."
    wp plugin install elementor --activate --allow-root
fi

echo "WordPress initialized successfully!"
echo "Browser URL: https://<your-codespaces-url>"
