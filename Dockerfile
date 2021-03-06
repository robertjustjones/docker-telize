FROM ubuntu:15.10
MAINTAINER Etki etki@etki.name

EXPOSE 80

RUN apt-get update -yq > /dev/null && apt-get upgrade -yq > /dev/null \
    && apt-get install -yq gcc make wget zlib1g-dev libpcre3-dev libgeoip-dev > /dev/null

WORKDIR /tmp

RUN wget -nv -O /tmp/nginx.tar.gz http://nginx.org/download/nginx-1.9.5.tar.gz > /dev/null \
    && wget -nv -O /tmp/nginx.echo.tar.gz https://github.com/openresty/echo-nginx-module/archive/v0.58.tar.gz > /dev/null \
    && wget -nv -O /tmp/luajit.tar.gz http://luajit.org/download/LuaJIT-2.0.4.tar.gz > /dev/null \
    && wget -nv -O /tmp/nginx-dev-kit.tar.gz https://github.com/simpl/ngx_devel_kit/archive/v0.2.19.tar.gz > /dev/null \
    && wget -nv -O /tmp/nginx-lua.tar.gz https://github.com/openresty/lua-nginx-module/archive/v0.9.19.tar.gz > /dev/null \
    && wget -nv -O /tmp/nginx.more.headers.tar.gz https://github.com/openresty/headers-more-nginx-module/archive/v0.28.tar.gz > /dev/null \
    && wget -nv -O /tmp/lua-cjson.tar.gz https://github.com/mpx/lua-cjson/archive/2.1.0.tar.gz > /dev/null \
    && wget -nv -O /tmp/lua-iconv.tar.gz https://github.com/downloads/ittner/lua-iconv/lua-iconv-7.tar.gz > /dev/null \
    && wget -nv -O /tmp/telize.tar.gz https://github.com/fcambus/telize/archive/1.04.tar.gz > /dev/null \
    && wget -nv -O /tmp/geoipv6.dat.gz http://geolite.maxmind.com/download/geoip/database/GeoIPv6.dat.gz > /dev/null \
    && wget -nv -O /tmp/geolitecityv6.dat.gz http://geolite.maxmind.com/download/geoip/database/GeoLiteCityv6-beta/GeoLiteCityv6.dat.gz > /dev/null \
    && wget -nv -O /tmp/geoipasnumv6.dat.gz http://download.maxmind.com/download/geoip/database/asnum/GeoIPASNumv6.dat.gz > /dev/null \
    && for i in *.tar.gz; do tar -xzf $i; done \
    && gunzip *.dat.gz \
    && rm *.gz \
    && mkdir -p /usr/share/geoip \
    && for i in *.dat; do mv $i `echo /usr/share/geoip/$i | tr [:upper:] [:lower:]`; done \
    && mkdir -p /var/log/nginx

RUN make --directory=/tmp/LuaJIT-2.0.4 > /dev/null \
    && make install --directory=/tmp/LuaJIT-2.0.4  > /dev/null \
    && ln -s $(which luajit) /usr/bin/lua

ENV LUAJIT_LIB=/usr/local/lib LUA_INCLUDE_DIR=/usr/local/include/luajit-2.0 \
    LUAINC=/usr/local/include/luajit-2.0 \
    LUAJIT_INC=/usr/local/include/luajit-2.0

RUN make --directory=/tmp/lua-cjson-2.1.0 LUA_INCLUDE_DIR=$LUA_INCLUDE_DIR > /dev/null \
    && make install --directory=/tmp/lua-cjson-2.1.0 > /dev/null

RUN make --directory=/tmp/lua-iconv-7 LUABIN=luajit LUAPKG=5.1 \
        CFLAGS="-I$LUA_INCLUDE_DIR -fPIC -O3 -Wall -fomit-frame-pointer" > /dev/null \
    && make install --directory=/tmp/lua-iconv-7 > /dev/null

WORKDIR /tmp/nginx-1.9.5

RUN /tmp/nginx-1.9.5/configure --with-http_geoip_module \
    --with-http_realip_module --with-ipv6 \
    --add-module=/tmp/ngx_devel_kit-0.2.19 \
    --add-module=/tmp/lua-nginx-module-0.9.19 \
    --add-module=/tmp/headers-more-nginx-module-0.28 \
    --add-module=/tmp/echo-nginx-module-0.58 \
    --with-ld-opt="-Wl,-rpath,$LUAJIT_LIB" \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf > /dev/null \
    && make -j2 > /dev/null \
    && make install > /dev/null

RUN mkdir -p /etc/nginx/sites-enabled && cp /tmp/telize-1.04/*.conf /etc/nginx \
    && cp /tmp/telize-1.04/telize /etc/nginx/sites-enabled/telize.conf

ADD nginx.conf /etc/nginx/
RUN nginx -t

RUN rm -rf /tmp/LuaJIT* /tmp/echo-nginx-module* /tmp/lua-nginx-module* \
    /tmp/nginx* /tmp/ngx_devel_kit* /tmp/headers-more-nginx-module* \
    /tmp/lua-cjson* /tmp/lua-iconv* /tmp/telize*

CMD ["nginx", "-g", "daemon off;"]