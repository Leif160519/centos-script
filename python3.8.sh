#!/bin/bash
echo -e '\033[1;32m 编译安装Python3.7 \033[0m'
echo -e '\033[1;32m 1.开始安装依赖包，centos里面是-devel，如果在ubuntu下安装则要改成-dev \033[0m'
yum -y groupinstall "Development tools"
yum -y install zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel db4-devel libpcap-devel xz-devel libffi-devel
echo -e '\033[1;32m 2.获取python3.8.3的安装包 \033[0m'
wget -c https://www.python.org/ftp/python/3.8.3/Python-3.8.3.tar.xz
echo -e '\033[1;32m 3.解压 \033[0m'
tar -xvJf  Python-3.8.3.tar.xz
echo -e '\033[1;32m 4.配置python3的安装目录 \033[0m'
cd Python-3.8.3 || exit
./configure --prefix=/usr/local/python3
echo -e '\033[1;32m 5.编译 \033[0m'
make
echo -e '\033[1;32m 6.安装 \033[0m'
make install
echo -e '\033[1;32m 7.创建软链接 \033[0m'
ln -s /usr/local/python3/bin/python3 /usr/bin/python3
ln -s /usr/local/python3/bin/pip3 /usr/bin/pip3
echo -e '\033[1;32m 8.查看pip3版本 \033[0m'
pip3 -V
echo -e '\033[1;32m 9.升级pip3 \033[0m'
pip3 install upgrade pip
echo -e '\033[1;32m 10.查看升级后的pip3版本 \033[0m'
pip3 -V
echo -e '\033[1;32m 11.查看python版本 \033[0m'
python3
echo -e "\033[1;32m python3安装完毕！ \033[0m"
echo -e "\033[1;32m 清除yum安装包 \033[0m"
yum -y clean all

echo -e '\033[1;32m 安装pip \033[0m'
yum -y install epel-release
yum -y install python-pip
echo -e '\033[1;32m 给pip换源 \033[0m'
mkdir /root/.pip
cat <<EOF >/root/.pip/pip.conf
[global]
index-url = http://mirrors.aliyun.com/pypi/simple/
[install]
trusted-host=mirrors.aliyun.com
EOF
echo -e '\033[1;32m 升级pip \033[0m'
pip install --upgrade pip
echo -e '\033[1;32m 查看pip版本 \033[0m'
pip -V

exit
