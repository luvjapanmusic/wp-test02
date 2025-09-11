FROM wordpress:6.5-apache

# 初期化スクリプトをコンテナにコピー
COPY wp-init.sh /usr/local/bin/wp-init.sh
RUN chmod +x /usr/local/bin/wp-init.sh

# コンテナ起動時に wp-init.sh を実行
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground", "/usr/local/bin/wp-init.sh"]
