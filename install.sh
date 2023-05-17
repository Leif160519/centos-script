#!/bin/bash

help_info(){
cat <<EOF
用法: bash $0 选项 [选项...]
示例:
        bash $0 common
        bash $0 rabbitmq
        bash $0 supervisor
选项:
        help       打印这个帮助信息
        update     更新镜像源
        common     安装常规软件
        gui        安装带有gui的软件
        general    安装通用软件
        clean      清理下载的安装包
        grafana    安装grafana
        gitlab     安装gitlab
        rar        编译安装rar
        nodejs     安装nodejs
        ccat       安装ccat
        mysql      安装mysql
        rabbitmq   安装rabbitmq
        fetch      安装screenfetch和neofetch
        supervisor 安装supervisor
        monit      安装monit
        docker     安装docker
        zsh        安装oh_my_zsh
        mongodb    安装mongodb

EOF
        exit 1
}

update_system(){ # {{{
    yum makecache
    echo "update system done."
} # }}}

install_common(){ # {{{
    software_list=(yum-utils epel-release nagios nc perf bind-utils ShellCheck nfs-utils samba-client iputils trafshow)
    for software in ${software_list[@]}
    do
        yum -y install ${software}
        echo -e "\033[1;32m Install ${software} done. \033[0m"
    done
    echo "install common software donw."
} # }}}

install_gui_software(){ # {{{
    gui_software_list=(kompare meld kdiff3 tkcvs yakuake nautilus remmina stacer copyq xsensors conky guake aterm gpick flameshot nnn hardinfo chromium)
    for software in ${gui_software_list{@}}
    do
        yum -y install ${software}
        echo -e "\033[1;32m Install ${software} done. \033[0m"
    done
    echo "install gui software done."
} # }}}

install_general(){ # {{{
    software_list=(nano vim emacs zip unzip git bash-completion wget iftop htop iotop nethogs mrgt telnet traceroute tree iperf lsof dpkg expect hdparm psmisc fping tcpdump nmap fio strace sysstat monit ansible dosfstools uuid make colordiff subnetcalc groovy python python3 python3-pip w3m lynx dos2unix curl nlod cifs-utils xfsprogs net-tools curlftpfs tig jq mosh axel lrzsz cloc ccache tmux byobu neovim mc powerman ncdu glances dstat pcp multitail figlet wdiff smartmontools ntp ntpdate lsb fortune-mod ethtool lvm2 enca nload iptraf bmon slurm tcptrack vnstat bwm-ng ifstat collectl zstd moreutils nvme-cli unhide highlight supervisor)
    for software in ${software_list[@]}
    do
        yum -y install ${software}
        echo -e "\033[1;32m Install ${software} done. \033[0m"
    done
    wait_start_service=(sysstat monit ntpd supervisord)
    for software in ${wait_start_service[@]}
    do
        systemctl start ${software}
        systemctl enable ${software}
    done
    echo "install general software done."
} # }}}

clean_up(){ # {{{
    yum -y autoremove
    yum clean all
    echo "system clean up done."
} # }}}

install_grafana(){ # {{{
    grafana_rpm_version="grafana-8.3.3-1.x86_64"
    grafana_rpm_url="https://dl.grafana.com/oss/release/${grafana_rpm_version}.rpm"
    wget -c ${grafana_rpm_url} -O /tmp/${grafana_rpm_version}.rpm --no-check-certificate
    yum -y install /tmp/${grafana_rpm_version}.rpm
    systemctl start grafana-server
    systemctl enable grafana-server
    echo "install grafana done."
} # }}}

install_gitlab(){ # {{{
    ip_addr=$(ip a | grep inet | grep -v inet6 | grep -v 127 | sed 's/^[ \t]*//g' | cut -d ' ' -f2  | cut -d '/' -f1 | head -1)
    gitlab_rpm_version="gitlab-ce-14.5.2-ce.0.el7.x86_64"
    gitlab_rpm_url="https://packages.gitlab.com/gitlab/gitlab-ce/packages/el/7/${gitlab_rpm_version}.rpm/download.rpm"
    if [[ ! -f /bin/gitlab-ctl ]];then
        yum -y install curl url policycoreutils openssh-server openssh-clients policycoreutils-python postfix
        systemctl start postfix
        systemctl enable postfix
        wget -c ${gitlab_rpm_url} -O /tmp/${gitlab_rpm_version}.rpm --no-check-certificate
        yum -y install /tmp/${gitlab_rpm_version}.rpm
        sed -i '/^external_url/cexternal_url 'http://${ip_addr}'/' /etc/gitlab/gitlab.rb
        sed -i "s/# gitlab_rails\['backup_keep_time'\] = 604800/gitlab_rails\['backup_keep_time'\] = 604800/g" /etc/gitlab/gitlab.rb
        [[ $(grep "gitlab" /var/spoo/cron/crontab/root | wc -l) == 0 ]] && echo "0 2 * * * /opt/gitlab/bin/gitlab-rake gitlab:backup:create CRON=1" >> /var/spool/cron/crontabs/root
        gitlab-ctl reconfigure
        echo "install gitlab done."
    fi
} # }}}

