FROM php:7-fpm

MAINTAINER sadoknet@gmail.com

ENV VERTICA_VERSION 7.2.x
ENV VERTICA_EXACT_VERSION 7.2.2-0
ENV VERTICA_CLIENT_PKG vertica-client-7.2.2-0.x86_64.tar.gz

RUN \
  apt-get -y update && \
  apt-get -y install \
  curl vim wget git build-essential make gcc nasm mlocate unixODBC unixODBC-dev

RUN echo "deb http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list.d/dotdeb.org.list && \
    echo "deb-src http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list.d/dotdeb.org.list && \
    wget -O- http://www.dotdeb.org/dotdeb.gpg | apt-key add -

#PHP7 dependencies
RUN apt-get -y update && \
    apt-get -y install \
    php7.0-mysql php7.0-odbc \
    php7.0-curl php7.0-gd \
    php7.0-intl php-pear \
    php7.0-imap php7.0-mcrypt \
    php7.0-pspell php7.0-recode \
    php7.0-sqlite3 php7.0-tidy \
    php7.0-xmlrpc php7.0-xsl \
    php7.0-xdebug php7.0-redis \
    php-gettext && \
    docker-php-ext-install pdo pdo_mysql opcache


#ODBC PDO ODBC
RUN docker-php-ext-configure pdo_odbc --with-pdo-odbc=unixODBC,/usr/ && \
    docker-php-ext-install pdo_odbc && \
    echo "extension=/usr/lib/php/20151012/odbc.so" > /usr/local/etc/php/conf.d/odbc.ini  && \
    echo "extension=/usr/lib/php/20151012/redis.so" > /usr/local/etc/php/conf.d/redis.ini && \
    echo "zend_extension=/usr/lib/php/20151012/xdebug.so" > /usr/local/etc/php/conf.d/xdebug.ini

#Vertica ODBC driver
RUN mkdir /opt/vertica && \
    wget "https://my.vertica.com/client_drivers/$VERTICA_VERSION/$VERTICA_EXACT_VERSION/$VERTICA_CLIENT_PKG" && \
    tar zxvf $VERTICA_CLIENT_PKG -C / && \
    touch /etc/odbc.ini && \
    touch /etc/odbcinst.ini && \
    touch /etc/vertica.ini && \
    echo "Description = Vertica Dev"  >> /etc/odbc.ini && \
    echo "Driver = /opt/vertica/lib64/libverticaodbc.so"  >> /etc/odbc.ini && \
    echo "Port = 5433"  >> /etc/odbc.ini && \
    echo "Driver = Vertica"  >> /etc/odbc.ini && \
    echo "[Vertica]"  >> /etc/odbcinst.ini && \
    echo "Description = Vertica driver"  >> /etc/odbcinst.ini && \
    echo "Driver = /opt/vertica/lib64/libverticaodbc.so"  >> /etc/odbcinst.ini && \
    echo "[Driver]"  >> /etc/vertica.ini && \
    echo "DriverManagerEncoding=UTF-16"  >> /etc/vertica.ini && \
    echo "ODBCInstLib = /usr/lib/x86_64-linux-gnu/libodbcinst.so.1"  >> /etc/vertica.ini && \
    echo "ErrorMessagesPath=/opt/vertica/lib64"  >> /etc/vertica.ini && \
    echo "LogLevel=4"  >> /etc/vertica.ini && \
    echo "LogPath=/tmp"  >> /etc/vertica.ini

#install phpUnit & composer
RUN \
    wget "https://phar.phpunit.de/phpunit.phar" && \
    chmod +x phpunit.phar && \
    mv phpunit.phar /usr/local/bin/phpunit && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

#add www-data + mdkdir var folder
RUN usermod -u 1000 www-data && \
    mkdir -p /var/www/html/var && \
    chown -R www-data:www-data /var/www/html/var

WORKDIR /var/www/html

CMD ["php-fpm"]