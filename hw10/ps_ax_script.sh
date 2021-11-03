#!/bin/bash

# PID 1 STATE 3 tty 7? uTIME 14 sTIME 15 PRI 18 NICE 19

get_tty(){
    echo $(awk '{print $7}' /proc/${PID}/stat)
}

get_time(){
    SYS_CLK_TCK=$(getconf CLK_TCK)
    SUMTIME=$(awk '{print $14+$15}' "/proc/${PID}/stat")
    PSTIME="$(($SUMTIME / $SYS_CLK_TCK / 60)):$(($SUMTIME / $SYS_CLK_TCK % 60))"
    echo "$PSTIME"
 }

get_state(){
    echo $(awk '{print $3}' /proc/${PID}/stat)
}

get_cmd(){
    CMDLINE="$(cat /proc/${PID}/cmdline | tr "\0" " ")"
    if [ -z "$CMDLINE" ] ; then
    CMDLINE=$(awk '{print $2}' /proc/${PID}/stat | tr "()" "[]");
    fi
    echo $CMDLINE
}

printf "%5s %-10s %-6s %4s %-s\n" PID TTY STAT TIME COMMAND
PIDLIST=$(ls /proc/ | grep -P '^\d+$' | sort -n)
for PID in $PIDLIST; do
    if [ -e /proc/$PID ]; then 
       
        printf "%5s %-10s %-6s %4s %s\n" $PID $(get_tty) $(get_state) $(get_time) "$(get_cmd)" ;
    fi ;
done