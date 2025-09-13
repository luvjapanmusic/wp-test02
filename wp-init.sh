#!/bin/bash
set -e

# Docker コンテナ名
CONTAINER_NAME="wordpress"

# Codespaces URL の自動取得
if [ -n "$CODESPACE_NAME" ]; then
    WP_URL="https://${CODESPACE_NAME}-8000.app.github.dev/"
fi
echo "Using URL: $WP_URL"

# WordPress CLI 実行関数
wp() {
    docker compose exec $CONTAINER_NAME wp "$@"
}

# WordPress が未インストールなら自動インストール
if ! wp core is-installed --allow-root; then
    echo "Installing WordPress..."
    wp core install \
        --url="$WP_URL" \
        --title="Test Site" \
        --admin_user="test" \
        --admin_password="test" \
        --admin_email="admin@example.com" \
        --skip-email \
        --allow-root
fi

# デバックモード有効化
wp config set WP_DEBUG true --raw --allow-root
# 日本語化
wp language core install ja --activate --allow-root 

# タイムゾーンと日時表記
wp option update timezone_string 'Asia/Tokyo' --allow-root 
wp option update date_format 'Y-m-d' --allow-root 
wp option update time_format 'H:i' --allow-root

# キャッチフレーズの設定
wp option update blogdescription '' --allow-root

# プラグインの削除
wp plugin delete hello.php --allow-root


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

# Astraテーマインストール＆有効化
if ! wp theme is-installed astra --allow-root; then
    wp theme install astra --activate --allow-root
fi

# Astra 子テーマ自動作成
# 削除中

# Astra 子テーマ作成
if [ ! -d "wordpress/wp-content/themes/astra-child" ]; then
    echo "Astra 子テーマを作成中..."
    mkdir -p wordpress/wp-content/themes/astra-child
    cat > wordpress/wp-content/themes/astra-child/style.css <<EOL
/*
Theme Name: Astra Child
Template: astra
*/
EOL
    wp theme activate astra-child --allow-root
else
    echo "Astra 子テーマはすでに存在します。"
fi

# 不要プラグインの削除
wp plugin delete hello.php --allow-root

# WP Multibyte Patch プラグインインストール＆有効化
if ! wp plugin is-installed wp-multibyte-patch --allow-root; then
    wp plugin install wp-multibyte-patch --activate --allow-root
fi

# Elementor プラグインインストール＆有効化
if ! wp plugin is-installed elementor --allow-root; then
    wp plugin install elementor --activate --allow-root
fi

# 不要な他言語ファイル削除（ja以外）
wp language core list --allow-root | awk '/installed/ {print $1}' | grep -v ja | xargs -r -n1 wp language core uninstall --allow-root
wp language plugin list --allow-root | awk '/installed/ {print $1}' | grep -v ja | xargs -r -n1 wp language plugin uninstall --allow-root
wp language theme list --allow-root | awk '/installed/ {print $1}' | grep -v ja | xargs -r -n1 wp language theme uninstall --allow-root

# WordPress本体アップデート
wp core update --allow-root

# WordPressプラグインアップデート
wp plugin update --all --allow-root

# WordPress翻訳アップデート
wp core language update --allow-root

# 自動更新無効化
wp config set AUTOMATIC_UPDATER_DISABLED true --raw --allow-root



echo "WordPress, Astra child theme, and Elementor are ready! 日本語でセットアップ完了しました！"

