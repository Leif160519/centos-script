#!/bin/bash
#--------------------------------脚本变量设置--------------------------------
#项目根目录
HOME_DIR="/home"
#jenkins ssh传输目录
JENKINS_DIR="/root"
#项目目录:/mect
PROJECT_DIR="mect"
#日志目录:/log
LOG_DIR="log"
#备份目录：/backup
BACKUP_DIR="mect-backup"
#资源目录：/resource
RESOURCE_DIR="resource"
#脚本目录：/script
SCRIPT_DIR="script"
#配置文件目录：/config
CONFIG_DIR="config"
#项目中shell脚本位置
BASH_DIR="script"
#获取本机ip地址
IP_ADDRESS=$(ip a | grep inet | grep -v inet6 | grep -v 127 | sed 's/^[ \t]*//g' | cut -d ' ' -f2 | grep -v 172 | cut -d '/' -f1 | head -1)
#服务名数组
SERVICE_NAME_ARRAY=($(head -1 /root/service-config.txt))
#服务映射端口号数组
SERVICE_PORT_ARRAY=($(tail -1 /root/service-config.txt))
#服务个数
SERVICE_NUM=${#SERVICE_PORT_ARRAY[@]}
#服务版本号
SERVER_VERSION="0.0.1-SNAPSHOT.jar"
#脚本运行环境(test代表测试环境，dev代表开发环境，不跟参数默认测试环境)
SCRIPT_ENV=${1:-"test"}


cat ${HOME_DIR}/${PROJECT_DIR}/${SCRIPT_DIR}/banner.txt
echo "********************** 当前本机IP地址为：${IP_ADDRESS};部署环境为：${SCRIPT_ENV} **********************"

cd ${HOME_DIR}/${BACKUP_DIR}
# 获取最后一个备份文件夹(最新备份文件夹)
backup_dir=$(ls | tail -1)
echo "--------------------------------最新备份的日期文件夹为:${backup_dir}--------------------------------" #输出最新创建的备份文件夹
echo "当前服务器需回滚的服务有${SERVICE_NUM}个，分别是："
for ((i=1;i<${SERVICE_NUM}+1;i++))
{
  echo ${i}.${SERVICE_NAME_ARRAY[i-1]}:${SERVICE_PORT_ARRAY[i-1]};
  echo "1.暂停当前Docker容器:mect-${SERVICE_NAME_ARRAY[i-1]}"
  docker stop mect-${SERVICE_NAME_ARRAY[i-1]}
  echo "2.删除待替换的jar包:${HOME_DIR}/${PROJECT_DIR}/${RESOURCE_DIR}/${SERVICE_NAME_ARRAY[i-1]}-${SERVER_VERSION}"
  rm -f ${HOME_DIR}/${PROJECT_DIR}/${RESOURCE_DIR}/${SERVICE_NAME_ARRAY[i-1]}-${SERVER_VERSION}
  echo "3.开始复制jar包副本到指定文件夹中:${backup_dir}/${PROJECT_DIR}/${RESOURCE_DIR}/${SERVICE_NAME_ARRAY[i-1]}-${SERVER_VERSION} ---> ${HOME_DIR}/${PROJECT_DIR}/${RESOURCE_DIR}"
  cp  ${backup_dir}/${PROJECT_DIR}/${RESOURCE_DIR}/${SERVICE_NAME_ARRAY[i-1]}-${SERVER_VERSION}  ${HOME_DIR}/${PROJECT_DIR}/${RESOURCE_DIR}
  echo "4.重新启动Docker容器:mect-${SERVICE_NAME_ARRAY[i-1]}"
  docker start mect-${SERVICE_NAME_ARRAY[i-1]}
}
echo "回滚完毕"
echo "查看所有Docker容器状态"
docker ps
exit