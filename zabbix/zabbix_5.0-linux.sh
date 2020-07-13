#!/bin/bash
echo -e '\033[1;32m 安装Zabbix \033[0m'
if [[ `yum list installed | grep mysql-community | wc -l` == 0 ]];then
  echo -e '\033[1;32m mysql-community未安装，请先安装mysql再重新执行此脚本！ \033[0m'
else
  echo -e '\033[1;32m mysql-community已安装 \033[0m'
fi
echo -e '\033[1;32m 
说明：
zabbix版本：5.0.x;
OS:Centos 7;
数据库:MySQL;
Web Server:Nginx
\033[0m'

ip_address=`ip a | grep inet | grep -v inet6 | grep -v 127 | sed 's/^[ \t]*//g' | cut -d ' ' -f2 | grep -v 172 | cut -d '/' -f1 | head -1`

echo -e -n  '\033[1;32m 请输入mysql数据库密码(root用户)： \033[0m'
read mysql_password
echo -e -n  '\033[1;32m 请输入将要设置的mysql数据库密码(zabbix用户)： \033[0m'
read zabbix_password


echo -e '\033[1;32m 1.安装 数据库 \033[0m'
rpm -Uvh https://repo.zabbix.com/zabbix/4.5/rhel/7/x86_64/zabbix-release-4.5-2.el7.noarch.rpm
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
  if [[ `yum list installed | grep centos-release-scl |wc -l` == 0 ]];then
    yum install -y centos-release-scl
    install_zabbix_frontend
  else
    echo -e '\033[1;32m centos-release-scl已经安装 \033[0m'
  fi
}

install_zabbix_frontend


echo -e "\033[1;32m 编辑配置文件 /etc/yum.repos.d/zabbix.repo and enable zabbix-deprecated repository.\033[0m"
sed -i '11s/enabled=0/enabled=1/' /etc/yum.repos.d/zabbix.repo

echo -e "\033[1;32m Install Zabbix frontend packages.\033[0m"
function install_zabbix_web_mysql(){
  if [[ `yum list installed | grep zabbix-web-mysql-scl |wc -l` == 0 ]];then
    yum install -y zabbix-web-mysql-scl
    install_zabbix_web_mysql
  else
    echo -e '\033[1;32m zabbix-web-mysql-scl已经安装 \033[0m'
  fi
}

install_zabbix_web_mysql


