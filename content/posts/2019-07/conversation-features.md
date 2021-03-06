---
title: "对话机器人的关键功能点(一) : N阶多轮对话的分形结构"
date: 2019-07-22T21:08:32+08:00
draft: false
tags: ["commune", "chatbot"]
series: ["commune开发笔记"]
categories: ["开发记录"]
img: ""
toc: true
summary: "多轮对话机器人已经广泛地应用在智能客服, 智能音箱等领域. 但目前在对话管理方面的实现还存在许多不足. 我认为要达到成熟的应用级水平, 有9个功能点是必须实现的.本文讨论的是N阶多轮对话的分形结构"
---


多轮对话机器人已经广泛地应用在智能客服, 智能音箱等领域. 它在技术上应该可以大致分拆成四个部分:

-   对话平台 : 负责获取和输出信息 ( 文字, 语音 或其它多媒体 )
-   语义理解 : 负责将用户信息解析成数据结构
-   对话管理 : 负责执行用户意图, 生成反馈信号
-   输出合成 : 将反馈信号合成为文字或语音给用户

每个领域都存在许多技术难点. 而本文着重讨论 "对话管理" 领域的 "复杂多轮对话"问题.

以我有限的了解, 目前 "复杂多轮对话" 的实现还存在许多不足. 要 达到成熟的应用级水平, 无论用机器学习还是用工程手段, 以下10个功能点都是需要实现的.

-   N阶对话的分形结构
-   语境隔离
-   语境跳转
-   语境脱出
-   语境导航
-   上下文记忆
-   分布式一致性
-   语境挂起与唤醒
-   多任务调度
-   遗留语境唤醒

