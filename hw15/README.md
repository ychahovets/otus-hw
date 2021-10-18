### Необходимо решить задачу по ограничению доступа пользователей в 
### систему  по  ssh.  Это  будут  пользователи:  “day“,  “night”,  “friday”. 
### Введем для них соответственно ограничения:
###
```
”day” - имеет удаленный доступ каждый день с 8 до 20;
“night” - с 20 до 8;
“friday” - в любое время, если сегодня пятница.
```
### На стендовой виртуальной машине создадим 3х пользователей:
```
[vagrant@hostname ~]$ sudo useradd day && sudo useradd night && sudo useradd friday
```
### Назначим им пароли:
```
[vagrant@hostname ~]$ echo "Otus2019" | sudo passwd --stdin day 
[vagrant@hostname ~]$ echo "Otus2019" | sudo passwd --stdin night  
[vagrant@hostname ~]$ echo "Otus2019" | sudo passwd --stdin friday
```
### Чтобы быть уверенными, что на стенде разрешен вход через ssh по 
### паролю выполним:
```
[vagrant@hostname ~]$ sudo bash -c "sed -i 's/^PasswordAuthentication.*$/PasswordAuthentication yes/' /etc/ssh/sshd_config && systemctl restart sshd.service"
```
### Теперь стенд готов к работе

PAM (Pluggable Authentication Modules - подключаемые модули 
аутентификации)  -  это  набор  библиотек,  которые  позволяют 
интегрировать  различные  методы  аутентификации  в  виде  единого 
API, что позволяет предоставить единые механизмы для управления, 
встраивания прикладных программ в процесс аутентификации. PAM 
решает следующие задачи:
Authentication - Аутентификация, идентификация, процесс 
подтверждения пользователем своей “подлинности”, ввод логина 
и пароля;
Authorization - Авторизация, процесс наделения пользователя 
правами (предоставления доступа к каким-либо объектам);
Accounting - Запись информации о произошедших событиях.
Таким образом для решения задачи необходимо на первом или 
втором этапе применить необходимые нам проверки. Их можно 
реализвать несколькими способами. Рассмотрим их.
PAM. Модуль pam_time
Модуль pam_time позволяет достаточно гибко настроить доступ 
пользователя с учетом времени. Настройки данного модуля хранятся 
в файле `/etc/security/time.conf`. Данный файл содержит в себе 
пояснения и примеры использования. Добавим в конец файла строки:

```
*;*;day;Al0800-2000
*;*;night;!Al0800-2000
*;*;friday;Fr
```

### Разные параметры отделяются символом ";". 
### Разберем первую строку:
```
“*” сервис, к которому применяется правило
"*" имя терминала, к которому применяется правило
"day" имя пользователя, для которого данное правило будет действовать
"Al0800-2000" время, когда правило носит разрешающий характер
```
### PAM. Модуль pam_time
Теперь настроим PAM, так как по-умолчанию данный модуль не 
подключен. 
Для этого приведем файл `/etc/pam.d/sshd` к виду:
```
account    required     pam_nologin.so
account    required     pam_time.so
```
После чего в отдельном терминале можно проверить доступ к 
серверу по ssh для созданных пользователей.
```
ssh day@192.168.56.101
The authenticity of host '192.168.56.101 (192.168.56.101)' can't be established.
ECDSA key fingerprint is SHA256:MqfVWLBI1/JICp6b5KeWgrkfgYHSb3a29uGjKK//VkI.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '192.168.56.101' (ECDSA) to the list of known hosts.
day@192.168.56.101's password: 
[day@hostname ~]$ 
```

