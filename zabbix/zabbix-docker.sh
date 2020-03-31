#!/bin/bash
dir=`pwd`
docker run --name mysql-server -t \
    -v /etc/localtime:/etc/localtime \
    -e MYSQL_DATABASE="zabbix" \
    -e MYSQL_USER="zabbix" \
    -e MYSQL_PASSWORD="zabbix" \
    -e MYSQL_ROOT_PASSWORD="123456" \
    -p 3306:3306 \
    --restart=always \
    -d mysql:5.7.28 \
    --character-set-server=utf8 --collation-server=utf8_bin


docker run --name zabbix-java-gateway -t \
    -v /etc/localtime:/etc/localtime \
    --restart=always \
    -d zabbix/zabbix-java-gateway:latest

docker run --name zabbix-server-mysql -t \
    -e DB_SERVER_HOST="mysql-server" \
    -e MYSQL_DATABASE="zabbix" \
    -e MYSQL_USER="zabbix" \
    -e MYSQL_PASSWORD="zabbix" \
    -e MYSQL_ROOT_PASSWORD="123456" \
    -e ZBX_JAVAGATEWAY="zabbix-java-gateway" \
    -v /etc/localtime:/etc/localtime \
    --link mysql-server:mysql \
    --link zabbix-java-gateway:zabbix-java-gateway \
    -p 10051:10051 \
    --restart=always \
    -d zabbix/zabbix-server-mysql:latest

docker run --name zabbix-agent -t \
    -e ZBX_HOSTNAME="zabbix-agent" \
    -e ZBX_SERVER_HOST="zabbix-server-mysql" \
    -v /etc/localtime:/etc/localtime \
    --link zabbix-server-mysql:zabbix-server \
    --link zabbix-java-gateway:zabbix-java-gateway \
    -p 10050:10050 \
    --restart=always \
    -d zabbix/zabbix-agent:latest


docker run --name zabbix-web-nginx-mysql -t \
    -e DB_SERVER_HOST="mysql-server" \
    -e MYSQL_DATABASE="zabbix" \
    -e MYSQL_USER="zabbix" \
    -e MYSQL_PASSWORD="zabbix" \
    -e MYSQL_ROOT_PASSWORD="123456" \
    -v /etc/localtime:/etc/localtime \
    -v ${dir}/99-zabbix.ini:/etc/php7/conf.d/99-zabbix.ini \
    -v ${dir}/DejaVuSans.ttf:/usr/share/zabbix/assets/fonts/DejaVuSans.ttf \
    --link mysql-server:mysql \
    --link zabbix-server-mysql:zabbix-server \
    -p 80:80 \
    --restart=always \
    -d zabbix/zabbix-web-nginx-mysql:latest

exit
#检测zabbix-agent容器IP地址：
#docker exec  -it  $(docker ps -a | grep "zabbix-agent" | awk '{print $1}') "ifconfig"
#docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' zabbix-agent

#参考：
#https://www.jianshu.com/p/b2d44c733c2d
#https://zhuanlan.zhihu.com/p/35064593
#https://zhuanlan.zhihu.com/p/35068409
#https://blog.rj-bai.com/post/144.html
