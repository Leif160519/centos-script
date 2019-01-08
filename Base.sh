#!/bin/bash
echo -e '\033[1;31m ********************************此脚本自动化安装初始环境******************************** \033[0m'
#scp luofei@192.168.81.29:Desktop/command.sh /root
echo -e '\033[1;31m 1.安装必须组件 \033[0m'
echo -e '\033[1;31m 安装wget \033[0m'
yum -y install wget
echo -e '\033[1;31m ********************************************************************************** \033[0m'

echo -e '\033[1;31m 2.更换阿里源 \033[0m'
echo -e '\033[1;31m 备份本地yum源 \033[0m'
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo_bak
echo -e '\033[1;31m 获取阿里yum源配置文件 \033[0m'
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo 
echo -e '\033[1;31m 更新cache \033[0m'
yum makecache
echo -e '\033[1;31m 更新 \033[0m'
yum -y update
echo -e '\033[1;31m ********************************************************************************** \033[0m'

echo -e '\033[1;31m 安装nano \033[0m'
yum -y install nano
echo -e '\033[1;31m ********************************************************************************** \033[0m'
echo -e '\033[1;31m 安装unzip \033[0m'
yum -y install unzip
echo -e '\033[1;31m ********************************************************************************** \033[0m'
echo -e '\033[1;31m 安装git \033[0m'
yum -y install git
echo -e '\033[1;31m ********************************************************************************** \033[0m'
echo -e '\033[1;31m 安装java \033[0m'
yum -y install java
echo -e '\033[1;31m ********************************************************************************** \033[0m'
echo -e '\033[1;31m 安装yum-utils \033[0m'
yum -y install yum-utils
echo -e '\033[1;31m ********************************************************************************** \033[0m'
echo -e '\033[1;31m 安装expect \033[0m'
yum -y install expect
echo -e '\033[1;31m ********************************************************************************** \033[0m'
echo -e '\033[1;31m 安装htop \033[0m'
echo -e '\033[1;31m 启用epe版本 \033[0m'
yum -y install epel-release
yum -y install htop
echo -e '\033[1;31m ********************************************************************************** \033[0m'
echo -e '\033[1;31m 安装npm \033[0m'
yum -y install npm
echo -e '\033[1;31m ********************************************************************************** \033[0m'
echo -e '\033[1;31m 安装pv \033[0m'
yum -y install pv
echo -e '\033[1;31m ********************************************************************************** \033[0m'
echo -e '\033[1;31m 安装telnet \033[0m'
yum -y install telnet
echo -e '\033[1;31m ********************************************************************************** \033[0m'
echo -e '\033[1;31m 安装net-tools \033[0m'
yum -y install net-tools
echo -e '\033[1;31m ********************************************************************************** \033[0m'
echo -e '\033[1;31m 安装tree \033[0m'
yum -y install tree
echo -e '\033[1;31m ********************************************************************************** \033[0m'
echo -e '\033[1;31m 安装tmux \033[0m'
yum -y install tmux
echo -e '\033[1;31m ********************************************************************************** \033[0m'
echo -e '\033[1;31m 安装iperf \033[0m'
yum -y install iperf
echo -e '\033[1;31m ********************************************************************************** \033[0m'

echo -e '\033[1;31m 安装pip \033[0m'
yum -y install epel-release
yum -y install python-pip
echo -e '\033[1;31m 给pip换源 \033[0m'
mkdir /root/.pip
cat <<EOF >/root/.pip/pip.conf
[global]
index-url = http://mirrors.aliyun.com/pypi/simple/
[install]
trusted-host=mirrors.aliyun.com
EOF
echo -e '\033[1;31m 升级pip \033[0m'
pip install --upgrade pip
echo -e '\033[1;31m ********************************************************************************** \033[0m'

echo -e '\033[1;31m 安装supervisor \033[0m'
pip install supervisor
echo -e '\033[1;31m 将supervisor配置文件重定向到/etc/目录下面 \033[0m'
mkdir /etc/supervisor
echo_supervisord_conf > /etc/supervisor/supervisord.conf
echo -e '\033[1;31m 新建进程管理文件夹 \033[0m \033[1;33m /etc/supervisor/conf.d \033[0m'
mkdir /etc/supervisor/conf.d
echo -e '\033[1;31m 修改supervisor配置文件(将默认/temp路径放在/var下) \033[0m'
cat <<EOF >/etc/supervisor/supervisord.conf
[unix_http_server]
file=/var/run/supervisor.sock   ; the path to the socket file

[supervisord]
logfile=/var/log/supervisord.log ; main log file; default /supervisord.log
logfile_maxbytes=50MB        ; max main logfile bytes b4 rotation; default 50MB
logfile_backups=10           ; # of main logfile backups; 0 means none, default 10
loglevel=info                ; log level; default info; others: debug,warn,trace
pidfile=/var/run/supervisord.pid ; supervisord pidfile; default supervisord.pid
nodaemon=false               ; start in foreground if true; default false
minfds=1024                  ; min. avail startup file descriptors; default 1024
minprocs=200                 ; min. avail process descriptors;default 200

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///var/run/supervisor.sock ; use a unix:// URL  for a unix socket

