#!/bin/bash -
#########################################################################################
# startAll.sh
# 启动所有进程
# version:3.0
# update:20180502
#########################################################################################
[ /root/eGW/Config.sh/parameters.conf ] && source /root/eGW/Config.sh/parameters.conf
CUR_DIR=/root/eGW/Config.sh

#启动redis nginx ipsec
source $CUR_DIR/init.sh && init
#sleep 2

#配置iptables
source $CUR_DIR/iptables.sh && config_iptables

#keepalived
source $CUR_DIR/keepalived.sh && keepalived

#启动各进程
source $CUR_DIR/process.sh && process
sleep 1

#配置eGW
source $CUR_DIR/egw.sh && egw 

#启动watchdog
function watchdog() {
    while :
    do
        source $CUR_DIR/watchdog.sh
        watchdog_all && wait
        sleep 1
    done
}
watchdog &

