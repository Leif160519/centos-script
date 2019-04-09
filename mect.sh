
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
#项目中所有jar包的位置
JAR_DIR="jar/**/target"
#项目中shell脚本位置
BASH_DIR="script"
#获取本机ip地址
IP_ADDRESS=$(ip a | grep inet | grep -v inet6 | grep -v 127 | sed 's/^[ \t]*//g' | cut -d ' ' -f2 | grep -v 172 | cut -d '/' -f1 | head -1)
#临时文件夹目录
TMP_DIR="tmp"
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

cat ${JENKINS_DIR}/${TMP_DIR}/${SCRIPT_DIR}/banner.txt
echo "********************** 当前本机IP地址为：${IP_ADDRESS};部署环境为：${SCRIPT_ENV} **********************"
#--------------------------------1.备份项目旧版本--------------------------------
echo "--------------------------------1.开始备份项目旧版本--------------------------------"
BACKUP_DATE="$(date "+%Y-%m-%dT%H:%M:%S")"
echo "①.根据日期新建备份文件夹${HOME_DIR}/${BACKUP_DIR}/${BACKUP_DATE}"
mkdir -p ${HOME_DIR}/${BACKUP_DIR}/"${BACKUP_DATE}"
echo "②.开始备份文件"
#检测mect文件夹是否存在，存在则备份，否则不作任何操作
if [ -d ${HOME_DIR}/${PROJECT_DIR} ];then
  #将/home/mect整个目录除资源目录复制到/home/backup/${BACKUP_DATE}(当前时间)目录下
  echo "复制: ${HOME_DIR}/${PROJECT_DIR} 到 ${HOME_DIR}/${BACKUP_DIR}/${BACKUP_DATE} "
  cp -r ${HOME_DIR}/${PROJECT_DIR} ${HOME_DIR}/${BACKUP_DIR}/${BACKUP_DATE}


  for ((i=0;i<${SERVICE_NUM};i++))
  {
      echo "删除：服务 ${SERVICE_NAME_ARRAY[i]} --- jar包 ${HOME_DIR}/${PROJECT_DIR}/${RESOURCE_DIR}/${SERVICE_NAME_ARRAY[i]}-${SERVER_VERSION}"
      rm -f ${HOME_DIR}/${PROJECT_DIR}/${RESOURCE_DIR}/${SERVICE_NAME_ARRAY[i]}-${SERVER_VERSION}

      echo "删除：服务 ${SERVICE_NAME_ARRAY[i]} --- 日志目录 ${HOME_DIR}/${PROJECT_DIR}/${LOG_DIR}/${SERVICE_NAME_ARRAY[i]}"
      rm -rf ${HOME_DIR}/${PROJECT_DIR}/${LOG_DIR}/${SERVICE_NAME_ARRAY[i]}
  }

  #复制/root/service-config.txt配置文件到/home/mect/config目录下
  cp /root/service-config.txt ${HOME_DIR}/${BACKUP_DIR}/${BACKUP_DATE}/${PROJECT_DIR}/${CONFIG_DIR}
  echo "--------------------------------1.旧项目备份完成--------------------------------"
  tree ${HOME_DIR}/${BACKUP_DIR}/${BACKUP_DATE}
else
    echo "③.目录不存在，无需备份"
fi

#--------------------------------2.新建目录--------------------------------
echo "--------------------------------2.开始创建Jenkins自动部署目录--------------------------------"
echo "项目目录结构为："
echo "/root/"
echo "└── tmp"
echo "/home/"
echo "├── mect-backup"
echo "└── mect"
echo "   ├── config"
echo "   ├── log"
echo "   ├── resource"
echo "   └── script"

#判断配置文件是否为空，为空则无需进行任何操作
if [ ${SERVICE_NUM} == 0 ];then
    echo "检测到配置文件中无需要更新的服务,查看所有服务容器状态："
    docker ps
else
    echo "①.创建目录：${HOME_DIR}/${PROJECT_DIR}/{${LOG_DIR},${RESOURCE_DIR},${SCRIPT_DIR},${CONFIG_DIR}}"
    mkdir -p ${HOME_DIR}/${PROJECT_DIR}/{${LOG_DIR},${RESOURCE_DIR},${SCRIPT_DIR},${CONFIG_DIR}}

    echo "②.清空：${HOME_DIR}/${PROJECT_DIR}/${SCRIPT_DIR}目录下的所有文件"
    rm -rf ${HOME_DIR}/${PROJECT_DIR}/${SCRIPT_DIR}/*

    echo "③.移动：${JENKINS_DIR}/${TMP_DIR}/${SCRIPT_DIR} 到 ${HOME_DIR}/${PROJECT_DIR}"
    mv ${JENKINS_DIR}/${TMP_DIR}/${SCRIPT_DIR}  ${HOME_DIR}/${PROJECT_DIR}

    #根据配置文件中的服务列表将所需jar包移动到/home/mect/resource下
    echo "根据配置文件中的服务列表将所需jar包移动到${HOME_DIR}/${PROJECT_DIR}/${SCRIPT_DIR}/${RESOURCE_DIR}下"
    for ((i=0;i<${SERVICE_NUM};i++))
    {
        echo "移动：${JENKINS_DIR}/${TMP_DIR}/${RESOURCE_DIR}/${SERVICE_NAME_ARRAY[i]}-${SERVER_VERSION} 到 ${HOME_DIR}/${PROJECT_DIR}/${RESOURCE_DIR}"
        mv ${JENKINS_DIR}/${TMP_DIR}/${RESOURCE_DIR}/${SERVICE_NAME_ARRAY[i]}-${SERVER_VERSION}  ${HOME_DIR}/${PROJECT_DIR}/${RESOURCE_DIR}
    }

    echo "--------------------------------2.目录构建完成--------------------------------"
    tree ${HOME_DIR}/${PROJECT_DIR}


    #--------------------------------3.生成docker-compose.yml--------------------------------
    echo "--------------------------------3.生成docker-compose.yml配置文件--------------------------------"
    echo "①.获取java8镜像"
    docker pull leif0207/medcaptain-java:8
    echo "②.执行脚本，生成docker-compose.yml配置文件"
    bash ${HOME_DIR}/${PROJECT_DIR}/${SCRIPT_DIR}/docker-compose.sh ${SCRIPT_ENV}
    echo "--------------------------------3.配置文件生成成功--------------------------------"

    #--------------------------------4.构建镜像并启动容器--------------------------------
    echo "--------------------------------4.构建镜像并启动容器--------------------------------"
    cd ${HOME_DIR}/${PROJECT_DIR}/${CONFIG_DIR}
    docker-compose up -d
    echo "--------------------------------4.构建镜像并启动容器完成--------------------------------"
    docker ps
fi
echo "清除临时目录${JENKINS_DIR}/${TMP_DIR}"
rm -rf ${JENKINS_DIR}/${TMP_DIR}
echo "临时目录清除完毕"
exit