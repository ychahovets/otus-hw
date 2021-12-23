## Настроить стенд Vagrant с двумя виртуальными машинами: backup_server и client

Настроить удаленный бекап каталога /etc c сервера client при помощи borgbackup. Резервные копии должны соответствовать следующим критериям:

Разворачиваем ВМ Vagrantfile -ом
Накатываем настройки и устанавливаем дополнительные приложения

Добавляем пользователя и даём ему права на директорию с бекапами

на клиенте генерим ему ключ для подключения по ssh


```
[root@client ~]# ssh-keygen 
```

### на сервере добавляем открытую часть ключа в `.ssh/authorized_keys`


### на клиенте добавляем алиас в /etc/hosts для доступа к серверу бекапов по имени хоста
```
[root@client ~]# echo "192.168.56.101 backup-server" >> /etc/hosts
```
Дальнейшие действия выполняем на клиенте: инициализируем репозиторий бекапов c включеным шифрованием (опция --encryption repokey)
```
[root@client ~]# borg init --encryption repokey back_oper@backup-server:/var/backup/client
Remote: Warning: Permanently added 'backup-server,192.168.56.101' (ECDSA) to the list of known hosts.
Enter new passphrase: 
Enter same passphrase again: 
Do you want your passphrase to be displayed for verification? [yN]: y
Your passphrase (between double-quotes): "Pass123"
Make sure the passphrase displayed above is exactly what you wanted.

By default repositories initialized with this version will produce security
errors if written to with an older version (up to and including Borg 1.0.8).

If you want to use these older versions, you can disable the check by running:
borg upgrade --disable-tam ssh://back_oper@backup-server/var/backup/client

See https://borgbackup.readthedocs.io/en/stable/changes.html#pre-1-0-9-manifest-spoofing-vulnerability for details about the security implications.

IMPORTANT: you will need both KEY AND PASSPHRASE to access this repo!
If you used a repokey mode, the key is stored in the repo, but you should back it up separately.
Use "borg key export" to export the key, optionally in printable format.
Write down the passphrase. Store both at safe place(s).
```
после вышеописанных действий на сервере бекапов в каталоге репы появится конфигурационный файл следующего содержания:
```
[root@backup-server ~]# cat /var/backup/client/config 
[repository]
version = 1
segments_per_dir = 1000
max_segment_size = 524288000
append_only = 0
storage_quota = 0
additional_free_space = 0
id = 5172da06d69ac58692866474c658e944cfbde0c33fad14b80706fc0720dbf546
key = hqlhbGdvcml0aG2mc2hhMjU2pGRhdGHaAN6qW2tYpcPC2B6MYEQtJcCoYo/+soTunYOQ6J
        BPuNoXqJTrYpST0CaFFnhC+WC+bdQjpSGSd3ng6ADrLuk9jFvc7BZXKKtrGx45QRZeXN3e
        tjpMyCQMkt7PE9o9d10nC1f/vgAOtUGMxQpxAFxp3QUYYeZWRNVIic+iHpFjLEvBa3LUZf
        xnLlaxdg9+kw2l45HKk35HMAFh9l5IQNw3oP7rBD5upUKqiz0QgkhDf4SSWRVixaE4R52S
        C23WXGOQ2u/PcgAHjJn0MWEKlkMVN3zFh43SP43FTKNPimAe4a+kaGFzaNoAIFQFZQAhXO
        8mQiBZrFY52QjLzI1+61A+Eo1gxEPrG6PVqml0ZXJhdGlvbnPOAAGGoKRzYWx02gAgts7W
        E7yGM8MjLeyoGLohIX81dZo/zQcNOuMBBge3ui6ndmVyc2lvbgE=


```
Для удобства работы пароль от ключа шифрования бекапа запишем в переменную окружения
`export BORG_PASSPHRASE='Pass123'`

Для запуска процесса бекапа подготовим скрипт `borg-back.sh`
содержимое `borg-back.sh`
```
#!/bin/bash
# Client and server name
BACKUP_USER=back_oper
BACKUP_HOST=backup-server
export BORG_PASSPHRASE='Pass123'
# Backup type, it may be data, system, mysql, binlogs, etc.
TYPEOFBACKUP="etc"
REPOSITORY=$BACKUP_USER@$BACKUP_HOST:/var/backup/$(hostname)
# Backup
borg create -v --stats $REPOSITORY::$TYPEOFBACKUP-$(date +%Y-%m-%d-%H-%M) /${TYPEOFBACKUP}
# Clear old backups
borg prune \
  -v --list \
  ${REPOSITORY} \
  --keep-daily=90 \
  --keep-monthly=9
```

