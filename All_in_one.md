<font color='red'>最后更新：2014-07-16<br>
<blockquote>更新内容请在source -> Changes查看</font></blockquote>

# Openwrt端配置 #
首先安装ip包(<font color='red'>脚本中要使用ip命令</font>)：
```
opkg update
opkg install ip
```

下载打过补丁的dnsmasq，请根据自己的设备类型选择：
  * [dnsmasq\_all-in-one\_2.66-3\_ar71xx.ipk](http://autovpn-for-openwrt.googlecode.com/svn/trunk/packages/dnsmasq_all-in-one_2.66-3_ar71xx.ipk) (适用于基于Atheros：AR7xxx/AR9xxx的路由器，如tp-link wr703n，水星mw4530r等)
  * [dnsmasq\_all-in-one\_2.66-5\_ramips\_24kec.ipk](http://autovpn-for-openwrt.googlecode.com/svn/trunk/packages/dnsmasq_all-in-one_2.66-5_ramips_24kec.ipk) （适用于基于ralink：RT3x5x/RT5350主板的路由器，如华美a100,a1,a2）

上传到openwrt路由器/tmp/下，进行安装：
```
rm /tmp/opkg-lists/*
opkg remove dnsmasq
opkg install /tmp/xxxxx.ipk #请替换成您使用的包名
/etc/init.d/dnsmasq restart
```

修改vpn配置文件/etc/autovpn.conf：
```
SSH_SERVER=ssh-server             #ssh服务器ip或域名，必需修改
SSH_PORT=22                       #ssh服务器端口
SSH_KEY=/root/.ssh/id_rsa         #私钥文件
SSH_KEY_PUB=/root/.ssh/id_rsa.pub #公钥文件
ROUTES=/tmp/routes.txt            #路由表保存文件
```

生成密钥对并上传至服务器：
```
. /etc/autovpn.conf
mkdir /root/.ssh
dropbearkey -t rsa -s 1024 -f $SSH_KEY|grep -v "Public key portion is:\|Fingerprint" >$SSH_KEY_PUB
cat /root/.ssh/id_rsa.pub |ssh -p $SSH_PORT root@$SSH_SERVER "mkdir ~/.ssh;cat >>~/.ssh/authorized_keys;chmod 700 ~/.ssh;chmod 600 .ssh/*"
```

防火墙配置文件/etc/firewall.user加下以下内容：
```
iptables -t nat -I POSTROUTING -o pvpn+ -j MASQUERADE
iptables -I FORWARD -o pvpn+ -j ACCEPT

iptables -t nat -I POSTROUTING -o tun+ -j MASQUERADE
iptables -I FORWARD -o tun+ -j ACCEPT
```
重启防火墙：
```
/etc/init.d/firewall restart
```

执行autopvpn.sh手动连接vpn，首次连接会提示是否接受服务器公钥，选择接受之后不会再提示。然后把autopvpn.sh加入到计划任务，每一分钟检查一次vpn连接情况，断线重新连接：
```
echo "*/1 * * * * /usr/bin/autopvpn.sh" >>/etc/crontabs/root
```

重新加载cron配置：
```
/etc/init.d/cron reload
```

# 服务器端配置 #
ssh server 上启用源地址转换（SNAT），执行以下代码，并加入/etc/rc.local文件：
```
iptables -t nat  -A POSTROUTING -s 10.0.0.0/8 -j MASQUERADE
```

启用路由功能
```
echo "net.ipv4.ip_forward=1" >>/etc/sysctl.conf
sysctl -p
```

安装ppp包
```
#debian、ubuntu 服务器执行下面命令安装
apt-get install ppp
#centos服务器执行下面命令安装
yum install ppp
```
至此openwrt就具备了翻墙功能

# 新增翻墙域名 #
如让域名 autovpn-for-openwrt.googlecode.com 翻墙
```
echo "server=/autovpn-for-openwrt.googlecode.com/8.8.8.8" >>/etc/autovpn/vpn.conf
/etc/init.d/dnsmasq restart
```