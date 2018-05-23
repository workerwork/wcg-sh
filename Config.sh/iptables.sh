#!/bin/bash -
#########################################################################################
# iptables.sh
# version:3.1
# update:20180523
#########################################################################################
function init_iptables() {
    iptables -F          
    iptables -F -t nat  
    iptables -X         
    iptables -X -t nat	
    iptables -Z         
    iptables -Z -t nat  
}


function set_default_policy_iptables() {
    iptables -P INPUT ACCEPT      
    iptables -P OUTPUT ACCEPT     
    iptables -P FORWARD ACCEPT    
}

function set_firewalld_iptables() {
    local iptables_switch_default=${IPTABLES_SWITCH_DEFAULT:-"disable"}
    local iptables_switch_set=${IPTABLES_SWITCH_SET}
    local iptables_switch=${iptables_switch_set:-$iptables_switch_default}
    local iptables_interface_default=${IPTABLES_IF_DEFAULT}
    local iptables_interface_set=${IPTABLES_IF_SET}
    local iptables_interface=${iptables_interface_set:-$iptables_interface_default}
    if [[ $iptables_switch -eq 1 ]];then
        init_iptables
        set_default_policy_iptables
        iptables -A INPUT -p udp --sport 53 -j ACCEPT										
        iptables -A INPUT -p udp --dport 53 -j ACCEPT										
        iptables -A INPUT -p tcp --dport 50683 -j ACCEPT									
        iptables -A INPUT -p udp --dport 500 -j ACCEPT										
        iptables -A INPUT -p udp --dport 4500 -j ACCEPT										
        iptables -A INPUT -p sctp --dport 36412 -j ACCEPT									
        iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT    				
        iptables -A INPUT -p icmp -j ACCEPT													
        iptables -A INPUT -p esp -j ACCEPT                                  				
        [ $iptables_interface ] && iptables -A INPUT -p all -i ${iptables_interface} -j DROP	
    fi
}


function config_iptables() {
    set_firewalld_iptables
}

