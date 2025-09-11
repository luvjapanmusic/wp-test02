#!/bin/bash
set -e

# Docker コンテナ名
CONTAINER_NAME="wordpress"

# Codespaces URL の自動取得（内部アクセス用）
if [ -n "$GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN" ]; then
    WP_URL="http://localhost:8000"
else
    WP_URL="http://localhost"
fi

echo "Using internal URL: $WP_URL"

# WordPress コンテナ内で wp コマンドを実行する関数
wp() {
    docker compose exec $CONTAINER_NAME wp "$@"
}

# WordPress が未インストールなら自動インストール
if ! wp core is-installed --allow-root >/dev/null 2>&1; then
    echo "WordPress をインストール中..."
    wp core download --locale=ja --allow-root
    wp config create --dbname=wordpress --dbuser=root --dbpass=root --dbhost=db --allow-root
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

# 言語を日本語に設定（再インストール時も安全）
wp language core install ja --activate --allow-root

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
wp rewrite flush --hard --allow-root

# Astraテーマインストール & 有効化
if ! wp theme is-installed astra --allow-root; then
    wp theme install astra --activate --allow-root
else
    wp theme activate astra --allow-root
fi

# Astra子テーマ作成 (既存ならスキップ)
CHILD_THEME_DIR="/var/www/html/wp-content/themes/astra-child"
if [ ! -d "$CHILD_THEME_DIR" ]; then
    wp scaffold child-theme astra-child --parent_theme=astra --activate --allow-root
else
    echo "Astra 子テーマはすでに存在します。"
fi

# Elementorプラグインインストール & 有効化
if ! wp plugin is-installed elementor --allow-root; then
    wp plugin install elementor --activate --allow-root
else
    wp plugin activate elementor --allow-root
fi

echo "WordPress 初期セットアップが完了しました！"
echo "サイトURL: $WP_URL"
