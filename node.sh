#!/bin/bash
echo -e '\033[1;32m node \033[0m'
echo -e '\033[1;32m 1.下载Linux版本二进制包 \033[0m'
wget -c https://npm.taobao.org/mirrors/node/v12.11.1/node-v12.11.1-linux-x64.tar.xz
echo -e '\033[1;32m 2.解压 \033[0m'
tar -xvf node-v12.11.1-linux-x64.tar.xz
echo -e '\033[1;32m 3.重命名并复制到指定目录中 \033[0m'
mv node-v12.11.1-linux-x64 nodejs
cp -r nodejs /usr/local/src
echo -e '\033[1;32m 4.建立软连接，变为全局 \033[0m'
ln -s /usr/local/src/nodejs/bin/npm /usr/local/bin/
ln -s /usr/local/src/nodejs/bin/node /usr/local/bin/
echo -e '\033[1;32m 5.查看版本 \033[0m'
node -v
npm -v
echo -e '\033[1;32m 6.换源（淘宝源） \033[0m'
npm config set registry https://registry.npm.taobao.org
exit