### Еще один способ реализовать задачу это выполнить при 
подключении пользователя скрипт, в котором мы сами обработаем 
необходимую информацию.
Удалим из `/etc/pam.d/sshd` изменения из предыдущего этапа и 
приведем его к следующему виду:
```
account  required   pam_nologin.so
account  required   pam_exec.so  /usr/local/bin/test_login.sh
```
### Мы добавили модуль pam_exec и, в качестве параметра, указали 
скрипт, который осуществит необходимые проверки. Создадим сам 
скрипт. 
```
#!/bin/bash

if [ $PAM_USER = "friday" ]; then
  if [ $(date +%a) = "Fri" ]; then
      exit 0
    else 
      exit 1
  fi
fi

hour=$(date +%H)

is_day_hours=$(($(test $hour -ge 8; echo $?)+$(test $hour -lt 20; echo $?)))

if [ $PAM_USER = "day" ]; then
  if [ $is_day_hours -eq 0 ]; then
      exit 0
    else
      exit 1
  fi
fi

if [ $PAM_USER = "night" ]; then
  if [ $is_day_hours -eq 1 ]; then
      exit 0
    else
      exit 1
  fi
fi
```

При  запуске  данного  скрипта  PAM-модулем  будет  передана 
переменная  окружения  PAM_USER,  содержащая  имя  пользователя. 
Скрипт содержит простую логику. Если имя пользователя friday, то 
проверям день недели, если пятница, то возвращаем 0, если нет, то 
1 и завершаем скрипт.
Если же указан другой пользователь, то в строке 
```
is_day_hours=$(($(test $hour -ge 8; echo $?)+$(test $hour -lt 20; echo $?)))
```
происходит  проверка  принадлежит  ли  текущее  значение  времени 
(переменная    hour)  диапазону  от  8  до  20  часов.  Если  да,  то 
is_day_hours примет значение 0, если нет 1. Дальше проверяем имя 
пользователя  и  соотвествие  ему.  Если  пользователь  day  и  часы 
"дневные",  то  возвращаем  0,  если  пользователь  night  и  часы  НЕ 
дневные,  то  так  же  возвращаем  ноль.  В  противном  случае  скрипт 
вернет 1. Если в PAM_USER указано какое-то другое имя пользователя, 
то скрипт вернет 0.
На основании кода завершения скрипта модуль pam_exec принимает 
решение. Если вернулся 0, то все в порядке и пользователь будет 
авторизован, в обратном случае нет.

Данный модуль не входит, как предыдущие в базовую систему и 
должен быть установлен из отдельного репозитория Extra Packages 
for Enterprise Linux (EPEL). Подключим репозиторий и установим 
pam_script:
```
[root@hostname ~]# for pkg in epel-release pam_script; do yum install -y $pkg; done
```
Так же как и pam_exec модуль предназначен для выполнения 
произвольного скрипта в процессе авторизации, аутентификации 
или аккаунтинга пользователя. 
По сравнению с предыдущим примером в файле /etc/pam.d/sshd 
нужно просто переименовать pam_exec в pam_script:
```
account  required  pam_nologin.so
account  required  pam_script.so  /usr/local/bin/test_login.sh
```


Для демонстрации работы модуля установим дополнительный пакет 
nmap-ncat(CentOS). Пользователь day остался из предыдущего 
примера. Если стенд пересоздавался, то пользователя так же 
необходимо создать. 
Войдем на стендовую машину под пользователем day и попробуем 
выполнить команду nc и получим сообщение об ошибке. Пример 
ниже
```
[day@hostname ~]$ ncat -l -p 80
Ncat: bind to :::80: Permission denied. QUITTING.
```
Это связано с тем, что непривелигерованный пользователь day, от 
имени которого выполняется команда, не может открыть для 
прослушивания 80й порт.

