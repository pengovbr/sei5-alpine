#!/bin/sh
set -e 

apk add --no-cache php82-dev make build-base libaio libc6-compat

# Extrai o OCI8
tar -xvzf /tmp/oci8-3.3.0.tgz -C /tmp/
cd /tmp/oci8-3.3.0

# Compilar e instalar OCI8
/usr/bin/phpize82
./configure --with-oci8=instantclient,/opt/oracle/instantclient --with-php-config=/usr/bin/php-config82
make && make install

# Configuração do PHP
echo "extension=oci8.so" > /etc/php82/oci8.ini
ln -s /etc/php82/oci8.ini /etc/php82/conf.d/oci8.ini
