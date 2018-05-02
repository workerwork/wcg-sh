#!/bin/bash -

#########################################################################################
# watchdog_cdr.sh
# 看门狗程序，定时上传话单，归档话单，删除话单
# version:3.0
# update:20180502
#########################################################################################
function watch_cdr() {
    task=$1
    timer=$2
    num=$3
    while :
    do
        if [[ $num == "&" ]];then
            sleep_timer_default=$(redis-cli hget eGW-para-default $timer)
            sleep_timer_set=$(redis-cli hget eGW-para-set $timer)
            sleep_timer=${sleep_timer_set:-$sleep_timer_default}
            if [[ $sleep_timer -ne "0" ]];then
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
            if [[ $sleep_timer -ne "0" ]];then
                $task ${keep_num:-"15"} && sleep ${sleep_timer:-"10"} || exit 1
            else
                sleep 5
            fi
        fi
    done
}

[ $1 ] && watch_cdr $1 $2 $3

function cdr_upload() {   
    #cdr_tftp_ip=`cat /root/eGW/config.txt | grep "set_charge_service " | awk '{print $5}'`    #tftp上传地址
    list_cdr=`ls -lt /root/eGW/CDR/*.dat 2>/dev/null | awk '{if(NR>=2){print $9}}'`
    for i in $list_cdr
    do
    {
        #echo $i
        cdr_tmp=`echo $i |awk -F '_' '{print $4}'`	
        #echo ${cdr_tmp:0:8}
        if [[ ! -d "/root/eGW/CDR/cdrDat/${cdr_tmp:0:8}" ]];then
            mkdir -p /root/eGW/CDR/cdrDat/${cdr_tmp:0:8}
		fi
        #tftp $cdr_tftp_ip -c put $i
        mv $i /root/eGW/CDR/cdrDat/${cdr_tmp:0:8}
    } &
    done
}

function cdr_compress() {
    list_cdr_fold=`ls -lt /root/eGW/CDR/cdrDat 2>/dev/null | grep '^d' | awk '{if(NR>=2){print $9}}'`
    cd /root/eGW/CDR/cdrDat	
    for i in $list_cdr_fold
    do
    {
        tar -zcvf ${i}.tar.gz $i 
        rm -rf $i	
    } &
    done	
}

function cdr_del() {
    cdr_num=$1
    ls -lt /root/eGW/CDR/cdrDat/*.tar.gz 2>/dev/null | awk '{if(NR>$cdr_num){print $9}}' |xargs rm -rf
}

function cdr_all() {
    cdr_upload
    cdr_compress
    [ $1 ] && cdr_del $1
}


