#!/bin/bash -
#########################################################################################
# keepalived.sh
# 配置keepalived
# version:3.0
# update:20180502
#########################################################################################
LOG_PATH=/root/eGW/Logs/keepalived
NOTIFY=$1

function keepalived() {
    local ha_switch=$(awk -F ' = ' '/^ha_switch/{print $2}' /root/eGW/ha.conf)
    if [[ $ha_switch == "enable" ]];then
        systemctl enable keepalived
        systemctl start keepalived
        if [ ! -f /root/eGW/.ha.status  ];then
            echo "MASTER" > /root/eGW/.ha.status
        fi
        local ha_status=$(cat /root/eGW/.ha.status)
        if [[ $ha_status == "MASTER" ]];then
            redis-cli slaveof no one
            echo "local server is master,go on!"    
        else
            local ha_slave=$(awk -F ' = ' '/^slaveip/{print $2}' /root/eGW/ha.conf)
            redis-cli slaveof $ha_slave 6379
            [[ $(ipsec status) ]] && ipsec stop
            echo "local server is backup,exit!"
            exit 0
        fi
    else
        systemctl disable keepalived
        systemctl stop keepalived
    fi
}

function to_master() {
    echo "MASTER" > /root/eGW/.ha.status
    systemctl restart monitor
    time_all=`date +%Y-%m-%d' '%H:%M:%S`
    time_Ymd=`date +%Y%m%d`
    echo $time_all " keepalived: local server change to master,start monitor" >> $LOG_PATH/keepalived_${time_Ymd}.log
}

function to_backup() {
    echo "BACKUP" > /root/eGW/.ha.status
    systemctl restart monitor
    time_all=`date +%Y-%m-%d' '%H:%M:%S`
    time_Ymd=`date +%Y%m%d`
    echo $time_all " keepalived: local server change to backup,stop monitor" >> $LOG_PATH/keepalived_${time_Ymd}.log
}

function to_fault() {
    echo "FAULT" > /root/eGW/.ha.status
    systemctl restart monitor
    time_all=`date +%Y-%m-%d' '%H:%M:%S`
    time_Ymd=`date +%Y%m%d`
    echo $time_all " keepalived: local server change to fault,stop monitor" >> $LOG_PATH/keepalived_${time_Ymd}.log
}

function to_stop() {
    echo "STOP" > /root/eGW/.ha.status
    systemctl restart monitor
    time_all=`date +%Y-%m-%d' '%H:%M:%S`
    time_Ymd=`date +%Y%m%d`
    echo $time_all " keepalived: local server change to stop,stop monitor" >> $LOG_PATH/keepalived_${time_Ymd}.log
}

function notify() {
    case $NOTIFY in
        "master")
        to_master
        ;;
        "backup")
        to_backup
        ;;
        "fault")
        to_fault
        ;;
        "stop")
        to_stop
        ;;
    esac
}

notify
