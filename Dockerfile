ARG NGINX_VER=1.17.9

FROM nginx:${NGINX_VER}-alpine as build_modsecurity

ARG MODSEC_BRANCH=v3.0.4
ARG GEO_DB_RELEASE=2020-03
ARG OWASP_BRANCH=v3.2/master

WORKDIR /opt

# Install dependencies; includes dependencies required for compile-time options:
# curl, libxml, pcre, and lmdb and Modsec
RUN echo "Installing Dependencies" && \
    apk add --no-cache --virtual general-dependencies \
    gcc \
    make \
    libc-dev \
    g++ \
    openssl-dev \
    linux-headers \
    pcre-dev \
    zlib-dev \
    git \
    libtool \
    automake \
    autoconf \
    lmdb-dev \
    libxml2-dev \
    curl-dev \
    byacc \
    flex \
    yajl-dev \
    geoip-dev \
    libstdc++ \
    libmaxminddb-dev

# Clone and compile modsecurity. Binary will be located in /usr/local/modsecurity
RUN echo "Installing ModSec Library" && \
    git clone -b ${MODSEC_BRANCH} --depth 1 https://github.com/SpiderLabs/ModSecurity && \
    git -C /opt/ModSecurity submodule update --init --recursive && \
    (cd "/opt/ModSecurity" && \
        ./build.sh && \
        ./configure --with-lmdb && \
        make && \
        make install \
    ) && \
    rm -fr /opt/ModSecurity \
        /usr/local/modsecurity/lib/libmodsecurity.a \
        /usr/local/modsecurity/lib/libmodsecurity.la

# Clone Modsec Nginx Connector, GeoIP, ModSec OWASP Rules, and download/extract nginx and GeoIP databases
RUN echo 'Cloning Modsec Nginx Connector, GeoIP, ModSec OWASP Rules, and download/extract nginx and GeoIP databases' && \
    git clone -b master --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git && \
    git clone -b master --depth 1 https://github.com/leev/ngx_http_geoip2_module.git && \
    git clone -b ${OWASP_BRANCH} --depth 1 https://github.com/SpiderLabs/owasp-modsecurity-crs /usr/local/owasp-modsecurity-crs && \
    wget -O - https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz | tar -xz && \
    mkdir -p /etc/nginx/geoip && \
    wget -O - https://download.db-ip.com/free/dbip-city-lite-${GEO_DB_RELEASE}.mmdb.gz | gzip -d > /etc/nginx/geoip/dbip-city-lite.mmdb && \
    wget -O - https://download.db-ip.com/free/dbip-country-lite-${GEO_DB_RELEASE}.mmdb.gz | gzip -d > /etc/nginx/geoip/dbip-country-lite.mmdb

# Install GeoIP2 and ModSecurity Nginx modules
RUN echo 'Installing Nginx Modules' && \
    (cd "/opt/nginx-$NGINX_VERSION" && \
        ./configure --with-compat \
            --add-dynamic-module=../ModSecurity-nginx \
            --add-dynamic-module=../ngx_http_geoip2_module && \
        make modules \
    ) && \
    cp /opt/nginx-$NGINX_VERSION/objs/ngx_http_modsecurity_module.so \
        /opt/nginx-$NGINX_VERSION/objs/ngx_http_geoip2_module.so \
        /usr/lib/nginx/modules/ && \
    rm -fr /opt/* && \
    apk del general-dependencies


FROM nginx:${NGINX_VER}-alpine

LABEL maintainer="Andrew Kimball"

# Copy nginx, owasp-modsecurity-crs, and modsecurity from the build image
COPY --from=build_modsecurity /etc/nginx/ /etc/nginx/
COPY --from=build_modsecurity /usr/local/modsecurity /usr/local/modsecurity
COPY --from=build_modsecurity /usr/local/owasp-modsecurity-crs /usr/local/owasp-modsecurity-crs
COPY --from=build_modsecurity /usr/lib/nginx/modules/ /usr/lib/nginx/modules/

# Copy local config files into the image
COPY errors /usr/share/nginx/errors
COPY conf/nginx/ /etc/nginx/
COPY conf/modsec/ /etc/nginx/modsec/
COPY conf/owasp/ /usr/local/owasp-modsecurity-crs/

RUN apk add --no-cache \
    yajl \
    libstdc++ \
    libmaxminddb-dev \
    lmdb-dev \
    libxml2-dev \
    curl-dev \
    tzdata && \
    chown -R nginx:nginx /usr/share/nginx

WORKDIR /usr/share/nginx/html

EXPOSE 80 443

