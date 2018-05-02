#!/bin/bash -
#########################################################################################
# watchdog_ps.sh
# 看门狗程序，定时检测进程
# version:3.0
# update:20180502
#########################################################################################
function watch_ps() {
    task=$1
    timer=$2
    while :
    do
        sleep_timer_default=$(redis-cli hget eGW-para-default $timer)
        sleep_timer_set=$(redis-cli hget eGW-para-set $timer)
        sleep_timer=${sleep_timer_set:-$sleep_timer_default}
        if [[ $sleep_timer == 0  ]];then
            sleep 5
        else
            $task && sleep ${sleep_timer:-"5"} || exit 1
        fi
    done
}

[ $1 ] && watch_ps $1 $2

function ps_ltegwd() {
    ltegwd=$(ps -ef |grep 'ltegwd 0 1'$ |awk '{ print $8 }')
    if [[ $ltegwd != '/root/eGW/ltegwd' ]] && [[ -f /root/eGW/Licence/licence.bin ]] && [[ -f /root/eGW/Licence/licence.auth ]];then
        time_all=`date +%Y-%m-%d' '%H:%M:%S`
        time_Ymd=`date +%Y%m%d`
        echo $time_all " watchdog: ltegwd restart" >> /root/eGW/Logs/watchdog/ps_${time_Ymd}.log
        local tpid=$(pidof ltegwd)
        [ $tpid ] && kill -9 $tpid
        redis-cli hset eGW-status eGW-ps-state-ltegwd 1
        redis-cli lpush eGW-alarm-ps ltegwd:1
        /root/eGW/ltegwd 0 1 &
        find /root/eGW -maxdepth 1 -name "*.imsi" -print0 | xargs -0I {} mv -f {} /root/eGW/ImsiFiles
    else		
        ltegwd_state=$(redis-cli hget eGW-status eGW-ps-state-ltegwd)
        if [[ $ltegwd_state == 1 ]];then
            redis-cli lpush eGW-alarm-ps ltegwd:0
            redis-cli hset eGW-status eGW-ps-state-ltegwd 0
        fi
    fi
}

function ipsec_test() {
    if [[ $up_ipsec -eq  1 ]];then
        upipsec_addr=`ipsec status | grep client | grep === | awk '{print $2}' | awk 'BEGIN {FS = "/"} {print $1}'`
        up_ipsec_addr=${upipsec_addr}":"
        echo "show running-config" > /root/eGW/.config.show
        uplink_addr=$(/root/eGW/vtysh -c /root/eGW/.config.show | grep "macro-enblink add " | awk 'NR==1{print $5}')
        if [[ $upipsec_addr != $uplink_addr ]];then
            /root/eGW/vtysh -c /root/eGW/.config.show | \
            sed -n "/macro-enblink add /{s/add/del/;p}" | cut -d ' ' -f1-4 > /root/eGW/.config.cmd
            /root/eGW/vtysh -c /root/eGW/.config.show | \
            sed -n "s@\(macro-enblink add[ ].\{1,3\}[ ].[ ]\)[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\(.*\)@\1$ip_conf\2@p" >> /root/eGW/.config.cmd
            /root/eGW/vtysh -c /root/eGW/.config.show | \
            sed -n "/gtpu-uplink add /{s/add/del/;p}" >> /root/eGW/.config.cmd
            /root/eGW/vtysh -c /root/eGW/.config.show | sed "s@\(gtpu-uplink add[ ]\).*@\1$ip_conf@" >> /root/eGW.config.cmd
            /root/eGW/vtysh -c /root/eGW/.config.cmd
        fi
            time_all=`date +%Y-%m-%d' '%H:%M:%S`
            time_Ymd=`date +%Y%m%d`
            echo $time_all " watchdog: ipsec_addr changed" >> /root/eGW/Logs/watchdog/ps_${time_Ymd}.log
            find /root/eGW -maxdepth 1 -name "*.imsi" -print0 | xargs -0I {} mv -f {} /root/eGW/ImsiFiles
    fi
}


function ps_egw_manage() {
    egw_manage=`ps -ef |grep egw_manage$ |awk '{ print $8 }'`
    if [[ $egw_manage != '/root/eGW/OMC/egw_manage' ]];then
        time_all=`date +%Y-%m-%d' '%H:%M:%S`
        time_Ymd=`date +%Y%m%d`
        echo $time_all " watchdog: egw_manage restart" >> /root/eGW/Logs/watchdog/ps_${time_Ymd}.log
        local tpid=$(pidof egw_manage)
        [ $tpid ] && kill -9 $tpid
        redis-cli hset eGW-status eGW-ps-state-egw_manage 1
        redis-cli lpush eGW-alarm-ps egw_manage:1
        spawn-fcgi -a 127.0.0.1 -p 8089 -f /root/eGW/OMC/egw_manage
    else
        egw_manage_state=$(redis-cli hget eGW-status eGW-ps-state-egw_manage)
        if [[ $egw_manage_state == 1 ]];then
            redis-cli lpush eGW-alarm-ps egw_manage:0
            redis-cli hset eGW-status eGW-ps-state-egw_manage 0
        fi
    fi
}

