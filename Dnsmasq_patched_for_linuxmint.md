# 配置vpn #
略（详见 [Dnsmasq\_Patched for openwrt](https://code.google.com/p/autovpn-for-openwrt/wiki/Dnsmasq_Patched#1.%E5%BB%BA%E7%AB%8Bvpn%E8%BF%9E%E6%8E%A5%28%E4%B8%89%E9%80%89%E4%B8%80%29)）

# 安装Dnsmasq #
首先要说明一下，目前大多数linux桌面发行版的NetworkManager已经集成了dnsmasq插件，所以系统里已经安装了dnsmasq。

以linuxmint为例，dnsmasq-base 包默认被安装，该包包含 dnsmasq 的可执行文件，而且dnsmasq进程会随NetworkManager的启动而启动。为了实现翻墙我们所要做的是，下载相同版本的dnsmasq源码，打补丁编译（configure时要启用 dbus --enable-dbus），然后用生成的可执行文件替换系统现有的可执行文件。

为了降低配置难度，我已经制作好了64位 deb 包。用的官方源里 dnsmasq-base 的源码，打完补丁编译制作的，所以包的质量是有保证的，您直接下载安装替换系统现有的包即可。
  * [linuxmint16 x64 dnsmasq-base](http://autovpn-for-openwrt.googlecode.com/svn/trunk/packages/dnsmasq-base_2.66-4ubuntu1_amd64.deb) (理论上ubuntu 13.10也适用)
  * [linuxmint17 x64 dnsmasq-base](https://autovpn-for-openwrt.googlecode.com/svn/trunk/packages/dnsmasq-base_2.68-1_amd64.deb) (理论上ubuntu 14.04也适用)

下载后执行下面命令安装：
```
dpkg -i <包路径/dnsmasq-base_2.66-4ubuntu1_amd64.deb>
```

如果你使用的linux发行版不在上面列表中，需要您自行打补丁编译。下载dnsmasq 2.66的源码解压，源码目录下src/config.h文件：
```
/* #define HAVE_DBUS */
改为
#define HAVE_DBUS
```
编译完成后将src/dnsmasq 文件复制到 /usr/sbin/ 目录下替换原来的可执行文件，重启系统。

接下来还要安装dnsmasq包，这个包是一些可供用户管理的配置文件和启动脚本：
```
sudo apt-get install dnsmasq
```

# 配置 #

下载 gfwlist.txt，使用base64解码，得到被墙域名列表:
```
wget https://autoproxy-gfwlist.googlecode.com/svn/trunk/gfwlist.txt -O -| base64 -d  >gfwlist.txt
```
下载这两个脚本放同一目录下：[genDnsmasq.sh](http://autovpn-for-openwrt.googlecode.com/svn/trunk/script/genDnsmasq.sh) [autoproxy2dnsmasq](http://autovpn-for-openwrt.googlecode.com/svn/trunk/script/genDnsmasq.sh)

将被墙域名列表转换成dnsmasq配置格式：
```
genDnsmasq gfwlist.txt
```

将生成的dnsmasq.conf文件中的内容加入到/etc/dnsmasq.conf 文件的最后，并加入以下两个配置,之后重启dnsmasq服务：
```
server_script=/usr/bin/routeadd.sh
user=root
```

下载路由维护脚本，添加执行权限：
```
wget -O /usr/bin/routeadd.sh http://autovpn-for-openwrt.googlecode.com/svn/trunk/script/routeadd.sh
chmod +x /usr/bin/routeadd.sh
```

重启dnsmasq：
```
sudo /etc/init.d/dnsmasq restart
```

到此配置完成。


# 验证排错 #
在配置好的主机上，打开终端，ping <被墙域名>，再通过route -n 查看刚刚解释出来的ip是否在路由表，如果存在说明一切工作正常，否则按下面方法排错。

将routeadd.sh中的内容改为下面这样：
```
#!/bin/sh
echo $@ >>/tmp/info.txt
```

然后查看info.txt文件的所有者及内容，
```
ls -l /tmp/info.txt
cat /tmp/info.txt
```
如果文件不存在，或者所有者不为root，都是因为dnsmasq没正确配置。

如果info.txt所有者为root，且内容为ip地址列表，说明dnsmasq配置正确，但脚本没能正确把ip加入路由表。首先请检查脚本里VPN接口名在系统中是否存在。如一切正常，请联系我。

**另请注意**：电脑系统、手机系统、和dnsmasq都会缓存dns解析结果，在使用缓存中的dns结果时，不会触发调用脚本添加路由表的操作，所以调整dnsmasq配置后，请断开手机、电脑的网络，然后重新恢复网络，并在openwrt 上执行：
```
sudo kill -HUP `pgrep dnsmasq`
```
来确保客户端和dnsmasq的缓存都被清除后，再进行测试排错的操作。