Эту задачу можно решить несколькими способами: 
●установить suid-бит. Установка данного бита позволит 
выполнить ncat так, будто он запущен от root. Способ имеет 
низкую гибкость, так как установка бита позволит любому 
пользователю выполнить команду;
●предоставить пользователю права (возможности), чтобы он 
смог открыть порт. Способ более гибкий, потому что можно 
указать что именно, кому и при помощи какой программы мы 
разрешаем;
Решим задачу вторым способом. Для этого воспользумся pam-
модулем pam_cap. Поскольку это демо стенд, то SELinux можно 
просто выключить выполнив 
```
[vagrant@hostname ~]$ sudo setenforce 0
```
### Отключать SELinux в продакшене крайне не рекомендуется
Приведем файл /etc/pam.d/sshd к виду:
```
auth       include      postlogin
auth       required     pam_cap.so
```
Таким  образом  мы  включили  обработку  `capabilities`  при 
подключении  по  `ssh`.  Пропишем  необходимые  права  пользователю 
`day`.  Для  этого  создадим  файл  `/etc/security/capability.conf `
содержащий одну строку:
```
[root@hostname ~]# echo "cap_net_bind_service     day" > /etc/security/capability.conf
```
Теперь необходимо программе `(/usr/bin/ncat)`, при помощи которой 
будет  открываться  порт,  так  же  выдать  разрешение  на  данное 
действие:
```
[root@hostname ~]# setcap cap_net_bind_service=ei /usr/bin/ncat
```
### Мы  сопоставили  права,  выданные  пользователю  с  правами 
выданными на программу. Снова зайдем на стенд под пользователем 
day и проверим, что мы получили необходимые права:
```
[day@hostname ~]$ capsh --print Current: = cap_net_bind_service +i
Current: =
```
Теперь попробуем выполнить команду:
[day@hostname ~]$ ncat -l -p 80


Теперь ошибки не возникло. Теперь можно открыть еще одну 
консоль и там выполнить:
```
[day@hostname ~]$ echo "Make Linux great again!" > /dev/tcp/127.0.0.1/80
```
и увидеть сообщение в перовой консоли

### Попробуем предоставить пользователю day права на sudo без запроса пароля. Для этого создадим файлик /etc/sudoers.d/day из под root
```
echo 'day ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/day
```
### Проверка

[day@hostname ~]$ sudo -i
[root@hostname ~]# 

### --------------------------------------------------------

#### Домашка с PAM
Запретить всем пользователям, кроме группы admin логин в выходные (суббота и воскресенье), без учета праздников.

ОК, реалезуем с помощью скрипта [login.sh](login.sh) и модуля pam_exec. Создадим пользователей и группу, user1 добавим в группу admin
```
[root@hostname ~]# useradd -m -s /bin/bash user1
[root@hostname ~]# useradd -m -s /bin/bash user2
[root@hostname ~]# groupadd admin
[root@hostname ~]# usermod -a -G admin user1
[root@hostname ~]# id user1 && id user2
uid=1004(user1) gid=1004(user1) groups=1004(user1),1006(admin)
uid=1005(user2) gid=1005(user2) groups=1005(user2)
```
### Добавим нашим новым юзверям пароли:
```
[root@hostname ~]# echo "Otus2019" | sudo passwd --stdin user1
Changing password for user user1.
passwd: all authentication tokens updated successfully.
[root@hostname ~]# echo "Otus2019" | sudo passwd --stdin user2
Changing password for user user2.
passwd: all authentication tokens updated successfully.
```
### Включим возможность подключения по ssh с паролем
```
sed -i 's/^PasswordAuthentication.*$/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
systemctl restart sshd.service
```
### Проверяем
```
ssh user1@192.168.56.101
user1@192.168.56.101's password: 
[user1@hostname ~]$ exit
logout
Connection to 192.168.56.101 closed.

ssh user2@192.168.56.101
user2@192.168.56.101's password: 
[user2@hostname ~]$ exit
logout
Connection to 192.168.56.101 closed.
```
### Сделаем скрипт исполняемым, скопируем в `/usr/local/bin/`, добавим настройки в `/etc/pam.d/sshd`
```
[root@hostname /]# vim /usr/local/bin/login.sh
[root@hostname /]# chmod +x /usr/local/bin/login.sh
sed -i '/pam_nologin/a account\t   required\t pam_exec.so /usr/local/bin/login.sh' /etc/pam.d/sshd
```
Поставим дату на воскресенье
```
[root@hostname ~]# date -s Sun
Sun Oct 17 00:00:00 UTC 2021
```
Проверим
```
ssh user1@192.168.56.101
user1@192.168.56.101's password: 
[user1@hostname ~]$ exit
logout
Connection to 192.168.56.101 closed.

ssh user2@192.168.56.101
user2@192.168.56.101's password: 
/usr/local/bin/mylogin.sh failed: exit code 1
Connection closed by 192.168.56.101 port 22
```
Работает.
### --------------------------------------------------------