[inet_http_server]         ; inet (TCP) server disabled by default
port=0.0.0.0:9001          ; (ip_address:port specifier, *:port for all iface)
username=admin             ; 用户名 (default is no username (open server))
password=123456            ; 密码 (default is no password (open server))
[include]
files = /etc/supervisor/conf.d/*.conf
EOF
echo -e '\033[1;31m 修改新路径权限 \033[0m'
chmod 777 /var/run
chmor 777 /var/log
echo -e '\033[1;31m 创建supervisor.sock并赋予权限 \033[0m'
touch /var/run/supervisor.sock
chmod 777 /var/run/supervisor.sock
echo -e '\033[1;31m 生成supervisor服务自启动文件,文件路径为: \033[0m \033[1;33m /usr/lib/systemd/system/supervisor.service  \033[0m'
cat <<EOF >/usr/lib/systemd/system/supervisor.service
[Unit]
Description=Supervisor process control system for UNIX
Documentation=http://supervisord.org
After=network.target

[Service]
ExecStart=/usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
ExecStop=/usr/bin/supervisorctl $OPTIONS shutdown
ExecReload=/usr/bin/supervisorctl -c /etc/supervisor/supervisord.conf $OPTIONS reload
KillMode=process
Restart=on-failure
RestartSec=50s

[Install]
WantedBy=multi-user.target
EOF

echo -e '\033[1;31m 启动supervisor \033[0m'
systemctl daemon-reload
systemctl start supervisor
echo -e '\033[1;31m 允许开机自启supervisor \033[0m'
systemctl enable supervisor
echo -e '\033[1;31m 查看supervisor服务启动状态 \033[0m'
systemctl status supervisor
echo -e '\033[1;31m 管理supervisor下的服务 \033[0m
\033[1;33m
    1.启动服务
    supervisorctl start all
    supervisorctl start service_name
    2.关闭服务
    supervisorctl stop all
    supervisorctl stop service_name
    3.查看状态
    supervisorctl status [service_name]
    4.重新启动所有服务或者是某个服务
    supervisorctl restart all
    supervisorctl restart service_name
    5.关闭supervisor
    supervisorctl shutdown
    6.重新载入supervisor，在这里相当于重启supervisor服务，里面的服务也会跟着重新启动
    supervisorctl reload
    7.添加/删除 要管理服务
    supervisorctl update
\033[0m'
echo -e '\033[1;31m 查看supervisor web管理页面 \033[0m  \033[1;33m http://localhost:9001; 用户名：admin; 密码：123456 \033[0m'
echo -e '\033[1;31m ********************************************************************************** \033[0m'

echo -e '\033[1;31m 3.安装时间同步服务器 \033[0m'
yum -y install ntp
echo -e '\033[1;31m 设置开机启动 \033[0m'
systemctl enable ntpd
echo -e '\033[1;31m 启动时间同步服务器 \033[0m'
systemctl start ntpd
echo -e '\033[1;31m 查看时间同步服务器运行状态 \033[0m'
systemctl status ntpd
echo -e '\033[1;31m ********************************************************************************** \033[0m'

echo -e '\033[1;31m 4.关闭swap分区 \033[0m'
swapoff -a
echo -e '\033[1;31m 查看内存实用情况 \033[0m'
free -m 
echo -e '\033[1;31m ********************************************************************************** \033[0m'

echo -e '\033[1;31m 5.关闭防火墙 \033[0m'
echo -e '\033[1;31m 修改 \033[1;33m /etc/selinux/config \033[0m 配置文件 \033[0m'
cat <<EOF >/etc/selinux/config
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
SELINUX=disabled
# SELINUXTYPE= can take one of three two values:
#     targeted - Targeted processes are protected,
#     minimum - Modification of targeted policy. Only selected processes are protected. 
#     mls - Multi Level Security protection.
SELINUXTYPE=targeted 
EOF
echo -e '\033[1;31m 停止防火墙服务 \033[0m'
systemctl stop firewalld
echo -e '\033[1;31m 禁止防火墙开机自启 \033[0m'
systemctl disable firewalld
echo -e '\033[1;31m ********************************************************************************** \033[0m'

echo -e '\033[1;31m 6.安装screenfetch \033[0m'
echo -e '\033[1;31m 从github上下载screenfetch \033[0m'
git clone git://github.com/KittyKatt/screenFetch.git screenfetch
echo -e '\033[1;31m 复制文件到/usr/bin/目录 \033[0m'
cp screenfetch/screenfetch-dev /usr/bin/screenfetch
echo -e '\033[1;31m 给screenfetch赋予可执行权限 \033[0m'
chmod +x /usr/bin/screenfetch
echo -e '\033[1;31m 查看计算机软硬件信息 \033[0m'
screenfetch
echo -e '\033[1;31m ********************************************************************************** \033[0m'

echo -e '\033[1;31m 7.关闭SSH DNS反向解析和GSSAPI的用户认证 \033[0m'
cat <<EOF >/etc/ssh/sshd_config
#	$OpenBSD: sshd_config,v 1.100 2016/08/15 12:32:04 naddy Exp $

# This is the sshd server system-wide configuration file.  See
# sshd_config(5) for more information.

# This sshd was compiled with PATH=/usr/local/bin:/usr/bin

# The strategy used for options in the default sshd_config shipped with
# OpenSSH is to specify options with their default value where
# possible, but leave them commented.  Uncommented options override the
# default value.

# If you want to change the port on a SELinux system, you have to tell
# SELinux about this change.
# semanage port -a -t ssh_port_t -p tcp #PORTNUMBER
#
#Port 22
#AddressFamily any
#ListenAddress 0.0.0.0
#ListenAddress ::

HostKey /etc/ssh/ssh_host_rsa_key
#HostKey /etc/ssh/ssh_host_dsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# Ciphers and keying
#RekeyLimit default none

# Logging
#SyslogFacility AUTH
SyslogFacility AUTHPRIV
#LogLevel INFO

# Authentication:

#LoginGraceTime 2m
#PermitRootLogin yes
#StrictModes yes
#MaxAuthTries 6
#MaxSessions 10

#PubkeyAuthentication yes

# The default is to check both .ssh/authorized_keys and .ssh/authorized_keys2
# but this is overridden so installations will only check .ssh/authorized_keys
AuthorizedKeysFile	.ssh/authorized_keys

#AuthorizedPrincipalsFile none

#AuthorizedKeysCommand none
#AuthorizedKeysCommandUser nobody

# For this to work you will also need host keys in /etc/ssh/ssh_known_hosts
#HostbasedAuthentication no
# Change to yes if you don't trust ~/.ssh/known_hosts for
# HostbasedAuthentication
#IgnoreUserKnownHosts no
# Don't read the user's ~/.rhosts and ~/.shosts files
#IgnoreRhosts yes

# To disable tunneled clear text passwords, change to no here!
#PasswordAuthentication yes
#PermitEmptyPasswords no
PasswordAuthentication yes

# Change to no to disable s/key passwords
#ChallengeResponseAuthentication yes
ChallengeResponseAuthentication no

# Kerberos options
#KerberosAuthentication no
#KerberosOrLocalPasswd yes
#KerberosTicketCleanup yes
#KerberosGetAFSToken no
#KerberosUseKuserok yes

# GSSAPI options
GSSAPIAuthentication no
GSSAPICleanupCredentials no
#GSSAPIStrictAcceptorCheck yes
#GSSAPIKeyExchange no
#GSSAPIEnablek5users no

# Set this to 'yes' to enable PAM authentication, account processing,
# and session processing. If this is enabled, PAM authentication will
# be allowed through the ChallengeResponseAuthentication and
# PasswordAuthentication.  Depending on your PAM configuration,
# PAM authentication via ChallengeResponseAuthentication may bypass
# the setting of "PermitRootLogin without-password".
# If you just want the PAM account and session checks to run without
# PAM authentication, then enable this but set PasswordAuthentication
# and ChallengeResponseAuthentication to 'no'.
# WARNING: 'UsePAM no' is not supported in Red Hat Enterprise Linux and may cause several
# problems.
UsePAM yes

#AllowAgentForwarding yes
#AllowTcpForwarding yes
#GatewayPorts no
X11Forwarding yes
#X11DisplayOffset 10
#X11UseLocalhost yes
#PermitTTY yes
#PrintMotd yes
#PrintLastLog yes
#TCPKeepAlive yes
#UseLogin no
#UsePrivilegeSeparation sandbox
#PermitUserEnvironment no
#Compression delayed
#ClientAliveInterval 0
#ClientAliveCountMax 3
#ShowPatchLevel no
UseDNS no
#PidFile /var/run/sshd.pid
#MaxStartups 10:30:100
#PermitTunnel no
#ChrootDirectory none
#VersionAddendum none

# no default banner path
#Banner none

# Accept locale-related environment variables
AcceptEnv LANG LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES
AcceptEnv LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT
AcceptEnv LC_IDENTIFICATION LC_ALL LANGUAGE
AcceptEnv XMODIFIERS

# override default of no subsystems
Subsystem	sftp	/usr/libexec/openssh/sftp-server

# Example of overriding settings on a per-user basis
#Match User anoncvs
#	X11Forwarding no
#	AllowTcpForwarding no
#	PermitTTY no
#	ForceCommand cvs server
EOF
echo -e '\033[1;31m 重启sshd服务 \033[0m'
systemctl restart sshd
echo -e '\033[1;31m 查看sshd服务状态 \033[0m'
systemctl status sshd
echo -e '\033[1;31m ********************************************************************************** \033[0m'

echo -e '\033[1;31m 8.更改主机hostname \033[0m'
#获取本机ip地址
IP_ADDRESS=$(ip a | grep inet | grep -v inet6 | grep -v 127 | sed 's/^[ \t]*//g' | cut -d ' ' -f2 | grep -v 172 | cut -d '/' -f1 | head -1)
cat <<EOF >/etc/hostname
${IP_ADDRESS}
EOF

echo -e '\033[1;32m系统初始化配置完成！\033[0m'
exit
