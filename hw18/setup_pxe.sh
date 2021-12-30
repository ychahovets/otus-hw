#!/bin/bash

echo Install PXE server
yum -y install epel-release

yum -y install dhcp-server
yum -y install tftp-server
yum -y install nfs-utils

#yum -y install nginx

firewall-cmd --add-service=tftp
firewall-cmd --add-service=http
# disable selinux or permissive
setenforce 0
# 

cat >/etc/dhcp/dhcpd.conf <<EOF
option space pxelinux;
option pxelinux.magic code 208 = string;
option pxelinux.configfile code 209 = text;
option pxelinux.pathprefix code 210 = text;
option pxelinux.reboottime code 211 = unsigned integer 32;
option architecture-type code 93 = unsigned integer 16;
subnet 10.0.0.0 netmask 255.255.255.0 {
	#option routers 10.0.0.254;
	range 10.0.0.100 10.0.0.120;
	class "pxeclients" {
	  match if substring (option vendor-class-identifier, 0, 9) = "PXEClient";
	  next-server 10.0.0.20;
	  if option architecture-type = 00:07 {
	    filename "uefi/shim.efi";
	    } else {
	    filename "pxelinux/pxelinux.0";
	  }
	}
}
EOF
systemctl start dhcpd

systemctl start tftp.service
yum -y install syslinux-tftpboot.noarch
mkdir -p /var/lib/tftpboot/pxelinux
cp /tftpboot/pxelinux.0 /var/lib/tftpboot/pxelinux
cp /tftpboot/libutil.c32 /var/lib/tftpboot/pxelinux
cp /tftpboot/menu.c32 /var/lib/tftpboot/pxelinux
cp /tftpboot/libmenu.c32 /var/lib/tftpboot/pxelinux
cp /tftpboot/ldlinux.c32 /var/lib/tftpboot/pxelinux
cp /tftpboot/vesamenu.c32 /var/lib/tftpboot/pxelinux

mkdir -p /var/lib/tftpboot/pxelinux/pxelinux.cfg

cat >/var/lib/tftpboot/pxelinux/pxelinux.cfg/default <<EOF
default menu
prompt 0
timeout 600
MENU TITLE Demo PXE setup
LABEL centos-8
  menu label ^Install CentOS-8
  menu default
  kernel images/CentOS-8/vmlinuz
  append initrd=images/CentOS-8/initrd.img ip=enp0s3:dhcp inst.repo=http://10.0.0.20/centos8-install
LABEL centos-7
  menu label ^Install CentOS-7
  kernel images/CentOS-7/vmlinuz
  append initrd=images/CentOS-7/initrd.img ip=enp0s3:dhcp inst.repo=http://10.0.0.20/centos7-install
LABEL centos-7-auto
  menu label Auto install CentOS-7
  kernel images/CentOS-7/vmlinuz
  append initrd=images/CentOS-7/initrd.img ip=enp0s3:dhcp inst.ks=http://10.0.0.20/cfg/centos7-autoinstall/ks.cfg inst.repo=http://10.0.0.20/centos7-autoinstall
LABEL rescue
  menu label ^Rescue installed system
  kernel images/CentOS-8.2/vmlinuz
  append initrd=images/CentOS-8.2/initrd.img rescue
LABEL local
  menu label Boot from ^local drive
  localboot 0xffff
EOF

# Create dir to mount installation media - it will be nginx root
mkdir -p /opt/pxe/

# download PXEboot images
mkdir -p /var/lib/tftpboot/pxelinux/images/CentOS-8/
curl -O http://mirror.mirohost.net/centos/8/BaseOS/x86_64/os/images/pxeboot/initrd.img
curl -O http://mirror.mirohost.net/centos/8/BaseOS/x86_64/os/images/pxeboot/vmlinuz
mv {vmlinuz,initrd.img} /var/lib/tftpboot/pxelinux/images/CentOS-8/

