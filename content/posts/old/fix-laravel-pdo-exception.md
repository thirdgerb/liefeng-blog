+++
date = "2016-08-16T21:42:29+08:00"
summary = "用lumen的时候遇到了SQLSTATE[HY000] [2002] No such file or directory, 找了一下解决方法."
draft = false
tags = ["laravel"]
title = "解决了lumen的migrate报错的问题"
categories = ["开发记录"]

+++


用lumen, 运行```artisan migrate``` 的时候, 出现了报错 ``` SQLSTATE[HY000] [2002] No such file or directory ``` .

单步追查源码也没有发现问题所在. 结果google搜索, 在stackoverflow 立刻找到了解决办法:

    Laravel 4: Change "host" in the app/config/database.php file from "localhost" to "127.0.0.1"
    Laravel 5: Change "DB_HOST" in the .env file from "localhost" to "127.0.0.1"

链接:[http://stackoverflow.com/questions/20723803/pdoexception-sqlstatehy000-2002-no-such-file-or-directory](http://stackoverflow.com/questions/20723803/pdoexception-sqlstatehy000-2002-no-such-file-or-directory). 第二层答案.

答主调查后了解到, PDO如果使用```localhost```的设置, 会使用UNIX socket 去链接mysql. 但我的mysql替换成xampp的mariaDB后, .sock文件没有链到系统默认的位置. 所以就链接不上了. 如果填写```127.0.0.1```的话, PDO 走的是TCP, 所以就能读到了.

感谢该答主.
