#!/bin/bash
echo -e '\033[1;31m ********************************此脚本自动化安装Zabbix******************************** \033[0m'
if [[ `yum list installed | grep mysql-community | wc -l` == 0 ]];then
  echo -e '\033[1;32m mysql-community未安装，请先安装mysql再重新执行此脚本！ \033[0m'
else
  echo -e '\033[1;32m mysql-community已安装 \033[0m'
fi
echo -e '\033[1;32m 
说明：
zabbix版本：4.4.x;
OS:Centos 7;
数据库:MySQL;
Web Server:Nginx
\033[0m'

ip_address=`ip a | grep inet | grep -v inet6 | grep -v 127 | sed 's/^[ \t]*//g' | cut -d ' ' -f2 | grep -v 172 | cut -d '/' -f1 | head -1`

echo -e -n  '\033[1;32m 请输入mysql数据库密码(root用户)： \033[0m'
read mysql_password
echo -e -n  '\033[1;32m 请输入将要设置的mysql数据库密码(zabbix用户)： \033[0m'
read zabbix_password


function install_nginx(){
  if [[ `yum list installed | grep nginx |wc -l` == 0 ]];then
    yum install -y nginx
    install_nginx
  else
    echo -e '\033[1;32m nginx已经安装 \033[0m'
  fi
}

install_nginx


function install_php_fpm(){
  if [[ `yum list installed | grep nginx |wc -l` == 0 ]];then
    yum install -y php_fpm
    install_php_fpm
  else
    echo -e '\033[1;32m php_fpm已经安装 \033[0m'
  fi
}

install_php_fpm


echo -e '\033[1;32m 1.安装 数据库 \033[0m'
rpm -Uvh https://repo.zabbix.com/zabbix/4.4/rhel/7/x86_64/zabbix-release-4.4-1.el7.noarch.rpm
yum clean all

echo -e '\033[1;32m 2.安装Zabbix server和agent \033[0m'
#此步骤由于经常失败，故需要多次尝试直到成功为止。
function install_zabbix_server_mysql(){
  if [[ `yum list installed | grep zabbix-server-mysql |wc -l` == 0 ]];then
    yum install -y zabbix-server-mysql
    install_zabbix_server_mysql
  else
    echo -e '\033[1;32m zabbix-server-mysql已经安装 \033[0m'
  fi
}

install_zabbix_server_mysql

function install_zabbix_agent(){
  if [[ `yum list installed | grep zabbix-agent |wc -l` == 0 ]];then
    yum install -y zabbix-agent
    install_zabbix_agent
  else
    echo -e '\033[1;32m zabbix-agent已经安装 \033[0m'
  fi
}

install_zabbix_agent



echo -e "\033[1;32m 3. Install Zabbix frontend\033[0m"
echo -e "\033[1;32m Install epel repository.\033[0m"
function install_zabbix_frontend(){
  if [[ `yum list installed | grep epel-release |wc -l` == 0 ]];then
    yum install -y epel-release
    install_zabbix_frontend
  else
    echo -e '\033[1;32m epel-release已经安装 \033[0m'
  fi
}

install_zabbix_frontend



echo -e "\033[1;32m Install Zabbix frontend packages.\033[0m"
function install_zabbix_web_mysql(){
  if [[ `yum list installed | grep zabbix-web-mysql |wc -l` == 0 ]];then
    yum install -y zabbix-web-mysql
    install_zabbix_web_mysql
  else
    echo -e '\033[1;32m zabbix-web-mysql已经安装 \033[0m'
  fi
}

install_zabbix_web_mysql


function install_zabbix_nginx_conf(){
  if [[ `yum list installed | grep zabbix_nginx_conf |wc -l` == 0 ]];then
    yum install -y zabbix-nginx-conf
    install_zabbix_nginx_conf
  else
    echo -e '\033[1;32m zabbix_nginx_conf已经安装 \033[0m'
  fi
}

install_zabbix_nginx_conf

echo -e "\033[1;32m 安装zabbix-get工具\033[0m"
function install_zabbix_get(){
  if [[ `yum list installed | grep zabbix-get |wc -l` == 0 ]];then
    yum install -y zabbix-get
    install_zabbix_get
  else
    echo -e '\033[1;32m zabbix-get已经安装 \033[0m'
  fi
}

install_zabbix_get


echo -e '\033[1;32m 4.创建初始数据库 \033[0m'
mysql -uroot -p${mysql_password} -e "CREATE USER 'zabbix'@'localhost' IDENTIFIED BY '${zabbix_password}';flush privileges;"
mysql -uroot -p${mysql_password} -e "CREATE USER 'zabbix'@'%' IDENTIFIED BY '${zabbix_password}';flush privileges;"
mysql -uroot -p${mysql_password} -e "GRANT ALL ON *.* TO 'zabbix'@'localhost';flush privileges;"
mysql -uroot -p${mysql_password} -e "GRANT ALL ON *.* TO 'zabbix'@'%';flush privileges;"
mysql -uroot -p${mysql_password} -e "create database zabbix character set utf8 collate utf8_bin;"


echo -e '\033[1;32m 导入初始架构和数据。 \033[0m'
gzip -d /usr/share/doc/zabbix-server-mysql*/create.sql.gz
docker cp /usr/share/doc/zabbix-server-mysql*/create.sql mysql:/root
mysql -uzabbix -p${zabbix_password} -e "use zabbix;source /root/create.sql;"

echo -e '\033[1;32m 5.为Zabbix server配置数据库 \033[0m'
echo -e '\033[1;32m 编辑配置文件 /etc/zabbix/zabbix_server.conf \033[0m'
sed -i "/^# DBPassword=/cDBPassword=${zabbix_password}" /etc/zabbix/zabbix_server.conf

echo -e '\033[1;32m 6.为Zabbix前端配置PHP \033[0m'
echo -e '\033[1;32m 编辑配置文件 /etc/nginx/conf.d/zabbix.conf \033[0m'
sed -i "s/#//g" /etc/nginx/conf.d/zabbix.conf
sed -i "s/; //g" /etc/php-fpm.d/zabbix.conf
sed -i "s/Europe\/Riga/Asia\/Shanghai/g" /etc/php-fpm.d/zabbix.conf

echo -e '\033[1;32m 替换字体 \033[0m'
cp DejaVuSans.ttf /usr/share/fonts/dejavu/

echo -e '\033[1;32m 7.启动Zabbix server和agent进程 \033[0m'
echo -e '\033[1;32m 启动Zabbix server和agent进程，并为它们设置开机自启： \033[0m'
systemctl restart zabbix-server zabbix-agent nginx php-fpm
systemctl enable zabbix-server zabbix-agent nginx php-fpm
systemctl status zabbix-server zabbix-agent nginx php-fpm

echo -e '\033[1;32m 7.配置Zabbix前端 \033[0m'
echo "连接到新安装的Zabbix前端： http://${ip_address}"
exit