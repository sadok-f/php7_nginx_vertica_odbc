# php7_nginx_vertica_odbc
PHP 7.0 fpm image + Nginx and Vertica ODBC driver managed by Supervisor

By defualt it works with 8.1.1-2 Client Drivers, but you can change Dockerfile to get another specific version [https://my.vertica.com/vertica-client-drivers/](https://my.vertica.com/vertica-client-drivers/)



## Usage

```sh
    $ docker pull sadokf/php7_nginx_vertica_odbc
```
```sh
    $ docker run -itd -p 8080:80  sadokf/php7_nginx_vertica_odbc
```