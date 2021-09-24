# Домашнее задание выполнено для курса [Administrator Linux. Professional](https://otus.ru/lessons/linux-professional/?int_source=courses_catalog&int_term=operations)

# **Введение**

Цель данной лабораторной работы продолжить освоение `VirtualBox` и `Vagrant`, получить навыки работы с файловыми системами Linux и LVM. На практике изучить команды для управления LVM.

---
# **Установка ПО**

В качестве хостовой системы используется ноутбук с установленной ОС `Ubuntu 20.04/Focal`
`VirtualBox` и `Vagrant` уже установлены с прошлой лабораторной работы


# **LVM**

Добавим установку пакета `xfsdump` в Vagrantfile:

```
yum install -y mdadm smartmontools hdparm gdisk xfsdump
```

### **Уменьшить том под / до 8G**

Создадим временный том для / раздела. Для этого разметим диск:

```
[vagrant@lvm ~]$ sudo pvcreate /dev/sdb
  Physical volume "/dev/sdb" successfully created.
```

Создадим volume group:

```
[vagrant@lvm ~]$ sudo vgcreate vg_root /dev/sdb
  Volume group "vg_root" successfully created
```

Создадим logical volume:

```
 [vagrant@lvm ~]$ sudo lvcreate -l+100%FREE -n lv_root /dev/vg_root
  Logical volume "lv_root" created.
```

Для переноса данных создадим xfs файловую систему на томе `lv_root` и смонтируем её:

```
[vagrant@lvm ~]$ sudo mkfs.xfs /dev/vg_root/lv_root 
meta-data=/dev/vg_root/lv_root   isize=512    agcount=4, agsize=655104 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=2620416, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0

[vagrant@lvm ~]$ sudo mount /dev/vg_root/lv_root /mnt/
```

Скопируем все данные с раздела / в раздел /mnt:

```
[vagrant@lvm ~]$ sudo xfsdump -J - /dev/VolGroup00/LogVol00 | sudo xfsrestore -J - /mnt
xfsrestore: using file dump (drive_simple) strategy
xfsrestore: version 3.1.7 (dump format 3.0)
xfsdump: using file dump (drive_simple) strategy
xfsdump: version 3.1.7 (dump format 3.0)
xfsdump: level 0 dump of lvm:/
xfsdump: dump date: Fri Sep 24 09:07:31 2021
xfsdump: session id: b2888731-0977-4371-a3bd-a9b4925ea2ff
xfsdump: session label: ""
...
...
xfsdump: media file size 1805076096 bytes
xfsdump: dump size (non-dir files) : 1778482768 bytes
xfsdump: dump complete: 67 seconds elapsed
xfsdump: Dump Status: SUCCESS
xfsrestore: restore complete: 67 seconds elapsed
xfsrestore: Restore Status: SUCCESS
```

Проверим результат:

```
vagrant@lvm ~]$ ls /mnt/
bin  boot  dev  etc  home  lib  lib64  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  vagrant  var
```

Изменим настройки Grub, чтобы при старте перейти в новый /:

```
[vagrant@lvm ~]$ for i in /proc/ /sys/ /dev/ /run/ /boot/; do sudo mount --bind $i /mnt/$i; done
[vagrant@lvm ~]$ sudo chroot /mnt/
[root@lvm /]# grub2-mkconfig -o /boot/grub2/grub.cfg 
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-3.10.0-862.2.3.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-862.2.3.el7.x86_64.img
done
```

Обновим образ `initrd`:
###
```
root@lvm /]# cd /boot; for i in `ls initramfs-*img`;do dracut -v $i `echo $i|sed "s/initramfs-//g;s/.img//g"` --force;done
Executing: /sbin/dracut -v initramfs-3.10.0-862.2.3.el7.x86_64.img 3.10.0-862.2.3.el7.x86_64 --force
...
...
*** Store current command line parameters ***
*** Creating image file ***
*** Creating image file done ***
*** Creating initramfs image file '/boot/initramfs-3.10.0-862.2.3.el7.x86_64.img' done ***
```

Заменим в файле `grub.cfg` строчку `rd.lvm.lv=VolGroup00/LogVol00` на `rd.lvm.lv=vg_root/lv_root`

Перегружаемся с новым / томом:

