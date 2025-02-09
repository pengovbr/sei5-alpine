##############################################################################
# Dockerfile de construcao do container APP com os pacotes basicos
##############################################################################

FROM alpine:3.21

LABEL \
    org.opencontainers.image.title="Imagem docker para SEI 5 Alpine em PHP82"


COPY src/ /opt/

RUN apk add --no-cache \
      apache2 \ 
      apache2-http2 \
      gnu-libiconv \
      php82 \
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
COPY --from=surnet/alpine-wkhtmltopdf:3.20.3-0.12.6-small \
    /bin/wkhtmltopdf /bin/wkhtmltopdf

## Add suporte ao Oracle
COPY assets/instantclient-basic-linux.x64-21.11.0.0.0dbru.zip /tmp/
COPY assets/instantclient-sdk-linux.x64-21.11.0.0.0dbru.zip /tmp/
COPY assets/oci8-3.3.0.tgz /tmp/
COPY assets/install_oci8.sh /tmp/install_oci8.sh

RUN mkdir -p /opt/oracle/ && \ 
    unzip /tmp/instantclient-basic-linux.x64-21.11.0.0.0dbru.zip -d /opt/oracle \
    && unzip /tmp/instantclient-sdk-linux.x64-21.11.0.0.0dbru.zip -d /opt/oracle \
    && rm -rf /tmp/*.zip \
    && mv /opt/oracle/instantclient_21_11 /opt/oracle/instantclient

ENV LD_LIBRARY_PATH="/opt/oracle/instantclient"
ENV ORACLE_HOME="/opt/oracle/instantclient/"

RUN chmod +x /tmp/install_oci8.sh && /tmp/install_oci8.sh
RUN rm -rf /tmp/install_oci8.sh

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
        
EXPOSE 8000
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/sh", "-c", "crond && httpd -DFOREGROUND"]
