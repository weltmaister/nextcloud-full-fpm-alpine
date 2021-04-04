FROM nextcloud:fpm-alpine

RUN set -ex; \
    \
    apk add --no-cache \
        ffmpeg \
        ghostscript \
        imagemagick \
        procps \
        samba-client \
        supervisor \
        zlib \
	unrar \
        tesseract-ocr \
        tesseract-ocr-data-deu \
#       libreoffice \
        gnu-libiconv \
	php7-iconv \
	htop \
    ;

RUN set -ex; \
    \
    apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        libtool \
        imap-dev \
        krb5-dev \
        openssl-dev \
        samba-dev \
        bzip2-dev \
    ; \
    \
    docker-php-ext-configure imap --with-kerberos --with-imap-ssl; \
    docker-php-ext-install \
        bz2 \
        imap \
    ; \
    pecl install smbclient; \
    pecl install inotify; \
    docker-php-ext-enable \
		inotify \
		smbclient; \
    \
    runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )"; \
    apk add --virtual .nextcloud-phpext-rundeps $runDeps; \
    apk del .build-deps


#RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ --allow-untrusted gnu-libiconv
#ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php


RUN mkdir -p \
    /var/log/supervisord \
    /var/run/supervisord \
;

RUN { \
      echo 'redis.session.locking_enabled = 1'; \
      echo 'redis.session.lock_retries = -1'; \
      echo 'redis.session.lock_wait_time = 10000'; \
    } > /usr/local/etc/php/conf.d/redis-session-locking.ini
    ;
    
COPY supervisord.conf /

ENV NEXTCLOUD_UPDATE=1
ENV LD_PRELOAD=/usr/lib/preloadable_libiconv.so

CMD ["/usr/bin/supervisord", "-c", "/supervisord.conf"]
