#!/bin/bash -
#########################################################################################
# init.sh
# 初始化
# version:3.0
# update:20180502
#########################################################################################
function init_net() {
    if [ -f /root/eGW/networkcfg.conf ];then
        while read line
        do
            if [ "${line:0:1}" != "#" ]; then
                [ -z "$line" ] && continue
                $line 2>&1>/dev/null
            fi
        done < /root/eGW/networkcfg.conf
	fi
}

function init_redis() {
    local ha_switch=$(awk -F '=' '/^ha_switch/{print $2}' /root/eGW/ha.conf)
    local ha_local=$(awk -F '=' '/^localip/{print $2}' /root/eGW/ha.conf)
    if [ $ha_switch == "enable"  ];then
        if [ $ha_local  ];then
            grep "^bind 127.0.0.1 $ha_local" /etc/redis.conf
            if [ $? = 1  ];then
                sed -i "s@^bind .*@bind 127.0.0.1 $ha_local@g" /etc/redis.conf
                systemctl restart redis
            fi
        fi
    else
        grep "^bind 127.0.0.1" /etc/redis.conf
        if [ $? = 1 ];then
            sed -i "s@^bind .*@bind 127.0.0.1@g" /etc/redis.conf
            systemctl restart redis
        fi
    fi
    local redis_pid=$(pidof redis-server)
    [ $redis_pid ] || systemctl restart redis
    while :
    do
        local redis_status=$(redis-cli ping)
        if [[ $redis_status == "PONG"  ]];then
            break
        fi
        #usleep 100000
    done
    redis-cli bgrewriteaof	
}

function init_para() {
    if [ -f /root/eGW/init_parameters.conf  ];then
        while read line
        do
            if [ "${line:0:1}" != "#"   ]; then
                [ -z "$line" ] && continue
                key=$(echo $line | awk '{print $1}')
                value=$(echo $line | awk '{print $3}')
                redis-cli hset eGW-para-default $key $value
            fi	
        done < /root/eGW/init_parameters.conf
    fi
}

function start_ipsec() {
    local ipsec_uplink_default=${IPSEC_UPLINK_DEFAULT:-"disable"}
    local ipsec_uplink_set=${IPSEC_UPLINK_SET}
    local ipsec_uplink=${ipsec_uplink_set:-$ipsec_uplink_default}
    local ipsec_downlink_default=${IPSEC_DOWNLINK_DEFAULT:-"disable"}
    local ipsec_downlink_set=${IPSEC_DOWNLINK_SET}
    local ipsec_downlink=${ipsec_downlink_set:-$ipsec_downlink_default}
    local ha_switch=$(awk -F '=' '/^ha_switch/{print $2}' /root/eGW/ha.conf)
    if [ ! -f /root/eGW/.ha.status   ];then
        echo "MASTER" > /root/eGW/.ha.status
    fi
    local ha_status=$(cat /root/eGW/.ha.status)
    if [[ $ha_switch == "enable"  ]];then
        if [[ $ha_status == "MASTER"  ]];then
            if [ $ipsec_uplink == "enable" ] || [ $ipsec_downlink == "enable" ];then
                ipsec start
            fi
        fi
    else
        if [ $ipsec_uplink == "enable"  ] || [ $ipsec_downlink == "enable"  ];then
            ipsec start
        fi
    fi
}

function init() {
    init_net
    init_redis
    init_para
    start_ipsec
}

