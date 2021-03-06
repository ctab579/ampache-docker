#!/bin/bash

VOLUME_HOME="/var/lib/mysql"

if [[ ! -d $VOLUME_HOME/mysql ]]; then
    echo "=> An empty or uninitialized MySQL volume is detected in $VOLUME_HOME"
    echo "=> Installing MySQL ..."
    mysqld --defaults-file=/etc/mysql/my.cnf --initialize-insecure
    echo "=> Done!"
    /create_mysql_admin_user.sh
else
    echo "=> Using an existing volume of MySQL"
fi

if [[ -f /var/temp/ampache.cfg.php && ! -f /var/www/ampache/config/ampache.cfg.php ]]; then
    mv /var/temp/ampache.cfg.php /var/www/ampache/config/ampache.cfg.php
fi
if [[ ! -f /var/www/config/ampache.cfg.php ]]; then
    mv /var/temp/ampache.cfg.php.dist /var/www/ampache/config/ampache.cfg.php.dist
fi


# Start apache in the background
service apache2 start

# Start cron in the background
cron

# Start a process to watch for changes in the library with inotify
(
while true; do
    inotifywatch /media
    php /var/www/ampache/bin/catalog_update.inc -a
    sleep 30
done
) &

# run this in the foreground so Docker won't exit
exec mysqld_safe
