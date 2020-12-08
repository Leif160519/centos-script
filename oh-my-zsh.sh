#!/bin/bash
echo -e '\033[1;32m 部署oh-my-zsh \033[0m'
echo -e '\033[1;32m 安装zsh包 \033[0m'
yum -y install zsh
yum -y install autojump
echo -e '\033[1;32m 切换默认shell为zsh \033[0m'
chsh -s /bin/zsh
echo -e '\033[1;32m 安装oh-my-zsh \033[0m'
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
#sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
plugins_path="${ZSH_CUSTOM:-~/.oh-my-zsh/custom}"/plugins
echo -e '\033[1;32m 安装zsh-syntax-highlighting:模仿fish命令行高亮的插件  \033[0m'
if [[ -d ${plugins_path}//zsh-syntax-highlighting ]];then
    echo "" > /dev/null
else
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${plugins_path}"//zsh-syntax-highlighting
fi

echo -e '\033[1;32m 安装zsh-autosuggestions:根据命令历史记录自动推荐和提示的插件  \033[0m'
if [[ -d ${plugins_path}//zsh-autosuggestions ]];then
    echo "" > /dev/null
else
    git clone https://github.com/zsh-users/zsh-autosuggestions "${plugins_path}"//zsh-autosuggestions
fi

echo -e '\033[1;32m 安装zsh-completions:自动命令补全，类似bash-completions功能的插件 \033[0m'
if [[ -d ${plugins_path}//zsh-completions ]];then
    echo "" > /dev/null
else
    git clone https://github.com/zsh-users/zsh-completions "${plugins_path}"//zsh-completions
fi

echo -e '\033[1;32m 安装history-substring-search:按住向上箭头可以搜索出现过该关键字的历史命令插件 \033[0m'
if [[ -d ${plugins_path}//zsh-history-substring-search ]];then
    echo "" > /dev/null
else
    git clone https://github.com/zsh-users/zsh-history-substring-search "${plugins_path}"//zsh-history-substring-search
fi

echo -e '\033[1;32m 安装history-search-multi-word:ctrl+r搜索历史记录插件 \033[0m'
if [[ -d ${plugins_path}//history-search-multi-word ]];then
    echo "" > /dev/null
else
    git clone https://github.com/zdharma/history-search-multi-word "${plugins_path}"//history-search-multi-word
fi

echo -e '\033[1;32m 修改zsh主题为随机 \033[0m'
sed -i "/^ZSH_THEME=/cZSH_THEME=\"random\"" ~/.zshrc

echo -e '\033[1;32m 配置zsh加载的插件 \033[0m'
sed -ie "/^plugins=(git)/d" ~/.zshrc
sed -ie "/^source/d" ~/.zshrc
cat <<EOF >> ~/.zshrc
plugins=(
        git
        zsh-autosuggestions
        zsh-syntax-highlighting
        zsh-completions
        z
        history-substring-search
        command-not-found
        colored-man-pages
        extract
        history-search-multi-word
)
source $ZSH/oh-my-zsh.sh
EOF

echo -e '\033[1;32m 重启终端生效 \033[0m'
exit
