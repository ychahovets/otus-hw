### *Домашнее задание*
### 1) Создать свой RPM пакет  (можно взять свое приложение, либо собрать, например, 
### апач с определенными опциями)
### 2) Создать свой репозиторий и разместить там ранее собранный RPM
### Реализовать это все либо в Vagrant, либо развернуть у себя через NGINX и дать ссылку 
### на репозиторий.
### ● Для данного задания нам понадобятся следующие установленные пакеты, которые мы установим через config.sh:
```
redhat-lsb-core wget rpmdevtools rpm-build createrepo yum-utils gcc tree
```

### Создать свой RPM пакет
### ● Для примера возьмем пакет NGINX и соберем его с поддержкой openssl
### ● Загрузим SRPM пакет NGINX для дальнейшей работы над ним:
```
[root@hw06 ~]# wget https://nginx.org/packages/centos/7/SRPMS/nginx-1.20.1-1.el7.ngx.src.rpm
```

### ● При установке такого пакета в домашней директории создается древо каталогов для 
### сборки: 
```
[root@hw06 ~]# rpm -i nginx-1.20.1-1.el7.ngx.src.rpm
```

### ● Также нужно скачать и разархивировать последний исходники для openssl - он 
### потребуется при сборке
```
[root@hw06 ~]# wget https://www.openssl.org/source/openssl-1.1.1l.tar.gz --no-check-certificate
```
### Распакуем:
```
[root@hw06 ~]tar -xvf openssl-1.1.1l.tar.gz
```

### Заранее поставим все зависимости чтобы в процессе сборки не было ошибок
```
[root@hw06 ~]# yum-builddep rpmbuild/SPECS/nginx.spec
```

### Исправим spec файл - добавим нужные опции
```
[root@hw06 ~]# sed -i "s#--with-debug#--with-openssl=/root/openssl-1.1.1l#g" rpmbuild/SPECS/nginx.spec
```

### Теперь можно приступить к сборке RPM пакета:
```
[root@hw06 ~]# rpmbuild -bb rpmbuild/SPECS/nginx.spec
```

```
Wrote: /root/rpmbuild/RPMS/x86_64/nginx-1.20.1-1.el7.ngx.x86_64.rpm
Wrote: /root/rpmbuild/RPMS/x86_64/nginx-debuginfo-1.20.1-1.el7.ngx.x86_64.rpm
Executing(%clean): /bin/sh -e /var/tmp/rpm-tmp.rC857Q
+ umask 022
+ cd /root/rpmbuild/BUILD
+ cd nginx-1.20.1
+ /usr/bin/rm -rf /root/rpmbuild/BUILDROOT/nginx-1.20.1-1.el7.ngx.x86_64
+ exit 0
```
### Убедимся что пакеты создались:
```
[root@hw06 ~]# ll rpmbuild/RPMS/x86_64/
total 3908
-rw-r--r--. 1 root root 2038920 окт  5 11:23 nginx-1.20.1-1.el7.ngx.x86_64.rpm
-rw-r--r--. 1 root root 1960568 окт  5 11:23 nginx-debuginfo-1.20.1-1.el7.ngx.x86_64.rpm
```
### Теперь установим собранный пакет
```
[root@hw06 ~]# yum localinstall -y rpmbuild/RPMS/x86_64/nginx-1.20.1-1.el7.ngx.x86_64.rpm
```
### И убедимся, что всё работает
```
[root@hw06 ~]# systemctl start nginx

[root@hw06 ~]# systemctl status nginx
● nginx.service - nginx - high performance web server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Вт 2021-10-05 11:50:16 UTC; 24min ago
     Docs: http://nginx.org/en/docs/
  Process: 19914 ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx.conf (code=exited, status=0/SUCCESS)
 Main PID: 19915 (nginx)
   CGroup: /system.slice/nginx.service
           ├─19915 nginx: master process /usr/sbin/nginx -c /etc/nginx/nginx.conf
           └─19916 nginx: worker process

окт 05 11:50:15 hw06 systemd[1]: Starting nginx - high performance web server...
окт 05 11:50:15 hw06 systemd[1]: Can't open PID file /var/run/nginx.pid (yet?) after start: No such file or directory
окт 05 11:50:16 hw06 systemd[1]: Started nginx - high performance web server.
```

### ● Теперь приступим к созданию своего репозитория. Директория для статики у NGINX по 
### умолчанию /usr/share/nginx/html. Создадим там каталог repo:
```
[root@hw06 ~]# mkdir /usr/share/nginx/html/repo
```

### ● Копируем туда наш собранный RPM и, например, RPM для установки репозитория 
### Percona-Server:
```
[root@hw06 ~]# cp rpmbuild/RPMS/x86_64/nginx-1.20.1-1.el7.ngx.x86_64.rpm /usr/share/nginx/html/repo/

[root@hw06 ~]# wget https://downloads.percona.com/downloads/percona-release/percona-release-1.0-9/redhat/percona-release-1.0-9.noarch.rpm -O /usr/share/nginx/html/repo/percona-release-1.0-9.noarch.rpm
```
### Инициализируем репозиторий командой:
```
[root@hw06 ~]# createrepo /usr/share/nginx/html/repo/
```
### Но мы хотим увидеть наш репо в браузере. Поэтому добавим в location / в файле /etc/nginx/conf.d/default.conf директиву autoindex on
```
[root@hw06 ~]# sed -i '/index  index.html index.htm;/ a autoindex on;' /etc/nginx/conf.d/default.conf
```
### Проверяем синтаксис и перезапускаем NGINX:
```
[root@hw06 ~]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
[root@hw06 ~]# nginx -s reload
```
### Теперь ради интереса можно посмотреть в браузере или curl-ануть:
```
[root@hw06 ~]# curl http://localhost/repo/
```
<html>
<head><title>Index of /repo/</title></head>
<body>
<h1>Index of /repo/</h1><hr><pre><a href="../">../</a>
<a href="repodata/">repodata/</a>                                          05-Oct-2021 12:29                   -
<a href="nginx-1.20.1-1.el7.ngx.x86_64.rpm">nginx-1.20.1-1.el7.ngx.x86_64.rpm</a>                  05-Oct-2021 12:19             2038920
<a href="percona-release-1.0-9.noarch.rpm">percona-release-1.0-9.noarch.rpm</a>                   11-Nov-2020 21:49               16664
</pre><hr></body>
</html>

### Все готово для того, чтобы протестировать репозиторий.
### Добавим его в /etc/yum.repos.d:
```
[root@hw06 ~]# cat >> /etc/yum.repos.d/otus.repo << EOF
> [otus]
> name=otus-linux
> baseurl=http://localhost/repo
> gpgcheck=0
> enabled=1
> EOF
```
### Убедимся что репозиторий подключился и посмотрим что в нем есть:
```
[root@hw06 ~]# yum repolist enabled | grep otus
otus                                otus-linux                                 2

[root@hw06 ~]# yum list | grep otus
percona-release.noarch                      1.0-9                      otus   
```

### Так как NGINX у нас уже стоит установим репозиторий percona-release:
```
[root@hw06 ~]# yum install percona-release -y
```
### Все прошло успешно. 
