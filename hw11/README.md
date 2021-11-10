Запустить nginx на нестандартном порту 3-мя разными способами:

переключатели setsebool;
добавление нестандартного порта в имеющийся тип;
формирование и установка модуля SELinux. 
К сдаче:
README с описанием каждого решения (скриншоты и демонстрация приветствуются).

Обеспечить работоспособность приложения при включенном selinux.

Развернуть приложенный стенд https://github.com/mbfx/otus-linux-adm/tree/master/selinux_dns_problems
Выяснить причину неработоспособности механизма обновления зоны (см. README);
Предложить решение (или решения) для данной проблемы;
Выбрать одно из решений для реализации, предварительно обосновав выбор;
Реализовать выбранное решение и продемонстрировать его работоспособность. К сдаче:
README с анализом причины неработоспособности, возможными способами решения и обоснованием выбора одного из них;
Исправленный стенд или демонстрация работоспособной системы скриншотами и описанием.

Задание I

Развернём стенд командой

vagrant up

Теперь можем запустить ansible роль nginx которая установит нам NGINX

ansible-playbook playbooks/deploy.yml

В результате nginx будет установлен и настроен на работу на порту 80.  Осталось только перезапустить сервис.
```
[root@hw11 vagrant]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)
   Active: active (running) since Wed 2021-11-10 11:12:29 UTC; 16min ago
  Process: 5545 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 5543 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 5541 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 5547 (nginx)
   CGroup: /system.slice/nginx.service
           ├─5547 nginx: master process /usr/sbin/nginx
           └─5550 nginx: worker process

Nov 10 11:12:29 hw11 systemd[1]: Starting The nginx HTTP and reverse proxy server...
Nov 10 11:12:29 hw11 nginx[5543]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Nov 10 11:12:29 hw11 nginx[5543]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Nov 10 11:12:29 hw11 systemd[1]: Started The nginx HTTP and reverse proxy server.
```


Перезапускаем его новым значение порта `port:5555`:

systemctl restart nginx
```
[root@hw11 vagrant]# systemctl restart nginx
Job for nginx.service failed because the control process exited with error code. See "systemctl status nginx.service" and "journalctl -xe" for details.
```
Что-то пошло не так.
```
[root@hw11 vagrant]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)
   Active: failed (Result: exit-code) since Tue 2021-11-09 15:54:12 UTC; 34s ago
  Process: 6627 ExecReload=/usr/sbin/nginx -s reload (code=exited, status=0/SUCCESS)
  Process: 5017 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 6706 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=1/FAILURE)
  Process: 6705 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 5019 (code=exited, status=0/SUCCESS)

Nov 09 15:54:12 hw11 systemd[1]: Starting The nginx HTTP and reverse proxy server...
Nov 09 15:54:12 hw11 nginx[6706]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Nov 09 15:54:12 hw11 nginx[6706]: nginx: [emerg] bind() to 0.0.0.0:5555 failed (13: Permission denied)
Nov 09 15:54:12 hw11 nginx[6706]: nginx: configuration file /etc/nginx/nginx.conf test failed
Nov 09 15:54:12 hw11 systemd[1]: nginx.service: control process exited, code=exited status=1
Nov 09 15:54:12 hw11 systemd[1]: Failed to start The nginx HTTP and reverse proxy server.
Nov 09 15:54:12 hw11 systemd[1]: Unit nginx.service entered failed state.
Nov 09 15:54:12 hw11 systemd[1]: nginx.service failed.
```


Есть одно подозрение...

sestatus
```
[root@hw11 vagrant]# sestatus 
SELinux status:                 enabled
SELinuxfs mount:                /sys/fs/selinux
SELinux root directory:         /etc/selinux
Loaded policy name:             targeted
Current mode:                   enforcing
Mode from config file:          enforcing
Policy MLS status:              enabled
Policy deny_unknown status:     allowed
Max kernel policy version:      31
```
И 100%-е подтверждение

audit2why < /var/log/audit/audit.log

