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
    $watch ps_ltegwd watchdog_ltegwd_timer &
    $watch ps_egw_manage watchdog_manage_timer &
    $watch ps_egw_report watchdog_report_timer &
    $watch ps_egw_monitor watchdog_monitor_timer &
    $watch ps_egw_manage_logger watchdog_manage_logger_timer&
    $watch ipsec_test watchdog_ipsec_test_timer &
}

function cdr() {
    source /root/eGW/Config.sh/watchdog_cdr.sh
    export -f cdr_all
    export -f cdr_upload
    export -f cdr_compress
    export -f cdr_del

    local watch="/root/eGW/Config.sh/watchdog_cdr.sh"
    $watch cdr_all watchdog_cdr_timer watchdog_cdr_number &
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
    $watch ps_log watchdog_ps_log_timer watchdog_ps_log_number &
    $watch history_log watchdog_history_log_timer watchdog_history_log_number &
    $watch keepalived_log watchdog_keepalived_log_timer watchdog_keepalived_log_number &
    $watch ltegwd_log watchdog_ltegwd_log_timer watchdog_ltegwd_log_number &
    $watch manage_log watchdog_manage_log_timer watchdog_manage_log_number &
    $watch report_log watchdog_report_log_timer watchdog_report_log_number &
    $watch monitor_log watchdog_monitor_log_timer watchdog_monitor_log_number &
    $watch vtysh_log watchdog_vtysh_log_timer watchdog_vtysh_log_number &
}

function watchdog_all() {
    ps
    cdr
    log
    echo "watchdog start"
}
