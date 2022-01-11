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

configure_ssh(){ # {{{
    judge_user
    sed -i 's/^(#|)UseDNS/UseDNS no/g' /etc/ssh/sshd_config
    sed -i 's/^(#|)GSSAPIAuthentication/GSSAPIAuthentication no/g' /etc/ssh/sshd_config
    sed -i 's/^(#|)ClientAliveInterval/ClientAliveInterval 60/g' /etc/ssh/sshd_config
    sed -i 's/^(#|)ClientAliveCountMax/ClientAliveCountMax 60/g' /etc/ssh/sshd_config
    sed -i 's/^(#|)PermitRootLogin/PermitRootLogin without-password/g' /etc/ssh/sshd_config
    sed -i 's/^(#|)PasswordAuthentication/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    sed -i 's/^(#|)PermitEmptyPasswords/PermitEmptyPasswords no/g' /etc/ssh/sshd_config
    sed -i 's/^(#|)   StrictHostKeyChecking/    StrictHostKeyChecking no/g' /etc/ssh/ssh_config
    sed -i '$a    ServerAliveInterval 20' /etc/ssh/ssh_config
    sed -i '$a    ServerAliveCountMax 999' /etc/ssh/ssh_config
    sed -i '$a    GSSAPIAuthentication yes' /etc/ssh/ssh_config
    sed -i '$a    GSSAPIAuthentication no' /etc/ssh/ssh_config
    systemctl reload sshd
} # }}}

configure_sudo_privileges(){ # {{{
    judge_user
    sed -i 's/^(|)%wheel/%wheel ALL=(ALL) NOPASSWD: ALL/g' /etc/sudoers
    if [[ ! -f /var/log/sudo.log ]];then
        touch /var/log/sudo.log
    fi
    sed -i '$alocal2.debug /var/log/sudo.log' /etc/rsyslog.conf
    sed -i '$aDefaults logfile=/var/log/sudo.log' /etc/sudoers
    sed -i '$aDefaults loglinelen=0' /etc/sudoers
    sed -i '$aDefaults !syslog' /etc/sudoers
    systemctl restart rsyslog
} # }}}

disable_selinux(){ # {{{
    judge_user
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
} # }}}

disable_firewalld(){ # {{{
    judge_user
    systemctl stop firewalld
    systemctl disable firewalld
} # }}}

disable_swap(){ # {{{
    judge_user
    swapoff -a
    sed -i '/swap/d' /etc/fstab
} # }}}

configure_pip(){ # {{{
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
} # }}}

configure_shutdown_wait_time(){ # {{{
    judge_user
    sed -i 's/^(#|)DefaultTimeoutStartSec/DefaultTimeoutStartSec=10s/g' /etc/systemd/system.conf
    sed -i 's/^(#|)DefaultTimeoutStopSec/DefaultTimeoutStopSec=10s/g' /etc/systemd/system.conf
} # }}}

open_cron_log(){ # {{{
    judge_user
    sed -i 's/#cron/cron/g' /etc/rsyslog.conf
    systemctl restart rsyslog
} # }}}

configure_clock(){ # {{{
    judge_user
    timedatectl set-local-rtc 0
    timedatectl set-timezone Asia/Shanghai
} # }}}

configure_default_editor(){ # {{{
    judge_user
    echo 'SELECTED_EDITOR="/usr/bin/vim.basic"' > /root/.selected_editor
} # }}}

configure_git(){ # {{{
    judge_user
    if [[ -f /usr/bin/git ]];then
        git config --global core.editor vim
        git config --global core.quotepath false
    fi
} # }}}

configure_email(){ # {{{
    judge_user
    find /var/mail/* -path "*/var/mail/*" -type f -delete
} # }}}

reboot_server(){ # {{{
    read -rp "是否重启？(y or n):" choice
    case $choice in
        "y") echo -e '\033[1;32m 你选择了重启 \033[0m' && reboot ;;
        "n") echo "你选择了不重启" ;;
        *) echo "输入有误，请重新输入!" && reboot_server ;;
    esac
} # }}}

all(){ # {{{
    configure_ssh
    configure_sudo_privileges
    disable_selinux
    disable_firewalld
    disable_swap
    configure_pip
    configure_shutdown_wait_time
    open_cron_log
    configure_clock
    configure_default_editor
    configure_git
    configure_email
    reboot_server
} # }}}

if (($#==0))
then
    help_info
else
    case $1 in
        help) help_info;;
        all) all;;
        ssh) configure_ssh;;
        sudo) configure_sudo_privileges;;
        selinux) disable_selinux;;
        firewalld) disable_firewalld;;
        swap) disable_swap;;
        pip) configure_pip;;
        shutdown) configure_shutdown_wait_time;;
        cron) configure_shutdown_wait_time;;
        clock) configure_clock;;
        editor) configure_default_editor;;
        git) configure_git;;
        email) configure_email;;
        *) echo "未识别的参数: $1"
    esac
fi
