---
title: "CommuneChatbot Demo 服务器搭建"
date: 2020-03-09T14:58:50+08:00
draft: false
tags: []
series: []
categories: ["开发记录"]
img: ""
toc: true
summary: "因为备案审批没通过, 要重新搭建一个香港的服务器. 而搭建流程都忘光光了, 只好重新趟一边, 记录下来."
---


CommuneChatbot 的官网服务器备案没通过, 再放下去要罚款.
只好重新买一个香港的服务器, 重新建站. 整个流程特别长, 真是麻烦死了.

之前的流程已经忘光光了, 这次长记性先开一个文档来记录.


## 服务器购买

略.

## 初始化

- useradd 创建用户
- passwd 设置密码
- /etc/sudoers 设置新用户管理员权限
- .bashrc 修改一下界面, 界面不习惯就活不下去
- /etc/vimrc 修改一下 vim 的界面

### ssh 修改

创建 ```~/.ssh```目录, 并确保目录权限正确.
上传用户私钥到 ```~/.ssh/authorized_keys```.

修改 ```/etc/ssh/sshd_config``` :

```
# 允许公钥登录
PubkeyAuthentication yes

# 允许登录客户端保活
ClientAliveInterval 60
ClientAliveCountMax 3

# 禁止密码登录
PasswordAuthentication no
# 允许指定用户
AllowUsers ****
```

参数 ```RSAAuthentication``` 已经弃用了, 见文章https://www.cnblogs.com/Leroscox/p/9627809.html.

重启 sshd :
```
systemctl status sshd
systemctl restart sshd
```

重启完后测试用密钥登录.

### 启动防火墙

```
systemctl start firewalld.service
systemctl enable firewalld.service
```

查看已经打开的防火墙:

    firewall-cmd --list-ports
    firewall-cmd --add-port=80/tcp --permanent
    firewall-cmd --add-port=443/tcp --permanent




## 安装开发运行环境


### yum 安装编译工具

```
dnf install gcc-c++
```

### yum 安装各种应用程序

[使用阿里的 yum 源](https://www.cnblogs.com/operationhome/p/11094493.html):

```
mv /etc/yum.repos.d/CentOS-Base.repo  /etc/yum.repos.d/CentOS-Base.repo.back

curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-8.repo

yum clean all
yum makecache

```


- git
- mysql: ```dnf install mariadb-server && dnf install mariadb```
- redis: ```dnf install redis```
- nginx: ```dnf install nginx```

启动服务:

```
systemctl start mariadb
systemctl enable mariadb
systemctl start redis
systemctl enable redis
```


### dnf 安装 php7

参考文章 https://www.php.cn/topic/php7/434093.html

注意是 centos-8, 不要和 7 的搞错了.

```
yum update && yum install epel-release

yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
yum -y install https://rpms.remirepo.net/enterprise/remi-release-8.rpm

# 验证
rpm -qa | grep remi

dnf -y install dnf-utils

dnf module install php:remi-7.4

dnf install php-pdo
dnf install php-opcache
dnf install php-redis
dnf install php-intl
dnf install php-swoole
```

安装 composer:

```
curl -sS https://getcomposer.org/installer | php
```

看情况使用阿里云镜像.

修改 php.ini :

- 内存设置大一点.


### supervisor

参考 https://www.cnblogs.com/maruko/p/9876782.html

安装 supervisor:

    dnf install supervisor

创建配置:

```
echo_supervisord_conf > /etc/supervisord.conf

```

修改 ```/etc/supervisor/supervisord.conf``` 修改 include, 将```/etc/supervisor.d/*.conf``` 配置文件引入.


### 安装 node

```
dnf install nodejs
```

### 安装 rasa


```
sudo dnf install python3-devel
sudo pip3 install -U pip

sudo pip3 install rasa
sudo pip3 install jieba


```

