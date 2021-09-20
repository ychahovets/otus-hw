# **Введение**

Цель данной лабораторной работы продолжить освоение `VirtualBox` и `Vagrant`, получить навыки работы с дисковой подсистемой Linux, программными RAID массивами. На практике применить утилиты для работы с файловой системой и управлением RAID массивом.

---
# **Установка ПО**

В качестве хостовой системы используется ноутбук с установленной ОС `Ubuntu 20.04/Focal`
`VirtualBox` и `Vagrant` уже установлены с прошлой лабораторной работы


# **Сборка RAID0/1/5/6/10**

### **Копирование и запуск**

Копируем начальный стенд с https://github.com/erlong15/otus-linux

Добавим в файл конфигурации ещё 2 диска:

```

:sata5 => {
            :dfile => './sata5.vdi',
            :size => 250, # Megabytes
            :port => 5
          },
:sata6 => {
            :dfile => './sata6.vdi',
            :size => 250, # Megabytes
            :port => 6
          }

```

Запустим виртуальную машину и залогинимся:
```
vagrant up
...
==> otuslinux: Importing base box 'centos/7'...
...
==> otuslinux: Booting VM...
...
==> otuslinux: Setting hostname...

vagrant ssh
[vagrant@otuslinux ~]$ 
```

### **Окружение**

В виртуальной машине должно быть 6 дисков. Посмотрим какие блочные устройства у нас есть в системе после загрузки:

```
[vagrant@otuslinux ~]$ sudo lsblk 
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   40G  0 disk 
 -sda1   8:1    0   40G  0 part /
sdb      8:16   0  250M  0 disk 
sdc      8:32   0  250M  0 disk 
sdd      8:48   0  250M  0 disk 
sde      8:64   0  250M  0 disk 
sdf      8:80   0  250M  0 disk 
sdg      8:96   0  250M  0 disk

[vagrant@otuslinux ~]$ sudo lshw -short | grep disk
/0/100/1.1/0.0.0    /dev/sda   disk        42GB VBOX HARDDISK
/0/100/d/0          /dev/sdb   disk        262MB VBOX HARDDISK
/0/100/d/1          /dev/sdc   disk        262MB VBOX HARDDISK
/0/100/d/2          /dev/sdd   disk        262MB VBOX HARDDISK
/0/100/d/3          /dev/sde   disk        262MB VBOX HARDDISK
/0/100/d/4          /dev/sdf   disk        262MB VBOX HARDDISK
/0/100/d/5          /dev/sdg   disk        262MB VBOX HARDDISK


vagrant@otuslinux ~]$ sudo fdisk -l          

Disk /dev/sdg: 262 MB, 262144000 bytes, 512000 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/sdb: 262 MB, 262144000 bytes, 512000 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/sdc: 262 MB, 262144000 bytes, 512000 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/sda: 42.9 GB, 42949672960 bytes, 83886080 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x0009ef1a

   Device Boot      Start         End      Blocks   Id  System
/dev/sda1   *        2048    83886079    41942016   83  Linux

Disk /dev/sdd: 262 MB, 262144000 bytes, 512000 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/sdf: 262 MB, 262144000 bytes, 512000 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/sde: 262 MB, 262144000 bytes, 512000 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
```

Видим, что в системе 7 дисков, один из образа с системой, остальные добавленные в описании виртуальной машины.
Исходя из количества дисков и их размера выберем RAID10 для тестирования и проверки.

### **Сборка RAID10**

На всякий случай занулим суперблоки:

```
[vagrant@otuslinux ~]$ sudo mdadm --zero-superblock --force /dev/sd[b-g]
mdadm: Unrecognised md component device - /dev/sdb
mdadm: Unrecognised md component device - /dev/sdc
mdadm: Unrecognised md component device - /dev/sdd
mdadm: Unrecognised md component device - /dev/sde
mdadm: Unrecognised md component device - /dev/sdf
mdadm: Unrecognised md component device - /dev/sdg
```

Создаём RAID10 командой:

