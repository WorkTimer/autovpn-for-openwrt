# 介绍 #
Openwrt路由器自动智能翻墙方案，TCP/IP网络层实现，无需人为维护路由表，完全不影响正常上网。最少仅需500K左右的空闲flash空间。

翻墙需要解决两个问题：
  * 用什么翻
  * 哪些域名/IP需要翻

在此推荐使用ppp over ssh 来翻墙；让dnsmasq根据配置判断哪些域名需要翻墙，dnsmasq收到用户dns请求，判断域名是否存在配置中，如是解析出来的ip将被加入到路由表（或ipset），随后经过的流量按照路由表转发，就有选择的翻墙了。


上面的流程有两种实现方案，所用的组件有所区别：
  1. [dnsmasq维护路由表 （推荐）](http://code.google.com/p/autovpn-for-openwrt/wiki/Contents)
  1. [dnsmasq维护ipset ](http://code.google.com/p/autovpn-for-openwrt/wiki/Dnsmasq_Ipset) （OLD）

方法2是最原始的方案，组件多配置有些复杂，利用现有软件即可，文档不再维护；方法1是方法2的改进，组件少易配置，通过修改dnsmasq源码（增加--server-script 参数）+脚本 实现和方法2类似的功能。
