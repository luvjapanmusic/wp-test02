#!/bin/bash
set -e

# Docker コンテナ名
CONTAINER_NAME="wordpress"

# Codespaces URL の自動取得（ブラウザ用）
if [ -n "$GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN" ]; then
    CODESPACES_URL="https://$GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN"
else
    CODESPACES_URL="http://localhost:8000"
fi

echo "Browser URL: $CODESPACES_URL"

# WordPress コンテナに入って wp コマンドを実行する関数
wp() {
    docker compose exec $CONTAINER_NAME wp "$@"
}

# HTTP_HOST 未定義を回避する wp-config.php の追加設定
docker compose exec $CONTAINER_NAME bash -c "grep -q 'HTTP_HOST' /var/www/html/wp-config.php || echo \"if (!isset(\$_SERVER['HTTP_HOST'])) { \$_SERVER['HTTP_HOST'] = parse_url('$CODESPACES_URL', PHP_URL_HOST); }\" >> /var/www/html/wp-config.php"

# WordPress が未インストールなら自動インストール
if ! wp core is-installed --allow-root; then
    echo "Installing WordPress..."
    wp core download --locale=ja --force --allow-root
    wp config create \
        --dbname=wordpress \
        --dbuser=wordpress \
        --dbpass=wordpress \
        --dbhost=db \
        --locale=ja \
        --allow-root
    wp core install \
        --url="http://localhost:8000" \
        --title="My Site" \
        --admin_user="admin" \
        --admin_password="password" \
        --admin_email="admin@example.com" \
        --skip-email \
        --allow-root
fi

# Astra テーマと子テーマ
ASTRA_LATEST=$(wp theme list --field=name --status=inactive | grep -i astra || echo "")
if [ -z "$ASTRA_LATEST" ]; then
    echo "Installing Astra theme..."
    wp theme install astra --activate --allow-root
fi

if [ ! -d "/var/www/html/wp-content/themes/astra-child" ]; then
    echo "Creating Astra child theme..."
    wp scaffold child-theme astra-child --theme=Astra --activate --allow-root
fi

# Elementor プラグインインストール
if ! wp plugin is-installed elementor --allow-root; then
    echo "Installing Elementor plugin..."
    wp plugin install elementor --activate --allow-root
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

echo "WordPress initialized successfully!"
echo "Access your site at: $CODESPACES_URL"
