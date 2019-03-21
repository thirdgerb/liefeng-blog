+++
date = "2016-07-20T17:32:55+08:00"
title = "install_hugo"
categories = ["开发记录"]
draft = false

+++

今天打算正式使用github的pages做博客. 安装了hugo试一试.

### 安装步骤

1.直接用homebrew 安装, 最快捷

    brew install hugo

2.用hugo创建一个站点的文件

    hugo new site myblog

3.在hugo的[http://themes.gohugo.io/]() 挑选了一个主题. 我选的是blackburn, 感谢作者!

4.安装主题
    
    cd themes
    git clone https://github.com/yoshiharuyamashita/blackburn.git

5.修改配置, config.toml 文件

6.创建第一个文件

    hugo new post/filename.md

7.生成页面! 用hugo serve 调试

    hugo
    hugo serve

因为事情比较多, 先写这一点点, 用做hugo的测试

### 遇到问题

之前没有注意到hugo new 生成时会查看 draft 属性, 连续几次都没生成文章. 完成草稿后要去掉toml段中的draft=true

