#!/bin/bash
cp /vagrant/scripts/httpd@.service /etc/systemd/system/
cp /vagrant/scripts/httpd@80* /etc/sysconfig/
systemctl disable httpd

cp -a /etc/httpd /etc/httpd-8080
sed -i 's#^ServerRoot "/etc/httpd"$#ServerRoot "/etc/httpd-8080"#g' /etc/httpd-8080/conf/httpd.conf
sed -i 's#^Listen 80$#Listen 8080#g' /etc/httpd-8080/conf/httpd.conf
cp -a /etc/httpd /etc/httpd-8081

systemctl enable httpd@808{0,1}.service
systemctl start httpd@808{0,1}.service
systemctl status httpd@808{0,1}.service