function ps_egw_report() {
    egw_report=`ps -ef |grep egw_report$ |awk '{ print $8 }'`
    if [[ $egw_report != '/root/eGW/OMC/egw_report' ]];then
        time_all=`date +%Y-%m-%d' '%H:%M:%S`
        time_Ymd=`date +%Y%m%d`
        echo $time_all " watchdog: egw_report restart" >> /root/eGW/Logs/watchdog/ps_${time_Ymd}.log
        local tpid=$(pidof egw_report)
        [ $tpid ] && kill -9 $tpid 
        redis-cli hset eGW-status eGW-ps-state-egw_report 1
        redis-cli lpush eGW-alarm-ps egw_report:1
        /root/eGW/OMC/egw_report &
    else
        egw_report_state=$(redis-cli hget eGW-status eGW-ps-state-egw_report)
        if [[ $egw_report_state == 1 ]];then
            redis-cli lpush eGW-alarm-ps egw_report:0
            redis-cli hset eGW-status eGW-ps-state-egw_report 0
        fi
    fi
}

function ps_egw_monitor() {
    egw_monitor=`ps -ef |grep egw_monitor$ |awk '{ print $8 }'`
    if [[ $egw_monitor != '/root/eGW/OMC/egw_monitor' ]];then
        time_all=`date +%Y-%m-%d' '%H:%M:%S`
        time_Ymd=`date +%Y%m%d`
        echo $time_all " watchdog: egw_monitor restart" >> /root/eGW/Logs/watchdog/ps_${time_Ymd}.log
        local tpid=$(pidof egw_monitor)	
        [ $tpid ] && kill -9 $tpid 
        redis-cli hset eGW-status eGW-ps-state-egw_monitor 1
        redis-cli lpush eGW-alarm-ps egw_monitor:1
        /root/eGW/OMC/egw_monitor &
    else
        egw_monitor_state=$(redis-cli hget eGW-status eGW-ps-state-egw_monitor)
        if [[ $egw_monitor_state == 1 ]];then
            redis-cli lpush eGW-alarm-ps egw_monitor:0
            redis-cli hset eGW-status eGW-ps-state-egw_monitor 0
        fi
    fi
}

function ps_egw_manage_logger() {
    egw_manage_logger=`ps -ef |grep egw_manage_logger$ |awk '{ print $8 }'`
    if [[ $egw_manage_logger != '/root/eGW/OMC/egw_manage_logger' ]];then
        time_all=`date +%Y-%m-%d' '%H:%M:%S`
        time_Ymd=`date +%Y%m%d`
        echo $time_all " watchdog: egw_manage_logger restart" >> /root/eGW/Logs/watchdog/ps_${time_Ymd}.log
        local tpid=$(pidof egw_manage_logger)
        [ $tpid ] && kill -9 $tpid 
        redis-cli hset eGW-status eGW-ps-state-egw_manage_logger 1
        redis-cli lpush eGW-alarm-ps egw_manage_logger:1
        /root/eGW/OMC/egw_manage_logger &
    else
        egw_manage_logger_state=$(redis-cli hget eGW-status eGW-ps-state-egw_manage_logger)
        if [[ $egw_manage_logger_state == 1 ]];then
            redis-cli lpush eGW-alarm-ps egw_manage_logger:0
            redis-cli hset eGW-status eGW-ps-state-egw_manage_logger 0
        fi
    fi
}

function ps_tftp() {
    tftp_enable=`cat /root/eGW/networkcfg.conf |grep ^set_tftp_enable |awk '{print $2}'`
    if [[ $tftp_enable -eq 1  ]];then
        tftp_status=$(netstat -aux |grep tftp |grep "udp ")
        if [[ ! -n $tftp_status ]];then
            systemctl restart xinetd
            time_all=`date +%Y-%m-%d' '%H:%M:%S`
            time_Ymd=`date +%Y%m%d`
            echo $time_all " watchdog: tftp restart" >> /root/eGW/Logs/watchdog/ps_${time_Ymd}.log
        fi
    fi
}
