#!/bin/bash -

#########################################################################################
# iptables.sh
# 防火墙程序,定义iptables规则,对公网口进行过滤
# version:3.0
# update:20180502
#########################################################################################
function init_iptables() {
    iptables -F         #删除filter表规则 
    iptables -F -t nat  #删除nat表规则
    iptables -X         #删除filter表用户定义规则 
    iptables -X -t nat	#删除nat表用户定义规则
    iptables -Z         #清空filter表计数器
    iptables -Z -t nat  #清空nat表计数器
}


function set_default_policy_iptables() {
    iptables -P INPUT ACCEPT      #允许所有包进入
    iptables -P OUTPUT ACCEPT     #允许所有包出去
    iptables -P FORWARD ACCEPT    #允许所有包转发
}

function set_firewalld_iptables() {
    local iptables_switch_default=${IPTABLES_SWITCH_DEFAULT:-"disable"}
    local iptables_switch_set=${IPTABLES_SWITCH_SET}
    local iptables_switch=${iptables_switch_default:-$iptables_switch_set}
    local public_interface_default=${PUBLIC_INTERFACE_DEFAULT}
    local public_interface_set=${PUBLIC_INTERFACE_SET}
    local public_interface=${public_interface_set:-$public_interface_default}
    if [[ $iptables_switch -eq 1 ]];then
        iptables -A INPUT -p udp --sport 53 -j ACCEPT										#允许DNS
        iptables -A INPUT -p udp --dport 53 -j ACCEPT										#允许DNS
        iptables -A INPUT -p tcp --dport 50683 -j ACCEPT									#允许SSH登录
        iptables -A INPUT -p udp --dport 500 -j ACCEPT										#允许IPSEC握手
        iptables -A INPUT -p udp --dport 4500 -j ACCEPT										#允许IPSEC隧道包
        iptables -A INPUT -p sctp --dport 36412 -j ACCEPT									#允许SCTP包
        iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT    				#允许已经建链的包和响应包
        iptables -A INPUT -p icmp -j ACCEPT													#允许ICMP包
        iptables -A INPUT -p esp -j ACCEPT                                  				#允许ESP包
        [ $public_interface ] && iptables -A INPUT -p all -i ${public_interface} -j DROP	#丢弃指定端口包
    fi
}


function config_iptables() {
    init_iptables
    set_default_policy_iptables
    set_firewalld_iptables
}

#config_iptables
