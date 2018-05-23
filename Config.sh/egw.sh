#!/bin/bash -
#########################################################################################
# egw.sh
# version:3.1
# update:20180523
#########################################################################################
function ipsec_ipaddr() {
    local ipsec_uplink_default=${IPSEC_UPLINK_DEFAULT:-"disable"}
    local ipsec_uplink_set=${IPSEC_UPLINK_SET}
    local ipsec_uplink=${ipsec_uplink_set:-$ipsec_uplink_default}
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
        #sleep 60	
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
    lsmod | grep gtp_relay
    if [[ $? == 0 ]];then
        rmmod /root/eGW/gtp-relay.ko
        insmod /root/eGW/gtp-relay.ko
    else
        insmod /root/eGW/gtp-relay.ko
    fi
    local lf_switch_default=${LF_SWITCH_DEFAULT:-"disable"}
    local lf_switch_set=${LF_SWITCH_SET}
    local lf_switch=${lf_switch_set:-$lf_switch_default}
    local gtp_addr_default=${LF_GTP_ADDR_DEFAULT:-"73.73.0.1"}
    local gtp_addr_set=${LF_GTP_ADDR_SET}
    local gtp_addr=${gtp_addr_set:-$gtp_addr_default}
    local gtp_a=$(echo $gtp_addr | awk -F '.' '{print $1}')
    local gtp_b=$(echo $gtp_addr | awk -F '.' '{print $2}')
    local gtp_nat_if_default=${LF_GTP_NAT_IF_DEFAULT:-"x"}
    local gtp_nat_if_set=${LF_GTP_NAT_IF_SET}
    local gtp_nat_if=${gtp_nat_if_set:-$gtp_nat_if_default}
    local gtp_nat_addr_default=${LF_GTP_NAT_ADDR_DEFAULT:-"x.x.x.x"}
    local gtp_nat_addr_set=${LF_GTP_NAT_ADDR_SET}
    local gtp_nat_addr=${gtp_nat_addr_set:-$gtp_nat_addr_default}
    if [ $lf_switch == "enable" ];then
        echo 1 > /sys/module/gtp_relay/parameters/gtp_islip
        [ $gtp_addr  ] && ifconfig gtp1_1 $gtp_addr
        if [ $gtp_a  ] && [ $gtp_b  ];then
            var=`expr $gtp_a \* 256 + $gtp_b`
            echo $var > /sys/module/gtp_relay/parameters/gtp_lip
            if [ $gtp_nat_if ] && [ $gtp_nat_addr ];then
                iptables -t nat -A POSTROUTING -s ${gtp_a}.${gtp_b}.0.0/16 -o $gtp_nat_if -j SNAT --to-source $gtp_nat_addr
            fi
        fi
    else
        echo 0 > /sys/module/gtp_relay/parameters/gtp_islip
    fi
    local ipsec_uplink_default=${IPSEC_UPLINK_DEFAULT:-"disable"}
    local ipsec_uplink_set=${IPSEC_UPLINK_SET}
    local ipsec_uplink=${ipsec_uplink_set:-$ipsec_uplink_default}
    local ipsec_downlink_default=${IPSEC_DOWNLINK_DEFAULT:-"disable"}
    local ipsec_downlink_set=${IPSEC_DOWNLINK_SET}
    local ipsec_downlink=${ipsec_downlink_set:-$ipsec_downlink_default}
    if [[ $ipsec_downlink == "enable" ]];then
        echo 1 > /sys/module/gtp_relay/parameters/gtp_ipsec_dl
    else
        echo 0 > /sys/module/gtp_relay/parameters/gtp_ipsec_dl
    fi
    if [[ $ipsec_uplink == "enable" ]];then
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
