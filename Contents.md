# 原理简介 #
  1. 为防止DNS污染，ssh over ppp 连接建立后会自动将IP：8.8.8.8 加入路由表，出口指向vpn接口（防止8.8.8.8被劫持）
  1. dnsmasq 中把被墙域名的DNS服务器配置为8.8.8.8（server=/xxxx.com/8.8.8.8）
  1. dnsmasq 收到用户dns请求，检查域名是否存在配置中，如查到则将查询请求转发到指定服务器(8.8.8.8)，dnsmasq得到解析结果调用指定的脚本将解析结果中的IP加入路由表出口为vpn接口（server-script=/path/to/routeadd.sh）

以google.com为例
将被墙域名配置到dnsmasq.conf中（openwrt为/etc/config/dhcp），通过8.8.8.8解析：
```
server=/google.com/8.8.8.8
```
用户访问google.com，首先发起dns查询，dnsmasq接收并将请求转发给8.8.8.8，dnsmasq从8.8.8.8得到域名解析结果，检查请求的域名是否在server=/xxx/xxx 的配置中（是否被墙），找到后传递解析结果给 --server-script 指定的脚本并执行，将这些IP加入路由表，出口指向vpn接口。然后dnsmasq把解析结果发给用户，用户得到google.com服务器IP发起连接，dnsmasq所在路由器根据路由表将目的为这些IP的流量通过vpn转发出去。

# 安装配置 #

  1. 快速部署
    * [适用于Openwrt 12.09、14.07 ](https://code.google.com/p/autovpn-for-openwrt/wiki/All_in_one_netifd)
  1. 逐步部署
    * [适用于 Openwrt Attitude Adjustment 12.09](https://code.google.com/p/autovpn-for-openwrt/wiki/Dnsmasq_Patched)
---- 附 ----
  * [linuxmint下部署 (ubuntu？)](https://code.google.com/p/autovpn-for-openwrt/wiki/Dnsmasq_patched_for_linuxmint)