```
[vagrant@otuslinux ~]$ sudo mdadm --create --verbose /dev/md0 -l 10 -n 6 /dev/sd[b-g]
mdadm: layout defaults to n2
mdadm: layout defaults to n2
mdadm: chunk size defaults to 512K
mdadm: size set to 253952K
mdadm: Defaulting to version 1.2 metadata
mdadm: array /dev/md0 started.
```

Поверим, что RAID собрался:

```
[vagrant@otuslinux ~]$ cat /proc/mdstat 
md0 : active raid10 sdf[4] sdg[5] sde[3] sdb[0] sdc[1] sdd[6]
      761856 blocks super 1.2 512K chunks 2 near-copies [6/6] [UUUUUU]
      
unused devices: <none>

[vagrant@otuslinux ~]$ ls /sys/block/
md0  sda  sdb  sdc  sdd  sde  sdf  sdg

[vagrant@otuslinux ~]$ sudo mdadm --detail /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Mon Sep 20 12:13:56 2021
        Raid Level : raid10
        Array Size : 761856 (744.00 MiB 780.14 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 6
     Total Devices : 6
       Persistence : Superblock is persistent

       Update Time : Mon Sep 20 12:57:30 2021
             State : clean 
    Active Devices : 6
   Working Devices : 6
    Failed Devices : 0
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 512K

Consistency Policy : resync

              Name : otuslinux:0  (local to host otuslinux)
              UUID : fe2c99fa:bc16b74e:45d7e1f9:bdb50ff2
            Events : 41

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync set-A   /dev/sdb
       1       8       32        1      active sync set-B   /dev/sdc
       6       8       48        2      active sync set-A   /dev/sdd
       3       8       64        3      active sync set-B   /dev/sde
       4       8       80        4      active sync set-A   /dev/sdf
       5       8       96        5      active sync set-B   /dev/sdg

```

После выключения виртуальной машины и повторной загрузки RAID md0 появился автоматически, но для того, чтобы быть уверенным что ОС запомнила какой RAID массив требуется создать и какие компоненты в него входят создадим файл mdadm.conf. Сначала убедимся, что информация верна:

```
[vagrant@otuslinux ~]$ sudo mdadm -D --scan --verbose
ARRAY /dev/md0 level=raid10 num-devices=6 metadata=1.2 name=otuslinux:0 UUID=fe2c99fa:bc16b74e:45d7e1f9:bdb50ff2
   devices=/dev/sdb,/dev/sdc,/dev/sdd,/dev/sde,/dev/sdf,/dev/sdg

```
А затем создадим файл mdadm.conf:

```
[vagrant@otuslinux ~]$ mkdir /etc/mdadm
[vagrant@otuslinux ~]$ echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
[vagrant@otuslinux ~]$ sudo mdadm -D --scan --verbose | awk '/ARRAY/{print}' >> /etc/mdadm/mdadm.conf
```

---

# **Тестирование сбоя/восстановления**

Смоделируем сбой диска в RAID массиве, искусственно "зафейлив" одно из блочных устройств:

```
[vagrant@otuslinux ~]$ sudo mdadm /dev/md0 --fail /dev/sdd
mdadm: set /dev/sdd faulty in /dev/md0
```

Посмотрим текущее состояние RAID:

