#!/bin/bash
echo -e '\033[1;32m 安装初始环境 \033[0m'
echo -e '\033[1;32m 1.安装常用软件或工具包 \033[0m'

for software_name in yum-utils epel-release bind-utils \
    wget nano vim emacs zip unzip git java expect htop iotop iftop nethogs nagios ShellCheck\
    mrtg npm pv telnet net-tools tree tmux iperf lsof dpkg hdparm smartmontools \
    psmisc fping tcpdump nmap fio nc strace perf build-utils dstat lynx w3m lrzsz \
    monit ntp bash-completion ctop ansible dosfstools uuid make colordiff subnetcalc groovy \
    python python3 python3-pip dos2unix nload curl cifs-utils xfsprogs exfat-utils rename \
    curlftpfs tig jq mosh axel cloc ccache neovim mc powerman ncdu glances pcp multitail \
    figlet wdiff ;
do
    echo -e "\033[1;32m 安装${software_name} \033[0m"
    yum -y install "${software_name}"
done

echo -e '\033[1;32m 2.启动相关服务 \033[0m'
for software_name in sysstat monit ntpd;
do
    systemctl start "${software_name}"
    systemctl enable "${software_name}"
done

echo -e '\033[1;32m 3.安装screenfetch \033[0m'
echo -e '\033[1;32m 从github上下载screenfetch \033[0m'
git clone git://github.com/KittyKatt/screenFetch.git screenfetch
echo -e '\033[1;32m 复制文件到/usr/bin/目录 \033[0m'
cp screenfetch/screenfetch-dev /usr/bin/screenfetch
echo -e '\033[1;32m 给screenfetch赋予可执行权限 \033[0m'
chmod +x /usr/bin/screenfetch
echo -e '\033[1;32m 查看计算机软硬件信息 \033[0m'
screenfetch


# curl -o screenfetch.zip https://codeload.github.com/KittyKatt/screenFetch/zip/master
# unzip screenfetch.zip
# cp screenFetch-master/screenfetch-dev /usr/local/bin/screenfetch
# chmod +x /usr/local/bin/screenfetch
# screenfetch

echo -e '\033[1;32m 4.安装neofetch \033[0m'
curl -o /etc/yum.repos.d/konimex-neofetch-epel-7.repo https://copr.fedorainfracloud.org/coprs/konimex/neofetch/repo/epel-7/konimex-neofetch-epel-7.repo
yum -y install neofetch
neofetch


echo -e '\033[1;32m 5.安装ccat \033[0m'
wget -c https://github.com/jingweno/ccat/releases/download/v1.1.0/linux-amd64-1.1.0.tar.gz -O /tmp/linux-amd64-1.1.0.tar.gz
tar -xzvf /tmp/linux-amd64-1.1.0.tar.gz
cp /tmp/linux-amd64-1.1.0/ccat /usr/local/bin
sed -i '$a/alias cat=ccat' /root/.bashrc

echo -e '\033[1;32m系统初始化配置完成！\033[0m'
echo -e "\033[1;32m 清除yum安装包 \033[0m"
yum -y clean all

exit
