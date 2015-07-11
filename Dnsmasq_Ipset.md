**注意：**从dnsmasq 2.66 版开发内置了ipset支持，openwrt 官方dnsmasq默认没有启用ipset，您可以自行编译并启用ipset，来替换本文档第3节中的ipset-dns软件，但相比之下使用ipset依然是不推荐的。

# 工作原理 #
  1. 为防止DNS污染，将IP 8.8.8.8 加入路由表，出口指向vpn
  1. ipset-dns 根据解析结果维护ipset中的ip地址(添加IP)
  1. Dnsmasq 根据配置，将不同域名转发给不同DNS服务器进行解析（被墙域名转发给ipset-dns解析）
  1. iptables 根据Ipset中的IP，对流量打上标记
  1. 打过标记的流量查询特殊路由表并进行转发,被转发到vpn接口

比如，用户访google.com，首先发起DNS查询，dnsmasq接收，判断是否为此域名配置了特定的DNS服务器（server=/google.com/127.0.0.1#53000），如否转发给默认DNS服务器，如是转发给该DNS服务器（这里为127.0.0.1#53000 即Ipset-dns端口），Ipset-dns接到dns查询请求，转发给自己的上级DNS（8.8.8.8），上级DNS返回结果给Ipset-dns，ipset-dns 把解析结果加入 ipset （例如名为vpn的ipset）并返回结果给dnsmasq ，dnsmasq返回解析结果给用户。用户得到google.com服务器的IP，发起TCP连接，iptables 查询ipset：vpn，不匹配直接使用默认路由表转发，匹配则打上标记（set mark），打上标记的数据包，会查询一个特殊的路由表，该路由表默认路由指向vpn接口，即流量通过vpn转发。

# 安装 #
首先安装ip包：
```
opkg install ip
```

## 1.建立vpn连接 ##

