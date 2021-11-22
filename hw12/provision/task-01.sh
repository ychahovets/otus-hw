#!/bin/bash
cp -r /vagrant/watchlog/* /
chmod +x /opt/watchlog.sh

systemctl start watchlog.timer 