В нём для выполнения условия глубины хранения используем следующую конструкцию: (то, что хранится согласно --keep-daily не идёт в зачёт --keep-monthly https://borgbackup.readthedocs.io/en/stable/usage/prune.html)
```
    borg prune \
    -v --list \
    ${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_REPO} \
    --keep-daily`=90 \
    --keep-monthly=9
```
для запуска бекапа с заданным интервалом сделаем systemd сервис и повесим на него timer
`borg-back.service`
```
[Unit]
Description=Borg backup
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=/root/borg-back.sh

[Install]
WantedBy=default.target
```
`borg-back.timer`
```
[Unit]
Description=Borg backup timer

[Timer]
#run hourly
OnBootSec=2min
OnUnitActiveSec=5min
Unit=borg-back.service

[Install]
WantedBy=multi-user.target
```

Запустим скрипт и убедимся, что он работает: 
`[root@client ~]# ./borg-back.sh`
```
[root@client ~]# ./borg-back.sh 
Creating archive at "back_oper@backup-server:/var/backup/client::etc-2021-12-23-11-54"
------------------------------------------------------------------------------
Archive name: etc-2021-12-23-11-54
Archive fingerprint: 0ee533295443d144935d2dbb2157b55971bfeeeb98db2f6148b27f21deaeb084
Time (start): Thu, 2021-12-23 11:54:02
Time (end):   Thu, 2021-12-23 11:54:03
Duration: 0.51 seconds
Number of files: 1704
Utilization of max. archive size: 0%
------------------------------------------------------------------------------
                       Original size      Compressed size    Deduplicated size
This archive:               28.44 MB             13.50 MB                665 B
All archives:               56.87 MB             27.00 MB             11.85 MB

                       Unique chunks         Total chunks
Chunk index:                    1289                 3416
------------------------------------------------------------------------------
Keeping archive: etc-2021-12-23-11-54                 Thu, 2021-12-23 11:54:02 [0ee533295443d144935d2dbb2157b55971bfeeeb98db2f6148b27f21deaeb084]
Pruning archive: etc-2021-12-23-11-51                 Thu, 2021-12-23 11:51:33 [e990004cd8d6d8c35f621269a5f0dbc500e83c0b295bfbb5b937c441de1c7025] (1/1)
```
посмотрим, что осталось в репозитории:

    [root@client ~]# borg list back_oper@backup-server:/var/backup/client
    etc-2021-07-18-17-00 Sun, 2021-07-18 17:00:27 [9a2bc614f2beb91608e010e7f27faf61df7026d8c21ef39715d2d6b6b5bd5779]

.... прошло не так много времени

статус `borg-back.service`
```
[root@client ~]# systemctl daemon-reload 
[root@client ~]# systemctl restart borg-back.service

[root@client ~]# systemctl status borg-back.service
● borg-back.service - Borg backup
   Loaded: loaded (/etc/systemd/system/borg-back.service; enabled; vendor preset: disabled)
   Active: inactive (dead) since Thu 2021-12-23 11:51:36 UTC; 3min 41s ago
  Process: 4963 ExecStart=/root/borg-back.sh (code=exited, status=0/SUCCESS)
 Main PID: 4963 (code=exited, status=0/SUCCESS)

Dec 23 11:51:34 client borg-back.sh[4963]: ---------------------------------------------------...---
Dec 23 11:51:34 client borg-back.sh[4963]: Original size      Compressed size    Deduplicated size
Dec 23 11:51:34 client borg-back.sh[4963]: This archive:               28.44 MB             13... kB
Dec 23 11:51:34 client borg-back.sh[4963]: All archives:               56.87 MB             27... MB
Dec 23 11:51:34 client borg-back.sh[4963]: Unique chunks         Total chunks
Dec 23 11:51:34 client borg-back.sh[4963]: Chunk index:                    1294                 3415
Dec 23 11:51:34 client borg-back.sh[4963]: ---------------------------------------------------...---
Dec 23 11:51:35 client borg-back.sh[4963]: Keeping archive: etc-2021-12-23-11-51              ...25]
Dec 23 11:51:35 client borg-back.sh[4963]: Pruning archive: etc-2021-12-23-11-49              .../1)
Dec 23 11:51:36 client systemd[1]: Started Borg backup.
Hint: Some lines were ellipsized, use -l to show in full.
```
И у нас есть один бекап - последний за текущий день
```
[root@client ~]# borg list back_oper@backup-server:/var/backup/client
Enter passphrase for key ssh://back_oper@backup-server/var/backup/client: 
etc-2021-12-23-11-54                 Thu, 2021-12-23 11:54:02 [0ee533295443d144935d2dbb2157b55971bfeeeb98db2f6148b27f21deaeb084]
```
Работает
