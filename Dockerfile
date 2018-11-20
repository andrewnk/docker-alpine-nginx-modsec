FROM nginx:alpine

LABEL maintainer="Andrew Kimball"

RUN apk add --no-cache --virtual .build-deps \
        gcc \
        libc-dev \
        make \
        openssl-dev \
        pcre-dev \
        zlib-dev \
        linux-headers \
        curl \
        gnupg \
        libxslt-dev \
        gd-dev \
        perl-dev \
    && apk add --no-cache --virtual .libmodsecurity-deps \
        pcre-dev \
        libxml2-dev \
        git \
        libtool \
        automake \
        autoconf \
        g++ \
        flex \
        bison \
        yajl-dev \
    # Add runtime dependencies that should not be removed
    && apk add --no-cache \
        doxygen \
        geoip \
        geoip-dev \
        yajl \
        libstdc++ \
        git \
        sed \
        libmaxminddb-dev

WORKDIR /opt/ModSecurity

RUN echo "Installing ModSec Library" && \
    git clone -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity . && \
    git submodule init && \
    git submodule update && \
    ./build.sh && \
    ./configure && make && make install

WORKDIR /opt

RUN echo 'Installing ModSec - Nginx connector' && \
    git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git && \
    wget http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz && \
    tar zxvf nginx-$NGINX_VERSION.tar.gz

WORKDIR /opt/GeoIP

RUN git clone -b master --single-branch https://github.com/leev/ngx_http_geoip2_module.git .

WORKDIR /opt/nginx-$NGINX_VERSION

RUN ./configure --with-compat --add-dynamic-module=../ModSecurity-nginx  --add-dynamic-module=../GeoIP && \
    make modules && \
    cp objs/ngx_http_modsecurity_module.so objs/ngx_http_geoip2_module.so /etc/nginx/modules

WORKDIR /opt

RUN echo "Begin installing ModSec OWASP Rules" && \
    git clone -b v3.0/master https://github.com/SpiderLabs/owasp-modsecurity-crs && \
    mv owasp-modsecurity-crs/ /usr/local/

RUN mkdir /etc/nginx/modsec && \
    rm -fr /etc/nginx/conf.d/ && \
    rm -fr /etc/nginx/nginx.conf

COPY conf/nginx/ /etc/nginx/
COPY conf/modsec/ /etc/nginx/modsec/
COPY conf/owasp/ /usr/local/owasp-modsecurity-crs/
COPY errors /usr/share/nginx/errors

RUN mkdir -p /etc/nginx/geoip && \
    wget http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz && \
    wget http://geolite.maxmind.com/download/geoip/database/GeoLite2-Country.tar.gz && \
    tar -xvzf GeoLite2-City.tar.gz --strip-components=1 && \
    tar -xvzf GeoLite2-Country.tar.gz --strip-components=1 && \
    mv *.mmdb /etc/nginx/geoip/

RUN chown -R nginx:nginx /usr/share/nginx /etc/nginx

#delete uneeded and clean up
RUN apk del .build-deps && \
    apk del .libmodsecurity-deps && \
    rm -fr ModSecurity && \
    rm -fr ModSecurity-nginx && \
    rm -fr GeoIp && \
    rm -fr nginx-$NGINX_VERSION.tar.gz && \
    rm -fr nginx-$NGINX_VERSION

WORKDIR /usr/share/nginx/html