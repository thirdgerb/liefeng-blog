+++
date = "2016-07-21T22:12:01+08:00"
draft = false
tags = ["服务器"]
title = "新服务器apache的设置"
categories = ["开发记录"]
summary = "把阿里云的服务器给退了, 换了conoha的服务器, 重新配置apache"

+++

把阿里云的服务器给退了, 换了conoha的服务器. 主要原因是阿里云不能科学上网, conoha的服务器看上去不错, 首先当然是能够用国外的节点, 然后流量没有约束, 价格还和阿里云差不太多. 

换了服务器后环境又要重新搭. 不过昨天踩坑最严重的firewall-cmd开启端口的问题已经熟悉了. 今天重点学习配置xampp的apache

记录一下要点. 可能有各种错误

### apache分配独有账号

    useradd -g www -M -s /sbin/nologin httpd

### 创建web访问目录

创建了一个www用户
然后把/var/www给他

    chown www:www /var/www

很多路径组权限要给到5, 有些路径要给到7, 挺麻烦的, 应该有更好的办法

### httpd.conf 的配置

-   htdocs 改成 require local
-   加载httpd-vhost.conf
-   只需要解析80端口, 请求在hosts里绑定一个地址就能做测试用



### 系统配置

配置时又遇到了外网无法访问的问题, 还是这个原因

    firewall-cmd --zone=public --add-port=80/tcp --permanent

期间改了几个ssh的配置, 禁止管理员意外的所有用户用ssh登录.要重启一下service

    systemctl restart sshd.service