```
[vagrant@otuslinux ~]$ cat /proc/mdstat 
Personalities : [raid10] 
md0 : active raid10 sdg[5] sdf[4] sde[3] sdd[2](F) sdc[1] sdb[0]
      761856 blocks super 1.2 512K chunks 2 near-copies [6/5] [UU_UUU]
      
unused devices: <none>

[vagrant@otuslinux ~]$ sudo mdadm -D /dev/md0 
/dev/md0:
           Version : 1.2
     Creation Time : Mon Sep 20 12:13:56 2021
        Raid Level : raid10
        Array Size : 761856 (744.00 MiB 780.14 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 6
     Total Devices : 6
       Persistence : Superblock is persistent

       Update Time : Mon Sep 20 13:13:56 2021
             State : clean, degraded 
    Active Devices : 5
   Working Devices : 5
    Failed Devices : 1
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 512K

Consistency Policy : resync

              Name : otuslinux:0  (local to host otuslinux)
              UUID : fe2c99fa:bc16b74e:45d7e1f9:bdb50ff2
            Events : 41

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync set-A   /dev/sdb
       1       8       32        1      active sync set-B   /dev/sdc
       -       0        0        2      removed
       3       8       64        3      active sync set-B   /dev/sde
       4       8       80        4      active sync set-A   /dev/sdf
       5       8       96        5      active sync set-B   /dev/sdg

       2       8       48        -      faulty   /dev/sdd

```
Третий диск помечен как `faulty`, статус всего массива `clean, degraded`.

Удалим сбойнувший диск из массива:

```
[vagrant@otuslinux ~]$ sudo mdadm /dev/md0 --remove /dev/sdd
mdadm: hot removed /dev/sdd from /dev/md0
```

```
[vagrant@otuslinux ~]$ sudo mdadm -D /dev/md0 
/dev/md0:
           Version : 1.2
     Creation Time : Mon Sep 20 13:13:56 2021
        Raid Level : raid10
        Array Size : 761856 (744.00 MiB 780.14 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 6
     Total Devices : 5
       Persistence : Superblock is persistent

       Update Time : Mon Sep 20 14:13:56 2021
             State : clean, degraded 
    Active Devices : 5
   Working Devices : 5
    Failed Devices : 0
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 512K

Consistency Policy : resync

              Name : otuslinux:0  (local to host otuslinux)
              UUID : fe2c99fa:bc16b74e:45d7e1f9:bdb50ff2
            Events : 20

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync set-A   /dev/sdb
       1       8       32        1      active sync set-B   /dev/sdc
       -       0        0        2      removed
       3       8       64        3      active sync set-B   /dev/sde
       4       8       80        4      active sync set-A   /dev/sdf
       5       8       96        5      active sync set-B   /dev/sdg

```
 Битый диск не отображается в последней строке вывода, но статус массива остался `degraded`

Мы "заменили" диск, вместо сбойнувшего вставили новый:

```
[vagrant@otuslinux ~]$ sudo mdadm /dev/md0 --add /dev/sdd
mdadm: added /dev/sdd
```

Диск прошёл процесс rebuild и стал полноценным членом массива:

```
[vagrant@otuslinux ~]$ cat /proc/mdstat 
Personalities : [raid10] 
md0 : active raid10 sdd[6] sdg[5] sdf[4] sde[3] sdc[1] sdb[0]
      761856 blocks super 1.2 512K chunks 2 near-copies [6/6] [UUUUUU]
      
unused devices: <none>
```

Статус RAID массива снова `clean`:

```
[vagrant@otuslinux ~]$ sudo mdadm -D /dev/md0 
/dev/md0:
           Version : 1.2
     Creation Time : Mon Sep 20 14:43:56 2021
        Raid Level : raid10
        Array Size : 761856 (744.00 MiB 780.14 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 6
     Total Devices : 6
       Persistence : Superblock is persistent

       Update Time : Mon Sep 20 15:13:56 2021
             State : clean 
    Active Devices : 6
   Working Devices : 6
    Failed Devices : 0
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 512K

Consistency Policy : resync

              Name : otuslinux:0  (local to host otuslinux)
              UUID : fe2c99fa:bc16b74e:45d7e1f9:bdb50ff2
            Events : 39

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync set-A   /dev/sdb
       1       8       32        1      active sync set-B   /dev/sdc
       6       8       48        2      active sync set-A   /dev/sdd
       3       8       64        3      active sync set-B   /dev/sde
       4       8       80        4      active sync set-A   /dev/sdf
       5       8       96        5      active sync set-B   /dev/sdg
```

### **Создать GPT раздел, пять партиций и смонтировать их**
Создадим GPT раздел на RAID массиве:

