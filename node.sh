#!/usr/bin/env bash 
#1.下载Linux版本二进制包
wget https://npm.taobao.org/mirrors/node/v12.11.1/node-v12.11.1-linux-x64.tar.xz
#2.解压
tar -xvf node-v12.11.1-linux-x64.tar.xz
#3.重命名并复制到指定目录中
mv node-v12.11.1-linux-x64 nodejs
cp -r nodejs /usr/local/src
#4.建立软连接，变为全局
ln -s /usr/local/src/nodejs/bin/npm /usr/local/bin/ 
ln -s /usr/local/src/nodejs/bin/node /usr/local/bin/
#5.查看版本
node -v
npm -v
#6.换源（淘宝源）
npm config set registry https://registry.npm.taobao.org
exit
