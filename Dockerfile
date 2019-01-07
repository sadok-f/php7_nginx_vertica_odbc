FROM php:7.2-fpm

MAINTAINER sadoknet@gmail.com

ENV DEBIAN_FRONTEND noninteractive

ENV VERTICA_VERSION 9.2.x
ENV VERTICA_EXACT_VERSION 9.2.0-0
ENV VERTICA_CLIENT_PKG vertica-client-${VERTICA_EXACT_VERSION}.x86_64.tar.gz

RUN \
  apt-get update -y && \
  apt-get install -y --no-install-recommends\
  curl vim wget git build-essential make gcc nasm mlocate unixodbc unixodbc-dev \
  nginx supervisor libmcrypt-dev libgpgme11-dev \
  apt-transport-https lsb-release ca-certificates \
  net-tools libxrender1 locales && \
  echo 'en_US.UTF-8 UTF-8'  > /etc/locale.gen && \
  echo 'LC_ALL="en_US.UTF-8"' > /etc/default/locale && \
  dpkg-reconfigure --frontend=noninteractive locales && \
  update-locale LC_ALL=en_US.UTF-8

# see https://github.com/docker-library/php/pull/542
RUN rm /etc/apt/preferences.d/no-debian-php

RUN wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg  && \
    echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" |  tee /etc/apt/sources.list.d/php.list

#PHP7 dependencies
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends\
    php7.2-mysql php7.2-odbc \
    php7.2-curl php7.2-gd \
    php7.2-intl php-pear \
    php7.2-imap \
    php7.2-pspell php7.2-recode \
    php7.2-sqlite3 php7.2-tidy \
    php7.2-xmlrpc php7.2-xsl \
    php-gettext && \
    docker-php-ext-install pdo pdo_mysql opcache && \
    pecl install redis xdebug mcrypt-1.0.1 gnupg


#ODBC PDO ODBC
RUN docker-php-ext-configure pdo_odbc --with-pdo-odbc=unixODBC,/usr/ && \
    docker-php-ext-install pdo_odbc && \
    docker-php-ext-enable redis xdebug pdo_odbc mcrypt gnupg

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
    echo "ErrorMessagesPath=/opt/vertica"  >> /etc/vertica.ini && \
    echo "LogLevel=4"  >> /etc/vertica.ini && \
    echo "LogPath=/tmp"  >> /etc/vertica.ini && \
    echo "max_execution_time = 300" >> /usr/local/etc/php/php.ini && \
    echo "memory_limit = 512M" >> /usr/local/etc/php/php.ini


RUN touch /var/www/html/index.php && \
    echo "<?php phpinfo();"  >> /var/www/html/index.php

COPY docker/resources/etc/ /etc/

#install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer


WORKDIR /var/www/html

EXPOSE 80

CMD ["/usr/bin/supervisord"]