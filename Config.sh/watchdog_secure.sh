#!/bin/bash -

#########################################################################################
# watchdog_secure.sh
# version:3.1
# update:20180523
#########################################################################################

protect_time=600

function set_sshd_protect() {
    sshd_protect=`cat /root/eGW/networkcfg.conf |grep '^set_sshd_protect_enable' |awk '{ print $2 }'`
    HEAD=$(lastb|grep ssh|head -n 20|tail -n 1|awk '{print $5" "$6" "$7}')
    #echo $HEAD
    TIME=$(($(date +%s)-$(date +%s -d "$HEAD")))
    #echo $TIME
    if [ $TIME -lt 600 ]; then
        time_all=`date +%Y-%m-%d' '%H:%M:%S`
        echo $time_all "login error too much!" >> /root/eGW/Logs/watchdog/secure.log
        if [[ $sshd_protect -eq 1 ]];then
            lastb|grep ssh|head -n 20 |awk '{ip[$3]++}END{ for(key in ip){ if(ip[key]>5){print key}}}' >> /root/eGW/Logs/watchdog/secure.txt
            cat /root/eGW/Logs/watchdog/secure.txt |sort |uniq > /root/eGW/Logs/watchdog/secure_sort.txt
            mv /root/eGW/Logs/watchdog/secure_sort.txt /root/eGW/Logs/watchdog/secure.txt
            echo "#hosts.deny" > /etc/hosts.deny
            while read line
            do
                echo "sshd:"$line >> /etc/hosts.deny
            done < /root/eGW/Logs/watchdog/secure.txt 
        fi
    fi
}



function protect_while() {
    while true
    do
        set_sshd_protect
        systemctl restart sshd
        sleep $protect_time
    done
}

#set_sshd_protect
protect_while &