install_rar(){ # {{{
    rar_version="rarlinux-x64-5.7.1"
    rar_url="http://www.rarlab.com/rar/${rar_version}.tar.gz"
    if [[ ! -f /usr/local/bin/rar ]];then
        wget -c ${rar_url} -O /tmp/${rar_version}.tar.gz --no-check-certificate
        tar -zxvf /tmp/${rar_version}.tar.gz -C /tmp
        cd /tmp/rar
        make
        echo "install rar done."
    else
        echo "rar is already installed."
    fi
} # }}}

install_nodejs(){ # {{{
    yum -y install nodejs npm
    npm config set registry https://registry.npm.taobao.org
    npm install n -g
    n stable
    npm install -g cnpm
    echo "install nodejs done."
} # }}}

install_ccat_software(){ # {{{
    ccat_version="linux-amd64-1.1.0"
    ccat_url="https://github.com/jingweno/ccat/releases/download/v1.1.0/${ccat_version}.tar.gz"
    if [[ ! -f /usr/local/bin/ccat ]];then
        wget -c ${ccat_url} -O /tmp/${ccat_version}.tar.gz --no-check-certificate
        tar -zxvf /tmp/${ccat_version}.tar.gz -C /tmp
        cp /tmp/${ccat_version}/ccat /usr/local/bin
        chmod +x /usr/local/bin/ccat
        echo "install ccat done."
    else
        echo "ccat is already installed."
    fi
    [[ $(grep "ccat" /root/.bashrc | wc -l) == 0 ]] && echo "alias ccat=cat" >> /root/.bashrc
} # }}}

install_mysql(){ # {{{
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
        wget -c ${mysql_url} -O /tmp/${mysql_version}.tar.gz --no-check-certificate
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
        systemctl daemon-reload
        systemctl start mysqld
        systemctl enable mysqld
        # 创建软链接
        find ${mysql_root_dir}/bin -type f -exec ln -s {} /usr/local/bin \;
    fi
} # }}}

