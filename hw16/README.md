### В вагранте поднимаем 2 машины web и log на web поднимаем nginx на log настраиваем центральный лог сервер на любой системе на выбор
```
journald  
rsyslog  
elk   
```
### настраиваем аудит следящий за изменением конфигов нжинкса
все критичные логи с web должны собираться и локально и удаленно
все логи с nginx должны уходить на удаленный сервер (локально только критичные)
логи аудита должны также уходить на удаленную систему

Итак, будем реализовать решение на rsyslog

Запускаем стенд:
```
vagrant up
```
и раскатываем настройки:
```
ansible-playbook playbooks/deploy.yml
```
Для того, чтобы auditd следил за конфигами nginx добавим в /etc/audit/rules.d/audit.rules такие строки:
```
-w /etc/nginx/nginx.conf -p wa -k nginx_conf
-w /etc/nginx/default.d/ -p wa -k nginx_conf
```

для отправки критичных логов системы воспользуемся rsyslog, а именно - пропишем в /etc/rsyslog.conf следующую строку:
```
*.crit action(type="omfwd" target="{{ syslog_host }}" port="{{ syslog_port }}" protocol="tcp"  
              action.resumeRetryCount="100"  
              queue.type="linkedList" queue.size="10000")  
```

nginx
```
error_log /var/log/nginx/error.log crit;
error_log syslog:server={{ syslog_host }}:{{ syslog_port }},tag=nginx_error;

# access_log  /var/log/nginx/access.log  main;
access_log syslog:server={{ syslog_host }}:{{ syslog_port }},tag=nginx_access main;
```

логи audit'а уходят в rsyslog

Для этого установим плагин для auditd
И внесём соответствующие изменения в конфигурационные файлы: В `/etc/audisp/plugins.d/au-remote.conf` установим `active = yes` для отправки логов на удалённый сервер.
```
cat /etc/audisp/plugins.d/au-remote.conf

# This file controls the audispd data path to the
# remote event logger. This plugin will send events to
# a remote machine (Central Logger).

active = yes
direction = out
path = /sbin/audisp-remote
type = always
args = /etc/audisp/audisp-remote.conf
format = string
```
В /etc/audisp/audisp-remote.conf укажем куда слать логи аудита remote_server = 192.168.56.122, порт оставим по-умолчанию

В файле /etc/audit/auditd.conf поменяем значение в строке write_log на no - это отключит запись логов локально.


### Настройка сервера сбора логов

Настроим rsyslog на приём логов. Для этого в файле /etc/rsyslogd.conf раскомментируем строки:
```
$ModLoad imudp
$UDPServerRun 514

$ModLoad imtcp
$InputTCPServerRun 514
```

и добавим следующую конструкцию для разделения access и error логов nginx
```
    if ($hostname == 'web') and ($programname == 'nginx_access') then {
    action(type="omfile" file="/var/log/rsyslog/web/nginx_access.log")
    stop
    }

    if ($hostname == 'web') and ($programname == 'nginx_error') then {
    action(type="omfile" file="/var/log/rsyslog/web/nginx_error.log")
    stop
    }
```

Пример реакции на редактирование конфига nginx'а:
```
[root@log ~]# ausearch -i -k nginx_conf
Skipping line 36 in /etc/audit/auditd.conf: too long
----
node=web type=CONFIG_CHANGE msg=audit(12/15/21 10:28:27.802:1883) : auid=unset ses=unset subj=system_u:system_r:unconfined_service_t:s0 op=add_rule key=nginx_conf list=exit res=yes 
----
node=web type=CONFIG_CHANGE msg=audit(12/15/21 10:28:27.802:1884) : auid=unset ses=unset subj=system_u:system_r:unconfined_service_t:s0 op=add_rule key=nginx_conf list=exit res=yes 
[root@log ~]# 

```
Работает






