#!/bin/bash
#获取本机ip地址
IP_ADDRESS=$(ip a | grep inet | grep -v inet6 | grep -v 127 | sed 's/^[ \t]*//g' | cut -d ' ' -f2 | grep -v 172 | cut -d '/' -f1)
#服务名
# SERVICE_NAME=${1:-"eureka-server admin-server"}
#服务名数组
SERVICE_NAME_ARRAY=($(head -1 service-config.txt))
#服务映射端口号
# SERVICE_PORT=${2:-"8761 5000"}
#服务映射端口号数组
SERVICE_PORT_ARRAY=($(tail -1 service-config.txt))
#服务个数
SERVICE_NUM=${#SERVICE_PORT_ARRAY[@]}
#服务版本号
SERVER_VERSION="0.0.1-SNAPSHOT.jar"

echo "当前服务器部署服务有${SERVICE_NUM}个，分别是："
echo "服务名:端口号"
for ((i=1;i<SERVICE_NUM+1;i++))
{
  echo ${i}.${SERVICE_NAME_ARRAY[i-1]}:${SERVICE_PORT_ARRAY[i-1]};
}

if [ ! -d /data/ ];then
  echo "检测到/data/路径不存在,新建之"
  mkdir /data/
fi
cd /data/
if [ -f docker-compose.yml ];then
  echo "检测到docker-compose.yml已存在，删除之"
  rm -f docker-compose.yml
fi

# vi docker-compose.yml
echo "开始动态生成docker-compose.yml"
echo "version: '0.01'" >> docker-compose.yml
echo "services:" >> docker-compose.yml
for ((i=0;i<SERVICE_NUM;i++))
{
  echo "  ${SERVICE_NAME_ARRAY[i]}:" >> docker-compose.yml
  echo "    image: leif0207/medcaptain-java:8" >> docker-compose.yml
  echo "    restart: always" >> docker-compose.yml
  echo "    container_name: mect-${SERVICE_NAME_ARRAY[i]}" >> docker-compose.yml
  echo "    ports:" >> docker-compose.yml
  echo "    - ${SERVICE_PORT_ARRAY[i]}:${SERVICE_PORT_ARRAY[i]}" >> docker-compose.yml
  echo "    volumes:" >> docker-compose.yml
  echo "    - /data:/data:rw" >> docker-compose.yml
  echo "    - /logs:/logs:rw" >> docker-compose.yml
  echo "    - /tmp" >> docker-compose.yml
  echo "    command: java -Djava.security.egd=file:/dev/./urandom -jar /data/${SERVICE_NAME_ARRAY[i]}-${SERVER_VERSION} --spring.profiles.active=test --eureka.instance.ip-address=${IP_ADDRESS}" >> docker-compose.yml
  echo -e ""
}
for file in $*;do
  echo $file >> docker-compose.yml
done
echo "docker-compose.yml写入完成"
exit