install_rabbitmq(){ # {{{
    # erlang下载 https://www.erlang-solutions.com/resources/download.html;https://github.com/rabbitmq/erlang-rpm/releases

    # RabbitMQ下载 https://www.rabbitmq.com/install-rpm.html#install-erlang;https://github.com/rabbitmq/rabbitmq-server/releases/

    centos6=$(grep -cIE 'CentOS.*?6.*?' /etc/issue)
    centos7=$(grep -cIE 'CentOS.*?7.*?' /etc/issue)

    if [ "$centos6" == 1 -o "$centos7" == 1 ]; then
        echo -e "\033[1;32m 1.卸载RabbitMQ \033[0m"
        yum -y remove rabbitmq
        rpm -qa | grep rabbitmq | xargs -I {} rpm -e {}
        echo -e "\033[1;32m 2.卸载erlang  \033[0m"
        yum -y remove erlang
        rpm -qa | grep erlang | xargs -I {} rpm -e {}
        echo -e "\033[1;32m 3.安装socat  \033[0m"
        yum -y install socat
    fi

    if [ "$centos6" == 1 ]; then
        echo -e "\033[1;32m 4.下载erlang  \033[0m"
        wget -c https://github.com/rabbitmq/erlang-rpm/releases/download/v21.3.8.1/erlang-21.3.8.1-1.el6.x86_64.rpm --no-check-certificate
        echo -e "\033[1;32m 5.安装erlang \033[0m"
        rpm -ivh erlang-21.3.8.1-1.el6.x86_64.rpm
        echo -e "\033[1;32m 6.下载RabbitMQ \033[0m"
        wget -c https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.7.14/rabbitmq-server-3.7.14-1.el6.noarch.rpm --no-check-certificate
        echo -e "\033[1;32m 7.安装RabbitMQ  \033[0m"
        rpm -ivh rabbitmq-server-3.7.14-1.el6.noarch.rpm
    fi

    if [ "$centos7" == 1 ]; then
        echo -e "\033[1;32m 4.下载erlang \033[0m"
        wget -c https://github.com/rabbitmq/erlang-rpm/releases/download/v21.3.8.1/erlang-21.3.8.1-1.el7.x86_64.rpm --no-check-certificate
        echo -e "\033[1;32m 5.安装erlang \033[0m"
        rpm -ivh erlang-21.3.8.1-1.el7.x86_64.rpm
        echo -e "\033[1;32m 6.下载RabbitMQ \033[0m"
        wget -c https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.7.14/rabbitmq-server-3.7.14-1.el7.noarch.rpm --no-check-certificate
        echo -e "\033[1;32m 7.安装RabbitMQ \033[0m"
        rpm -ivh rabbitmq-server-3.7.14-1.el7.noarch.rpm
    fi

    echo -e "\033[1;32m 8.设置开机启动 \033[0m"
    systemctl enable rabbitmq-server
    echo -e "\033[1;32m 9.编辑配置 \033[0m"
cat <<EOF >/etc/rabbitmq/rabbitmq.config
[{rabbit,[{loopback_users, []}]}] .
EOF
cat <<EOF >/etc/rabbitmq/rabbitmq-env.conf
NODENAME=rabbit@localhost
EOF
    #重新启动服务
    echo -e "\033[1;32m 10.启动服务 \033[0m"
    systemctl restart  rabbitmq-server
    echo -e "\033[1;32m 11.开启管理功能 \033[0m"
    rabbitmq-plugins enable rabbitmq_management
    echo -e "\033[1;32m 12.重启服务 \033[0m"
    systemctl restart  rabbitmq-server
    echo -e "\033[1;32m 13.增加管理员用户 \033[0m"
    rabbitmqctl add_user admin 123456
    rabbitmqctl set_user_tags admin administrator
    echo -e "\033[1;32m 14.在浏览器中使用端口15672登录控制台，可以对RabbitMQ进行管理 \033[0m"
    curl http://localhost:15672
    echo -e '\033[1;32m RabbitMQ配置完成！\033[0m'
} # }}}

install_fetch(){ # {{{
    if [[ ! -f /usr/bin/screenfetch ]];then
        git clone http://github.com/KittyKatt/screenFetch.git /tmp/screenfetch
        cp /tmp/screenfetch/screenfetch-dev /usr/bin/screenfetch
        chmod +x /usr/bin/screenfetch
        echo "install screenfetch done."
    else
        echo "screenfetch is already installed."
    fi

    if [[ ! -f /usr/bin/neofetch ]];then
         curl -o /etc/yum.repos.d/konimex-neofetch-epel-7.repo https://copr.fedorainfracloud.org/coprs/konimex/neofetch/repo/epel-7/konimex-neofetch-epel-7.repo
         yum -y install neofetch
         echo "install neofetch done."
    else
        echo "neofetch is already installed."
    fi
} # }}}

install_supervisor(){ # {{{
    yum -y install supervisor
    systemctl start supervisord
    systemctl enable supervisor
} # }}}

install_monit(){ # {{{
    yum -y install monit
    systemctl start monit
    systemctl enable monit
} # }}}

install_docker(){ # {{{
    if [[ ! -f /usr/bin/docker ]];then
        wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo
        yum makecache
        yum install -y docker-ce docker-compose
cat <<EOF > /etc/docker/daemon.json
{
    "data-root": "/var/lib/docker",
    "live-restore": true,
    "log-driver": "json-file",
    "log-opts":
        {
            "max-file": "3",
            "max-size": "10m"
        },
    "default-address-pools":
        [
            {
                "base": "198.18.0.0/16",
                "size": 24
            }
        ],
    "registry-mirrors":
        [
            "http://hub-mirror.c.163.com",
            "https://registry.cn-hangzhou.aliyuncs.com",
            "http://docker.mirrors.ustc.edu.cn",
            "https://registry.docker-cn.com"
        ]
}
EOF
        systemctl start docker
        systemctl enable docker
        wget -c https://github.com/bcicen/ctop/releases/download/v0.7.2/ctop-0.7.2-linux-amd64 -O /usr/local/bin/ctop
        chmod +x /usr/local/bin/ctop
        echo "install docker done."
    else
        echo "docker is already installed."
    fi
    wget -c https://github.com/bcicen/ctop/releases/download/0.7.6/ctop-0.7.6-linux-amd64 -O /usr/local/bin/ctop
    chmod +x /usr/local/bin/ctop
} # }}}

