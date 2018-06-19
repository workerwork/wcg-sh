#!/bin/bash -
#########################################################################################
# startAll.sh
# version:3.2
# update:20180619
#########################################################################################
#[ /root/eGW/Config.sh/parameters.conf ] && source /root/eGW/Config.sh/parameters.conf
CUR_DIR=/root/eGW/Config.sh

#init the redis nginx ipsec
source $CUR_DIR/init.sh && init
#sleep 2

#configure iptables
source $CUR_DIR/iptables.sh && config_iptables

#configure keepalived
source $CUR_DIR/keepalived.sh && keepalived

#start process
source $CUR_DIR/process.sh && process
sleep 1

#configure eGW
source $CUR_DIR/egw.sh && egw 

#start watchdog
function watchdog() {
    while :
    do
        source $CUR_DIR/watchdog.sh
        watchdog_all
        sleep 30
    done
}
watchdog &

