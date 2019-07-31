#!/bin/bash
set -eo pipefail
shopt -s nullglob

if [ ! -f "/var/www/html/.installed" ]; then
    echo "Installing app... $APACHE_RUN_USER"
    chown $APACHE_RUN_USER /var/www/html/ && \
    #su -p $APACHE_RUN_USER -s /bin/bash -c "composer create-project --no-dev -n -s stable phalkaline/phkondo /var/www/html/" && \
    su -p $APACHE_RUN_USER -s /bin/bash -c "git clone https://github.com/pHAlkaline/phkondo.git /var/www/html/ && cd /var/www/html/ && composer update" && \
    chown $APACHE_RUN_USER /var/www/html/app/tmp && \
    chmod 755 /var/www/html/app/tmp && \
    mkdir -p /var/www/.config/app/Config/ && \
    touch /var/www/html/.installed && \
    echo "App installed!"

    if getent hosts $MYSQL_HOST; then 
        cat /var/www/html/app/Config/Schema/phkondo.sql | mysql
        cat /var/www/html/app/Plugin/Feedback/Config/Schema/feedback.sql | mysql
        cat "/var/www/html/app/Config/Schema/phkondodata${PHKONDO_DATA_LANG}.sql" | mysql
    fi
fi

if [ ! -f "/var/www/html/app/Config/database.php" ]; then
    cp /var/www/.config/app/Config/database.php /var/www/html/app/Config/database.php 2>/dev/null || :
fi
if [ ! -f "/var/www/html/app/Config/core_phapp.php" ]; then
    cp /var/www/.config/app/Config/core_phapp.php /var/www/html/app/Config/core_phapp.php 2>/dev/null || :
fi
if [ ! -f "/var/www/html/app/Config/bootstrap_phapp.php" ]; then
    cp /var/www/.config/app/Config/bootstrap_phapp.php /var/www/html/app/Config/bootstrap_phapp.php 2>/dev/null || :
fi

exec /usr/local/bin/docker-php-entrypoint "$@"