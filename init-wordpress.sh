#!/bin/bash
set -e

WP_PATH=/var/www/html
CONFIG_FILE=$WP_PATH/wp-config.php

echo "Initializing WordPress permissions..."

# 所有者を www-data に設定
chown -R www-data:www-data "$WP_PATH"

# ディレクトリのパーミッション
find "$WP_PATH" -type d -exec chmod 755 {} \;

# ファイルのパーミッション
find "$WP_PATH" -type f -exec chmod 644 {} \;

echo "Permissions initialized."

# wp-config.php にリバースプロキシ対応コードを追記
if [ -f "$CONFIG_FILE" ]; then
    if ! grep -q "Codespaces / reverse proxy HTTPS対応" "$CONFIG_FILE"; then
        echo "" >> "$CONFIG_FILE"
        echo "// Codespaces / reverse proxy HTTPS対応" >> "$CONFIG_FILE"
        echo "if (isset(\$_SERVER['HTTP_X_FORWARDED_PROTO']) && \$_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {" >> "$CONFIG_FILE"
        echo "    \$_SERVER['HTTPS'] = 'on';" >> "$CONFIG_FILE"
        echo "}" >> "$CONFIG_FILE"
        echo "if (isset(\$_SERVER['HTTP_X_FORWARDED_HOST'])) {" >> "$CONFIG_FILE"
        echo "    \$_SERVER['HTTP_HOST'] = \$_SERVER['HTTP_X_FORWARDED_HOST'];" >> "$CONFIG_FILE"
        echo "}" >> "$CONFIG_FILE"
        echo "wp-config.php にリバースプロキシ対応コードを追記しました。"
    fi
fi
