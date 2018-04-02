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
        sed

RUN echo "Installing ModSec Library" && \
    git clone -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity /opt/ModSecurity

WORKDIR /opt/ModSecurity

RUN git submodule init && \
    git submodule update && \
    ./build.sh && \
    ./configure && make && make install && \
    echo "Finished Installing ModSec Library"

WORKDIR /opt

RUN echo 'Installing ModSec - Nginx connector' && \
    git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git && \
    wget http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz && \
    tar zxvf nginx-$NGINX_VERSION.tar.gz

WORKDIR /opt/nginx-$NGINX_VERSION

RUN ./configure --with-compat --add-dynamic-module=../ModSecurity-nginx && \
    make modules && \
    cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules && \
    echo "Finished Installing ModSec - Nginx connector"

RUN echo "Begin installing ModSec OWASP Rules" && \
    mkdir /etc/nginx/modsec && \
    wget -P /etc/nginx/modsec/ https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/modsecurity.conf-recommended && \
    mv /etc/nginx/modsec/modsecurity.conf-recommended /etc/nginx/modsec/modsecurity.conf && \
    sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/nginx/modsec/modsecurity.conf

WORKDIR /opt

RUN git clone -b v3.0/master https://github.com/SpiderLabs/owasp-modsecurity-crs && \
    mv owasp-modsecurity-crs/ /usr/local/ && \
    cp /usr/local/owasp-modsecurity-crs/crs-setup.conf.example /usr/local/owasp-modsecurity-crs/crs-setup.conf

RUN echo 'Creating modsec file' && \
    echo -e '# From https://github.com/SpiderLabs/ModSecurity/blob/master/\n \
      # modsecurity.conf-recommended\n \
      # Edit to set SecRuleEngine On\n \
      Include "/etc/nginx/modsec/modsecurity.conf"\n \
      # OWASP CRS v3 rules\n \
      Include "/usr/local/owasp-modsecurity-crs/crs-setup.conf"\n \
      Include "/usr/local/owasp-modsecurity-crs/rules/*.conf"'\
      >>/etc/nginx/modsec/main.conf && \
      chown nginx:nginx /etc/nginx/modsec/main.conf

RUN rm -fr /etc/nginx/conf.d/ && \
    rm -fr /etc/nginx/nginx.conf

COPY conf/nginx.conf /etc/nginx
COPY conf/conf.d /etc/nginx/conf.d
COPY errors /usr/share/nginx/errors

RUN chown -R nginx:nginx /usr/share/nginx

#delete uneeded and clean up
RUN apk del .build-deps && \
    apk del .libmodsecurity-deps && \
    rm -fr ModSecurity && \
    rm -fr ModSecurity-nginx && \
    rm -fr nginx-$NGINX_VERSION.tar.gz && \
    rm -fr nginx-$NGINX_VERSION

WORKDIR /usr/share/nginx/html
