FROM node:18.18.0
RUN apt-get update
RUN apt-get install -y vim
RUN mkdir -p /usr/app
WORKDIR /usr/app
COPY ./src /usr/app/
RUN npm install