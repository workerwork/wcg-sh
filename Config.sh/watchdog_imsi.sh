#!/bin/bash -

#########################################################################################
# watchdog_imsi.sh
# version:1.0
# update:20180605
#########################################################################################
function watch_imsi() {
    task=$1
    timer=$2
    num=$3
    while :
    do
        if [[ $num == "&" ]];then
            sleep_timer_default=$(redis-cli hget eGW-para-default $timer)
            sleep_timer_set=$(redis-cli hget eGW-para-set $timer)
            sleep_timer=${sleep_timer_set:-$sleep_timer_default}
            if [[ $sleep_timer != "0" ]];then
                $task && sleep ${sleep_timer:-"10"} || exit 1
            else
                sleep 5
            fi
        else
            sleep_timer_default=$(redis-cli hget eGW-para-default $timer)
            sleep_timer_set=$(redis-cli hget eGW-para-set $timer)
            sleep_timer=${sleep_timer_set:-$sleep_timer_default}
            keep_num_default=$(redis-cli hget eGW-para-default $num)
            keep_num_set=$(redis-cli hget eGW-para-set $num)
            keep_num=${keep_num_set:-$keep_num_default}
            if [[ $sleep_timer != "0" ]];then
                $task ${keep_num:-"15"} && sleep ${sleep_timer:-"10"} || exit 1
            else
                sleep 5
            fi
        fi
    done
}

[ $1 ] && watch_imsi $1 $2 $3

function imsi_del() {
    imsi_num=$1
    ls -lt /root/eGW/ImsiFiles/*.txt 2>/dev/null | awk -v imsi_num=$imsi_num '{if(NR>imsi_num){print $9}}' |xargs rm -rf
}

function imsi_all() {
    [ $1 ] && imsi_del $1
}


