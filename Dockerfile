# ベースイメージ
FROM wordpress:6.5-apache

# 初期化スクリプトを docker-entrypoint-init.d にコピー
COPY wp-init.sh /docker-entrypoint-init.d/wp-init.sh
RUN chmod +x /docker-entrypoint-init.d/wp-init.sh

# php.ini を追加したい場合はここでコピー（任意）
# COPY php.ini /usr/local/etc/php/conf.d/custom.ini

# CMD はデフォルトのまま
# ENTRYPOINT は wordpress のデフォルトを使用
