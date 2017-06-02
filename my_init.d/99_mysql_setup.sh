#!/usr/bin/env sh

if [ ! -d /var/lib/mysql/mysql ]; then

    echo '*** Rebuilding mysql data dir'
        
    chown -R mysql.mysql /var/lib/mysql
    mysql_install_db > /dev/null

    rm -rf /var/run/mysqld/*

    echo '*** Starting mysqld'
    # The sleep 1 is there to make sure that inotifywait starts up before the socket is created
    mysqld_safe &

    echo '*** Waiting for mysqld to come online'
    while [ ! -x /var/run/mysqld/mysqld.sock ]; do
        sleep 1
    done
    
    echo '*** Setting root password to root'
    /usr/bin/mysqladmin -u root password 'root'

    echo "*** Creating mysql user: $MYSQL_USER with pass: $MYSQL_PASS"
    mysql -uroot -proot -e "CREATE USER '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASS}';"
    mysql -uroot -proot -e "GRANT ALL PRIVILEGES ON jiradb TO '${MYSQL_USER}'@'localhost' WITH GRANT OPTION; FLUSH PRIVILEGES;"

    echo '*** Bootstrapping database with scripts found in /root/setup'
    if [ -d /root/setup ]; then
        for sql in $(ls /root/setup/*.sql 2>/dev/null | sort); do
            echo '*** Running script:' $sql
            mysql -uroot -proot -e "\. $sql"
        done
    else
        echo '*** Directory /root/setup does not exist'
    fi

    echo '*** Shutting down mysqld'
    mysqladmin -uroot -proot shutdown

else

    echo '*** Using existing mysql data dir'

fi
