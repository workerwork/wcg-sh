#!/bin/bash -
#########################################################################################
# egw.sh
# 配置eGW
# version:3.0
# update:20180502
#########################################################################################
function ipsec_ipaddr() {
    local ipsec_uplink=${IPSEC_UPLINK:-"disable"}
    if [[ $ipsec_uplink == "enable" ]];then
        while :
        do
            ip_conf=`ipsec status | grep client | grep === | awk '{print $2}' | awk 'BEGIN {FS = "/"} {print $1}'`
            if [ -n "$ip_conf" ];then
                #echo "$ip_conf"
                break
            fi
            sleep 2
        done
        echo "show running-config" > /root/eGW/Config.sh/.config.show
        /root/eGW/vtysh -c /root/eGW/Config.sh/.config.show | \
        sed -n "/macro-enblink add /{s/add/del/;p}" | cut -d ' ' -f1-4 > /root/eGW/Config.sh/.config.cmd
        /root/eGW/vtysh -c /root/eGW/Config.sh/.config.show | \
        sed -n "s@\(macro-enblink add[ ].\{1,3\}[ ].[ ]\)[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\(.*\)@\1$ip_conf\2@p" >> /root/eGW/Config.sh/.config.cmd
        /root/eGW/vtysh -c /root/eGW/Config.sh/.config.show | \
        sed -n "/gtpu-uplink add /{s/add/del/;p}" >> /root/eGW/Config.sh/.config.cmd
        /root/eGW/vtysh -c /root/eGW/Config.sh/.config.show | \
        sed -n "s@\(gtpu-uplink add[ ]\).*@\1$ip_conf@p" >> /root/eGW/Config.sh/.config.cmd
        /root/eGW/vtysh -c /root/eGW/Config.sh/.config.cmd
        sleep 60	
    fi
}

function init_gso() {
    echo "show running-config" > /root/eGW/Config.sh/.config.show
    ipaddr_toepc=$(/root/eGW/vtysh -c /root/eGW/.config.show |grep "macro-enblink add " | awk 'NR==1{print $5}')
    ipaddr_toenb=$(/root/eGW/vtysh -c /root/eGW/.config.show | awk '/home-enb accessip/{print $4;exit}')
    inet_toepc=$(ifconfig -a |grep $ipaddr_toepc -B 1 | head -1 | cut -d " " -f 1 | sed 's/.$//')
    inet_toenb=$(ifconfig -a |grep $ipaddr_toenb -B 1 | head -1 | cut -d " " -f 1 | sed 's/.$//')
    ethtool -K $inet_toepc gso off
    ethtool -K $inet_toenb gso off
}


function gtp() {
    rmmod /root/eGW/gtp-relay.ko
    insmod /root/eGW/gtp-relay.ko
    local gtp_address=${GTP_ADDRESS:-"73.73.0.1"}
    local gtp_a=$(echo $gtp_address | awk -F '.' '{print $1}')
    local gtp_b=$(echo $gtp_address | awk -F '.' '{print $2}')
    local gtpnat_interface=$GTPNAT_INTERFACE
    local gtpnat_address=$GTPNAT_ADDRESS
    [ $gtp_address ] && ifconfig gtp1_1 $gtp_address
    if [ $gtp_a ] && [ $gtp_b ];then
        var=`expr $gtp_a \* 256 + $gtp_b`
        echo $var > /sys/module/gtp_relay/parameters/gtp_lip
    fi
    if [ $LOCAL_FORWARD == "enable" ];then
        echo 1 > /sys/module/gtp_relay/parameters/gtp_islip
        if [ $gtp_a ] && [ $gtp_b ] && [ $gtpnat_interface ] && [ $gtpnat_address ];then
            iptables -t nat -A POSTROUTING -s ${gtp_a}.${gtp_b}.0.0/16 -o $gtpnat_interface -j SNAT --to-source $gtpnat_address
        fi
    else
        echo 0 > /sys/module/gtp_relay/parameters/gtp_islip
    fi
    if [[ $IPSEC_DOWNLINK == "enable" ]];then
        echo 1 > /sys/module/gtp_relay/parameters/gtp_ipsec_dl
    else
        echo 0 > /sys/module/gtp_relay/parameters/gtp_ipsec_dl
    fi
    if [[ $IPSEC_UPLINK == "enable" ]];then
        echo 1 > /sys/module/gtp_relay/parameters/gtp_ipsec_ul
    else
        echo 0 > /sys/module/gtp_relay/parameters/gtp_ipsec_ul
    fi
}

function egw() {
    ipsec_ipaddr
    init_gso
    gtp
}
