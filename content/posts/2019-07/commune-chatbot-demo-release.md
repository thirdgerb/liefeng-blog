---
title: "多轮对话机器人框架 commune/chatbot 项目的demo发布"
date: 2019-07-18T13:33:23+08:00
draft: false
tags: ["commune-chatbot"]
series: ["commune开发笔记"]
categories: ["开发记录"]
img: "/img/commune-chatbot-test1.png"
toc: true
summary: "离职在家, 一个人历经三个多月的时间, 多轮对话机器人框架 commune/chatbot 项目终于完成初步开发. 第一个 demo 终于发布到微信公众号了!"
---

commune/chatbot 的第一个demo 终于发布了!. 本项目是一个基于 php 开发的多轮对话机器人框架, 作者是 thirdgerb@gmail.com


它能用工程结合配置的方式, 开发各种能完成复杂多轮对话机器人, 可用于即时通讯软件和语音平台.

![test1](/img/commune-chatbot-test1.png)

![test2](/img/commune-chatbot-test2.png)


## demo 地址:

请使用微信扫描二维码, 进入微信公众号可以测试:

![qrcode](/img/commune-qrcode.bmp)

(强烈推荐用桌面版微信测试)

或者在微信内搜索公众号: CommuneChatbot


## 什么是对话机器人

对话机器人, 指用户可以通过文字或语音对话理解用户的意图, 执行各种任务并将信息反馈给用户的机器人.

常见的应用有:

- 智能客服
- 智能音箱
- 智能无限耳机
- 声控智能家居
- 语音电话机器人
- 问答机器人
- 对话知识库
- 闲聊机器人
- 等等

## 对话机器人的构成

我理解对话机器人整体上有三大模块, 分别是:

- 交互层 : 人接触的设备, 例如微信公众号, 智能音箱等
- 语义解析层 : 将传入数据统一抽象, 并解析成软件能识别的数据结构
- 对话管理层 : 负责处理上下文逻辑, 调用服务, 生成回复等.


commune/chatbot 项目则有两大部分:

- framework (框架) : 负责接入交互层, 对接语义模块, 再到对话管理层的整个管道.
- host (对话管理) : 负责实现复杂多轮对话的管理.


## 什么是多轮对话

按对话上下文关系分, 对话机器人有三类:

- 单轮对话
- 简单多轮对话
- 复杂多轮对话

单轮对话, 就是用户每次输入都当第一次输入对待. 现在常见的智能音箱就是这种.

简单的多轮对话, 在识别任务后 (比如查询天气), 会用几轮对话来要求用户输入更多信息 (比如所在城市, 查询的日期), 信息充足后调用 api 执行逻辑.


单轮对话, 是每句话之间没有上下文关系. 简单多轮对话, 是每一轮对话之间没有上下文关系.

人类真正的对话是分形几何式的, 一大段对话可以分成很多小段, 每一小段又分成几段, 直到拆分成一句话. 每一句话, 每一段话之间都是上下文相关的. 一段对话同时可能有多个任务在进行.


这需要实现各种特性 :

- 分型几何结构
- 上下文记忆
- 语境跳转
- 语境隔离
- 语境脱出
- 语境挂起
- 多任务调度
- 分布式一致性

commune/chatbot 给以上特性提供了一种工程化的初步解决方案, 具体可以在demo中查看.

## 多轮对话的两种实现, "工程"和"学习"

实现多轮对话有两种做法. 工程方法需要编程来写死多轮对话的逻辑, 而学习方法可以从大量多轮对话语料中, 用机器学习使机器人掌握的回复, 例如 rasa core .

机器学习更偏重于"对话", 而工程方法则能够对每一轮对话的处理逻辑进行编程. 机器学习更适合在积累大量对话语料之后, 掌握更灵活的对话逻辑. 而工程的手段则可以快速从无到有开发一个对话应用.

两种实现方法互有利弊, 未来的趋势一定是有机地结合起来. commune/chatbot 目前是偏工程的, 旨在让程序员像开发 app, web 网站一样规范, 快捷地开发多轮对话应用.

## commune/chatbot 项目地址

本项目目前还在开发中, 文档还没有完善. 可以到 github 上查看源码.

- chatbot : 核心开发框架, 地址 https://github.com/thirdgerb/chatbot
- chatbot-laravel : chatbot 应用到 laravel 中的package, 地址 https://github.com/thirdgerb/chatbot-laravel
- chatbot-wechat : 基于 chatbot-laravel 的微信包. https://github.com/thirdgerb/chatbot-wechat
- chatbot-studio : 基于 laravel 的完整框架. https://github.com/thirdgerb/chatbot-studio

## commune/chatbot 的技术实现

commune/chatbot 项目选择用 php 语言来开发.

首先因为 对话机器人 更适合用 "解释型" + "弱类型" 语言, 开发调试方面都有很大的便利. 所以作者在设计时没有选择 java 或者 go.

而本项目在设计思路上, 同时大量使用面向对象和函数式变成的思路. 需要语言对两种编程风格都有足够的支持. php 是胜任的.

最根本的原因是作者比较熟悉 php 的高级特性, 实现关键的思路比较顺手.


本项目主要用到的组件有:

- php 组件:
    - [swoole](https://www.swoole.com/) : 用于启动服务 (tcp, web等)
    - [symfony](https://symfony.com/) : 使用各种组件
    - [laravel](https://laravel.com/) : 使用各种组件
    - [easywechat](https://easywechat.com) : 搭建 wechat 服务
    - monolog : 日志
    - phpunit : 单元测试
    - preds : 连接redis
- nlu (自然语言单元):
    - rasa nlu : 提供自然语言识别服务
    - jieba : 中文分词
    - mitie : 训练中文词向量模型


## 下一阶段的开发

commune/chatbot 项目还在初步开发阶段. 我个人希望它能成为一个正式的, 有用的开源项目. 所以接下来仍会往这个方向推进:

- 应用到具体产品上
- 发布第一个正式版本
- 编写使用文档
- 搭建网站

如果有用户需求, 就优先完善网站和文档. 如果初期没有别的用户需求, 我应该会推进用它开发产品, 证明使用价值. 初步考虑实现一个智能音箱的demo.

## 关于作者

本人多年从事互联网服务端的开发工作. 自己设计的几个产品, 都曾想用对话的方式来实现.

但主流的多轮对话开发框架, 如 [hubot](https://hubot.github.com/), [botman](https://botman.io/) 等, 没有实现复杂多轮对话的能力, 无法满足我的需求.

因此, 当我认为积累的设想足够能实现时, 就辞掉工作, 独立开发了这个框架.  由于攻克核心技术难度较大, 也遇上一些家务事, 历时三个多月才初步开发完成. 比预期多了一半的时间.

如对此项目有了解的兴趣, 请关注公众号, 或者与我联系(thirdgerb@gmail.com).  交流QQ群: 907985715
