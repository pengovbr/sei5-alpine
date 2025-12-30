##############################################################################
# Dockerfile de construcao do container APP com os pacotes basicos 
##############################################################################

FROM alpine:3.22.2

LABEL \
    org.opencontainers.image.title="Imagem docker para SEI 5 Alpine em PHP82"

# Erro do iconv com musl ASCII//TRANSLIT
# https://github.com/docker-library/php/issues/1495
RUN apk add --no-cache \
    --repository http://dl-cdn.alpinelinux.org/alpine/v3.12/community/ \
    gnu-libiconv=1.15-r2;

ENV LD_PRELOAD=/usr/lib/preloadable_libiconv.so

RUN apk add --no-cache \
      apache2 \ 
      apache2-http2 \
      php82-apache2 \
      php82-bcmath \
      php82-bz2 \
      php82-calendar \
      php82-ctype \
      php82-curl \
      php82-dom \
      php82-exif \
      php82-fileinfo \
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
      php82-snmp \
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
    fontconfig \
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
    bash curl;

# Suporte para módulo de assinatura avançada
RUN apk add --no-cache \
    php82-tokenizer php82-xmlwriter;

# Geração de audio do captcha
# RUN apk add --no-cache ffmpeg;

COPY assets/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh ; ln -s /usr/bin/php82 /usr/bin/php

# Permite o uso do SQLSERVER mas não funciona corretamente devido ao requisito de iso88591 do SEI
# RUN apk add --no-cache --virtual .build-deps php82-dev make gcc g++ autoconf php82-pear unixodbc-dev gnupg \
#    && curl -O https://download.microsoft.com/download/3/5/5/355d7943-a338-41a7-858d-53b259ea33f5/msodbcsql18_18.3.2.1-1_amd64.apk \
#    && curl -O https://download.microsoft.com/download/3/5/5/355d7943-a338-41a7-858d-53b259ea33f5/mssql-tools18_18.3.1.1-1_amd64.apk \
#    && curl -O https://download.microsoft.com/download/3/5/5/355d7943-a338-41a7-858d-53b259ea33f5/msodbcsql18_18.3.2.1-1_amd64.sig \
#    && curl -O https://download.microsoft.com/download/3/5/5/355d7943-a338-41a7-858d-53b259ea33f5/mssql-tools18_18.3.1.1-1_amd64.sig \
#    && curl https://packages.microsoft.com/keys/microsoft.asc  | gpg --import - \
#    && gpg --verify msodbcsql18_18.3.2.1-1_amd64.sig msodbcsql18_18.3.2.1-1_amd64.apk \
#    && gpg --verify mssql-tools18_18.3.1.1-1_amd64.sig mssql-tools18_18.3.1.1-1_amd64.apk \
#    && apk add --allow-untrusted msodbcsql18_18.3.2.1-1_amd64.apk mssql-tools18_18.3.1.1-1_amd64.apk \
#    && rm *.apk *.sig \
#    && apk add --no-cache unixodbc \
#    && pecl82 install pdo_sqlsrv sqlsrv \
#    && apk del .build-deps \
#    && echo 'extension=sqlsrv.so' > /etc/php82/conf.d/98_sqlserver.ini \
#    && echo 'extension=pdo_sqlsrv.so' > /etc/php82/conf.d/99_sqlserver.ini
        
EXPOSE 8000
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/sh", "-c", "crond && httpd -DFOREGROUND"]
