FROM alpine
RUN apk update && apk add nginx 
COPY ./index.html /usr/share/nginx/html/index.html
COPY ./nginx.conf /etc/nginx/
COPY ./default.conf /etc/nginx/conf.d/
RUN  chmod +r /usr/share/nginx/html/index.html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]