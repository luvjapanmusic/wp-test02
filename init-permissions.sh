#!/bin/bash
# wp-test02/init-permissions.sh
# ホスト側から WordPress パーミッションを安全に初期化する

# WordPress がマウントされているディレクトリ
WP_DIR="./wordpress"

if [ ! -d "$WP_DIR" ]; then
  echo "Error: $WP_DIR が存在しません。docker-compose.yml の volumes を確認してください。"
  exit 1
fi

echo "Setting ownership to www-data:www-data for $WP_DIR..."
sudo chown -R 33:33 "$WP_DIR"   # www-data UID:GID は一般的に 33:33

echo "Setting directory permissions to 755..."
find "$WP_DIR" -type d -exec chmod 755 {} \;

echo "Setting file permissions to 644..."
find "$WP_DIR" -type f -exec chmod 644 {} \;

echo "Permissions initialized successfully."
