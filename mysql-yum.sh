#!/bin/bash
echo -e '\033[1;32m 安装MySQL \033[0m'
echo -e '\033[1;32m 开始安装mysql最新稳定版5.7（实际上为社区版本)\033[0m'
echo -e '\033[1;32m 下载mysql安装包 \033[0m'
wget -c http://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm
echo -e '\033[1;32m 安装mysql依赖 \033[0m'
yum localinstall -y mysql57-community-release-el7-11.noarch.rpm
# echo '查看最新稳定版本信息'
# yum repolist all | grep mysql
echo -e '\033[1;32m 安装mysql社区服务器 \033[0m'
yum -y install mysql-community-server
echo -e '\033[1;32m 修改mysql配置文件 \033[0m'
sed -i '$a\federated'  /etc/my.cnf
sed -i '$a\max_connections = 2000'  /etc/my.cnf
sed -i '$a\max_allowed_packet = 64M'  /etc/my.cnf
sed -i '$a\skip-grant-tables=1'  /etc/my.cnf
echo -e '\033[1;32m 设置mysql开机启动 \033[0m'
systemctl enable mysqld
echo -e '\033[1;32m 启动mysql \033[0m'
systemctl start mysqld

echo -e -n '\033[1;32m 请输入将要设置的mysql root用户密码\033[0m'
read mysql_passwd
mysql -u root -e "update mysql.user  set authentication_string=password('${mysql_passwd}') where user='root';flush privileges;"
echo -e "\033[1;32m mysql密码设置完毕！ \033[0m"
echo -e "\033[1;32m 清除yum安装包 \033[0m"
yum -y clean all
sed -i "s/skip-grant-tables=1//g"  /etc/my.cnf
echo -e '\033[1;32m 重启mysql \033[0m'
systemctl restart mysqld
mysql -u root -p${mysql_passwd} -e "set global validate_password_policy=0;" --connect-expired-password
mysql -u root -p${mysql_passwd} -e "set global validate_password_mixed_case_count=0;" --connect-expired-password
mysql -u root -p${mysql_passwd} -e "set global validate_password_number_count=3;" --connect-expired-password
mysql -u root -p${mysql_passwd} -e "set global validate_password_special_char_count=0;" --connect-expired-password
mysql -u root -p${mysql_passwd} -e "set global validate_password_length=3;" --connect-expired-password
mysql -u root -p${mysql_passwd} -e "alter user 'root'@'localhost' identified by '${mysql_passwd}';flush privileges;" --connect-expired-password
mysql -u root -p${mysql_passwd} -e "SHOW VARIABLES LIKE 'validate_password%';" --connect-expired-password
exit
