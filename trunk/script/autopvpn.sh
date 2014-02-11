#!/bin/sh

. /etc/autovpn.conf
ps |grep -v grep|grep -qe "ssh.*-TCf\|pppd ifname pvpn"
if [ $? -ne 0 ] ;then
    echo "[ `date +'%Y/%m/%d %H:%M:%S'` ] restart pvpn" >>/tmp/autopvpn.log
    export SSH_ARGS="-p $SSH_PORT -i $SSH_KEY"
    pvpn root@$SSH_SERVER 8.8.8.8
    kill -HUP `pgrep dnsmasq`
    while read route ; do
        ip route add $route
    done 2>/dev/null <$ROUTES
fi
