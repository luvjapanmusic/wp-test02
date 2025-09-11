FROM wordpress:6.5-apache

# WP-CLI をインストール
RUN apt-get update && apt-get install -y less mariadb-client \
  && curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
  && chmod +x wp-cli.phar \
  && mv wp-cli.phar /usr/local/bin/wp \
  && rm -rf /var/lib/apt/lists/*

# 初期化スクリプトをコピー
COPY wp-init.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/wp-init.sh

# 起動時に wp-init.sh を実行してから Apache を起動
CMD ["bash", "-c", "wp-init.sh && apache2-foreground"]
