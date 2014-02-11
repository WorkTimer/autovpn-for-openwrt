#!/bin/sh
DEV=`ifconfig |grep -e "tun[0-9]\|pvpn"|cut -d" " -f 1`
IPS=`echo $1|tr "," "\n"`

if [ -n "$IPS" ] ;then
    . /etc/autovpn.conf
    for ip in $IPS ;do
        ip route get $ip|grep -q $DEV
        if [ $? -ne 0 ];then
            echo "add $ip to route table"
            ip route add $ip dev $DEV
            echo "$ip dev $DEV" >>$ROUTES
        fi
    done
fi