audit2why выхлоп:
```
[root@hw11 vagrant]# audit2why < /var/log/audit/audit.log
type=AVC msg=audit(1636473140.846:2077): avc:  denied  { name_bind } for  pid=5019 comm="nginx" src=5555 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0

        Was caused by:
        The boolean nis_enabled was set incorrectly. 
        Description:
        Allow nis to enabled

        Allow access by executing:
        # setsebool -P nis_enabled 1
type=AVC msg=audit(1636473252.783:2119): avc:  denied  { name_bind } for  pid=6706 comm="nginx" src=5555 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0

        Was caused by:
        The boolean nis_enabled was set incorrectly. 
        Description:
        Allow nis to enabled

        Allow access by executing:
        # setsebool -P nis_enabled 1
```

```
semanage port -l | grep 5555
```
А в ответ - пусто. Проверим `audit.log` средством `sealert`.
```
sealert -a /var/log/audit/audit.log
```

результат проверки `audit.log` и дальнейшие рекомендации.

Нам предлагают три варианта действий: 
I   - разрешить nginx работать на порту 5555 командой semanage
II  - включить nis_enabled командой setsebool 
III - собрать модуль с политикой, разрешающей работу nginx работать на порту 5555

Вариант I
semanage port...

Кроме команды нам предложили варианты, куда можно прописать наш порт:

    where PORT_TYPE is one of the following: http_cache_port_t, http_port_t, jboss_management_port_t, jboss_messaging_port_t, ntop_port_t, puppet_port_t.

http_port_t подходит к нашему httpd_t. 
Пропишем порт для SELinux 

semanage port -a -t http_port_t -p tcp 5555

Запустим nginx

```
systemctl start nginx
systemctl status nginx

[root@hw11 vagrant]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)
   Active: active (running) since Wed 2021-11-10 11:07:12 UTC; 4s ago
  Process: 4813 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 4811 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 4810 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 4815 (nginx)
   CGroup: /system.slice/nginx.service
           ├─4815 nginx: master process /usr/sbin/nginx
           └─4817 nginx: worker process

Nov 10 11:07:12 hw11 systemd[1]: Starting The nginx HTTP and reverse proxy server...
Nov 10 11:07:12 hw11 nginx[4811]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Nov 10 11:07:12 hw11 nginx[4811]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Nov 10 11:07:12 hw11 systemd[1]: Started The nginx HTTP and reverse proxy server.
```
Работает

Вернём начальное состояние:
```
semanage port -d -t http_port_t -p tcp 5555
systemctl restart nginx

[root@hw11 vagrant]# systemctl restart nginx
Job for nginx.service failed because the control process exited with error code. See "systemctl status nginx.service" and "journalctl -xe" for details.
```

Вариант II

`setsebool 1`

Используем команду:
```
[root@hw11 vagrant]# setsebool -P nis_enabled 1
```

Отработало быстро и гарантирует результат:
```
systemctl start nginx
systemctl status nginx

    [root@task-13-selinux ~]# systemctl status nginx/
    ● nginx.service - The nginx HTTP and reverse proxy server/
    Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)/
    Active: active (running) since Wed 2021-07-07 21:51:58 UTC; 2s ago/
    Process: 3893 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)/
    Process: 3890 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)/
    Process: 3888 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)/
    Main PID: 3894 (nginx)/
    CGroup: /system.slice/nginx.service/
    ├─3894 nginx: master process /usr/sbin/nginx/
    └─3895 nginx: worker process/
    /
    Jul 07 21:51:58 task-13-selinux systemd[1]: Starting The nginx HTTP and reverse proxy server.../
    Jul 07 21:51:58 task-13-selinux nginx[3890]: nginx: the configuration file /etc/nginx/nginx.conf sy... ok/
    Jul 07 21:51:58 task-13-selinux nginx[3890]: nginx: configuration file /etc/nginx/nginx.conf test i...ful/
    Jul 07 21:51:58 task-13-selinux systemd[1]: Started The nginx HTTP and reverse proxy server./
```
NGINX работает на порту 5555
```
$ curl -I 192.168.56.111:5555
HTTP/1.1 200 OK
Server: nginx/1.20.1
Date: Wed, 10 Nov 2021 11:32:58 GMT
Content-Type: text/html
Content-Length: 4833
Last-Modified: Fri, 16 May 2014 15:12:48 GMT
Connection: keep-alive
ETag: "53762af0-12e1"
Accept-Ranges: bytes
```

