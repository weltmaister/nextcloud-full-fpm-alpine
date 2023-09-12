FROM nextcloud:production-fpm-alpine

RUN set -ex; \
    \
    apk add --no-cache \
    	ocrmypdf \
        ffmpeg \
        ghostscript \
        imagemagick \
        procps \
        samba-client \
        supervisor \
        zlib \
        tesseract-ocr \
        tesseract-ocr-data-deu \
#       libreoffice \
        gnu-libiconv \
		py3-pip \

		
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
	
RUN pip install pytest-metadata


RUN mkdir -p \
    /var/log/supervisord \
    /var/run/supervisord \
;

    
RUN wget -P / https://github.com/nextcloud/docker/raw/master/.examples/dockerfiles/full/fpm-alpine/supervisord.conf

ENV NEXTCLOUD_UPDATE=1
CMD ["/usr/bin/supervisord", "-c", "/supervisord.conf"]