install_oh_my_zsh(){ # {{{
    yum -y install zsh autojump
    sed -i '/^root/croot:x:0:0:root:/root:/bin/zsh' /etc/passwd
    curl -sSLf https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh > /tmp/install.sh
    chmod +x /tmp/install.sh
    bash /tmp/install.sh
    plugins_path="/root/.oh-my-zsh/custom/plugins"
    echo -e '\033[1;32m 安装zsh-syntax-highlighting:模仿fish命令行高亮的插件  \033[0m'
    if [[ ! -d ${plugins_path}/zsh-syntax-highlighting ]];then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${plugins_path}"/zsh-syntax-highlighting
    fi

    echo -e '\033[1;32m 安装zsh-autosuggestions:根据命令历史记录自动推荐和提示的插件  \033[0m'
    if [[ ! -d ${plugins_path}/zsh-autosuggestions ]];then
        git clone https://github.com/zsh-users/zsh-autosuggestions "${plugins_path}"/zsh-autosuggestions
    fi

    echo -e '\033[1;32m 安装zsh-completions:自动命令补全，类似bash-completions功能的插件 \033[0m'
    if [[ ! -d ${plugins_path}/zsh-completions ]];then
        git clone https://github.com/zsh-users/zsh-completions "${plugins_path}"/zsh-completions
    fi

    echo -e '\033[1;32m 安装history-substring-search:按住向上箭头可以搜索出现过该关键字的历史命令插件 \033[0m'
    if [[ ! -d ${plugins_path}/zsh-history-substring-search ]];then
        git clone https://github.com/zsh-users/zsh-history-substring-search "${plugins_path}"/zsh-history-substring-search
    fi

    echo -e '\033[1;32m 安装history-search-multi-word:ctrl+r搜索历史记录插件 \033[0m'
    if [[ ! -d ${plugins_path}/history-search-multi-word ]];then
        git clone https://github.com/zdharma-continuum/history-search-multi-word "${plugins_path}"/history-search-multi-word
    fi

    echo -e '\033[1;32m 安装fast-syntax-highlighting:丰富的语法高亮插件 \033[0m'
    if [[ ! -d ${plugins_path}/fast-syntax-highlighting ]];then
        git clone https://github.com/zdharma-continuum/fast-syntax-highlighting "${plugins_path}"/fast-syntax-highlighting
    fi

cat <<EOF > ~/.zshrc
export ZSH="/root/.oh-my-zsh"

ZSH_THEME="random"

plugins=(
        emotty
        git
        zsh-autosuggestions
        zsh-syntax-highlighting
        zsh-completions
        z
        history-substring-search
        command-not-found
        colored-man-pages
        extract
        history-search-multi-word
        fast-syntax-highlighting
)

source \$ZSH/oh-my-zsh.sh
EOF
} # }}}

install_mongodb(){ # {{{
cat <<EOF > /etc/yum.repos.d/mongodb-org-4.0.repo
[mongodb-org-4.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2013.03/mongodb-org/4.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.0.asc
EOF
    yum install -y mongodb-org
    sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
    systemctl start mongod
    systemctl enable mongod
} # }}}

if (($#==0))
then
    help_info
else
    case $1 in
        help) help_info;;
        update) update_system;;
        common) install_common;;
        gui) install_gui_software;;
        general) install_general;;
        clean) clean_up;;
        grafana) install_grafana;;
        gitlab) install_gitlab;;
        rar) install_rar;;
        nodejs) install_nodejs;;
        ccat) install_ccat_software;;
        mysql) install_mysql;;
        rabbitmq) install_rabbitmq;;
        fetch) install_fetch;;
        supervisor) install_supervisor;;
        monit) install_monit;;
        docker) install_docker;;
        zsh) install_oh_my_zsh;;
        mongodb) install_mongodb;;
        *) echo "未识别的参数: $1";;
    esac
fi