Возвращаемся к предыдущему состоянию:
```
[root@hw11 vagrant]# setsebool -P nis_enabled 0
[root@hw11 vagrant]# systemctl restart nginx
Job for nginx.service failed because the control process exited with error code. See "systemctl status nginx.service" and "journalctl -xe" for details.
```

вариант III

Пользуемся инструкциями полученными в результате анализа audit.log :
```
[root@hw11 vagrant]# ausearch -c 'nginx' --raw | audit2allow -M my-nginx
******************** IMPORTANT ***********************
To make this policy package active, execute:

semodule -i my-nginx.pp
```

Формируем и устанавливаем модуль SELinux . Используем команду: 
```
[root@hw11 vagrant]# semodule -i my-nginx.pp
```
Стартуем nginx:
```
[root@hw11 vagrant]# systemctl start nginx
```
Проверяем статус:
```
[root@hw11 vagrant]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)
   Active: active (running) since Wed 2021-11-10 11:40:24 UTC; 23s ago
  Process: 24572 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 24569 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 24568 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 24574 (nginx)
   CGroup: /system.slice/nginx.service
           ├─24574 nginx: master process /usr/sbin/nginx
           └─24576 nginx: worker process

Nov 10 11:40:24 hw11 systemd[1]: Starting The nginx HTTP and reverse proxy server...
Nov 10 11:40:24 hw11 nginx[24569]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Nov 10 11:40:24 hw11 nginx[24569]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Nov 10 11:40:24 hw11 systemd[1]: Started The nginx HTTP and reverse proxy server.
```

NGINX снова слушает сеть на 5555 порту.

Задание II

Запустим стенд и проверим работу с клиента:

vagrant ssh client

```
[vagrant@client ~]$ dig @192.168.50.10 ns01.dns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.7 <<>> @192.168.50.10 ns01.dns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 20360
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;ns01.dns.lab.                  IN      A

;; ANSWER SECTION:
ns01.dns.lab.           3600    IN      A       192.168.50.10

;; AUTHORITY SECTION:
dns.lab.                3600    IN      NS      ns01.dns.lab.

;; Query time: 7 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Wed Nov 10 14:20:05 UTC 2021
;; MSG SIZE  rcvd: 71
```
############################################################################
Ок, теперь повторим попытку изменить зону:

[vagrant@client ~]$ nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> 
> update add www.ddns.lab. 60 A 192.168.50.15
> send
update failed: SERVFAIL

Ошибка воспроизводится. Идем на сервер ns01

vagrant ssh ns01

Для выяснения причины сначала выполняем на сервере
```
[root@ns01 vagrant]# cat  /var/log/audit/audit.log | audit2why
type=AVC msg=audit(1636555367.279:1969): avc:  denied  { create } for  pid=5260 comm="isc-worker0000" name="named.ddns.lab.view1.jnl" scontext=system_u:system_r:named_t:s0 tcontext=system_u:object_r:etc_t:s0 tclass=file permissive=0

        Was caused by:
                Missing type enforcement (TE) allow rule.

                You can use audit2allow to generate a loadable module to allow this access.
```

