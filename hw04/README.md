# **Введение**

Цель данной лабораторной работы на практике изучить команды для управления файловой системой ZFS.

# **Определить алгоритм с наилучшим сжатием**

Создадим несколько томов, проверим их параметры, определим доступные алгоритмы сжатия и сравним их эффективность.


### **Создание файловых систем**

Посмотрим какие блочные устройства есть в системе:

```
[vagrant@server ~]$ lsblk 
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
sda      8:0    0  10G  0 disk 
`-sda1   8:1    0  10G  0 part /
sdb      8:16   0   1G  0 disk 
sdc      8:32   0   1G  0 disk 
sdd      8:48   0   1G  0 disk 
sde      8:64   0   1G  0 disk 
sdf      8:80   0   1G  0 disk 
sdg      8:96   0   1G  0 disk
```

Создадим zfs pool. Для этого выполним:

```
[vagrant@server ~]$ sudo zpool create bigdata /dev/sd[b-g]
```

Проверим:

```
[vagrant@server ~]$ sudo zpool status
  pool: bigdata
 state: ONLINE
  scan: none requested
config:

	NAME        STATE     READ WRITE CKSUM
	bigdata     ONLINE       0     0     0
	  sdb       ONLINE       0     0     0
	  sdc       ONLINE       0     0     0
	  sdd       ONLINE       0     0     0
	  sde       ONLINE       0     0     0
	  sdf       ONLINE       0     0     0
	  sdg       ONLINE       0     0     0

errors: No known data errors

[vagrant@server ~]$ sudo zpool list
NAME      SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
bigdata  5.62G    96K  5.62G        -         -     0%     0%  1.00x    ONLINE  -
```

Перейдём к созданию файловых систем:

```
[vagrant@server ~]$ sudo zfs create bigdata/zfs_gzip
[vagrant@server ~]$ sudo zfs create bigdata/zfs_lz4
[vagrant@server ~]$ sudo zfs create bigdata/zfs_lzjb
[vagrant@server ~]$ sudo zfs create bigdata/zfs_zle
```

### **Изменение настроек файловых систем**

Доступные значения для установки сжатия данных:

compression=on|off|gzip|gzip-N|lz4|lzjb|zle

Установим каждой файловой системе соответствующий алгоритм сжатия:

```
[vagrant@server ~]$ sudo zfs set compression=gzip bigdata/zfs_gzip
[vagrant@server ~]$ sudo zfs set compression=lz4 bigdata/zfs_lz4
[vagrant@server ~]$ sudo zfs set compression=lzjb bigdata/zfs_lzjb
[vagrant@server ~]$ sudo zfs set compression=zle bigdata/zfs_zle

```
Проверим изменение настроек:

```
[vagrant@server ~]$ zfs get compression
NAME              PROPERTY     VALUE     SOURCE
bigdata           compression  off       default
bigdata/zfs_gzip  compression  gzip      local
bigdata/zfs_lz4   compression  lz4       local
bigdata/zfs_lzjb  compression  lzjb      local
bigdata/zfs_zle   compression  zle       local
```

### **Проверка эффективности сжатия**

Скачаем текстовый документ на все 4 файловые системы:

```
[vagrant@server ~]$ sudo wget -O War_and_Peace.txt https://www.gutenberg.org/files/2600/2600-0.txt -P /bigdata/zfs_gzip/
...
[vagrant@server ~]$ sudo wget -O War_and_Peace.txt https://www.gutenberg.org/files/2600/2600-0.txt -P /bigdata/lz4/
...
[vagrant@server ~]$ sudo wget -O War_and_Peace.txt https://www.gutenberg.org/files/2600/2600-0.txt -P /bigdata/zfs_lzjb/
...
vagrant@server ~]$ sudo wget -O War_and_Peace.txt https://www.gutenberg.org/files/2600/2600-0.txt -P /bigdata/zfs_zle/
--2021-08-17 09:52:28--  https://www.gutenberg.org/files/2600/2600-0.txt
Resolving www.gutenberg.org (www.gutenberg.org)... 152.19.134.47
Connecting to www.gutenberg.org (www.gutenberg.org)|152.19.134.47|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 3359408 (3.2M) [text/plain]
Saving to: 'War_and_Peace.txt'

  100%[=======================================================================>]   3.20M  1.66MB/s    in 1.9s    

