### Отрабатываем навыки установки и настройки DHCP, TFTP, PXE загрузчика и автоматической загрузки

Следуя шагам из документа `https://docs.centos.org/en-US/8-docs/advanced-install/assembly_preparing-for-a-network-install` установить и настроить загрузку по сети для дистрибутива CentOS8 
В качестве шаблона воспользуйтесь репозиторием `https://github.com/nixuser/virtlab/tree/main/centos_pxe`
Поменять установку из репозитория NFS на установку из репозитория HTTP
Настройить автоматическую установку для созданного kickstart файла (*) Файл загружается по HTTP


Критерии оценки:

ссылка на репозиторий github.
Vagrantfile с шагами установки необходимых компонентов
Исходный код scripts для настройки сервера (если необходимо)
Если какие-то шаги невозможно или сложно автоматизировать, то инструкции по ручным шагам для настройки

Возьмём за основу файл ` https://github.com/nixuser/virtlab/tree/main/centos_pxe `
`nginx`

Для размещения загрузочных файлов сделаем директорию /opt/pxe/ - в неё мы смонтируем скачанные образы и kickstart файлы. И добавим в установку  nginx чтобы инсталляционный образ был доступен по http. Установим его уже привычной ролью ansible, при этом выделим такой момент: В качестве root укажем /opt/pxe и в location добавим autoindex on;

Убедимся, что nginx работает и раздаёт образы
pxe сервер

в ks.cfg выставим минимальную установку, для CentOS 7 эта опция будет иметь вид
```
    %packages
    @^minimal
```
Скриншоты процесса

Запрос IP-адреса pxeclient-ом
![](https://github.com/ychahovets/otus-hw/blob/main/hw18/img/001.png)

Выбираем пункт Auto install CentOS-7
![](https://github.com/ychahovets/otus-hw/blob/main/hw18/img/002.png)

Установка CentOS-7 начнется автоматически
![](https://github.com/ychahovets/otus-hw/blob/main/hw18/img/003.png)

Установка CentOS-7 в процессе
![](https://github.com/ychahovets/otus-hw/blob/main/hw18/img/004.png)
