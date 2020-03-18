FROM wordpress:5.3-apache

RUN apt-get update
RUN apt-get install -y libcap2-bin

RUN setcap 'cap_net_bind_service=+ep' /usr/sbin/apache2
RUN getcap /usr/sbin/apache2

COPY ./wp-content /var/www/html/wp-content

USER www-data