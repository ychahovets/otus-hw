Создайте свой кастомный образ nginx на базе alpine. После запуска nginx должен отдавать кастомную страницу (достаточно изменить дефолтную страницу nginx). Собранный образ необходимо запушить в docker hub и дать ссылку на ваш репозиторий.

Определите разницу между контейнером и образом

Ответьте на вопрос: Можно ли в контейнере собрать ядро?

Создайте свой кастомный образ nginx
Сначала необходимо создать dockerfile
Затем собрать докер образ


`sudo docker build -t ychahovets/nginx_ych:0.1 .`

```
Sending build context to Docker daemon  8.704kB
Step 1/8 : FROM alpine
latest: Pulling from library/alpine
a0d0a0d46f8b: Pull complete 
Digest: sha256:e1c082e3d3c45cccac829840a25941e679c25d438cc8412c2fa221cf1a824e6a
Status: Downloaded newer image for alpine:latest
 ---> 14119a10abf4
Step 2/8 : RUN apk update && apk add nginx
 ---> Running in 7c4cc332fe6a
fetch https://dl-cdn.alpinelinux.org/alpine/v3.14/main/x86_64/APKINDEX.tar.gz
fetch https://dl-cdn.alpinelinux.org/alpine/v3.14/community/x86_64/APKINDEX.tar.gz
v3.14.2-123-g010734651f [https://dl-cdn.alpinelinux.org/alpine/v3.14/main]
v3.14.2-120-g90167408c8 [https://dl-cdn.alpinelinux.org/alpine/v3.14/community]
OK: 14943 distinct packages available
(1/2) Installing pcre (8.44-r0)
(2/2) Installing nginx (1.20.1-r3)
Executing nginx-1.20.1-r3.pre-install
Executing nginx-1.20.1-r3.post-install
Executing busybox-1.33.1-r3.trigger
OK: 7 MiB in 16 packages
Removing intermediate container 7c4cc332fe6a
 ---> 06a8144a4b6b
Step 3/8 : COPY ./index.html /usr/share/nginx/html/index.html
 ---> 5c6613b2de68
Step 4/8 : COPY ./nginx.conf /etc/nginx/
 ---> ecc5bf1df469
Step 5/8 : COPY ./default.conf /etc/nginx/conf.d/
 ---> f351d1d93539
Step 6/8 : RUN  chmod +r /usr/share/nginx/html/index.html
 ---> Running in 57b69767fb8d
Removing intermediate container 57b69767fb8d
 ---> bc8a23a15840
Step 7/8 : EXPOSE 80
 ---> Running in c10be602c965
Removing intermediate container c10be602c965
 ---> 9b3311b50450
Step 8/8 : CMD ["nginx", "-g", "daemon off;"]
 ---> Running in 7180c776e798
Removing intermediate container 7180c776e798
 ---> da8083b3eeda
Successfully built da8083b3eeda
Successfully tagged ychahovets/nginx_ych:0.1

```    
   
Запустить контейнер

`docker run -d -p 80:80 ychahovets/nginx_ych:0.1`

Добавляем контейнер в docker hub

`docker push ychahovets/nginx_ych:0.1`

Проверка доступности:

`curl localhost:80`


Ссылка на docker hub с образом:
`https://hub.docker.com/repository/docker/ychahovets/nginx_ych`

Образ - "сущность" стека слоев только для чтения.Контейнер - "сущность" стека слоев с верхним слоем для записи.

Можно, только контейнер нужно будет запускать с привилигерованными правами

Полезное:
```
docker stop $(docker ps -aq)
docker build -t id/cont-name:ver .
docker commit nginx-base
docker exec -it container_id /bin/bash
docker-compose exec {CONTAINER_NAME} {COMMAND}
ENV - переменные окружения
ARG - переменные во время сборки
COPY - скопировать файл или папку
ADD - скопировать файл или папку, скачать по ссылке, разархивировать архив
EXPOSE - документация
Контейнер- Это приложение и его зависимости упакованные в окружение
```

