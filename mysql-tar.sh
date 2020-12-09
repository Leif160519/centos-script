#!/bin/bash
# 变量定义
mysql_version="mysql-5.7.28-linux-glibc2.12-x86_64"
mysql_root_dir="/var/lib/mysql"
mysql_config_file="/etc/my.cnf"
mysql_log_file="/var/log/mysqld.log"
mysql_run_dir="/var/run/mysqld"
mysql_pid_file="${mysql_run_dir}/mysqld.pid"
mysql_sock_file="${mysql_run_dir}/mysql.sock"
mysql_pre_dir=/usr/share/mysql
mysql_pre_file="${mysql_pre_dir}/mysql-systemd-pre"
mysql_url="https://downloads.mysql.com/archives/get/p/23/file/${mysql_version}.tar.gz"

# 创建mysql配置文件
function create_config_file(){
cat <<EOF > ${mysql_config_file}
[client]
socket=${mysql_sock_file}
default-character-set=utf8

[mysql]
default-character-set=utf8

[mysql.server]
default-character-set=utf8

[mysqld_safe]
default-character-set=utf8

[mysqld]
port = 3306
bind-address=0.0.0.0
datadir=${mysql_root_dir}/data
socket=${mysql_sock_file}
basedir=${mysql_root_dir}

character-set-server=utf8
collation-server=utf8_general_ci
skip-character-set-client-handshake
skip-external-locking

symbolic-links=0

log-error=${mysql_log_file}
pid-file=${mysql_pid_file}

max_connections = 2000
max_allowed_packet = 64M
EOF

chown mysql:mysql ${mysql_config_file}
chmod 0644 ${mysql_config_file}
}

# 创建运行文件夹
function create_run_dir() {
    mkdir -p ${mysql_run_dir}
    chown -R mysql:mysql ${mysql_run_dir}
    chmod -R 0755 ${mysql_run_dir}
}

# 创建日志文件
function create_log_file() {
    touch ${mysql_log_file}
    chmod 0644 ${mysql_log_file}
    chown mysql:mysql ${mysql_log_file}
}

# 初始化mysql
function init_mysql(){
    ${mysql_root_dir}/bin/mysqld \
        --initialize-insecure \
        --user=mysql \
        --basedir=${mysql_root_dir} \
        --datadir=${mysql_root_dir}/data
}

# 创建mysql服务启动之前所需脚本
function create_pre_file() {
mkdir -p ${mysql_pre_dir}
chmod -R 0755 ${mysql_pre_dir}
chown -R root:root ${mysql_pre_dir}
cat <<EOF > ${mysql_pre_file}
if [ ! -d "${mysql_run_dir}" ];then
mkdir "${mysql_run_dir}"
chown -R mysql:mysql /var/run/mysqld
fi
exit
EOF

chmod +x ${mysql_pre_file}
chown root:root ${mysql_pre_file}
}

# 创建mysqld服务启动文件
function create_service_file() {
cat <<EOF > /lib/systemd/system/mysqld.service
[Unit]
Description=MySQL Community Server
After=network.target

[Service]
ExecStartPre=/bin/bash ${mysql_pre_file}
ExecStart=${mysql_root_dir}/bin/mysqld_safe --defaults-file=${mysql_config_file}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

chmod 0644 /lib/systemd/system/mysqld.service
chown root:root /lib/systemd/system/mysqld.service
}

# 环境检测
port_monit=$(lsof -i:3306 | wc -l)
if [[ ${port_monit} -ge 2 ]];then
    echo "端口已被占用，请检查mysql是否已经安装！"
else
    # 安装依赖软件
    yum -y install numactl
    # 创建mysql用户和组
    useradd mysql
    # 下载解压mysql安装程序
    wget -c ${mysql_url} -O /tmp/${mysql_version}.tar.gz
    tar -zxvf /tmp/${mysql_version}.tar.gz -C /var/lib
    if [[ -d ${mysql_root_dir} ]];then
        echo "${mysql_root_dir}已存在,退出安装程序！"
        exit 1
    else
        mv /var/lib/${mysql_version} ${mysql_root_dir}
    fi
    # 设置mysql文件夹权限
    chown -R mysql:mysql ${mysql_root_dir}
    # 创建data目录
    mkdir -p ${mysql_root_dir}/data
    chmod -R 0755 ${mysql_root_dir}/data
    chown -R mysql:mysql ${mysql_root_dir}/data
    # 创建mysql配置文件
    create_config_file
    # 创建运行文件夹
    create_run_dir
    # 创建日志文件
    create_log_file
    # 初始化mysql
    init_mysql
    # 创建mysql服务启动之前所需脚本
    create_pre_file
    # 创建mysqld服务启动文件
    create_service_file
    # 启动mysqld服务
    systemctl start mysqld
    systemctl enable mysqld
    # 创建软链接
    find ${mysql_root_dir}/bin -type f -exec ln -s {} /usr/local/bin \;
fi
