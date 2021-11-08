
Развертывание `nginx` с использованием  Ansible.
Иерархия файлов
```
.
├── ansible.cfg
├── inventories
│   └── all.yml
├── nginx.yml
├── README.md
├── roles
│   └── nginx
│       ├── defaults
│       │   └── main.yml
│       ├── handlers
│       │   └── main.yml
│       ├── tasks
│       │   ├── configure.yml
│       │   ├── install.yml
│       │   └── main.yml
│       └── templates
│           └── nginx.conf.j2
└── Vagrantfile
```
Установим `ansible` в виртуальном окружении python
```
python3 -m venv .venv
source .venv/bin/activate
pip install ansible
```

Стартуем vm `vagrant up`


Запускаем `ansible-playbook nginx.yml`, смотрим вывод:

```
(.venv) ych@dell:~/OTUS/test-hw/hw10.01$ ansible-playbook nginx.yml 

PLAY [NGINX | Install and configure NGINX] ************************************************************************************

TASK [Gathering Facts] ********************************************************************************************************
ok: [nginx]

TASK [nginx : NGINX | install | EPEL Repo package from standart repo] *********************************************************
changed: [nginx]

TASK [nginx : NGINX | install | NGINX package from EPEL Repo] *****************************************************************
changed: [nginx]

TASK [nginx : NGINX | configure | Create NGINX config file from template] *****************************************************
changed: [nginx]

RUNNING HANDLER [nginx : restart nginx] ***************************************************************************************
changed: [nginx]

RUNNING HANDLER [nginx : reload nginx] ****************************************************************************************
changed: [nginx]

PLAY RECAP ********************************************************************************************************************
nginx                      : ok=6    changed=5    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

Заходим на vm и проверяем как работает сервис nginx

```
[vagrant@nginx ~]$ systemctl status nginx.service 
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)
   Active: active (running) since Mon 2021-11-08 15:32:13 UTC; 36s ago
  Process: 5705 ExecReload=/usr/sbin/nginx -s reload (code=exited, status=0/SUCCESS)
  Process: 6911 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 6908 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 6907 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 6913 (nginx)
   CGroup: /system.slice/nginx.service
           ├─6913 nginx: master process /usr/sbin/nginx
           └─6915 nginx: worker process
```

Смотрим конфигурационный файл nginx
```
[vagrant@nginx ~]$ cat /etc/nginx/nginx.conf
# Ansible managed
events {
    worker_connections 1024;
}

http {
    server {
        listen       8080 default_server;
        server_name  default_server;
        root         /usr/share/nginx/html;

        location / {
        }
    }
}
```

Проверяем доступность nginx  на нестандартном порту из консоли 
```
(.venv) ych@dell:~/OTUS/test-hw/hw10.01$ curl -I 192.168.56.111:8080
HTTP/1.1 200 OK
Server: nginx/1.20.1
Date: Mon, 08 Nov 2021 15:21:19 GMT
Content-Type: text/html
Content-Length: 4833
Last-Modified: Fri, 16 May 2014 15:12:48 GMT
Connection: keep-alive
ETag: "53762af0-12e1"
Accept-Ranges: bytes
```