我是 "多轮对话机器人框架" [CommuneChatbot](https://github.com/thirdgerb/chatbot-studio) 的作者.

这篇文章与大家分享我对以上技术问题的个人理解, 今天先讨论"N阶多轮对话的分形结构". 先说明我本人还不是正规的从业者, 因此观点仅供分享, 希望大家批评指教.



## 什么是对话管理


目前对话机器人的实现上, "语义理解" 和 "对话管理" 是两个独立的模块 ( 未来会日渐紧密地结合在一起 ) . 对许多不从事对话机器人开发的朋友而言, 两者的区别可能还分不太清楚.

简单而言, "语义理解" 是负责搞明白用户说了什么, 并将之解析成机器适合处理的数据结构. 而 "对话管理" 则是拿到语义数据后, 要能让服务器或设备正确执行任务, 并给用户反馈.

它们之间的关系, 就像是 "遥控器" 和 "电视机" 一样. 无论是 "遥控器" 听不懂用户的命令, 还是 "电视机" 不能正确换台, 这个机器都是用不了的.

## 单轮对话

对话中的 "单轮", 指的是用户说一句话, 机器人回复一句话, 构成一个回合.

最简单的对话机器人是 "单轮" 的. 用户的每一句话, 对机器人而言都是全新的. 用户前面说了什么, 后面将要说什么, 对话管理模块不需要担心.

最常见的闲聊机器人就是这种. 只要 "语义理解" 模块正确识别了用户的意图, 机器人只要从语料库挑一个恰当的回复就行了. 技术难度在于回复什么, 在于如何搜集海量的语料喂给机器人.

[CommuneChatbot](https://github.com/thirdgerb/chatbot-studio) 目前的 "闲聊" 功能就是用一个 yaml 配置实现:

https://github.com/thirdgerb/chatbot-studio/blob/master/commune/data/chats/demo.yml

## 多轮对话

当用户的一个意图, 不一定能一句话完成, 而需要进行多轮的对话, 这就是一个"多轮对话" 问题.

例如

    // 单轮完成的对话:

    用户: 北京明天的天气怎么样?

    机器人: 北京 猴年-马月-狗日 的天气是blah blah blah...

    // 需要多轮的情况:

    用户: 明天的天气怎么样?

    机器人: 请问您想了解哪个城市的?

    用户: 北京    // 补充城市信息

    机器人: 北京 猴年-马月-狗日 的天气是 blah blah blah

    用户: 后天呢?  // 延用城市信息

    机器人: 北京 猴年-马月-猪日 的天气是 blah blah blah


可以看到用户补充了信息, 机器人才能获得完成任务的必要参数. 常见导致多轮对话的原因有:

-   要用户补充信息
-   要用户做选择
-   非同步任务 ( 需要一定时间后才能完成 )


## 复杂多轮对话

在 "单轮" 对话系统中, 每一回合的对话之间都是上下文无关的. 我个人称之为 "0阶对话" .

而在 "简单多轮对话" 系统中, 每一组的多轮对话之间, 又可能是上下文无关的. 我个人称之为 "1阶对话".


如果好几轮的多轮对话之间, 也存在逻辑和上下文关联, 这就是 "复杂多轮对话"问题, 我也称之为 "n阶对话".

假设某公司有一个在内部IM上运行的"助理机器人", 这是一个复杂多轮对话例子.:


    /*---- 多轮对话 1 : 选择任务 ----*/

    用户: 公司的助理机器人, 你好!

    机器人: 您好, 请问有什么可以为您做的?

    用户: 你能做什么?

    机器人: 我能请假, 销假, 报销发票

    用户: 我要报销发票

        /*---- 多轮对话 1.1 : 获取发票信息 ----*/

        机器人: 请问您想报销哪几个月的发票?

        用户: 四,五,六 三个月的.

        机器人: 好的, 请问您需要报销哪些类型的?

        用户: 餐饮, 打车的发票.

            /*---- 多轮对话 1.1.1 : 获取餐饮发票信息 ----*/

            机器人: 好的, 我们先报销餐饮. 请问您要报销多少钱?

            用户: 625元.

            机器人: 请您提交足额的发票pdf

            用户: [发票1], [发票2], [发票3]

            // 参数校验
            机器人: 您好, 发票2 的时间不对, 请重新提交

            用户: 不好意思, 这是 [发票4]

            机器人: 收到.

            /*---- 多轮对话 1.1.2 : 获取餐饮发票信息 ----*/

            机器人: 我们继续报销打车的发票. 请您提交打车的行程单

            用户: 这是 [行程单]

            // 识别图像
            机器人: 识别总共700元, 请您提交足额的发票

            用户: 这是xx公司的发票

            机器人: 收到!

        /*---- 多轮对话 1.1 : 获取发票信息 ----*/

        机器人: 您好, 餐饮和打车发票我已收到. 请问还有别的报销需求吗?

        用户: 木有了.

    /*---- 多轮对话 1 : 选择任务 ----*/

    机器人: 好的. 请问您还有别的事情需要我做吗?

    用户: 没有了, 拜拜, 公司的助理机器人.

    机器人: 好的, 再见, 希望下次继续为您服务.



在这个例子中, 出现了四个对话任务的嵌套:

-   选择任务
    -   提交发票信息
        -   提交餐饮发票
        -   提交打车发票

它们四组相互嵌套, 构成了一个 "3阶多轮对话". 父任务被分成了多个子任务, 子任务又有子任务, 子任务完结后回调父任务, 父任务完结后继续回调父任务.

对于任何一个父级对话, 它都可以不关心子对话的过程, 也不用关心子对话嵌套了多少级, 它只要关心子对话的结果, 专注于自己的流程就好了.


## N阶多轮对话的分形结构


人类自然语言的对话, 整体呈现出一种分形几何的结构. 一场大的对话, 可以分割成若干个子对话; 每一个子对话, 又分割为若干子对话; 每一个子对话, 又分割成若干个子对话 ... 直到分割成一问一答的 "0阶对话".

每一阶多轮对话都有相似的结构, 和我们程序员写的function是一样的, 有入参, 开始, 结束, 异常. 因此多轮对话也会像function 一样, 在子代中调用自身, 从而出现递归调用.


在完整的N阶多轮对话树中, 每一个节点的信息都可以被任何一个节点用到 ( 上下文记忆问题 ), 而这些信息可能又是相互隔离的.

而一个子任务完结后, 会跳转到另一个子任务, 还是返回到父任务, 这也完全取决于上下文 ( 语境跳转问题 ).

如果一个子任务因故要终止, 比如用户取消, 用户无权限, 发生错误等; 那它应该退回哪一个任务呢 ? 这同样取决于上下文 ( 语境脱出问题 ).


所以复杂多轮对话最核心的问题就在于此. 如果各种 "语义理解" 算法, 解决的是某一句话的代数解析问题; 那 "对话管理" 模块, 则要能代数地模拟出"N阶多轮对话分形结构" 的问题.

这对于开发一个足够可用的多轮对话机器人, 是必须跨过的门槛.

## 机器学习思路与工程思路

我三四年前想用对话机器人开发应用的时候, 还没有想过自己开发一个[CommuneChatbot](https://github.com/thirdgerb/chatbot-studio) 这样的框架. 但一直没有找到任何一个合适的.

以我所见, 有两种类型的解决方案:

-   机器学习实现
-   工程方法实现


机器学习的实现, 是把对话中的每一回合对话当成一个位点, 把上下文解析成代数形式, 交给机器学习去训练模型, 让模型预测当前所在的节点.

[Rasa.core](https://rasa.com/) 就是一个典型的例子. 它需要开发者提交设计好的对话文档.


而另一种方案是基于工程的. 程序员自己手写多轮对话的逻辑, 用正则等方式去匹配. 例如

-   [hubot](https://hubot.github.com/) : github 官方出品, 15k stars
-   [botkit](https://botkit.ai/) : 微软的机器人框架, 9.3 k 赞.
-   [botman](https://botman.io/) : php 实现的机器人, 4.5 k 赞.

其中多轮对话的能力, 微软的 botkit > botman > hubot .

但我看到即便是微软 botkit, 似乎也主要实现 "1阶多轮对话", 还实现不了我所需要的更复杂对话的功能.

## CommuneChatbot 项目对 "n阶多轮对话" 的实现


我在设计 [CommuneChatbot](https://github.com/thirdgerb/chatbot-studio) 有一个基本的哲学观点. 这就是: '''对话机器人的本质是人机交互''' .

我没有把 "对话机器人" 设想成取代真人的工具 ( 比如智能客服 ), 而认为它是一种和 桌面操作系统, 浏览器, shell 命令行一个本质的交互形式.

把每一轮对话视作一次"交互", 那么 "n阶多轮对话" 问题, 就变成了 "n阶交互操作" 问题.

而在操作系统, 或者在浏览器中, 所有的交互都是有上下文的. 同样 "n阶的多轮交互" 也存在着分形结构.


所以结论很明了, 用开发 "操作系统", "软件", "网站", "触屏app", "命令行工具" 类似的工程思路, 也能够解决 "n阶多轮对话" 的需求.

能够让开发对话机器人至少和开发网站一样快, 甚至更快, 因为设备依赖更少, 平台更通用.


所以我综合了其它交互形式上的工程经验, 开发了 [CommuneChatbot](https://github.com/thirdgerb/chatbot-studio) 项目. Demo 已经上线, 无论是作为工程师开发 Demo 的体验, 还是作为用户测试 Demo 的体验, 我个人都比较满意.

这里面涉及的技术细节比较多, 就留到未来逐步讨论吧.

## 关于作者

由作者 thirdgerb@gmail.com 开发的多轮对话机器人框架 [CommuneChatbot](https://github.com/thirdgerb/chatbot-studio) 已开始 Demo 的测试. 可以通过关注微信公众号 CommuneChatbot 进行测试.

二维码:

![qrcode](/img/commune-qrcode.bmp)

对项目感兴趣, 可关注公众号, 未来会持续分享与本项目有关的技术内容.


QQ交流群: 907985715 .

微信交流群二维码:

![wqrcode](/img/wqrcode.jpeg)

