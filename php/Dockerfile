FROM php:8.1.8-fpm-bullseye

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y wget make libzip-dev unzip sqlite3 procps && \
  wget -q https://dev.mysql.com/get/mysql-apt-config_0.8.22-1_all.deb && \
  apt-get -y install ./mysql-apt-config_*_all.deb && \
  apt-get -y update && \
  apt-get -y install default-mysql-client && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure zip && \
  docker-php-ext-install zip && \
  docker-php-ext-install pdo_mysql

RUN \
  sed -i \
    -e 's/pm.max_children = 5/pm.max_children = 40/' \
    -e 's/pm.start_servers = 2/pm.start_servers = 16/' \
    -e 's/pm.min_spare_servers = 1/pm.min_spare_servers = 8/' \
    -e 's/pm.max_spare_servers = 3/pm.max_spare_servers = 24/' \
    /usr/local/etc/php-fpm.d/www.conf

RUN useradd --uid=1001 --create-home isucon
USER isucon
RUN mkdir -p /home/isucon/webapp/php
WORKDIR /home/isucon/webapp/php

COPY composer* /home/isucon/webapp/php/
RUN ./composer.phar install

COPY --chown=isucon:isucon ./ /home/isucon/webapp/php/