```
[vagrant@otuslinux ~]$ sudo parted -s /dev/md0 mklabel gpt
[vagrant@otuslinux ~]$
```
Создадим партиции:

```
[vagrant@otuslinux ~]$ sudo parted /dev/md0 mkpart primary ext4 0% 20%
Information: You may need to update /etc/fstab.
[vagrant@otuslinux ~]$ sudo parted /dev/md0 mkpart primary ext4 20% 40%
Information: You may need to update /etc/fstab.
[vagrant@otuslinux ~]$ sudo parted /dev/md0 mkpart primary ext4 40% 60%
Information: You may need to update /etc/fstab.
[vagrant@otuslinux ~]$ sudo parted /dev/md0 mkpart primary ext4 60% 80% 
Information: You may need to update /etc/fstab.
[vagrant@otuslinux ~]$ sudo parted /dev/md0 mkpart primary ext4 80% 100%  
Information: You may need to update /etc/fstab.
```

```
[vagrant@otuslinux ~]$ sudo fdisk -l /dev/md0  
WARNING: fdisk GPT support is currently new, and therefore in an experimental phase. Use at your own discretion.

Disk /dev/md0: 780 MB, 780140544 bytes, 1523712 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 524288 bytes / 1572864 bytes
Disk label type: gpt
Disk identifier: 16C274C0-F44A-4413-97BB-506F812830AC


#         Start          End    Size  Type            Name
 1         3072       304127    147M  Microsoft basic primary
 2       304128       608255  148,5M  Microsoft basic primary
 3       608256       915455    150M  Microsoft basic primary
 4       915456      1219583  148,5M  Microsoft basic primary
 5      1219584      1520639    147M  Microsoft basic primary

```

Теперь создадим файловые системы на этих партициях:

```
[vagrant@otuslinux ~]$ for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done
mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=1024 (log=0)
Fragment size=1024 (log=0)
Stride=512 blocks, Stripe width=1536 blocks
37696 inodes, 150528 blocks
7526 blocks (5.00%) reserved for the super user
First data block=1
Maximum filesystem blocks=33816576
19 block groups
8192 blocks per group, 8192 fragments per group
1984 inodes per group
Superblock backups stored on blocks: 
	8193, 24577, 40961, 57345, 73729

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done 
....

```

```
[vagrant@otuslinux ~]$ ls /dev/md0*
/dev/md0  /dev/md0p1  /dev/md0p2  /dev/md0p3  /dev/md0p4  /dev/md0p5
```

Монтируем фаловые системы по каталогам:

```
[vagrant@otuslinux ~]$ sudo mkdir -p /raid/part{1,2,3,4,5}
[vagrant@otuslinux ~]for i in $(seq 1 5); do sudo mount /dev/md0p$i /raid/part$i; done
[vagrant@otuslinux ~]$ mount
...
/dev/md0p1 on /raid/part1 type ext4 (rw,relatime,seclabel,stripe=1536,data=ordered)
/dev/md0p2 on /raid/part2 type ext4 (rw,relatime,seclabel,stripe=1536,data=ordered)
/dev/md0p3 on /raid/part3 type ext4 (rw,relatime,seclabel,stripe=1536,data=ordered)
/dev/md0p4 on /raid/part4 type ext4 (rw,relatime,seclabel,stripe=1536,data=ordered)
/dev/md0p5 on /raid/part5 type ext4 (rw,relatime,seclabel,stripe=1536,data=ordered)
```

### **Заключение**

В процессе выполнения лабораторной работы были получены навыки общения с утилитами для работы с файловой системой Linux. Были добавлены диски в стенд, собран RAID массив 10, проведено удаление и замена дисков в этом массиве. Созданы и смонтированы файловые системы на RAID массиве. Приложены конфигурационный файл для автосборки рейда при загрузке (mdadm.sh) и скрипт (script_mdadm.sh) для настройки виртуальной машины, который сразу собирает систему с подключенным рейдом и монтирует разделы. После перезагрузки стенда разделы монтируются автоматически.
