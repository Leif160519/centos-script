#!/bin/bash
echo -e '\033[1;32m 部署oh-my-zsh \033[0m'
echo -e '\033[1;32m 安装zsh包 \033[0m'
yum -y install zsh
echo -e '\033[1;32m 切换默认shell为zsh \033[0m'
chsh -s /bin/zsh
echo -e '\033[1;32m 安装oh-my-zsh \033[0m'
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
#sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
echo -e '\033[1;32m 重启生效 \033[0m'
exit
