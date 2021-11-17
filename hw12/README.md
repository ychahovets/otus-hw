### Systemd
### Написать сервис watchlog, запускаемый по расписанию
При запуске VM этот каталог скопируется внутрь гостевой системы в каталог /vagrant. Скопируем файлы сервиса в необходимые каталоги, сделаем файл скрипта исполняемым
```
sudo -s
cp -r /vagrant/watchlog/* /
chmod +x /opt/watchlog.sh
```

Необходимые нам файлы расположем в подкаталоге рабочего каталога watchlog, 
посмотрим что внутри

`[root@hw12 vagrant]# cat /etc/sysconfig/watchlog `
```
# Configuration file for my watchdog service
# Place it to /etc/sysconfig
# File and word in that file that we will be monit
WORD="ALERT"
LOG=/var/log/watchlog.log[root@hw12 vagrant]# 
```

`[root@hw12 ~]# cat /etc/systemd/system/watchlog.service `

```
[Unit]
Description=My watchlog service
[Service]
Type=oneshot
EnvironmentFile=/etc/sysconfig/watchlog
ExecStart=/opt/watchlog.sh $WORD $LOG
```

`[root@hw12 ~]# cat /etc/systemd/system/watchlog.timer `
```
[Unit]
Description=Run watchlog script every 5 second
Requires=watchlog.service
[Timer]
# Run every 5 second
OnUnitActiveSec=5
AccuracySec=1us
Unit=watchlog.service
[Install]
WantedBy=multi-user.target
```

`[root@hw12 ~]# cat /opt/watchlog.sh `

```
#!/bin/bash
WORD=$1
LOG=$2
DATE=$(date)
if grep $WORD $LOG &>/dev/null; then
    logger "$DATE: keyword found!"
else
    exit 0
fi
```

`[root@hw12 ~]# cat /var/log/watchlog.log `
```
ALERT
```

Запустим timer командой `[root@hw12 ~]# systemctl start watchlog.timer `, 

проверим работу `[root@hw12 ~]# tail -f /var/log/messages `
```
Nov 16 10:30:55 localhost systemd: Started My watchlog service.
Nov 16 10:31:00 localhost systemd: Starting My watchlog service...
Nov 16 10:31:00 localhost root: Tue Nov 16 10:31:00 UTC 2021: keyword found!
Nov 16 10:31:00 localhost systemd: Started My watchlog service.
Nov 16 10:31:05 localhost systemd: Starting My watchlog service...
Nov 16 10:31:05 localhost root: Tue Nov 16 10:31:05 UTC 2021: keyword found!
Nov 16 10:31:05 localhost systemd: Started My watchlog service.
Nov 16 10:31:10 localhost systemd: Starting My watchlog service...
Nov 16 10:31:10 localhost root: Tue Nov 16 10:31:10 UTC 2021: keyword found!
Nov 16 10:31:10 localhost systemd: Started My watchlog service.
...
```
Работает!

### Из репозитория epel установить spawn-fcgi и переписать init-скрипт на unit-файл (имя service должно называться так же: spawn-fcgi).

Устанавливаем `spawn-fcgi` и необходимые пакеты

`[root@hw12 ~]# yum install epel-release -y && yum install spawn-fcgi php php-cli mod_fcgid httpd -y`

Копируем и заменяем файлы

