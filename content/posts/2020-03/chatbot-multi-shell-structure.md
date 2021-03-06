---
title: "Commune v0.2 对话机器人的多端架构设想"
date: 2020-03-27T16:52:53+08:00
draft: false
tags: ["commune", "chatbot"]
series: ["commune开发笔记"]
categories: ["开发记录"]
img: ""
toc: true
summary: "简单来说, 一个机器人可以同时有很多个 I/O 端, 例如 音箱/微信/网页 等. 这些 I/O 端相当于同一个机器人的 眼睛/耳朵/嘴巴/手脚 等肢体.所有的肢体都有独立的输入和输出, 但都由一个统一的中控来决策. 中控拥有唯一状态.任何一个端的输入, 所有的端都作出响应."
---

我现在把 [CommuneChatbot](https://github.com/thirdgerb/chatbot) 项目当成一个试验平台,
用来探索一些对话机器人的新思路. 目前正在开发 v0.2 版本.

相比 v0.1, 新版本几乎是重构一遍. 主要原因有两个:

- 试图实现多端机器人
- 试图实现可以在线热修改思维的动态机器人

本文着重谈谈前一个思路.

## 1. 什么是多端机器人?

举个例子, 我电脑浏览器打开了一个网页, 然后对着智能音箱说话, 网页内容随着我的命令而变化.
网页, 智能音箱是完全隔离的两个端, 但被同一个机器人管理着.

简单来说, 一个机器人可以同时有很多个 I/O 端, 例如 音箱/微信/网页 等.
这些 I/O 端相当于同一个机器人的 眼睛/耳朵/嘴巴/手脚 等肢体.
所有的肢体都有独立的输入和输出, 但都由一个统一的中控来决策.
中控拥有唯一状态.
任何一个端的输入, 所有的端都作出响应, 就像 "手舞足蹈".

我暂时管这样的机器人叫多端机器人.

或许叫多模态机器人更合适, 但多模态这个词一般都是机器学习领域在用,
每每让他们产生很多歧义的联想, 尽量先不说多模态.


## 2. 多端架构解决了什么问题?

一系列现实的应用动机, 使得 CommuneChatbot 的设计思路走向了多端机器人. 我举几个例子:

### 2.1 多平台机器人

[CommuneChatbot](https://github.com/thirdgerb/chatbot) 虽然还不是一个多端的机器人, 但已经实现了多平台.
它在 网页/API/微信/百度音箱 四个端上是同一个机器人, 使用相同的数据表和缓存, 记忆也是互通的.
事实上, 我可以通过在微信端使用对话命令投递消息, 直接发给智能音箱端的用户.
只要这个工程方案更进一步, 让多个端通过某种广播机制互通消息, 就可以进化成多端机器人.

### 2.2 对话OS

过去很长一段时间, 我认为对话 OS 必须有操作系统权限才能实现.
所以只有苹果/华为/小米 这类独占操作系统的公司, 才能开发对话交互界面 (例如Siri).
后来思考多模态方案, 发现并不是如此.
任何一个 APP 只需要一个 SDK 和跨设备的鉴权机制, 就可以和任何一个智能耳机进行对话互动,
只需要服务端做到一致性的状态同步.
这里面主要需解决的是工程问题.

### 2.3 数据展示2.0

和一位大数据从业者交谈, 他们想做 "数据展示2.0".
可以通过语音互动, 改变数据展示屏上的信息.
我当时就觉得这很好做, 只需要 Chatbot 对话中改变网页所需的环境变量.
而数据展示网页, 通过双工通道或轮询, 获取这些环境变量然后自我改变就好.
这是一个极简的策略, 缺点是无法通用.

### 2.4 智能音箱显示屏

好一点的智能音箱会带一个可以互动的屏幕.
但我觉得屏幕应用的开发实在太麻烦了, 开发功能远远不如 web 应用或小程序完善.
同时又与服务端强耦合, 服务端必须直接下发屏幕需要显示的内容.

CommuneChatbot 本身是跨平台通用机器人, 为了同时兼容 Wechat 和 DuerOS,
我专门开发了不同端上的 ReplyRender 功能, 每个端可以把相同的消息抽象渲染成本端独特的回复.

如果这套方案用在 音箱 + 显示屏 上, 显示屏完全可以用全套 Web 工具独立开发,
然后与语音交互同步. 两块彻底解耦, 问题变成同一个回复, 每个端应该如何渲染.

### 2.5 对话网页双模态

[CommuneChatbot 主站](https://communechatbot.com) 上尝试了一个伪双模态.
在对话框里对话时, 点击右上角的 "<>" 图标, 可以看到对话机器人当前逻辑的源代码.
同时, 点击网页左边的菜单按钮, 又可以改变对话的内容.

之所以是 "伪双模态", 因为我没时间做一个网页版的 Websocket 双工通道, 让页面自动更新.
但实际上已经实现了对话框和网页的状态同步.

### 2.6 对话冒险游戏

项目 Demo 做了三个小游戏: 迷宫/[疑案追声 Demo](https://communechatbot.com/?scene=unheard)/[大战长坂坡](https://communechatbot.com/?scene=story).
其实我一直想给这些游戏配上图片, 并加上用按钮交互的功能.

进一步的, 这其实已经是一个完整的 视觉 + 听觉 小说引擎了.
当对话机器人状态改变时, 可以同步下发包括 "画面背景/人物立绘/背景音乐/动画效果" 的信息, 让网页作出视觉小说游戏般的变化. 当然的代码成本很高, 但作为引擎, 技术上已经可行了.

### 2.7 机器人后门

CommuneChatbot 上线后, 因为没有精力研发管理后台, 我把管理功能直接做成了多轮对话模块.
而用户在各个平台上的对话内容, 还得上服务器 tail 日志去查看.
我一直想给机器人做几个后门, 例如像 Wechat 等即时通讯一样的界面, 直接同步查看机器人与用户的对话, 甚至可以插进去真人的回复.
这实际上就要实现单一机器人同时和两个以上的端进行交互, 并保持唯一状态.

## 3. 不再是 "对话机器人"

CommuneChatbot 最早是一个 "对话机器人", 重点放在了复杂多轮对话的状态管理上.

但它作为一个多端机器人的内核, 就不仅仅是 "对话机器人" 了. 语言只是众多输入输出模态的一种罢了.

进一步的, Intent (意图) 也不再是一个 "自然语言问题" (NLP), 而是 "通用指令" 的抽象.
Intent 可以来自语言, 也可以来自按钮, 来自命令, 来自 API 接口.

## 4. Ghost In Shells

目前的设计思路参考了动画 Ghost in the shell.
机器人的单一状态管理中枢 (原来的多轮对话管理内核), 现在称之为 Ghost.
接入 Ghost 的每个端都是一个独立的 Shell.

Ghost 和 Shell 都是服务端实例, 都可以分开来进行分布式部署.
Shell 通常像调用微服务那样, 和 Ghost 进行互动.

Ghost 和 Shell 既有同步通讯, 也有双工通讯. 而 Shell 和客户端也有同步模型和双工模型.

同一时间只允许一个 Shell 给 Ghost 发送信号, 避免 "裂脑". 而 Ghost 的响应既有对该 Shell 的同步回复, 也可以有跨平台的广播. 每一个 Shell 有自己独立的一套响应机制. 双方都通过高度抽象的 Message 进行通讯.

## 5. 一些可能的应用

CommuneChatbot v0.2 的探索, 应该要实现几个关键的 Demo :

1. 智能音箱与网页的互通.
2. 机器人管理后门

智能音箱和浏览器网页, 是完全不同的两个端. 网页是可以通过 websocket 搭建双工通道的,
智能音箱可能实现双向通讯的还少, 大多是同步响应.

只要可以与智能音箱对话, 改变浏览器网页内容, 那么各种跨平台的对话 OS 在技术上都可以实现了.
这某种意义上会改变智能音箱的生态.

例如在智能音箱上播放网易云音乐, 是智能音箱调用网易云音乐的接口, 提供服务.
而以后对智能耳机下命令, 手机上的网易云音乐 App 自动播放/切歌, 变成了 App 使用智能耳机的服务.

一旦如此, 智能音箱这种软硬件一体的设备就会像当初的 随身听/收音机 一样被淘汰掉. 语音 OS 只需要是软件就可以了.


另外一个应用是做机器人管理的后门.
我想做到用户在 网页/微信/智能音箱 上与应用对话, 我都可以通过另一个界面实时看到, 还可以实时回复, 甚至可以控制对话机器人的状态.

这里面涉及到一个核心技术, 把对话状态中的 "task" 跨越 Chat 传递, 就像传皮球一样.
具体效果很像各种工作流应用, 张三提交流程给李四审批, 李四审批完转到王五, 最后才回送给张三.
关键的技术难点在于多轮对话状态管理中的 Yield 和 Retain.

这里面的思路未来有机会再写了.



