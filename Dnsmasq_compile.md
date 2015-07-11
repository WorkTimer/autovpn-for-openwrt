# dnsmasq 编译 for Openwrt #

下载配置好的dnsmasq autovpn 版本源码：
```
#Barrier Breaker 14.07 用户下载以下包
wget http://autovpn-for-openwrt.googlecode.com/svn/trunk/packages/dnsmasq-14.07-2.71-src-autovpn.tar.gz

#attitude_adjustment_12.09 用户下载以下包
wget http://autovpn-for-openwrt.googlecode.com/svn/trunk/packages/dnsmasq-12.09-2.71-src-autovpn.tar.gz
```

以上源码包包含了 patch 和必要的所有文件，下载后解压替换掉源码目录中的dnsmasq。attitude\_adjustment\_12.09版源码替换 package/dnsmasq 文件夹，Barrier Breaker 14.07源码替换 package/network/services/dnsmasq 文件夹。

执行编译：
```
make package/dnsmasq/clean
make package/dnsmasq/compile V=99
```
bin/ar71xx/packages 下找到 编译好的ipk包，上传到openwrt 然后安装即可