### 1.1 pvpn(推荐使用,需有root用户权限) ###
详见：[pvpn配置](http://code.google.com/p/autovpn-for-openwrt/wiki/Dnsmasq_Patched#1.1_pvpn%28%E6%8E%A8%E8%8D%90%E4%BD%BF%E7%94%A8%EF%BC%8C%E9%9C%80%E6%9C%89root%E7%94%A8%E6%88%B7%E6%9D%83%E9%99%90%29)

### 1.2 openvpn ###

创建/usr/bin/vpnup.sh:
```
#!/bin/sh

ip route del 8.8.8.8
ip route add 8.8.8.8 via $VPNGW
ip route flush table 1 2>/dev/null
ip rule del table 1 2>/dev/null
ip rule add fwmark 1 table 1 priority 1000
ip route add default dev $1 table 1
```
然后在openvpn客户端配置文件中加入：
```
up /usr/bin/vpnup.sh
script-security 3 system
route-nopull
```

### 1.3 pptp/l2tp ###
pptp没有自动添加路由的方法，请自行配置连接vpn，并将8.8.8.8加入到路由表通过vpn转发，来防止DNS污染。

## 2.防火墙配置 ##
在/etc/firewall.user 中添加（使用openvpn tap模式或pptp/l2tp，请注意修改命令中的接口名）：
```
iptables -t nat -I POSTROUTING -o tun+ -j MASQUERADE
iptables -I FORWARD -o tun+ -j ACCEPT

iptables -t nat -I POSTROUTING -o pvpn -j MASQUERADE
iptables -I FORWARD -o pvpn -j ACCEPT
```
应用防火墙配置：
```
/etc/init.d/firewall restart
```

## 3.安装ipset-dns ##
如果你使用的是openwrt Attitude Adjustment (12.09 final)的话，点击[ipset-dns\_2013-05-03\_ar71xx.ipk](http://autovpn-for-openwrt.googlecode.com/svn/trunk/packages/ipset-dns_2013-05-03_ar71xx.ipk)下载安装即可.

某则您只能下载源码包，自己自己编译了，使用svn获取源码包：
```
svn co svn://svn.openwrt.org/openwrt/trunk/package/network/services/ipset-dns/
```

安装ipset，ipset内核模块，ip命令：
```
opkg install iptables-mod-ipset kmod-ipt-ipset ipset ip iptables-mod-ipmark kmod-ipt-ipmark kmod-tun
```

ipset-dns配置/etc/config/ipset-dns：
```
config ipset-dns
        # use given ipset for type A (IPv4) responses
        option ipset 'vpn'

        # use given ipset for type AAAA (IPv6) responses
        #option ipset6 'domain-filter-ipv6'

        # use given listening port
        # defaults to 53000 + instance number
        option port  '53000'

        # use given upstream DNS server,
        # defaults to first entry in /tmp/resolv.conf.auto
        option dns   '8.8.8.8'
```

修改ipset-dns启动脚本/etc/init.d/ipset-dns ，在start()函数中加入：
```
        iptables -t mangle -D PREROUTING -m set --match-set "vpn" dst,src -j MARK --set-mark "1" 2>/dev/null
        ipset -X "vpn" 2>/dev/null
        ipset -N "vpn" iphash
        iptables -t mangle -A PREROUTING -m set --match-set "vpn" dst,src -j MARK --set-mark "1"
```

然后启动 ipset-dns DNS代理，监听在53000端口：
```
/etc/init.d/ipset start
```

如果你想调试ipset-dns查看输出内容，需要设置NO\_DAEMONIZE环境变量,然后手动启动ipset-dns：
```
export NO_DAEMONIZE=y
ipset-dns vpn 53000 8.8.8.8 #手动启动
```

## 4.配置dnsmasq ##
下载[gfwlist.txt](https://autoproxy-gfwlist.googlecode.com/svn/trunk/gfwlist.txt)，使用base64 解码
```
 wget https://autoproxy-gfwlist.googlecode.com/svn/trunk/gfwlist.txt -O -|base64 -d >gfwlist.txt
```
用脚本[genDnsmasq.sh](http://pvpn-for-openwrt.googlecode.com/svn/trunk/script/genDnsmasq.sh)（请同时下载[autoproxy2domain](http://pvpn-for-openwrt.googlecode.com/svn/trunk/script/autoproxy2domain) 放同一目录下），修改genDnsmasq脚本中的“DNSServer=8.8.8.8”为“DNSServer=127.0.0.1#53000”，然后生成dnsmasq的配置格式：
```
genDnsmasq gfwlist.txt openwrt #不加openwrt参数生成的为原生dnsmasq配置格式
```
将生成的dnsmasq.conf中的内容加入dnsmasq 配置文件中config dnsmasq块中，重启dnsmasq服务。

如果你不关心下面提到的问题，至此一切就ok了。

# 已知问题 #
上面提到的这个问题是对于Openwrt路由器本身，是不能翻墙的，因为iptable 无法在Routing decision之前对local process发出去的包进行set mark操作，所以，无法使用为vpn新建的路由表。

限于我的水平，我的解决方案是都过修改ipset-dns，添加第4个参数:脚本文件，指定脚本启动后，在ipset-dns把解析结果加入ipset之后发给用户之前会执行这个脚本，并把解析到的ip（以,分隔）传递给脚本，这个过程是阻塞的，也就会增加DNS响应延时，但我们的目的是把不能变成可能，所以慢无所谓只要能用就行。在这个脚本检查ip是否已经在路由表中，不在则添加之。patch请在本项目trunk目录下载。脚本内容如下：
```
#!/bin/sh

DEV='tun0'   #请修改vpn接口名
#DEV=`ip tuntap|cut -d: -f1 |head -n1` #如果您确定只有一个tun的 vpn接口，可以去掉本行前的注释，来自动获取接口名

IPS=`echo $1|tr "," "\n"`
if [ -n "IPS" ] ;then
    for ip in $IPS ;do
        ip route get $ip|grep -q "tun"
        if [ $? -ne 0 ];then
            echo "add $ip to route table"
            ip route add $ip dev $DEV
        fi
    done
fi

```
之后还需要修改ipset-dns包中的启动脚本和配置文件，这个等有时间我会把patch过的ipk包上传上来，手动启动ipset-dns的命令就变成了这样：
```
ipset-dns <ipset name> <port> <upstream dns> <script name>
```

可能您已经想到了，用了patch之后的ipset-dns，和[方案一](https://code.google.com/p/autovpn-for-openwrt/wiki/Dnsmasq_Patched)中用dnsmasq 的实现差不多的。
最后如果没有特殊需求或不能接受修改dnsmasq源码的方式，请不要使用此方案。