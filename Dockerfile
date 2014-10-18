FROM ubuntu:14.04
MAINTAINER Li Meng Jun "lmjubuntu@gmail.com"

RUN apt-get update && \
    apt-get install -y --force-yes nodejs npm && \
    ln -s /usr/bin/nodejs /usr/bin/node

RUN npm install -g react-tools coffee-script less browserify uglify-js

ENV TZ Asia/Shanghai

ADD . /src

RUN cd /src && \
    npm install && \
    make

WORKDIR /src

EXPOSE 3000

CMD node app.js
