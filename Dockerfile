FROM openmedicus/centos-lamp:latest
MAINTAINER Mikkel Kruse Johnsen <mikkel@xmedicus.com>

# Create locale
RUN localedef -f UTF-8 -i da_DK da_DK.UTF-8

RUN echo 'date.timezone = "Europe/Copenhagen"' >> /etc/php.ini

ADD simple-nuget-server /var/www/
RUN rm -rf /var/www/.git*

RUN rm -rf /var/www/html/ ; mv /var/www/public /var/www/html ; chown -R apache:apache /var/www

RUN sed -i -e 's!;error_log = syslog!error_log = \/var\/log\/php.log!g' /etc/php.ini
RUN sed -i -e 's!memory_limit = 128M!memory_limit = 512M!g' /etc/php.ini

RUN touch /var/log/php.log ; chown apache:apache /var/log/php.log

