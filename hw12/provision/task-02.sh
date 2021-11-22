#!/bin/bash
yum install epel-release -y && yum install spawn-fcgi php php-cli mod_fcgid httpd -y
cp -fr /vagrant/spawn-fcgi/* /


systemctl start spawn-fcgi.service 
systemctl status spawn-fcgi.service 