<font color='red'>最后更新：2014-10-11<br>
<blockquote>更新内容请在source -> Changes查看</font></blockquote>

# 安装配置 #
首先安装ip包(<font color='red'>脚本中要使用ip命令</font>)：
```
opkg update
opkg install ip
```
## 1.建立vpn连接 ##
目前PPTP L2tp Openvpn  SSH 都不同程度的受到了GFW的干扰，其中对SSH干扰是最小的，所以建议您使用 pvpn-for-openwrt 来做vpn隧道。

pvpn 有两种模式，都需要用密钥验证：
  1. ppp over ssh
  1. ssh原生tun接口（使用-t ssh-3参数，flash空闲空间需要在1M以上）

ppp over ssh 的方式要求ssh帐号拥有在服务器端执行pppd的权限。最方便快捷的方式是使用root用户，但安全性较低。普通用户通过 sudo 执行 pppd，安全性相对较高，同时也可以限制用户不能登陆到shell，配置略复杂，参见[ppp over ssh（普通用户）服务器端配置](https://code.google.com/p/pvpn-for-openwrt/wiki/pvpn_nonroot)

tun接口模式目前只能使用root用户。

pvpn 更具体的使用方法请移步至：[pvpn-for-openwrt 项目主页](https://code.google.com/p/pvpn-for-openwrt/)。

1) 下载pvpn for openwrt、autopvpn.sh、autovpn.conf 到 openwrt 相应目录下，并添加执行权限：
```
wget -O /usr/bin/pvpn http://pvpn-for-openwrt.googlecode.com/svn/trunk/pvpn
wget -O /usr/bin/autopvpn.sh http://autovpn-for-openwrt.googlecode.com/svn/trunk/script/autopvpn.sh
#如果使用ssh layer3模式修改autopvpn.sh 文件中pvpn 所在行为：pvpn -t ssh-3 ......
wget -O /etc/autovpn.conf http://autovpn-for-openwrt.googlecode.com/svn/trunk/script/autovpn.conf
chmod +x /usr/bin/pvpn /usr/bin/autopvpn.sh
```

2) 修改vpn配置文件 /etc/autovpn.conf：
```
SSH_SERVER=ssh-server             #ssh服务器ip或域名，必需修改
SSH_PORT=22                       #ssh服务器端口
SSH_KEY=/root/.ssh/id_rsa         #私钥文件
SSH_KEY_PUB=/root/.ssh/id_rsa.pub #公钥文件
DEV=`ifconfig |grep -e "tun[0-9]\|pvpn"|cut -d" " -f 1` #vpn接口
ROUTES=/tmp/routes.txt            #路由表保存文件
```

3) 在openwrt下生成密钥对并上传到服务器：
```
. /etc/autovpn.conf
mkdir /root/.ssh
dropbearkey -t rsa -s 1024 -f $SSH_KEY|sed -n '/Public key portion is:/{n;p}' >$SSH_KEY_PUB
cat /root/.ssh/id_rsa.pub |ssh -p $SSH_PORT root@$SSH_SERVER "mkdir ~/.ssh;cat >>~/.ssh/authorized_keys;chmod 700 ~/.ssh;chmod 600 .ssh/*"
```

4) 如果 1) 中没使用-t ssh-3 参数，即ssh layer3模式，请跳过该步骤：

安装所需包
```
rm /usr/bin/ssh
rm /usr/bin/scp
opkg install openssh-client
opkg install kmod-tun

opkg install dropbearconvert
dropbearconvert dropbear openssh /root/.ssh/id_rsa /root/.ssh/id_rsa_openssh  #将dropbear格式私钥转为 openssh格式
mv /root/.ssh/id_rsa_openssh /root/.ssh/id_rsa #覆盖旧私钥
```

ssh server 上启用TUN隧道支持：
```
echo "PermitTunnel yes" >>/etc/ssh/sshd_config
/etc/init.d/ssh reload
```

5) ssh server 上启用路由功能和源地址转换（SNAT）：
```
iptables -t nat -A POSTROUTING -s 10.0.0.0/8 -j MASQUERADE
echo "net.ipv4.ip_forward=1" >>/etc/sysctl.conf
sysctl -p
```



6) ssh server 上安装ppp包
```
#debian、ubuntu 执行下面命令
apt-get install ppp
#centos 执行下面命令
yum install ppp

```

7) openwrt 上手动执行/usr/bin/autopvpn.sh ，首次连接可能会提示是否接受服务器公钥，接受之后不会再提示，然后将autopvpn.sh 加入计划任务：
```
echo "*/1 * * * * /usr/bin/autopvpn.sh" >>/etc/crontabs/root
```
重新加载cron配置：
```
/etc/init.d/cron reload
```

## 2.Openwrt 防火墙配置 ##
在/etc/firewall.user 中添加（使用openvpn tap模式或pptp/l2tp，请注意修改命令中的接口名tun+为tap+或ppp+）：
```
#for pvpn normal
iptables -t nat -I POSTROUTING -o pvpn+ -j MASQUERADE
iptables -I FORWARD -o pvpn+ -j ACCEPT

#for openvpn and pvpn ssh layer 3 tunnel
iptables -t nat -I POSTROUTING -o tun+ -j MASQUERADE
iptables -I FORWARD -o tun+ -j ACCEPT
```
应用防火墙配置：
```
/etc/init.d/firewall restart
```

