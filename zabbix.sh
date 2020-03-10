#!/bin/bash
echo -e '\033[1;31m ********************************此脚本自动化安装Zabbix******************************** \033[0m'
ip_address=`ip a | grep inet | grep -v inet6 | grep -v 127 | sed 's/^[ \t]*//g' | cut -d ' ' -f2 | grep -v 172 | cut -d '/' -f1 | head -1`

echo -e -n  '\033[1;32m 请输入将要设置的mysql数据库密码(root用户)： \033[0m'
read mysql_password
echo -e -n  '\033[1;32m 请输入将要设置的mysql数据库密码(zabbix用户)： \033[0m'
read zabbix_password
echo -e '\033[1;32m 生成mysql的docker-compose.yml \033[0m'
mkdir -p /root/mysql
cat <<EOF > /root/mysql/docker-compose.yml
version: '3'
services:
  mysql:
    image: mysql:5.7.28
    restart: always
    container_name: mysql
    environment:
    - TZ=Asia/Shanghai
    - MYSQL_ROOT_PASSWORD=${mysql_password}
    ports:
    - 3306:3306
    volumes:
    - /root:/root:rw
    - /tmp
    - ./mysqld.cnf:/etc/mysql/mysql.conf.d/mysqld.cnf
    network_mode: host
EOF

echo -e '\033[1;32m 生成mysql的配置文件mysqld.cnf \033[0m'
cat <<EOF > /root/mysql/mysqld.cnf
[mysqld]
max_connections = 2000
max_allowed_packet = 64M
pid-file	= /var/run/mysqld/mysqld.pid
socket		= /var/run/mysqld/mysqld.sock
datadir		= /var/lib/mysql
symbolic-links=0

character-set-server=utf8
collation-server=utf8_general_ci
skip-character-set-client-handshake

[client]
default-character-set=utf8

[mysql]
default-character-set=utf8

[mysql.server]
default-character-set=utf8

[mysqld_safe]
default-character-set=utf8
EOF

cd /root/mysql
docker-compose up -d


echo -e '\033[1;32m 1.Install Zabbix repository \033[0m'
rpm -Uvh https://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-release-4.0-2.el7.noarch.rpm
yum clean all

echo -e '\033[1;32m 2.Install Zabbix server, frontend, agent \033[0m'
yum install -y zabbix-server-mysql
yum install -y zabbix-web-mysql
yum install -y zabbix-agent 

echo -e '\033[1;32m 3.Create initial database \033[0m'
echo -e '\033[1;32m 3.1 Run the following on your database host. \033[0m'
docker exec -it mysql mysql -uroot -p${mysql_password} -e "CREATE USER 'zabbix'@'localhost' IDENTIFIED BY '${zabbix_password}';flush privileges;"
docker exec -it mysql mysql -uroot -p${mysql_password} -e "CREATE USER 'zabbix'@'%' IDENTIFIED BY '${zabbix_password}';flush privileges;"
docker exec -it mysql mysql -uroot -p${mysql_password} -e "GRANT ALL ON *.* TO 'zabbix'@'localhost';flush privileges;"
docker exec -it mysql mysql -uroot -p${mysql_password} -e "GRANT ALL ON *.* TO 'zabbix'@'%';flush privileges;"
docker exec -it mysql mysql -uroot -p${mysql_password} -e "create database zabbix;"


echo -e '\033[1;32m 3.2 On Zabbix server host import initial schema and data. You will be prompted to enter your newly created password. \033[0m'
zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | docker exec -itd mysql mysql -uzabbix -p ${zabbix_password}

echo -e '\033[1;32m 4.Configure the database for Zabbix server \033[0m'
sed -i "/^# DBPassword=/cDBPassword=${zabbix_password}" /etc/zabbix/zabbix_server.conf

echo -e '\033[1;32m 5.Configure PHP for Zabbix frontend \033[0m'
sed -i "/^# php_value date.timezone/cphp_value date.timezone Aisa\/Shanghai" /etc/httpd/conf.d/zabbix.conf

echo -e '\033[1;32m 6.Start Zabbix server and agent processes \033[0m'
systemctl restart zabbix-server zabbix-agent httpd
systemctl enable zabbix-server zabbix-agent httpd
systemctl status zabbix-server zabbix-agent httpd

echo -e '\033[1;32m 7.Configure Zabbix frontend \033[0m'
echo "Connect to your newly installed Zabbix frontend: http://${ip_address}/zabbix"
exit