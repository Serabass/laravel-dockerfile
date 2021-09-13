FROM php:fpm as project-php-vendor
WORKDIR /app

COPY ./composer.json /app/composer.json
COPY ./composer.lock /app/composer.lock

RUN composer install \
    --no-dev \
    --no-autoloader \
    --no-interaction \
    --no-scripts

FROM node:latest as project-node-vendor
WORKDIR /app

COPY ./package.json /app/package.json
COPY ./package-lock.json /app/package-lock.json

RUN npm ci



FROM node:14 as project-node-assets
WORKDIR /app

COPY ./public/ /app/public

COPY --from=project-node-vendor /app/node_modules /app/node_modules
COPY ./resources/ /app/resources
COPY ./package-lock.json /app/
COPY ./package.json /app/
COPY ./webpack.mix.js /app/

RUN npm run dev

FROM php:fpm as project-build-app
WORKDIR /app

COPY ./composer.json /app/
COPY ./composer.lock /app/
COPY ./package.json /app/
COPY ./package-lock.json /app/

# COPY --from=project-node-vendor /app/node_modules /app/node_modules
COPY --from=project-php-vendor /app/vendor /app/vendor
COPY --from=project-node-assets /app/public /app/public

RUN composer install \
    --no-dev \
    --no-autoloader \
    --no-interaction \
    --no-scripts

# RUN npm ci

# RUN apt-get update && apt-get install -y procps
COPY ./app/ /app/app
COPY ./bootstrap/ /app/bootstrap
COPY ./config/ /app/config
COPY ./database/ /app/database
COPY ./routes/ /app/routes
COPY ./resources/ /app/resources
COPY ./storage/ /app/storage
COPY ./first-dump.sql /app/
# COPY ./.env /app/
COPY ./artisan /app/
COPY ./server.php /app/

RUN composer dump-autoload
RUN php artisan lang:js

RUN chmod 0777 storage -R
EXPOSE 9000

CMD ["php-fpm"]