`cp -fr /vagrant/spawn-fcgi/* / `
```
[root@hw12 ~]# cp -fr /vagrant/spawn-fcgi/* / 
cp: overwrite '/etc/sysconfig/spawn-fcgi'? y
cp: overwrite '/etc/systemd/system/spawn-fcgi.service'? y
```
Запускаем сервис, и смотрим состояние:
```
[root@hw12 ~]# systemctl start spawn-fcgi.service 
[root@hw12 ~]# systemctl status spawn-fcgi.service 
● spawn-fcgi.service - Spawn-fcgi startup service by hw otus
   Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; disabled; vendor preset: disabled)
   Active: active (running) since Tue 2021-11-16 13:09:08 UTC; 7s ago
 Main PID: 2769 (php-cgi)
   CGroup: /system.slice/spawn-fcgi.service
           ├─2769 /usr/bin/php-cgi
           ├─2770 /usr/bin/php-cgi
           ├─2771 /usr/bin/php-cgi
           ├─2772 /usr/bin/php-cgi
           ├─2773 /usr/bin/php-cgi
           ├─2774 /usr/bin/php-cgi
           ├─2775 /usr/bin/php-cgi
           ├─2776 /usr/bin/php-cgi
           ├─2777 /usr/bin/php-cgi
           ├─2778 /usr/bin/php-cgi
           ├─2779 /usr/bin/php-cgi
           ├─2780 /usr/bin/php-cgi
           ├─2781 /usr/bin/php-cgi
           ├─2782 /usr/bin/php-cgi
           ├─2783 /usr/bin/php-cgi
           ├─2784 /usr/bin/php-cgi
           ├─2785 /usr/bin/php-cgi
           ├─2786 /usr/bin/php-cgi
           ├─2787 /usr/bin/php-cgi
           ├─2788 /usr/bin/php-cgi
           ├─2789 /usr/bin/php-cgi
           ├─2790 /usr/bin/php-cgi
           ├─2791 /usr/bin/php-cgi
           ├─2792 /usr/bin/php-cgi
           ├─2793 /usr/bin/php-cgi
           ├─2794 /usr/bin/php-cgi
           ├─2795 /usr/bin/php-cgi
           ├─2796 /usr/bin/php-cgi
           ├─2797 /usr/bin/php-cgi
           ├─2798 /usr/bin/php-cgi
           ├─2799 /usr/bin/php-cgi
           ├─2800 /usr/bin/php-cgi
           └─2801 /usr/bin/php-cgi

Nov 16 13:09:08 hw12 systemd[1]: Started Spawn-fcgi startup service by hw otus.
```

### Дополнить unit-файл httpd (он же apache) возможностью запустить несколько инстансов сервера с разными конфигурационными файлами.

Установим `httpd (apache)` Мы его уже установили на предыдущем шаге. 

Копируем файлы 
```
[root@hw12 ~]# cp /vagrant/scripts/httpd@.service /etc/systemd/system/

[root@hw12 ~]# cp /vagrant/scripts/httpd@80* /etc/sysconfig/
```

Стопаем наш httpd (который установился)
```
[root@hw12 ~]# systemctl disable httpd
```

Копируем конфиги и редактируем настройки 
```
[root@hw12 ~]#  cp -a /etc/httpd /etc/httpd-8080
[root@hw12 ~]#  sed -i 's#^ServerRoot "/etc/httpd"$#ServerRoot "/etc/httpd-8080"#g' /etc/httpd-8080/conf/httpd.conf
[root@hw12 ~]# sed -i 's#^Listen 80$#Listen 8080#g' /etc/httpd-8080/conf/httpd.conf
[root@hw12 ~]#  cp -a /etc/httpd /etc/httpd-8081
```

Включаем сервис и стартуем его
```
[root@hw12 ~]# systemctl enable httpd@808{0,1}.service
[root@hw12 ~]# systemctl start httpd@808{0,1}.service
```

