---
title: "Swoole 双工通讯服务端主动推送"
date: 2020-03-18T17:50:58+08:00
draft: false
tags: ["swoole"]
series: []
categories: ["开发记录"]
img: ""
toc: true
summary: "今天一直在探索，通过 Swoole 建立一个双工通讯后，怎么让服务端主动推送消息给用户。简单来说，客户端与服务端建立了长连接后（TCP，WebSocket)，服务端会主动轮询每个客户端的收件箱。如果发现有新消息，而长连接又存在，就通过长连接，主动推送给用户。"

--------------------------------------------------------------------------------------

今天一直在探索，通过 Swoole 建立一个双工通讯后，怎么让服务端主动推送消息给用户。

简单来说，客户端与服务端建立了长连接后（TCP，WebSocket)，服务端会主动轮询每个客户端的收件箱。
如果发现有新消息，而长连接又存在，就通过长连接，主动推送给用户。

最后发现，用 Swoole 的子进程就可以解决这个问题。代码如下：

```php
<?php

$serv = new Swoole\Server("127.0.0.1", 9501);

$process = new Swoole\Process(function($process) use ($serv) {
    $redis = new Redis();
    $redis->connect('127.0.0.1',6379);
    while(true) {
        foreach($serv->connections as $fd) {
            $message = $redis->rPop("test_$fd");
            if (!empty($message) && $serv->exists($fd)) {
                $serv->send($fd, "redis $fd: $message\n");
            }
        }
        sleep(1);
    }
});

$serv->addProcess($process);

//监听连接进入事件
$serv->on('Connect', function ($serv, $fd) {
    echo "Client: Connect. $fd\n";
});

//监听数据接收事件
$serv->on('Receive', function ($serv, $fd, $from_id, $data) {
    $serv->send($fd, "Server: ".$data."\n");

    if (trim($data) == "close") {
        echo "shutdown.... \n";
        $serv->shutdown();
    }

});

//监听连接关闭事件
$serv->on('Close', function ($serv, $fd) {
    echo "Client: Close.\n";
});


//启动服务器
$serv->start();

```
