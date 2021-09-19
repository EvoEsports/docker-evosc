FROM php:7.4-cli-alpine

# environment variables
ARG EVOSC_GIT="https://github.com/EvoTM/EvoSC.git"
ARG EVOSC_BRANCH="develop"
ARG BUILD_DATE
ARG REVISION
ARG EVOSC_VERSION

# labels
LABEL org.opencontainers.image.title="EvoSC Trackmania/ManiaPlanet Server Controller" \
      org.opencontainers.image.description="Server Controller for Trackmania and ManiaPlanet servers." \
      org.opencontainers.image.version=${EVOSC_VERSION} \
      org.opencontainers.image.created=${BUILD_DATE} \
      org.opencontainers.image.authors="Nicolas Graf <nicolas.j.graf@gmail.com>" \
      org.opencontainers.image.vendor="Evo" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.revision=${REVISION}

# create base dir
RUN set -eux; \
    addgroup -g 9999 evosc && \
    adduser -u 9999 -Hh /controller -G evosc -s /sbin/nologin -D evosc && \
    install -d -o evosc -g evosc -m 775 /controller

WORKDIR /controller

# install packages
RUN apk add --no-cache unzip git libpng-dev zlib-dev curl-dev libzip-dev zip jq su-exec procps libjpeg-turbo-dev bash

# install composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# install php extensions
RUN docker-php-ext-configure gd --with-jpeg && docker-php-ext-install gd && \
    docker-php-ext-install curl mysqli pdo_mysql zip pcntl

# increase default memory limit
RUN echo 'memory_limit = 512M' >> /usr/local/etc/php/conf.d/docker-php-memlimit.ini

# install evosc
RUN git clone --branch ${EVOSC_BRANCH} ${EVOSC_GIT} /controller && \
    composer i --no-dev && \
    chown evosc:evosc -Rf /controller

# copy entrypoint.sh
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# check if the process is still up
HEALTHCHECK --interval=5s --timeout=5s --start-period=20s --retries=3 \
    CMD pgrep -x php || exit 1

# switch to non-root user
USER evosc

# set entrypoint
ENTRYPOINT [ "entrypoint.sh" ]
CMD [ "php", "esc", "run" ]