Смотрим статус
```
[root@hw12 ~]# systemctl status httpd@808{0,1}.service
● httpd@8080.service - The Apache HTTP Server instance 8080
   Loaded: loaded (/etc/systemd/system/httpd@.service; enabled; vendor preset: disabled)
   Active: active (running) since Wed 2021-11-17 13:13:51 UTC; 5s ago
     Docs: man:httpd(8)
           man:apachectl(8)
  Process: 3729 ExecStart=/usr/sbin/httpd $OPTIONS -c PidFile "/var/run/httpd/httpd-%i.pid" (code=exited, status=0/SUCCESS)
 Main PID: 3732 (httpd)
   CGroup: /system.slice/system-httpd.slice/httpd@8080.service
           ├─3732 /usr/sbin/httpd -d /etc/httpd-8080 -c PidFile "/var/run/httpd/httpd-8080.pid"
           ├─3734 /usr/sbin/httpd -d /etc/httpd-8080 -c PidFile "/var/run/httpd/httpd-8080.pid"
           ├─3740 /usr/sbin/httpd -d /etc/httpd-8080 -c PidFile "/var/run/httpd/httpd-8080.pid"
           ├─3741 /usr/sbin/httpd -d /etc/httpd-8080 -c PidFile "/var/run/httpd/httpd-8080.pid"
           ├─3742 /usr/sbin/httpd -d /etc/httpd-8080 -c PidFile "/var/run/httpd/httpd-8080.pid"
           ├─3743 /usr/sbin/httpd -d /etc/httpd-8080 -c PidFile "/var/run/httpd/httpd-8080.pid"
           └─3744 /usr/sbin/httpd -d /etc/httpd-8080 -c PidFile "/var/run/httpd/httpd-8080.pid"

Nov 17 13:13:51 hw12 systemd[1]: Starting The Apache HTTP Server instance 8080...
Nov 17 13:13:51 hw12 httpd[3729]: AH00558: httpd: Could not reliably determine the server's fully qualified domai...essage
Nov 17 13:13:51 hw12 systemd[1]: Can't open PID file /var/run/httpd/httpd-8080.pid (yet?) after start: No such fi...ectory
Nov 17 13:13:51 hw12 systemd[1]: Started The Apache HTTP Server instance 8080.

● httpd@8081.service - The Apache HTTP Server instance 8081
   Loaded: loaded (/etc/systemd/system/httpd@.service; enabled; vendor preset: disabled)
   Active: active (running) since Wed 2021-11-17 13:13:51 UTC; 5s ago
     Docs: man:httpd(8)
           man:apachectl(8)
  Process: 3730 ExecStart=/usr/sbin/httpd $OPTIONS -c PidFile "/var/run/httpd/httpd-%i.pid" (code=exited, status=0/SUCCESS)
 Main PID: 3731 (httpd)
   CGroup: /system.slice/system-httpd.slice/httpd@8081.service
           ├─3731 /usr/sbin/httpd -d /etc/httpd-8081 -c PidFile "/var/run/httpd/httpd-8081.pid"
           ├─3733 /usr/sbin/httpd -d /etc/httpd-8081 -c PidFile "/var/run/httpd/httpd-8081.pid"
           ├─3735 /usr/sbin/httpd -d /etc/httpd-8081 -c PidFile "/var/run/httpd/httpd-8081.pid"
           ├─3736 /usr/sbin/httpd -d /etc/httpd-8081 -c PidFile "/var/run/httpd/httpd-8081.pid"
           ├─3737 /usr/sbin/httpd -d /etc/httpd-8081 -c PidFile "/var/run/httpd/httpd-8081.pid"
           ├─3738 /usr/sbin/httpd -d /etc/httpd-8081 -c PidFile "/var/run/httpd/httpd-8081.pid"
           └─3739 /usr/sbin/httpd -d /etc/httpd-8081 -c PidFile "/var/run/httpd/httpd-8081.pid"

Nov 17 13:13:51 hw12 systemd[1]: Starting The Apache HTTP Server instance 8081...
Nov 17 13:13:51 hw12 httpd[3730]: AH00558: httpd: Could not reliably determine the server's fully qualified domai...essage
Nov 17 13:13:51 hw12 systemd[1]: Can't open PID file /var/run/httpd/httpd-8081.pid (yet?) after start: No such fi...ectory
Nov 17 13:13:51 hw12 systemd[1]: Started The Apache HTTP Server instance 8081.
Hint: Some lines were ellipsized, use -l to show in full.
```
Работает
