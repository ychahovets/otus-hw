FROM alpine:3.12
RUN  apk update && apk add nginx 
COPY ./index.html /usr/share/nginx/html/index.html
COPY ./nginx.conf /etc/nginx/
COPY ./default.conf /etc/nginx/conf.d/
RUN  chmod +r /usr/share/nginx/html/index.html
RUN  rm -rf /etc/apk/cache
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
