一般linux服务器端的pppd只允许root用户执行，普通用户要通过配置sudo才能执行。通过特殊的ssh配置，可以限制用户只能建立ppp over ssh的连接，不允许登陆到shell。

<font color='red'>注意：虽然限制了用户不能登陆到shell，但普通用户能以root身份运行pppd也是有风险的，比如pppd有未知漏洞可以得到shell的情况。</font>



# 配置 #
1) 新建用户，修改密码（密码不要分发给用户）
```
useradd sshvpn1 -m
passwd sshvpn1
```
2) 为用户生成密钥对
```
ssh-keygen -f id_rsa_sshvpn1 -N ""
```
3) 配置用户密钥验证,验证成功自动执行pppos.sh脚本
```
mkdir ~sshvpn1/.ssh
echo -n 'command="/usr/bin/pppos.sh",no-pty,no-agent-forwarding,no-port-forwarding,no-user-rc,no-X11-forwarding ' >>~sshvpn1/.ssh/authorized_keys  #注意最后的单引前面有空格
cat id_rsa_sshvpn1.pub >>~sshvpn1/.ssh/authorized_keys
```
4) 下载pppos.sh脚本到/usr/bin/pppos.sh
```
wget -O /usr/bin/pppos.sh http://autovpn-for-openwrt.googlecode.com/svn/trunk/script/pppos.sh
chmod +x /usr/bin/pppos.sh
```
5) 授权用户可以执行pppd
```
echo "sshvpn1 ALL = (root) /usr/sbin/pppd, NOPASSWD:/usr/sbin/pppd" >>/etc/sudoers
```

6) 把私钥文件:id\_rsa\_sshvpn1 分发给用户，ssh连接的时候使用此密钥验证。