#!/bin/bash

mkdir -p ~root/.ssh
cp ~vagrant/.ssh/auth* ~root/.ssh
yum install -y mdadm smartmontools hdparm gdisk

sudo mdadm --zero-superblock --force /dev/sd[b-g]
sudo mdadm --create --verbose /dev/md0 -l 10 -n 6 /dev/sd[b-g]

mkdir /etc/mdadm
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
sudo mdadm -D --scan --verbose | awk '/ARRAY/{print}' >> /etc/mdadm/mdadm.conf

sudo parted -s /dev/md0 mklabel gpt
for i in $(seq 0 20 80); do sudo parted /dev/md0 mkpart primary ext4 $i% `expr $i + 20`%; done

for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done

sudo mkdir -p /raid/part{1,2,3,4,5}
for i in $(seq 1 5); do sudo mount /dev/md0p$i /raid/part$i; done

for i in $(seq 1 5); do sudo sh -c "echo `sudo blkid /dev/md0p$i | awk '{print$2}'` /raid/part$i ext4 defaults 0 0 >> /etc/fstab"; done

