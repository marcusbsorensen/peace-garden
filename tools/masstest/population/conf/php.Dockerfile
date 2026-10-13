# PHP-FPM for the population test, in Docker beside nginx and MariaDB, so a
# request's 84 database round trips cross a Docker network rather than the
# Docker VM's port forwarding from macOS (OrbStack here). PHP 8.3: the code
# needs 8.1 or later (`never`), and 8.3 is what shared hosts commonly offer;
# the live host's version is not recorded in this repository.
FROM php:8.3-fpm-alpine
RUN docker-php-ext-install pdo_mysql opcache
COPY php-fpm-docker.conf /usr/local/etc/php-fpm.d/zz-pop.conf