```
[root@lvm boot]# exit
exit
[vagrant@lvm ~]$ sudo shutdown -r now
```
###
```
[vagrant@lvm ~]$ lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
├─sda1                    8:1    0    1M  0 part 
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part 
  ├─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
  └─VolGroup00-LogVol00 253:2    0 37.5G  0 lvm  
sdb                       8:16   0   10G  0 disk 
└─vg_root-lv_root       253:0    0   10G  0 lvm  /
sdc                       8:32   0    2G  0 disk 
sdd                       8:48   0    1G  0 disk 
sde                       8:64   0    1G  0 disk 
```
###
Изменим размер старого тома с 40G на 8G и вернём на него /.
Удаляем том LogVol00:

```
[vagrant@lvm ~]$ sudo lvremove /dev/VolGroup00/LogVol00
Do you really want to remove active logical volume VolGroup00/LogVol00? [y/n]: y
  Logical volume "LogVol00" successfully removed
```

Создаём новый:

```
[vagrant@lvm ~]$ sudo lvcreate -L 8G -n LogVol00 /dev/VolGroup00
WARNING: xfs signature detected on /dev/VolGroup00/LogVol00 at offset 0. Wipe it? [y/n]: y
  Wiping xfs signature on /dev/VolGroup00/LogVol00.
  Logical volume "LogVol00" created.
```

Создаём файловую систему, монтируем её и копируем /:

```
[vagrant@lvm ~]$ sudo mkfs.xfs /dev//VolGroup00/LogVol00 
meta-data=/dev//VolGroup00/LogVol00 isize=512    agcount=4, agsize=524288 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=2097152, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
[vagrant@lvm ~]$ sudo mount /dev//VolGroup00/LogVol00 /mnt/
[vagrant@lvm ~]$ sudo xfsdump -J - /dev/vg_root/lv_root | sudo xfsrestore -J - /mnt
xfsrestore: using file dump (drive_simple) strategy
xfsrestore: version 3.1.7 (dump format 3.0)
xfsdump: using file dump (drive_simple) strategy
xfsdump: version 3.1.7 (dump format 3.0)
xfsdump: level 0 dump of lvm:/
xfsdump: dump date: Fri Sep 24 09:43:07 2021
xfsdump: session id: 3a46e94c-2011-4479-84c9-7b2382f8e554
xfsdump: session label: ""
...
...
xfsrestore: restore complete: 76 seconds elapsed
xfsrestore: Restore Status: SUCCESS
```

Изменяем конфигурацию загрузчика grub:

```
[vagrant@lvm ~]$ for i in /proc/ /sys/ /dev/ /run/ /boot/; do sudo mount --bind $i /mnt/$i; done
[vagrant@lvm ~]$ sudo chroot /mnt/
[root@lvm /]# grub2-mkconfig -o /boot/grub2/grub.cfg
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-3.10.0-862.2.3.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-862.2.3.el7.x86_64.img
done

root@lvm /]# cd /boot; for i in `ls initramfs-*img`;do dracut -v $i `echo $i|sed "s/initramfs-//g;s/.img//g"` --force;done
Executing: /sbin/dracut -v initramfs-3.10.0-862.2.3.el7.x86_64.img 3.10.0-862.2.3.el7.x86_64 --force
dracut module 'busybox' will not be installed, because command 'busybox' could not be found!
dracut module 'crypt' will not be installed, because command 'cryptsetup' could not be found!
dracut module 'dmraid' will not be installed, because command 'dmraid' could not be found!
dracut module 'dmsquash-live-ntfs' will not be installed, because command 'ntfs-3g' could not be found!
...
...
*** Creating image file ***
*** Creating image file done ***
*** Creating initramfs image file '/boot/initramfs-3.10.0-862.2.3.el7.x86_64.img' done ***
```

### **Выделить том под /var в зеркало**
###
```
[root@lvm boot]# lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
├─sda1                    8:1    0    1M  0 part 
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part 
  ├─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
  └─VolGroup00-LogVol00 253:2    0    8G  0 lvm  /
sdb                       8:16   0   10G  0 disk 
└─vg_root-lv_root       253:0    0   10G  0 lvm  
sdc                       8:32   0    2G  0 disk 
sdd                       8:48   0    1G  0 disk 
sde                       8:64   0    1G  0 disk 
```

