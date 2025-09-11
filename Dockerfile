FROM wordpress:6.5-apache

# wp-cli をインストール
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# 初期化スクリプトをコンテナにコピー
COPY wp-init.sh /usr/local/bin/wp-init.sh
RUN chmod +x /usr/local/bin/wp-init.sh

# コンテナ起動時に wp-init.sh を実行
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
