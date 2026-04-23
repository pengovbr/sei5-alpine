##############################################################################
# Dockerfile de construcao do container APP com os pacotes basicos 
##############################################################################

FROM alpine:3.22.4

LABEL \
    org.opencontainers.image.title="Imagem docker para SEI 5 Alpine em PHP82"

# Erro do iconv com musl ASCII//TRANSLIT
# https://github.com/docker-library/php/issues/1495
RUN apk add --no-cache \
    --repository http://dl-cdn.alpinelinux.org/alpine/v3.12/community/ \
    gnu-libiconv=1.15-r2;

ENV LD_PRELOAD=/usr/lib/preloadable_libiconv.so

# CVE-2026-25646 - libpng
# CVE-2025-14017, CVE-2025-13034, CVE-2025-15079 - curl
# CVE-2025-14819, CVE-2025-14524, CVE-2025-10966 - curl
# CVE-2025-15224 - curl
# CVE-2006-5201 - nss 
# CVE-2025-70873 - sqllite-libs dependencia do nss
# CVE-2026-34085 - fontconfig
# CVE-2026-22185 - libldap
# CVE-2026-27456 - util-linux
RUN apk add --no-cache \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/main/ \
    curl libpng nss fontconfig libldap util-linux;

RUN apk add --no-cache \
      apache2 \
      apache2-http2 \
      apache2-proxy \
      php82-bcmath \
      php82-bz2 \
      php82-calendar \
      php82-ctype \
      php82-curl \
      php82-dom \
      php82-exif \
      php82-fileinfo \
      php82-fpm \
      php82-gd \
      php82-gettext \
      php82-gmp \
      php82-iconv \
      php82-imap \
      php82-intl \
      php82-ldap \
      php82-mbstring \
      php82-mysqli \
      php82-odbc \
      php82-openssl \
      php82-pcntl \
      php82-pdo \
      php82-pdo_mysql \
      php82-pdo_pgsql \
      php82-pear \
      php82-pecl-apcu \
      php82-pecl-igbinary \
      php82-pecl-mcrypt \
      php82-pecl-memcache \
      php82-pecl-xdebug \
      php82-pgsql \
      php82-phar \
      php82-pspell \
      php82-simplexml \
      php82-sodium \
      php82-shmop \
      php82-soap \
      php82-xml \
      php82-zip \
      php82-zlib \
      php82-pecl-uploadprogress;

# Pacotes para o wkhtmltopdf
RUN apk add --no-cache \
    libstdc++ \
    libx11 \
    libxrender \
    libxext \
    libssl3 \
    ca-certificates \
    font-carlito \
    freetype \
    ttf-dejavu \
    ttf-droid \
    ttf-freefont \
    ttf-liberation \
    # more fonts
  && apk add --no-cache --virtual .build-deps \
    msttcorefonts-installer \
  # Install microsoft fonts
  && update-ms-fonts \
  && fc-cache -f \
  # Clean up when done
  && rm -rf /tmp/* \
  && apk del .build-deps

# wkhtmltopdf #
COPY --from=surnet/alpine-wkhtmltopdf:3.22.0-0.12.6-small \
    /bin/wkhtmltopdf /bin/wkhtmltopdf

RUN apk add --no-cache openjdk8

COPY assets/sei.ini /etc/php82/conf.d/99_sei.ini
COPY assets/xdebug.ini /etc/php82/conf.d/99_xdebug.ini
COPY assets/sei.conf /etc/apache2/conf.d/
COPY assets/cron.conf /etc/crontabs/root

# Pasta para arquivos externos
RUN mkdir -p /var/sei/arquivos && chown -R apache:apache /var/sei/arquivos && chmod 777 /tmp

RUN mkdir -p /var/log/sei && mkdir -p /var/log/sip
# Suporte para atualização do SEI. O script de atualização do SEI está fixo no bash
RUN apk add --no-cache \
    bash;

# Suporte para módulo de assinatura avançada
RUN apk add --no-cache \
    php82-tokenizer php82-xmlwriter;

# Geração de audio do captcha
# RUN apk add --no-cache ffmpeg;

COPY assets/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh ; chown apache:apache /entrypoint.sh ; ln -s /usr/bin/php82 /usr/bin/php ; \
    mkdir -p /var/www/html; \
    mkdir -p /opt/sei/temp; mkdir -p /opt/sip/temp; \
    chown apache:apache /var/www/logs/ ; chown apache:apache /var/log/php82/; \
    echo 'ServerName localhost:80' >> /etc/apache2/httpd.conf; echo 'PidFile /tmp/httpd.pid' >> /etc/apache2/httpd.conf

# Habilita FPM e HTTP2. O 'clean_env no' não deve ser usado em produção
RUN sed -i \
        -e 's/^#\(LoadModule .*mod_mpm_event.so\)/\1/' \
        -e 's/^LoadModule .*mod_mpm_prefork.so/#\0/' /etc/apache2/httpd.conf; \
    echo '<FilesMatch "\.(php)$">' >> /etc/apache2/httpd.conf; \
    echo '   SetHandler "proxy:fcgi://127.0.0.1:9000"' >> /etc/apache2/httpd.conf; \
    echo '</FilesMatch>' >> /etc/apache2/httpd.conf; \
    echo 'clear_env = no' >> /etc/php82/php-fpm.conf; \
    echo 'Protocols h2c http/1.1' >> /etc/apache2/httpd.conf

# Em DEV vários módulos esperam que esteja no root
# USER apache
EXPOSE 8000
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/sh", "-c", "crond && php-fpm82 -D && httpd -DFOREGROUND"]