mkdir -p /var/lib/tftpboot/pxelinux/images/CentOS-7/
curl -O http://mirror.mirohost.net/centos/7/os/x86_64/images/pxeboot/initrd.img
curl -O http://mirror.mirohost.net/centos/7/os/x86_64/images/pxeboot/vmlinuz
mv {vmlinuz,initrd.img} /var/lib/tftpboot/pxelinux/images/CentOS-7/
# Setup NFS auto install
# 

curl -o centos-8-boot.iso http://mirror.mirohost.net/centos/8/BaseOS/x86_64/os/images/boot.iso 
mkdir -p /opt/pxe/centos8-install
mount -t iso9660 centos-8-boot.iso /opt/pxe/centos8-install
#echo '/mnt/centos8-install *(ro)' > /etc/exports
#systemctl start nfs-server.service

curl -o centos-7-boot.iso http://mirror.mirohost.net/centos/7/os/x86_64/images/boot.iso 
mkdir -p /opt/pxe/centos7-install
mount -t iso9660 centos-7-boot.iso /opt/pxe/centos7-install

#http://mirror.mirohost.net/centos/7.9.2009/isos/x86_64/CentOS-7-x86_64-Minimal-2009.iso

autoinstall(){
  # to speedup replace URL with closest mirror
  curl -O http://mirror.mirohost.net/centos/7.9.2009/isos/x86_64/CentOS-7-x86_64-Minimal-2009.iso
  mkdir -p /opt/pxe/centos7-autoinstall
  mount -t iso9660 CentOS-7-x86_64-Minimal-2009.iso /opt/pxe/centos7-autoinstall
  #echo '/mnt/centos8-autoinstall *(ro)' >> /etc/exports
  mkdir -p /opt/pxe/cfg/centos7-autoinstall
cat > /opt/pxe/cfg/centos7-autoinstall/ks.cfg <<EOF
#version=RHEL7
ignoredisk --only-use=sda
autopart --type=lvm
# Partition clearing information
clearpart --all --initlabel --drives=sda
# Use graphical install
graphical
# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'
# System language
lang en_US.UTF-8
#repo
#url --url=http://mirror.mirohost.net/centos/7.9.2009/isos/x86_64/
# Network information
network  --bootproto=dhcp --device=enp0s3 --ipv6=auto --activate
network  --bootproto=dhcp --device=enp0s8 --onboot=off --ipv6=auto --activate
network  --hostname=localhost.localdomain
# Root password
rootpw --iscrypted $6$g4WYvaAf1mNKnqjY$w2MtZxP/Yj6MYQOhPXS2rJlYT200DcBQC5KGWQ8gG32zASYYLUzoONIYVdRAr4tu/GbtB48.dkif.1f25pqeh.
# Run the Setup Agent on first boot
firstboot --enable
# Do not configure the X Window System
skipx
# System services
services --enabled="chronyd"
# System timezone
timezone Europe/Kiev --isUtc
user --groups=wheel --name=val --password=$6$ihX1bMEoO3TxaCiL$OBDSCuY.EpqPmkFmMPVvI3JZlCVRfC4Nw6oUoPG0RGuq2g5BjQBKNboPjM44.0lJGBc7OdWlL17B3qzgHX2v// --iscrypted --gecos="val"
%packages
@^minimal
kexec-tools
%end
%addon com_redhat_kdump --enable --reserve-mb='auto'
%end
%anaconda
pwpolicy root --minlen=6 --minquality=1 --notstrict --nochanges --notempty
pwpolicy user --minlen=6 --minquality=1 --notstrict --nochanges --emptyok
pwpolicy luks --minlen=6 --minquality=1 --notstrict --nochanges --notempty
%end
EOF
#echo '/home/vagrant/cfg *(ro)' >> /etc/exports
#  systemctl reload nfs-server.service
}
# uncomment to enable automatic installation
autoinstall