На дисках sdc и sdd создадим зеркало:
#####
```
[root@lvm boot]# sudo vgcreate vg_var /dev/sdc /dev/sdd
  Physical volume "/dev/sdc" successfully created.
  Physical volume "/dev/sdd" successfully created.
  Volume group "vg_var" successfully created

  [root@lvm boot]# lvcreate -L 950M -m1 -n lv_var vg_var
  Rounding up size to full physical extent 952.00 MiB
  Logical volume "lv_var" created.
```
Создаём на нём фаловую систему и перемещаем туда /var:

```
[root@lvm boot]# mkfs.ext4 /dev/vg_var/lv_var 
mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=4096 (log=2)
Fragment size=4096 (log=2)
Stride=0 blocks, Stripe width=0 blocks
60928 inodes, 243712 blocks
12185 blocks (5.00%) reserved for the super user
First data block=0
Maximum filesystem blocks=249561088
8 block groups
32768 blocks per group, 32768 fragments per group
7616 inodes per group
Superblock backups stored on blocks: 
        32768, 98304, 163840, 229376

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

##### Монтируем
[root@lvm boot]# mount /dev/vg_var/lv_var /mnt/

##### Синхронимся
[root@lvm boot]# rsync -avHPSAX /var/ /mnt/
...
...
sent 899,657,149 bytes  received 281,024 bytes  17,820,557.88 bytes/sec
total size is 898,969,050  speedup is 1.00
```

Сохраним старый var:

```
[root@lvm boot]# mkdir /tmp/old_var && mv /var/* /tmp/old_var
```

Монтируем var в каталог /var:

```
[root@lvm boot]# umount /mnt/
[root@lvm boot]# lsblk 
NAME                     MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                        8:0    0   40G  0 disk 
├─sda1                     8:1    0    1M  0 part 
├─sda2                     8:2    0    1G  0 part /boot
└─sda3                     8:3    0   39G  0 part 
  ├─VolGroup00-LogVol01  253:1    0  1.5G  0 lvm  [SWAP]
  └─VolGroup00-LogVol00  253:2    0    8G  0 lvm  /
sdb                        8:16   0   10G  0 disk 
└─vg_root-lv_root        253:0    0   10G  0 lvm  
sdc                        8:32   0    2G  0 disk 
├─vg_var-lv_var_rmeta_0  253:3    0    4M  0 lvm  
│ └─vg_var-lv_var        253:7    0  952M  0 lvm  
└─vg_var-lv_var_rimage_0 253:4    0  952M  0 lvm  
  └─vg_var-lv_var        253:7    0  952M  0 lvm  
sdd                        8:48   0    1G  0 disk 
├─vg_var-lv_var_rmeta_1  253:5    0    4M  0 lvm  
│ └─vg_var-lv_var        253:7    0  952M  0 lvm  
└─vg_var-lv_var_rimage_1 253:6    0  952M  0 lvm  
  └─vg_var-lv_var        253:7    0  952M  0 lvm  
sde                        8:64   0    1G  0 disk 
[root@lvm boot]# mount /dev/vg_var/lv_var /var
```

Добавим в fstab строчку для автоматического монтирования /var:

```
[root@lvm boot]# echo "`blkid  | grep var: | awk '{print $2}'` /var ext4 defaults 0 0" >> /etc/fstab
```

Для завершения предыдущего пункта (уменьшили / до 8G) нужно перегрузиться и удалить временный том lv_root и группу gv_root:

```
[root@lvm boot]# exit
exit
[vagrant@lvm ~]$ sudo shutdown -r now

[vagrant@lvm ~]$ sudo lvremove /dev/vg_root/lv_root 
Do you really want to remove active logical volume vg_root/lv_root? [y/n]: y
  Logical volume "lv_root" successfully removed
[vagrant@lvm ~]$ sudo vgremove /dev/vg_root 
  Volume group "vg_root" successfully removed
[vagrant@lvm ~]$ sudo pvremove /dev/sdb
  Labels on physical volume "/dev/sdb" successfully wiped.
```

# **Выделить том под /home**

Создадим том в группе VolGroup00, файловую систему на нём, скопируем сожержимое каталога /home и смонтируем его:

