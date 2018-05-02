#!/bin/bash -
#########################################################################################
# watchdog
# 看门狗程序，管理话单，log，监控进程
# version:3.0
# update:20180502
#########################################################################################
#[ -f /root/eGW/Config.sh/watchdog_para.conf ] && source /root/eGW/Config.sh/watchdog_para.conf

function ps() {
    source /root/eGW/Config.sh/watchdog_ps.sh
    export -f ps_ltegwd
    export -f ps_egw_manage
    export -f ps_egw_report
    export -f ps_egw_monitor
    export -f ps_egw_manage_logger
    export -f ipsec_test

    local watch="/root/eGW/Config.sh/watchdog_ps.sh"
    $watch ps_ltegwd eGW-ltegwd-timer &
    $watch ps_egw_manage eGW-manage-timer &
    $watch ps_egw_report eGW-report-timer &
    $watch ps_egw_monitor eGW-monitor-timer &
    $watch ps_egw_manage_logger eGW-manage_logger-timer &
    $watch ipsec_test eGW-ipsec_test-timer &
}

function cdr() {
    source /root/eGW/Config.sh/watchdog_cdr.sh
    export -f cdr_all
    export -f cdr_upload
    export -f cdr_compress
    export -f cdr_del

    local watch="/root/eGW/Config.sh/watchdog_cdr.sh"
    $watch cdr_all eGW-cdr-timer eGW-cdr-num &
}

function log() {
    source /root/eGW/Config.sh/watchdog_log.sh
    export -f ps_log
    export -f history_log
    export -f keepalived_log
    export -f ltegwd_log
    export -f manage_log
    export -f report_log
    export -f monitor_log
    export -f vtysh_log
    
	local watch="/root/eGW/Config.sh/watchdog_log.sh"
    $watch ps_log eGW-ps_log-timer eGW-ps_log-num &
    $watch history_log eGW-history_log-timer eGW-history_log-num &
    $watch keepalived_log eGW-keepalived_log-timer eGW-keepalived-num &
    $watch ltegwd_log eGW-ltegwd_log-timer eGW-ltegwd_log-num &
    $watch manage_log eGW-manage_log-timer eGW-manage_log-num &
    $watch report_log eGW-report_log-timer eGW-report_log-num &
    $watch monitor_log eGW-monitor_log-timer eGW-monitor_log-num &
    $watch vtysh_log eGW-vtysh_log-timer eGW-vtysh_log-num &
}

function watchdog_all() {
    ps
    cdr
    log
    echo "watchdog start"
}
