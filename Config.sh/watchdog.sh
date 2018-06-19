#!/bin/bash -
#########################################################################################
# watchdog
# version:5.2
# update:20180619
#########################################################################################
#[ -f /root/eGW/Config.sh/watchdog_para.conf ] && source /root/eGW/Config.sh/watchdog_para.conf

function egw_ps() {
    source /root/eGW/Config.sh/watchdog_ps.sh
    export -f ps_ltegwd
    export -f ps_egw_manage
    export -f ps_egw_report
    export -f ps_egw_monitor
    export -f ps_egw_manage_logger
    export -f ipsec_test

    local watch="/root/eGW/Config.sh/watchdog_ps.sh"
    [[ -z $(ps -ef | grep "ps_ltegwd watchdog_ltegwd_timer$") ]] && \
    $watch ps_ltegwd watchdog_ltegwd_timer &
    [[ -z $(ps -ef | grep "ps_egw_manage watchdog_manage_timer$") ]] && \
    $watch ps_egw_manage watchdog_manage_timer &
    [[ -z $(ps -ef | grep "ps_egw_report watchdog_report_timer$") ]] && \
    $watch ps_egw_report watchdog_report_timer &
    [[ -z $(ps -ef | grep "ps_egw_monitor watchdog_monitor_timer$") ]] && \
    $watch ps_egw_monitor watchdog_monitor_timer &
    [[ -z $(ps -ef | grep "ps_egw_manage_logger watchdog_manage_logger_timer$") ]] && \
    $watch ps_egw_manage_logger watchdog_manage_logger_timer &
    [[ -z $(ps -ef | grep "ipsec_test watchdog_ipsec_test_timer$") ]] && \
    $watch ipsec_test watchdog_ipsec_test_timer &
}

function egw_cdr() {
    source /root/eGW/Config.sh/watchdog_cdr.sh
    export -f cdr_all
    export -f cdr_upload
    export -f cdr_compress
    export -f cdr_del

    local watch="/root/eGW/Config.sh/watchdog_cdr.sh"
    [[ -z $(ps -ef | grep "cdr_all watchdog_cdr_timer watchdog_cdr_number$") ]] && \
    $watch cdr_all watchdog_cdr_timer watchdog_cdr_number &
}

function egw_imsi() {
    source /root/eGW/Config.sh/watchdog_imsi.sh
    export -f imsi_all
    export -f imsi_del

    local watch="/root/eGW/Config.sh/watchdog_imsi.sh"
    [[ -z $(ps -ef | grep "imsi_all watchdog_imsi_timer watchdog_imsi_number$") ]] && \
    $watch imsi_all watchdog_imsi_timer watchdog_imsi_number &
}

function egw_log() {
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
    [[ -z $(ps -ef | grep "ps_log watchdog_ps_log_timer watchdog_ps_log_number$") ]] && \
    $watch ps_log watchdog_ps_log_timer watchdog_ps_log_number &
    [[ -z $(ps -ef | grep "history_log watchdog_history_log_timer watchdog_history_log_number$") ]] && \
    $watch history_log watchdog_history_log_timer watchdog_history_log_number &
    [[ -z $(ps -ef | grep "keepalived_log watchdog_keepalived_log_timer watchdog_keepalived_log_number$") ]] && \
    $watch keepalived_log watchdog_keepalived_log_timer watchdog_keepalived_log_number &
    [[ -z $(ps -ef | grep "ltegwd_log watchdog_ltegwd_log_timer watchdog_ltegwd_log_number$") ]] && \
    $watch ltegwd_log watchdog_ltegwd_log_timer watchdog_ltegwd_log_number &
    [[ -z $(ps -ef | grep "manage_log watchdog_manage_log_timer watchdog_manage_log_number$") ]] && \
    $watch manage_log watchdog_manage_log_timer watchdog_manage_log_number &
    [[ -z $(ps -ef | grep "report_log watchdog_report_log_timer watchdog_report_log_number$") ]] && \
    $watch report_log watchdog_report_log_timer watchdog_report_log_number &
    [[ -z $(ps -ef | grep "monitor_log watchdog_monitor_log_timer watchdog_monitor_log_number$") ]] && \
    $watch monitor_log watchdog_monitor_log_timer watchdog_monitor_log_number &
    [[ -z $(ps -ef | grep "vtysh_log watchdog_vtysh_log_timer watchdog_vtysh_log_number$") ]] && \
    $watch vtysh_log watchdog_vtysh_log_timer watchdog_vtysh_log_number &
}

function watchdog_all() {
    egw_ps
    egw_cdr
    egw_imsi
    egw_log
    echo "watchdog start"
}