2021-08-17 09:52:31 (1.66 MB/s) - 'War_and_Peace.txt' saved [3359408/3359408]
```

Проверим результат:

```
[vagrant@server ~]$ zfs get compression,compressratio
NAME              PROPERTY       VALUE     SOURCE
bigdata           compression    off       default
bigdata           compressratio  1.00x     -
bigdata/zfs_gzip  compression    gzip      local
bigdata/zfs_gzip  compressratio  1.00x     -
bigdata/zfs_lz4   compression    lz4       local
bigdata/zfs_lz4   compressratio  1.00x     -
bigdata/zfs_lzjb  compression    lzjb      local
bigdata/zfs_lzjb  compressratio  1.00x     -
bigdata/zfs_zle   compression    zle       local
bigdata/zfs_zle   compressratio  1.00x     -
```

Из листинга видно, что для разных систем установлены разные алгоритмы сжатия, но в данном случае сложно сказать какой алгоритм эффективней, т.к. compressratio у всех равен 1.00x


# **Определить настройки pool’a**

Проверим функцию переноса дисков между системами. 

### **Загрузка архива**

Загрузим архив с файлами локально распакуем его: 

```
wget --no-check-certificate 'https://docs.google.com/uc?export=download&id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg' -O zfs_task1.tar.gz

tar -xf zfs_task1.tar.gz
```

### **Импорт pool'а**

Импортируем pool:

```
[vagrant@server ~]$ sudo zpool import -d zpoolexport/
   pool: otus
     id: 6554193320433390805
  state: ONLINE
 action: The pool can be imported using its name or numeric identifier.
 config:

	otus                                 ONLINE
	  mirror-0                           ONLINE
	    /home/vagrant/zpoolexport/filea  ONLINE
	    /home/vagrant/zpoolexport/fileb  ONLINE

[vagrant@server ~]$ sudo zpool import -d zpoolexport/ otus
[vagrant@server ~]$ zpool list
NAME      SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
bigdata  5.62G   301K  5.62G        -         -     0%     0%  1.00x    ONLINE  -
otus      480M  2.18M   478M        -         -     0%     0%  1.00x    ONLINE  -
```

В списке доступных пулов появлся импортированный пул otus.

### **Определим настройки zfs**

Размер хранилища: 480Mb

```
[vagrant@server ~]$ zpool list otus
NAME   SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus   480M  2.09M   478M        -         -     0%     0%  1.00x    ONLINE  -

```
Тип pool: mirror

```
[vagrant@server ~]$ zpool status otus
  pool: otus
 state: ONLINE
  scan: none requested
config:

	NAME                                 STATE     READ WRITE CKSUM
	otus                                 ONLINE       0     0     0
	  mirror-0                           ONLINE       0     0     0
	    /home/vagrant/zpoolexport/filea  ONLINE       0     0     0
	    /home/vagrant/zpoolexport/fileb  ONLINE       0     0     0

errors: No known data errors
```

Значение recordsize: 128K
Сжатие: zle
Контрольная сумма: sha256

```
[vagrant@server ~]$ zfs get recordsize,compression,checksum otus/hometask2
NAME            PROPERTY     VALUE      SOURCE
otus/hometask2  recordsize   128K       inherited from otus
otus/hometask2  compression  zle        inherited from otus
otus/hometask2  checksum     sha256     inherited from otus
```


# **Найти сообщение от преподавателей**

Проверим работу функции восстановления snapshot и переноса файла.

### **Скопировать файл**

Скопируем файл с snapshot'ом из удаленной директории:

```
wget --no-check-certificate 'https://docs.google.com/uc?export=download&id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG' -O otus_task2.file
```

### **Восстановление**

Восстановим данные из snapshot:

```
vagrant@server ~]$ sudo zfs receive otus/storage@task2 < otus_task2.file
[vagrant@server ~]$ zfs list
NAME               USED  AVAIL     REFER  MOUNTPOINT
bigdata            238K  5.45G       28K  /bigdata
bigdata/zfs_gzip    24K  5.45G       24K  /bigdata/zfs_gzip
bigdata/zfs_lz4     24K  5.45G       24K  /bigdata/zfs_lz4
bigdata/zfs_lzjb    24K  5.45G       24K  /bigdata/zfs_lzjb
bigdata/zfs_zle     24K  5.45G       24K  /bigdata/zfs_zle
otus              4.93M   347M       25K  /otus
otus/hometask2    1.88M   347M     1.88M  /otus/hometask2
otus/storage      2.83M   347M     2.83M  /otus/storage
```

Файл `secret_message` находится по следующему пути: /otus/storage/task1/file_mess/secret_message.
И содержит сообщение:

```
[vagrant@server ~]$ cat /otus/storage/task1/file_mess/secret_message 
https://github.com/sindresorhus/awesome
```

### **Заключение**

В процессе выполнения лабораторной работы были получены навыки работы с файловой системой zfs. Были созданы тома, проверены функции импорта пулов и восстановления из snapshot'ов.