function install_zabbix_nginx_conf(){
  if [[ `yum list installed | grep zabbix-nginx-conf-scl |wc -l` == 0 ]];then
    yum install -y zabbix-nginx-conf-scl
    install_zabbix_nginx_conf
  else
    echo -e '\033[1;32m zabbix-nginx-conf-scl已经安装 \033[0m'
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




echo -e "\033[1;32m 安装zabbix-sender工具\033[0m"
function install_zabbix_sender(){
  if [[ `yum list installed | grep zabbix-sender |wc -l` == 0 ]];then
    yum install -y zabbix-sender
    install_zabbix_sender
  else
    echo -e '\033[1;32m zabbix-sender已经安装 \033[0m'
  fi
}

install_zabbix_sender


echo -e '\033[1;32m 4.创建初始数据库 \033[0m'
mysql -uroot -p${mysql_password} -e "CREATE USER 'zabbix'@'localhost' IDENTIFIED BY '${zabbix_password}';flush privileges;" --connect-expired-password
mysql -uroot -p${mysql_password} -e "CREATE USER 'zabbix'@'%' IDENTIFIED BY '${zabbix_password}';flush privileges;" --connect-expired-password
mysql -uroot -p${mysql_password} -e "GRANT ALL ON *.* TO 'zabbix'@'localhost';flush privileges;" --connect-expired-password
mysql -uroot -p${mysql_password} -e "GRANT ALL ON *.* TO 'zabbix'@'%';flush privileges;" --connect-expired-password
mysql -uroot -p${mysql_password} -e "create database zabbix character set utf8 collate utf8_bin;" --connect-expired-password


echo -e '\033[1;32m 导入初始架构和数据。 \033[0m'
gzip -d /usr/share/doc/zabbix-server-mysql*/create.sql.gz
cp /usr/share/doc/zabbix-server-mysql*/create.sql /root
mysql -uzabbix -p${zabbix_password} -e "use zabbix;source /root/create.sql;"

echo -e '\033[1;32m 5.为Zabbix server配置数据库 \033[0m'
echo -e '\033[1;32m 编辑配置文件 /etc/zabbix/zabbix_server.conf \033[0m'
sed -i "/^# DBPassword=/cDBPassword=${zabbix_password}" /etc/zabbix/zabbix_server.conf

echo -e '\033[1;32m 6.为Zabbix前端配置PHP \033[0m'
echo -e '\033[1;32m 编辑配置文件 /etc/opt/rh/rh-nginx116/nginx/conf.d/zabbix.conf \033[0m'
sed -i "s/#//g" /etc/opt/rh/rh-nginx116/nginx/conf.d/zabbix.conf
echo -e '\033[1;32m 编辑配置文件 /etc/opt/rh/rh-php72/php-fpm.d/zabbix.conf, add nginx to listen.acl_users directive. \033[0m'
sed -i "s/listen.acl_users = apache/listen.acl_users = apache,nginx/g"  /etc/opt/rh/rh-php72/php-fpm.d/zabbix.conf
sed -i "s/; //g" /etc/opt/rh/rh-php72/php-fpm.d/zabbix.conf
echo -e '\033[1;32m 编辑配置文件 /etc/opt/rh/rh-php72/php-fpm.d/zabbix.conf, set the right timezone for you. \033[0m'
sed -i "s/; php_value\[date.timezone\] = Europe\/Riga/php_value\[date.timezone\] = Asia\/Shanghai/g" /etc/opt/rh/rh-php72/php-fpm.d/zabbix.conf



cat <<EOF > /etc/opt/rh/rh-nginx116/nginx/nginx.conf
# For more information on configuration, see:
#   * Official English Documentation: http://nginx.org/en/docs/
#   * Official Russian Documentation: http://nginx.org/ru/docs/

user nginx;
worker_processes auto;
error_log /var/opt/rh/rh-nginx116/log/nginx/error.log;
pid /var/opt/rh/rh-nginx116/run/nginx/nginx.pid;

# Load dynamic modules. See /opt/rh/rh-nginx116/root/usr/share/doc/README.dynamic.
include /opt/rh/rh-nginx116/root/usr/share/nginx/modules/*.conf;

events {
    worker_connections  1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/opt/rh/rh-nginx116/log/nginx/access.log  main;

    sendfile        on;
    tcp_nopush      on;
    tcp_nodelay     on;
    keepalive_timeout  65;
    types_hash_max_size 2048;

    include	  /etc/opt/rh/rh-nginx116/nginx/mime.types;
    default_type  application/octet-stream;

    # Load modular configuration files from the /etc/nginx/conf.d directory.
    # See http://nginx.org/en/docs/ngx_core_module.html#include
    # for more information.
    include /etc/opt/rh/rh-nginx116/nginx/conf.d/*.conf;

}
EOF

echo -e '\033[1;32m 配置具有root权限的Zabbix代理(此命令只能在zabbix-server端执行，不能在zabbix-agent端执行，否则zabbix-agent服务无法启动) \033[0m'
sed -i "s/# AllowRoot=0/AllowRoot=1/g" /etc/zabbix/zabbix_agentd.conf

echo -e '\033[1;32m 替换字体 \033[0m'
\cp DejaVuSans.ttf /usr/share/fonts/dejavu/

#允许用户自定义脚本
sed -i "s/# UnsafeUserParameters=0/UnsafeUserParameters=1/g" /etc/zabbix/zabbix_agentd.conf

echo -e '\033[1;32m 7.启动Zabbix server和agent进程 \033[0m'
echo -e '\033[1;32m 启动Zabbix server和agent进程，并为它们设置开机自启： \033[0m'
systemctl restart zabbix-server zabbix-agent rh-nginx116-nginx rh-php72-php-fpm
systemctl enable zabbix-server zabbix-agent rh-nginx116-nginx rh-php72-php-fpm
systemctl status zabbix-server zabbix-agent rh-nginx116-nginx rh-php72-php-fpm

echo -e '\033[1;32m 7.配置Zabbix前端 \033[0m'
echo "连接到新安装的Zabbix前端： http://${ip_address}"
exit
