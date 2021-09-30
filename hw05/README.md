# **Введение**

Цель данной лабораторной получить навыки работы с сетевой файловой системой NFS. На практике изучить команды управления.

---
# **Настройка сервера**

Установим пакет для работы с NFS:

```
yum install nfs-utils -y
```

Создадим общую директроию:

```
vagrant@nfsv3 ~]$ sudo mkdir /var/net_share
```

Пропишем этот каталог в конфигурационный файл NFS:

```
[vagrant@nfsv3 ~]$ cat /etc/exports
[vagrant@nfsv3 ~]$ sudo vi /etc/exports
/var/net_share/ *(rw)
```

Применим наши новые настройки и проверим видимость папки:

```
[vagrant@nfsv3 ~]$ sudo exportfs -rav
exporting *:/var/net_share
```

Наш каталог стал виден в опубликованных ресурсах: 

```
vagrant@nfsv3 ~]$ sudo exportfs -s
/var/net_share  *(sync,wdelay,hide,no_subtree_check,sec=sys,rw,root_squash,no_all_squash)
```
После запуска сервиса nfs можем посмотреть доступные для монтирования сетевые файловые системы:

```
vagrant@nfsv3 ~]$ sudo systemctl start nfs
[vagrant@nfsv3 ~]$ sudo systemctl status nfs
● nfs-server.service - NFS server and services
   Loaded: loaded (/usr/lib/systemd/system/nfs-server.service; disabled; vendor preset: disabled)
   Active: active (exited) since Thu 2021-09-30 14:38:30 UTC; 8s ago
  Process: 3658 ExecStartPost=/bin/sh -c if systemctl -q is-active gssproxy; then systemctl reload gssproxy ; fi (code=exited, status=0/SUCCESS)
  Process: 3641 ExecStart=/usr/sbin/rpc.nfsd $RPCNFSDARGS (code=exited, status=0/SUCCESS)
  Process: 3640 ExecStartPre=/usr/sbin/exportfs -r (code=exited, status=0/SUCCESS)
 Main PID: 3641 (code=exited, status=0/SUCCESS)
   CGroup: /system.slice/nfs-server.service

Sep 30 14:38:30 nfsv3 systemd[1]: Starting NFS server and services...
Sep 30 14:38:30 nfsv3 systemd[1]: Started NFS server and services.

[vagrant@nfsv3 ~]$ showmount -e
Export list for nfsv3:
/var/net_share *
```
Создадим папку `upload` в папке `net_share`:

```
[vagrant@nfsv3 ~]$ sudo mkdir /var/net_share/upload
```
###
# **Настройка клиента**

Проверим видимость сетевого ресурса с клиента:

```
[vagrant@client ~]$ showmount -e 10.0.0.42
Export list for 10.0.0.42:
/var/net_share *
```
Создадим директорию 

```
[vagrant@client ~]$ sudo mkdir /mnt/nfs
```

В нее примонтируем ресурс с требуемыми опциями (NFSv3 по UDP):

```
[vagrant@client ~]$ sudo mount -o nfsvers=3,udp 10.0.0.42:/var/net_share /mnt/nfs/
```

Проверим результат:

```
[vagrant@client ~]$ mount -t nfs
10.0.0.42:/var/net_share on /mnt/nfs type nfs (rw,relatime,vers=3,rsize=32768,wsize=32768,namlen=255,hard,proto=udp,timeo=11,retrans=3,sec=sys,mountaddr=10.0.0.42,mountvers=3,mountport=20048,mountproto=udp,local_lock=none,addr=10.0.0.42)
```
Из листинга видно, что ресурс примонтировался с использованием NFSv3 (vers=3) и по протоколу UDP (proto=udp,mountproto=udp)

Отмонтируем NFS ресурс, добавим строчку в файл `fstab` для автоматического монтирования ресурса и проверим монтирование:
###
```
[vagrant@client ~]$ sudo umount /mnt/nfs
[root@client ~]# echo '10.0.0.42:/var/net_share /mnt/nfs/ nfs nfsvers=3,udp 0 0' >> /etc/fstab
[root@client ~]# mount -a
[root@client ~]# mount -t nfs
10.0.0.42:/var/net_share on /mnt/nfs type nfs (rw,relatime,vers=3,rsize=32768,wsize=32768,namlen=255,hard,proto=udp,timeo=11,retrans=3,sec=sys,mountaddr=10.0.0.42,mountvers=3,mountport=20048,mountproto=udp,local_lock=none,addr=10.0.0.42)
```

Перегрузим клиентскую машину и проверим автоматическое монтирование NFS ресурса.
После перезагрузки проверяем примонтировался ли ресурс:

```
[vagrant@client ~]$ mount -t nfs
10.0.0.42:/var/net_share on /mnt/nfs type nfs (rw,relatime,vers=3,rsize=32768,wsize=32768,namlen=255,hard,proto=udp,timeo=11,retrans=3,sec=sys,mountaddr=10.0.0.42,mountvers=3,mountport=20048,mountproto=udp,local_lock=none,addr=10.0.0.42)

```

# **Проверка стенда**

Проверим создание файла в примонтированном ресурсе:

```
[vagrant@client ~]$ sudo touch /mnt/nfs/upload/test_fiel_v3
touch: cannot touch '/mnt/nfs/upload/test_fiel_v3': Permission denied
```

Доступ запрещён, т.к. созданная на сервере папка `upload` не имеет прав на запись:

```
[vagrant@nfsv3 ~]$ ls -la /var/net_share/
total 0
drwxr-xr-x.  3 root root  20 Sep 30 14:39 .
drwxr-xr-x. 19 root root 271 Sep 30 14:33 ..
drwxr-xr-x.  2 root root   6 Sep 30 14:39 upload
```
###
Добавим права и попоробуем снова создать файл:

```
[vagrant@nfsv3 ~]$ sudo chmod o+w /var/net_share/upload

[vagrant@client ~]$ sudo touch /mnt/nfs/upload/test_fiel_v3
[vagrant@client ~]$

[vagrant@nfsv3 ~]$ ls -la /var/net_share/upload/
total 0
drwxr-xrwx. 2 root      root      26 Sep 30 14:56 .
drwxr-xr-x. 3 root      root      20 Sep 30 14:39 ..
-rw-r--r--. 1 nfsnobody nfsnobody  0 Sep 30 14:56 test_fiel_v3
```

Файл успешно создан.


### **Заключение**

В процессе выполнения домашней работы были на практике применены утилиты для работы с NFS. Были созданы сетевые ресурсы на сервере и примонтированы на клиенте. Проверена работа прав доступа к сетевым ресурсам и опций монтирования.