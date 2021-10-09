### Загрузка системы

### Задания:
```
   1. Попасть в систему без пароля несколькими способами
   2. Установить систему с LVM, после чего переименовать VG
   3. Добавить модуль в initrd
```
### 1: Необходимо зайти в режим редактора в меню grub.
### В конце строки, которая начинается с kernel вставить 
```
rd.break
```
Комбинация Ctrl + X
```
mount -o remount,rw /sysroot/ - добавляем права на запись для /sysroot
chroot /sysroot
passwd - изменить пароль пользователя root
touch /.autorelabel - необходим для SELinux context
exit
logout
```
### Если систему перезагрузить принудительно, то изменения не сохранятся.

### 2: Переименовать volume group cl_centos8
![](https://github.com/ychahovets/otus-hw/blob/main/hw07/001.png)
```
[root@centos8 ~]# vgrename cl_centos8 otus
```
![](https://github.com/ychahovets/otus-hw/blob/main/hw07/002.png)
### Заменить старое название на новое в следующих файлах:
```
[root@centos8 ~]# vi /etc/fstab
```
![](https://github.com/ychahovets/otus-hw/blob/main/hw07/003.png)
```
[root@centos8 ~]# vi /etc/default/grub
```
![](https://github.com/ychahovets/otus-hw/blob/main/hw07/004.png)
```
[root@centos8 ~]# vi /boot/grub2/grub.cfg
```
![](https://github.com/ychahovets/otus-hw/blob/main/hw07/005.png)
### Пересоздать initrd image 
```
[root@centos8 ~]# mkinitrd -f -v /boot/initramfs-$(uname -r).img $(uname -r)
```

### 3: Создать папку в директории 
```
[root@centos8 ~]# mkdir /usr/lib/dracut/modules.d/01test
```
### Поместить нужные скрипты 
```
(https://gist.github.com/lalbrekht/e51b2580b47bb5a150bd1a002f16ae85/raw/80060b7b300e193c187bbcda4d8fdf0e1c066af9/gistfile1.txt и https://gist.githubusercontent.com/lalbrekht/ac45d7a6c6856baea348e64fac43faf0/raw/69598efd5c603df310097b52019dc979e2cb342d/gistfile1.txt)
```
### Выполнить 
```
[root@centos8 ~]# mkinitrd -f -v /boot/initramfs-$(uname -r).img $(uname -r) 
или
[root@centos8 ~]# dracut -f -v
```
### Если в редакторе grub конфига удалить rghb и quiet в конце строки kernel то при загрузке отобразится пингвин! 
![](https://github.com/ychahovets/otus-hw/blob/main/hw07/006.png