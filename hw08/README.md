### Скрипт запускается каждую минуту
```
echo "*/1 * * * * /vagrant/script.sh" | crontab
```

### После старта vm можно подключится и проверить:

>  vagrant ssh
```
[root@centos8 ~]# cd /vagrant/
[root@centos8 vagrant]# cat logparser.letter 
Mon Dec 6 13:01:01 UTC 2021
```
### Ничего нового в логах за последний период

пока мы подключались скрипт сработал уже более одного раза и обработал файл, а нового ничего туда не попало.

Добавим в лог немного записей и посмотрим на результат:

```
[root@centos8 vagrant]# cat access-4560-644067.log | head -n 300 >> access-4560-644067.log
```