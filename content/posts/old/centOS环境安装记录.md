+++
date = "2016-07-20T18:29:19+08:00"
description = ""
tags = ["服务器"]
title = "centOS环境安装记录"
categories = ["开发记录"]

+++

> 今天买了阿里云的服务器, 准备安装一套环境, 把过程记录一下

##  目标

打算安装这些:

-   PHP7
-   Apache2.2
-   mysql or MariaDB
-   redis
-   memcached
-   yaf
-   swoole
-   nginx
-   mongoDB

一个一个来.

## 系统设置

### 修改.bashrc

忍不了没有颜色的命令行, 所以第一步是配置.bashrc, 顺便添加了几个常用alias

-   配置.bashrc
-   配置.bash_alias
-   配置.vimrc


### 添加用户

1.  创建用户
2.  给用户添加root分组,并设置到sudoers 中
3.  给用户添加authorize key
4.  考虑要不要禁止root的登录;还是留着吧

### 遇到问题

-   遇到``` break pipe ```是因为闲置断开. 在服务端或客户端设置轮询可破

## 系统环境

可以直接用yum安装:

-   gcc
-   gcc-c++
-   libevent
-   autoconf
-   lsof

都是用阿里云自己的镜像, 安装速度非常快

## 安装xampp

xampp 比较方便, 直接选择安装它了. 

-   从xampp官网下载.run文件
-   scp到服务器的/opt/目录
-   直接运行run
-   把xampp和/opt/lampp/bin 下的命令变成可直接使用

## 安装php常用扩展

-   memcache
-   swoole
-   yaf

都没装上, php7要单独操作

## 设置apache

-   创建vhosts, 建立.conf文件
-   取消默认监听80端口
-   添加www用户和www用户组
-   修改httpd的默认用户为www,www

### 遇到问题

-   no listen socket available
-   httpd.conf 默认没有引入vhosts
-   linux 要开启对外的端口?? 原来是centos 7 的防火墙关闭了. 坑死人了
-   apache 的vhosts配置, 折腾了几个小时, 不知道为什么好了


