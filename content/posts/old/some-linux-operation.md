+++
date = "2016-08-22T09:53:31+08:00"
description = "今天要手动初始化一个centos的环境.把中间的操作都记录一下."
draft = false
categories = ["开发记录"]
tags = ["服务器"]
title = "linux操作相关的命令随手记"

+++

今天要手动初始化一个centos的环境.把中间的操作都记录一下.

## 创建新用户流程

1.  useradd 添加用户
2.  passwd 修改用户密码
2.  usermod  修改用户组
4.  修改 /etc/sudoers 添加sudo权限
5.  用户目录~/.ssh/, 添加authorized_keys
6.  修改/etc/ssh/sshd_config , 允许用户登录
7.  必须记得 修改 ~/.ssh 的权限为700

## 修改服务器名称

给服务器取个名字, 再修改下hosts

## 配置yum的源

    cd /etc/yum.repos.d

推荐什么源好呢?

### 禁用账号

    usermod -L <username>

##

忙起来完全没有时间记录, 先不记了

