#!/usr/bin/env bash 
# curl -Ss 'https://raw.githubusercontent.com/firehol/netdata-demo-site/master/install-required-packages.sh' >/tmp/kickstart.sh && bash /tmp/kickstart.sh -i netdata-all
# # download it - the directory 'netdata' will be created
# git clone https://github.com/netdata/netdata.git --depth=1
# cd netdata

# # run script with root privileges to build, install, start netdata
# ./netdata-installer.sh

bash <(curl -Ss https://my-netdata.io/kickstart.sh)