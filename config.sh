#!/bin/bash

help_info(){
cat <<EOF
用法: bash $0 选项 [选项...]
示例:
        bash $0 all
        bash $0 help
        bash $0 sudo
选项:
        help       打印这个帮助信息
        all        配置所有
        repo       换源(阿里源)
        ssh        配置ssh服务
        sudo       配置sudo权限
        selinux    关闭selinux
        firewalld  关闭防火墙
        swap       关闭swap
        pip        配置pip源
        shutdown   配置关机时间
        cron       打开cron日志
        clock      配置时区
        editor     配置默认文本编辑器
        git        配置git
        email      配置默认邮件系统
EOF
        exit 1
}

judge_user(){ # {{{
    if [[ ! $(whoami) == "root" ]];then
        echo "请使用root用户执行此脚本！"
        exit 1
    fi
} # }}}

config_repository(){ # {{{
    if [[ -f /etc/redhat-release ]];then
        centos_major_version=$(awk '{print $4}' /etc/redhat-release | awk -F. '{print $1}')
        wget -c http://mirrors.aliyun.com/repo/Centos-"${centos_major_version}".repo -O /etc/yum.repos.d/CentOS-Base.repo
        yum makecache
        yum -y update
        yum clean all
    else
        echo "非centos或redhat系统"
    fi
} # }}}

config_ssh(){ # {{{
    judge_user
    sed -i '/^\(#\|\)UseDNS/cUseDNS no' /etc/ssh/sshd_config
    sed -i '/^\(#\|\)GSSAPIAuthentication/cGSSAPIAuthentication no' /etc/ssh/sshd_config
    sed -i '/^\(#\|\)ClientAliveInterval/cClientAliveInterval 60' /etc/ssh/sshd_config
    sed -i '/^\(#\|\)ClientAliveCountMax/cClientAliveCountMax 60' /etc/ssh/sshd_config
    sed -i '/^\(#\|\)PermitRootLogin/cPermitRootLogin without-password' /etc/ssh/sshd_config
    sed -i '/^\(#\|\)PasswordAuthentication/cPasswordAuthentication yes' /etc/ssh/sshd_config
    sed -i '/^\(#\|\)PermitEmptyPasswords/cPermitEmptyPasswords no' /etc/ssh/sshd_config
    sed -i '/^\(#\|\)   StrictHostKeyChecking/c    StrictHostKeyChecking no' /etc/ssh/ssh_config
    sed -i 's/\tGSSAPIAuthentication no/\        GSSAPIAuthentication yes/g' /etc/ssh/ssh_config
    [[ $(grep "ServerAliveInterval 20" /etc/ssh/ssh_config | wc -l) == 0 ]] && sed -i '$a\        ServerAliveInterval 20' /etc/ssh/ssh_config
    [[ $(grep "ServerAliveCountMax 999" /etc/ssh/ssh_config | wc -l) == 0 ]] && sed -i '$a\        ServerAliveCountMax 999' /etc/ssh/ssh_config
    systemctl reload sshd
    echo "configure ssh done."
} # }}}

config_sudo_privileges(){ # {{{
    judge_user
    sed -i '/^%wheel/c%wheel ALL=(ALL) NOPASSWD: ALL' /etc/sudoers
    if [[ ! -f /var/log/sudo.log ]];then
        touch /var/log/sudo.log
    fi
    [[ $(grep "local2.debug" /etc/rsyslog.conf | wc -l) == 0 ]] && sed -i '$alocal2.debug /var/log/sudo.log' /etc/rsyslog.conf
    [[ $(grep "Defaults logfile" /etc/sudoers | wc -l) == 0 ]] && sed -i '$aDefaults logfile=/var/log/sudo.log' /etc/sudoers
    [[ $(grep "Defaults loglinelen" /etc/sudoers | wc -l) == 0 ]] && sed -i '$aDefaults loglinelen=0' /etc/sudoers
    [[ $(grep "Defaults \!syslog" /etc/sudoers | wc -l ) == 0 ]] && sed -i '$aDefaults !syslog' /etc/sudoers
    systemctl restart rsyslog
    echo "config sudo done."
} # }}}

disable_selinux(){ # {{{
    judge_user
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
    echo "disable selinux done."
} # }}}

disable_firewalld(){ # {{{
    judge_user
    systemctl stop firewalld
    systemctl disable firewalld
    echo "disable firewalld done."
} # }}}

disable_swap(){ # {{{
    judge_user
    swapoff -a
    sed -i '/swap/d' /etc/fstab
    echo "disable swap done."
} # }}}

config_pip(){ # {{{
    judge_user
    if [[ ! -d /root/.pip ]];then
        mkdir /root/.pip
    fi

cat <<EOF > /root/.pip/pip.conf
[global]
index-url = http://mirrors.aliyun.com/pypi/simple/
[install]
trusted-host=mirrors.aliyun.com
EOF
    echo "config pip done."
} # }}}

config_shutdown_wait_time(){ # {{{
    judge_user
    sed -i '/^#DefaultTimeoutStartSec/cDefaultTimeoutStartSec=10s' /etc/systemd/system.conf
    sed -i '/^#DefaultTimeoutStopSec/cDefaultTimeoutStopSec=10s' /etc/systemd/system.conf
    echo "config shutdown wait time done."
} # }}}

open_cron_log(){ # {{{
    judge_user
    sed -i 's/#cron/cron/g' /etc/rsyslog.conf
    systemctl restart rsyslog
    echo "open cron log done."
} # }}}

config_clock(){ # {{{
    judge_user
    timedatectl set-local-rtc 0
    timedatectl set-timezone Asia/Shanghai
    echo "config clock done."
} # }}}

config_default_editor(){ # {{{
    judge_user
    echo 'SELECTED_EDITOR="/usr/bin/vim.basic"' > /root/.selected_editor
    echo "config default editor done."
} # }}}

config_git(){ # {{{
    judge_user
    if [[ -f /usr/bin/git ]];then
        git config --global core.editor vim
        git config --global core.quotepath false
    fi
    echo "config git done."
} # }}}

config_email(){ # {{{
    judge_user
    find /var/mail/* -path "*/var/mail/*" -type f -delete
    echo "config email done."
} # }}}

reboot_server(){ # {{{
    read -rp "Whether to restart ?(y or n):" choice
    case $choice in
        "y") echo -e '\033[1;32m You choose to reboot \033[0m' && reboot ;;
        "n") echo "You chose not to reboot" ;;
        *) echo "Input error please try again." && reboot_server ;;
    esac
} # }}}

all(){ # {{{
    config_repository
    config_ssh
    config_sudo_privileges
    disable_selinux
    disable_firewalld
    disable_swap
    config_pip
    config_shutdown_wait_time
    open_cron_log
    config_clock
    config_default_editor
    config_git
    config_email
    reboot_server
} # }}}

if (($#==0))
then
    help_info
else
    case $1 in
        help) help_info;;
        all) all;;
        repo) config_repository;;
        ssh) config_ssh;;
        sudo) config_sudo_privileges;;
        selinux) disable_selinux;;
        firewalld) disable_firewalld;;
        swap) disable_swap;;
        pip) config_pip;;
        shutdown) config_shutdown_wait_time;;
        cron) config_shutdown_wait_time;;
        clock) config_clock;;
        editor) config_default_editor;;
        git) config_git;;
        email) config_email;;
        *) echo "未识别的参数: $1";;
    esac
fi