## 3.Openwrt安装dnsmasq\_patched ##
请根据自己的设备类型下载适当的包装包

  * [dnsmasq\_patched\_2.66-3\_ar71xx.ipk ](http://autovpn-for-openwrt.googlecode.com/svn/trunk/packages/dnsmasq_patched_2.66-3_ar71xx.ipk) (适用于基于Atheros：AR7xxx/AR9xxx的路由器，如tp-link wr703n，水星mw4530r等)
  * [dnsmasq\_patched\_2.66-5\_ramips\_24kec.ipk](http://autovpn-for-openwrt.googlecode.com/svn/trunk/packages/dnsmasq_patched_2.66-5_ramips_24kec.ipk)（适用于基于ralink：RT3x5x/RT5350主板的路由器，如华美a100,a1,a2）
  * [dnsmasq\_2.66-3\_ramips-dreambox-MIPS\_24KC.ipk](http://autovpn-for-openwrt.googlecode.com/svn/trunk/packages/dnsmasq_2.66-3_ramips-HuaWei_HG255D-dreambox-MIPS_24KC.ipk)（由网友提供，同样适用基于ralink：RT3x5x/RT5350主板使用dreambox 12.08.28系统的路由器）


上传到路由器，进行安装：
```
rm /tmp/opkg-lists/*
opkg remove dnsmasq
opkg install /tmp/xxx.ipk #请替换成您使用的包名
/etc/init.d/dnsmasq restart
```

非上述情况您只能自行下载dnsmasq 2.66 打上trunk中的[dnsmasq-autovpn.patch](http://autovpn-for-openwrt.googlecode.com/svn/trunk/dnsmasq-autovpn.patch)补丁编译，详见 [Dnsmasq编译 for openwrt](http://code.google.com/p/autovpn-for-openwrt/wiki/Dnsmasq_compile)。

注：因我手头设备有限，无法编译其它更多设备的ipk包，如有需要请提供设备型号，编译好后我会更新到本项目svn

## 4.将被墙域名加入dnsmasq ##
您可以直接使用本项目中的dnsmasq的示例配置文件[vpn.conf](http://autovpn-for-openwrt.googlecode.com/svn/trunk/vpn.conf)。
```
wget -O /etc/autovpn/vpn.conf http://autovpn-for-openwrt.googlecode.com/svn/trunk/vpn.conf
```

还可以按下面的方法自己生成被墙域名列表，以下操作要在linux下（非openwrt）完成：

1) 下载[gfwlist.txt](https://autoproxy-gfwlist.googlecode.com/svn/trunk/gfwlist.txt)，使用base64 解码
```
wget -O - http://autoproxy-gfwlist.googlecode.com/svn/trunk/gfwlist.txt| base64 -d  >gfwlist.txt
```
下载这两个脚本放同一目录下：[genDnsmasq.sh](http://autovpn-for-openwrt.googlecode.com/svn/trunk/script/genDnsmasq.sh) [autoproxy2domain](http://autovpn-for-openwrt.googlecode.com/svn/trunk/script/autoproxy2domain)

2) 生成dnsmasq配置：
```
genDnsmasq gfwlist.txt #后面增加 openwrt 参数生成的为openwrt 格式dnsmasq配置文件
```

如果您要翻墙的域名，没有在生成的域名列表中请自行添加。

如果主域名翻墙，其下的某个子域名不翻墙，如下配置(以google为例):
```
server=/google.com/8.8.8.8
server=/code.google.com/#
```

3) 将生成的dnsmasq.conf文件中的内容追加入到/etc/autovpn/vpn.conf文件，之后重启dnsmasq服务：
```
/etc/init.d/dnsmasq restart
```

## 5.下载路由表维护脚本 ##
```
wget -O /usr/bin/routeadd.sh http://autovpn-for-openwrt.googlecode.com/svn/trunk/script/routeadd.sh
chmod +x /usr/bin/routeadd.sh
```


至此配置完成

## 6.验证排错 ##
在openwrt检查vpn接口（pvpnXX tunXX）有没有生成：
ifconfig
如果没有看到vpn接口，检查是整可以通过密钥验证登陆ssh server，执行：
ssh -i .ssh/id\_rsa root@ssh-server
如果能顺利免密码登陆，请检查/etc/autovpn.conf 的配置。

如vpn接口已经存，在openwrt路由器上执行下面命令（请不要使用ping）：
```
nslookup <被墙域名> 127.0.0.1
```
然后通过route -n 查看刚刚解释出来的ip是否在路由表中，如果存在说明一切工作正常，否则按下面方法排错。

将routeadd.sh中的内容改为下面这样：
```
#!/bin/sh 		
echo $@ >>/tmp/info.txt 		
```

在openwrt上再次执行nslookup命令，查看info.txt文件的所有者及内容：
```
ls -l /tmp/info.txt 		
cat /tmp/info.txt 		
```

如果文件不存在，或所有者不为root，都是因为dnsmasq没正确配置。
如果info.txt所有者为root，且内容为ip地址列表，说明dnsmasq配置正确，但脚本没能正确把ip加入路由表，请向我报告bug。
如一切正常，请检查openwrt firewall.user 有无增加自定义规则，服务器检查iptables 规则、路由功能有无启用。

**另请注意**：电脑系统、手机系统、和dnsmasq都会缓存dns解析结果，在使用缓存中的dns结果时，不会触发调用脚本添加路由表的操作，所以调整dnsmasq配置后，请断开手机、电脑的网络，然后重新恢复网络连接，并在openwrt 上执行：
```
kill -HUP `pgrep dnsmasq` 		
```
来确保客户端和dnsmasq的缓存都被清除后，再进行测试排错的操作。