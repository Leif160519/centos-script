#!/bin/bash
echo -e '\033[1;32m 安装Docker&docker-compose \033[0m'
echo -e '\033[1;32m 1.安装Docker \033[0m'
echo -e '\033[1;32m 添加Docker源 \033[0m'
wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo
echo -e '\033[1;32m 安装docker-ce \033[0m'
yum install -y docker-ce-18.06.1.ce-3.el7
echo -e '\033[1;32m 设置Docker开机自启动 \033[0m'
systemctl enable docker
echo -e '\033[1;32m 启动docker \033[0m'
systemctl start docker
echo -e '\033[1;32m 查看docker版本 \033[0m'
docker --version
echo -e '\033[1;32m 给docker换阿里源 \033[0m'
cat <<EOF > /etc/docker/daemon.json
{
"registry-mirrors": ["https://b9pmyelo.mirror.aliyuncs.com"]
}
EOF
# 若想更换docker网卡的网段，则json内容如下
#{
#"default-address-pools": [
#       {
#               "base": "198.18.0.0/16",
#               "size": 24
#               }
#       ],
#  "registry-mirrors": ["https://b9pmyelo.mirror.aliyuncs.com"]
#}
echo -e '\033[1;32m 重启docker服务 \033[0m'
systemctl restart docker

echo -e '\033[1;32m 查看docker信息 \033[0m'
docker info

echo -e '\033[1;32m 2.安装docker-compose \033[0m'
echo -e '\033[1;32m 下载docker-compose \033[0m'
yum -y install docker-compose
#curl -L https://github.com/docker/compose/releases/download/1.16.0-rc2/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
#echo -e '\033[1;32m 添加执行权限 \033[0m'
#chmod +x /usr/local/bin/docker-compose
echo -e '\033[1;32m 查看docker-compose版本 \033[0m'
docker-compose version

echo -e '\033[1;32m 3.安装ctop工具 \033[0m'
wget -c https://github.com/bcicen/ctop/releases/download/v0.7.2/ctop-0.7.2-linux-amd64 -O /usr/local/bin/ctop
chmod +x /usr/local/bin/ctop
echo -e "\033[1;32m 清除yum安装包 \033[0m"
yum -y clean all
exit
