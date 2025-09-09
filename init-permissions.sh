#!/bin/bash
set -e

echo "Initializing WordPress permissions..."

# WordPress パス
WP_PATH=/var/www/html

# 所有者を www-data に設定
chown -R www-data:www-data "$WP_PATH"

# ディレクトリのパーミッション
find "$WP_PATH" -type d -exec chmod 755 {} \;

# ファイルのパーミッション
find "$WP_PATH" -type f -exec chmod 644 {} \;

echo "Permissions initialized."
