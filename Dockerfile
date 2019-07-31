FROM php:5.6-apache

ARG COMPOSER_CACHE_DIR=/dev/null
ARG APACHE_RUN_USER=www-data
ARG MYSQL_HOST=db
ARG MYSQL_USER=phkondo
ARG MYSQL_PASSWORD=phkondo_db_password
ARG MYSQL_DATABASE=phkondo_db
ARG PHKONDO_DATA_LANG=

ENV COMPOSER_CACHE_DIR=$COMPOSER_CACHE_DIR
ENV APACHE_RUN_USER=$APACHE_RUN_USER
ENV MYSQL_HOST=$MYSQL_HOST
ENV PHKONDO_DATA_LANG=$PHKONDO_DATA_LANG

COPY --from=composer /usr/bin/composer /usr/bin/composer

RUN apt-get update && \
    apt-get -y install \
    libzip-dev \
    unzip \
    git \
    mysql-client \
    libmcrypt-dev

RUN docker-php-ext-install zip
RUN docker-php-ext-install pdo_mysql
RUN docker-php-ext-install mcrypt

RUN a2enmod rewrite

COPY entrypoint-webapp.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint-webapp.sh
RUN /usr/local/bin/entrypoint-webapp.sh

RUN printf "[client]\nhost=${MYSQL_HOST}\ndatabase=${MYSQL_DATABASE}\nuser=${MYSQL_USER}\npassword=${MYSQL_PASSWORD}\n" > /root/.my.cnf

RUN mkdir -p /var/www/.config/app/Config/
RUN cp /var/www/html/app/Config/database.php.default /var/www/.config/app/Config/database.php
RUN sed -i "s/'host' => 'localhost'/'host' => '${MYSQL_HOST}'/" /var/www/.config/app/Config/database.php
RUN sed -i "s/'login' => 'user'/'login' => '${MYSQL_USER}'/" /var/www/.config/app/Config/database.php
RUN sed -i "s/'password' => 'password'/'password' => '${MYSQL_PASSWORD}'/" /var/www/.config/app/Config/database.php
RUN sed -i "s/'database' => 'database_name'/'database' => '${MYSQL_DATABASE}'/" /var/www/.config/app/Config/database.php

RUN cp /var/www/html/app/Config/core_phapp.php.default /var/www/.config/app/Config/core_phapp.php
RUN cp /var/www/html/app/Config/bootstrap_phapp.php.default /var/www/.config/app/Config/bootstrap_phapp.php

ENTRYPOINT ["entrypoint-webapp.sh"]

EXPOSE 80
CMD ["apache2-foreground"]