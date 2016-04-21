FROM ubuntu:14.04
MAINTAINER Li Meng Jun "lmjubuntu@gmail.com"

RUN apt-get update && \
    apt-get install -y --force-yes wget make gcc

RUN wget https://nodejs.org/dist/v5.10.1/node-v5.10.1-linux-x64.tar.gz && \
    tar xvf node-v5.10.1-linux-x64.tar.gz && \
    cp -av node-v5.10.1-linux-x64/* /usr/local/ && \
    rm -rf node*

RUN npm install -g react-tools coffee-script less browserify uglify-js
ENV TZ Asia/Shanghai

ADD . /src

RUN cd /src && \
    npm install && \
    make

WORKDIR /src

EXPOSE 3000

CMD node app.js