Видно что проблема с `named.ddns.lab.view1.jnl`. Проверим статус named.service
```
[root@ns01 vagrant]# systemctl status named
● named.service - Berkeley Internet Name Domain (DNS)
   Loaded: loaded (/usr/lib/systemd/system/named.service; enabled; vendor preset: disabled)
   Active: active (running) since Wed 2021-11-10 12:03:17 UTC; 2h 50min ago
  Process: 5258 ExecStart=/usr/sbin/named -u named -c ${NAMEDCONF} $OPTIONS (code=exited, status=0/SUCCESS)
  Process: 5256 ExecStartPre=/bin/bash -c if [ ! "$DISABLE_ZONE_CHECKING" == "yes" ]; then /usr/sbin/named-checkconf -z "$NAMEDCONF"; else echo "Checking of zone files is disabled"; fi (code=exited, status=0/SUCCESS)
 Main PID: 5260 (named)
   CGroup: /system.slice/named.service
           └─5260 /usr/sbin/named -u named -c /etc/named.conf

Nov 10 12:03:17 ns01 named[5260]: network unreachable resolving './DNSKEY/IN': 2001:500:2f::f#53
Nov 10 12:03:17 ns01 named[5260]: network unreachable resolving './NS/IN': 2001:500:2f::f#53
Nov 10 12:03:17 ns01 named[5260]: managed-keys-zone/default: Key 20326 for zone . acceptance timer complete...rusted
Nov 10 12:03:17 ns01 named[5260]: resolver priming query complete
Nov 10 12:03:17 ns01 named[5260]: managed-keys-zone/view1: Key 20326 for zone . acceptance timer complete: ...rusted
Nov 10 12:03:17 ns01 named[5260]: resolver priming query complete
Nov 10 14:42:47 ns01 named[5260]: client @0x7ff45c03c3e0 192.168.50.15#51129/key zonetransfer.key: view vie...proved
Nov 10 14:42:47 ns01 named[5260]: client @0x7ff45c03c3e0 192.168.50.15#51129/key zonetransfer.key: view vie....50.15
Nov 10 14:42:47 ns01 named[5260]: /etc/named/dynamic/named.ddns.lab.view1.jnl: create: permission denied
Nov 10 14:42:47 ns01 named[5260]: client @0x7ff45c03c3e0 192.168.50.15#51129/key zonetransfer.key: view vie... error
Hint: Some lines were ellipsized, use -l to show in full.
```
Проблема с созданием файла в директории /etc/named/dynamic 

Проверим контекст директории
```
[root@ns01 vagrant]# ls -Z /etc/named/dynamic/
-rw-rw----. named named system_u:object_r:etc_t:s0       named.ddns.lab
-rw-rw----. named named system_u:object_r:etc_t:s0       named.ddns.lab.view1
```
Установлен контекст etc_t.

Но по-умолчанию динамические зоны лежат в ls -Z /var/named/dynamic/ Глянем, какой же там контекст у файлов:
```
[root@ns01 vagrant]# ls -Z /var/named/dynamic/
-rw-r--r--. named named system_u:object_r:named_cache_t:s0 default.mkeys
-rw-r--r--. named named system_u:object_r:named_cache_t:s0 default.mkeys.jnl
-rw-r--r--. named named system_u:object_r:named_cache_t:s0 view1.mkeys
-rw-r--r--. named named system_u:object_r:named_cache_t:s0 view1.mkeys.jnl
```

Видим несовпадение - `/etc/named/dynamic/named.ddns.lab.view1` имеет контекст `etc_t`, а файлы в `/var/named/dynamic/` - `named_cache_t` Его и выставляем для `/etc/named/dynamic/`

```
[root@ns01 vagrant]# restorecon -R -v /etc/named/dynamic/
restorecon reset /etc/named/dynamic context unconfined_u:object_r:etc_t:s0->unconfined_u:object_r:named_cache_t:s0
restorecon reset /etc/named/dynamic/named.ddns.lab context system_u:object_r:etc_t:s0->system_u:object_r:named_cache_t:s0
restorecon reset /etc/named/dynamic/named.ddns.lab.view1 context system_u:object_r:etc_t:s0->system_u:object_r:named_cache_t:s0
```
Для сохранения изменений после перезагрузки необходимо выполнить команду
```
[root@ns01 vagrant]# semanage fcontext -a -t named_cache_t '/etc/named/dynamic(/.*)?'
```

Теперь попробуем снова обновить зону с клиента:
```
[vagrant@client ~]$ nsupdate -k /etc/named.zonetransfer.key 
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
> quit
```
Проверяем:
```
[vagrant@client ~]$ nslookup www.ddns.lab    
Server:         192.168.50.10
Address:        192.168.50.10#53

Name:   www.ddns.lab
Address: 192.168.50.15
```

Работает