```
[vagrant@lvm ~]$ sudo lvcreate -L 2G -n LogVol_Home /dev/VolGroup00
  Logical volume "LogVol_Home" created.
[vagrant@lvm ~]$ sudo mkfs.xfs /dev/VolGroup00/LogVol_Home 
meta-data=/dev/VolGroup00/LogVol_Home isize=512    agcount=4, agsize=131072 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=524288, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
[vagrant@lvm ~]$ sudo mount /dev/VolGroup00/LogVol_Home /mnt
[vagrant@lvm ~]$ sudo cp -aR /home/* /mnt/

[vagrant@lvm ~]$ sudo rm -fr /home/*
[vagrant@lvm ~]$ sudo umount /mnt/
[vagrant@lvm ~]$ sudo mount /dev/VolGroup00/LogVol_Home /home
```

Добавим в fstab строчку для автоматического монтирования /home:

```
[root@lvm ~]$ echo `sudo blkid  | grep Home: | awk '{print $2}'` /home xfs defaults 0 0 >> /etc/fstab
[vagrant@lvm ~]$ lsblk 
NAME                       MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                          8:0    0   40G  0 disk 
├─sda1                       8:1    0    1M  0 part 
├─sda2                       8:2    0    1G  0 part /boot
└─sda3                       8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00    253:0    0    8G  0 lvm  /
  ├─VolGroup00-LogVol01    253:1    0  1.5G  0 lvm  [SWAP]
  └─VolGroup00-LogVol_Home 253:2    0    2G  0 lvm  /home
sdb                          8:16   0   10G  0 disk 
sdc                          8:32   0    2G  0 disk 
├─vg_var-lv_var_rmeta_0    253:3    0    4M  0 lvm  
│ └─vg_var-lv_var          253:7    0  952M  0 lvm  /var
└─vg_var-lv_var_rimage_0   253:4    0  952M  0 lvm  
  └─vg_var-lv_var          253:7    0  952M  0 lvm  /var
sdd                          8:48   0    1G  0 disk 
├─vg_var-lv_var_rmeta_1    253:5    0    4M  0 lvm  
│ └─vg_var-lv_var          253:7    0  952M  0 lvm  /var
└─vg_var-lv_var_rimage_1   253:6    0  952M  0 lvm  
  └─vg_var-lv_var          253:7    0  952M  0 lvm  /var
sde                          8:64   0    1G  0 disk 
```

# **/home - сделать том для снапшотов**
###
Создадим файлы в /home:

```
[vagrant@lvm ~]$ sudo touch /home/file{1..20}
[vagrant@lvm ~]$ ls /home/
file1   file11  file13  file15  file17  file19  file20  file4  file6  file8  vagrant
file10  file12  file14  file16  file18  file2   file3   file5  file7  file9
```

Сделаем снапшот:

```
[vagrant@lvm ~]$ sudo lvcreate -L 100MB -s -n home_snap /dev/VolGroup00/LogVol_Home
  Rounding up size to full physical extent 128.00 MiB
  Logical volume "home_snap" created.
```

Удалим несколько файлов из /home:

```
[vagrant@lvm ~]$ sudo rm -f /home/file{1..10}
[vagrant@lvm ~]$ ls /home/
file11  file12  file13  file14  file15  file16  file17  file18  file19  file20  vagrant
```

Восстановим файлы из снапшота:

```
[vagrant@lvm ~]$ sudo umount /home
[vagrant@lvm ~]$ sudo lvconvert --merge /dev/VolGroup00/
home_snap    LogVol00     LogVol01     LogVol_Home  
[vagrant@lvm ~]$ sudo lvconvert --merge /dev/VolGroup00/home_snap 
  Merging of volume VolGroup00/home_snap started.
  VolGroup00/LogVol_Home: Merged: 100.00%
[vagrant@lvm ~]$ sudo mount /home
[vagrant@lvm ~]$ ls /home/
file1   file11  file13  file15  file17  file19  file20  file4  file6  file8  vagrant
file10  file12  file14  file16  file18  file2   file3   file5  file7  file9
```
###
### **Заключение**
###
В процессе выполнения лабораторной работы были на практике применены команды для работы с LVM. Были созданы LVM тома для /var и /home. Получены навыки изменения размеров тома LVM, создание снапшота и восстановление изменений из него.