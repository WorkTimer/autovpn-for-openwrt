<font color='red'>最后更新：2014-10-24<br>
<blockquote>更新内容请在source -> Changes查看</font></blockquote>

# Openwrt端配置 #

下载集成补丁的 dnsmasq安装包，请根据自己的设备类型、系统版本选择（有问题请留言）：

  * Attitude Adjustment 12.09:
    * [dnsmasq\_all-in-one-12.09\_2.71-4\_ar71xx.ipk](http://autovpn-for-openwrt.googlecode.com/svn/trunk/packages/dnsmasq_all-in-one-12.09_2.71-4_ar71xx.ipk) (适用于基于Atheros：AR7xxx/AR9xxx的路由器，理论上支持所有使用mipseb类型CPU的路由器，以tp-link、水星等品牌为主)
    * [dnsmasq\_all-in-one-12.09\_2.71-4\_ramips\_24kec.ipk](http://autovpn-for-openwrt.googlecode.com/svn/trunk/packages/dnsmasq_all-in-one-12.09_2.71-4_ramips_24kec.ipk) （适用于基于ralink：RT3x5x/RT5350主板的路由器，理论上支持所有使用mipsel类型的路由器，以使用MTK（Ramips）解决方案的品牌为主）

  * Barrier Breaker 14.07:
    * [dnsmasq\_all-in-one-14.07\_2.71-4\_ar71xx.ipk](http://autovpn-for-openwrt.googlecode.com/svn/trunk/packages/dnsmasq_all-in-one-14.07_2.71-4_ar71xx.ipk) (适用于基于Atheros：AR7xxx/AR9xxx的路由器，理论上支持所有使用mipseb类型CPU的路由器，以tp-link、水星等品牌为主)
    * [dnsmasq\_all-in-one-14.07\_2.71-4\_ramips\_24kec.ipk ](http://autovpn-for-openwrt.googlecode.com/svn/trunk/packages/dnsmasq_all-in-one-14.07_2.71-4_ramips_24kec.ipk) （适用于基于ralink：RT3x5x/RT5350主板的路由器，理论上支持所有使用mipsel类型的路由器，以使用MTK（Ramips）解决方案的品牌为主）

上传到openwrt路由器/tmp/下，进行安装：
```
rm /tmp/opkg-lists/*
opkg remove dnsmasq
opkg install /tmp/xxxxx.ipk #请替换成您使用的包名
```

生成密钥对并上传至服务器：
```
mkdir /root/.ssh
dropbearkey -t rsa -s 1024 -f $SSH_KEY|sed -n '/Public key portion is:/{n;p}' >/root/.ssh/id_rsa.pub
#注意替换下面命令中的<PORT> <SSH_SERVER>
cat /root/.ssh/id_rsa.pub |ssh -p <PORT> root@<SSH_SERVER> "mkdir ~/.ssh;cat >>~/.ssh/authorized_keys;chmod 700 ~/.ssh;chmod 600 .ssh/*"
```

登录 LUCI（openwrt web配置界面） 进入 Network（网络）->Interface(接口) 页面，按下图步骤新建VPN接口（如图片不能正常显示，请点击图片下载后查看）：
<a href='http://autovpn-for-openwrt.googlecode.com/svn/trunk/images/1.png'><img src='http://autovpn-for-openwrt.googlecode.com/svn/trunk/images/1.png' /></a>

<a href='http://autovpn-for-openwrt.googlecode.com/svn/trunk/images/2.png'><img src='http://autovpn-for-openwrt.googlecode.com/svn/trunk/images/2.png' /></a>

<a href='http://autovpn-for-openwrt.googlecode.com/svn/trunk/images/3.png'><img src='http://autovpn-for-openwrt.googlecode.com/svn/trunk/images/3.png' /></a>

<a href='http://autovpn-for-openwrt.googlecode.com/svn/trunk/images/4.png'><img src='http://autovpn-for-openwrt.googlecode.com/svn/trunk/images/4.png' /></a>

<a href='http://autovpn-for-openwrt.googlecode.com/svn/trunk/images/5.png'><img src='http://autovpn-for-openwrt.googlecode.com/svn/trunk/images/5.png' /></a>


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

如想客户端连接服务器时使用普通用户，请参看这篇文章 [ppp over ssh（普通用户）服务器端配置](https://code.google.com/p/autovpn-for-openwrt/wiki/PPPoS_nonroot)

# 新增翻墙域名 #
如让域名 autovpn-for-openwrt.googlecode.com 翻墙
```
echo "server=/autovpn-for-openwrt.googlecode.com/8.8.8.8" >>/etc/autovpn/vpn.conf
/etc/init.d/dnsmasq restart
```

让所有 `*`.googlecode.com 子域名翻墙
```
echo "server=/googlecode.com/8.8.8.8" >>/etc/autovpn/vpn.conf
/etc/init.d/dnsmasq restart
```


---

## 部分实现参考了以下链接，感谢 ##
  * http://patchwork.openwrt.org/patch/6290/