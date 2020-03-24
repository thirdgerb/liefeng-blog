---
title: "对话机器人框架 CommuneChatbot 发布 v0.1.0版"
date: 2020-01-03T15:46:12+08:00
draft: false
tags: ["commune-chatbot"]
series: ["commune开发笔记"]
categories: ["开发记录"]
img: ""
toc: true
summary: "开源对话机器人开发框架 CommuneChatbot <https://github.com/thirdgerb/chatbot> 发布 v0.1.0 版了。"
---

开源对话机器人开发框架 CommuneChatbot <https://github.com/thirdgerb/chatbot> 发布 v0.1.0 版了。

## 1. 项目介绍

"Commune" 是 "亲切交谈" 的意思。CommuneChatbot 这个项目则是想通过 “对话” 的形式提供一种人与机器的交互方式。在这个思路中，“对话”不是目的，而是“操作机器”的手段。

简单来说，CommuneChatbot 是一个 :

* 个人开源项目
* 开发语言使用 PHP 7.2
* 可对接语音、即时通讯、公众号、智能音箱等平台，搭建对话机器人
* 最大特点是 多轮对话管理引擎, 用于解决 [复杂多轮对话问题](https://communechatbot.com/docs/#/zh-cn/core-concepts/complex-conversation)
* 基于 [Swoole](https://www.swoole.com/) + [Hyperf](https://www.hyperf.io/) 提供协程化的高性能服务端，提供工作站
* 使用自然语言单元（Rasa，百度UNIT等）作为中间件，接入自然语言解析能力
* 提供工程化 （模块/可配置/组件化） 的开发框架
* 目标是能够像开发网站、触屏App一样开发复杂的对话式应用。

项目相关的网址：

* 项目网站：<https://communechatbot.com/>
* 开发手册：<https://communechatbot.com/docs> （随时更新）
* 主框架仓库：<https://github.com/thirdgerb/chatbot>
* 工作站仓库：<https://github.com/thirdgerb/studio-hyperf>

项目目前的Demo有：

* 网页版 Demo : <https://communechatbot.com/>
* 微信公众号 Demo ： 搜索公众号 “CommuneChatbot”
* 百度智能音箱 ： 对音箱说 “打开三国群英传” 或 “打开方向迷宫”

推荐文档：

* [复杂多轮对话问题](https://communechatbot.com/docs/#/zh-cn/core-concepts/complex-conversation)
* [应用生命周期★](https://communechatbot.com/docs/#/zh-cn/app-lifecircle)
* [多轮对话生命周期★](https://communechatbot.com/docs/#/zh-cn/dm-lifecircle)
* [快速教程★](https://communechatbot.com/docs/#/zh-cn/lesions/index)
* [应用设想：对话式视频社交应用](https://communechatbot.com/docs/#/zh-cn/core-concepts/cva)

如有兴趣, 可以加入讨论 QQ 群: 907985715 ，或是参与项目 ISSUE :

* [CommuneChatbot Issue](https://github.com/thirdgerb/chatbot/issues)
* [StudioHyperf Issue](https://github.com/thirdgerb/studio-hyperf/issues)

## 2. 快速安装

如果想要快速尝试这个项目，可以只安装主框架。先要检查依赖：

* PHP >= 7.2
* 基本 PHP 扩展
* Intl 扩展（用于实现国际化）
* Composer

然后在命令行中安装：
```bash
$ git clone https://github.com/thirdgerb/chatbot.git
$ cd chatbot
$ composer install
```

如果 Composer 速度太慢， 建议使用 阿里云的Composer镜像 。 完成安装后，运行

```bash
$ php demo/console.php
```

查看Demo。更多内容请查看 [快速教程](https://communechatbot.com/docs/#/zh-cn/lesions/index)， 或 [搭建应用](https://communechatbot.com/docs/#/zh-cn/setup/index) 。

### 3. 开发样例

使用 CommuneChatbot 项目开发多轮对话机器人，一个极简的例子是这样的：

```php
/**
 * 定义一个 Hello world 的上下文
 * @property string $name userName
 */
class HelloWorldContext extends OOContext
{
    // 上下文的介绍
    const DESCRIPTION = 'hello world!';

    // 对话单元 "start"
    public function __onStart(Stage $stage) : Navigator
    {
        return $stage->buildTalk()

            // 发送消息给用户
            ->info('hello world!!')

            // 进入 "askName" 对话单元
            ->goStage('askName')
    }

    // 对话单元 "askName"
    public function __onAskName(Stage $stage) : Navigator
    {
        return $stage->buildTalk()

            // 询问用户姓名
            ->askVerbal('How may I address you?')

            // 等待用户的消息
            ->hearing()

            // 接受到用户的消息, 符合答案的格式
            ->isAnswer(function(Answer $answer, Dialog $dialog) {

                // 将答案赋值给上下文记忆
                $this->name = $answer->toResult();

                // 进入对话单元 "menu"
                return $this->goStage('menu');
            })

            // 结束用 Hearing API 定义对话逻辑
            ->end();
    }

    // 对话单元 "menu"
    public function __onMenu(Stage $stage) : Navigator
    {
        // 用 "menu" 工具构建一个 对话单元组件
        $menu = new Menu(
            // 菜单向用户的提问
            'What can I help you?',

            // 给用户回答的建议
            [
                // 进入 "play game" 的上下文
                PlayGameContext::class,

                // 进入 "order drink" 的上下文
                OrderDrinkContext::class,

                // 进入 "simple chat" 的上下文
                SimpleChatContext::class,
            ]
        );

        return $stage

            // 当目标上下文结束后, 触发这个回调方法
            ->onFallback(function(Dialog $dialog) {
                // 重复当前 Menu 对话
                return $dialog->repeat();
            });

            // 加载 stage component
            ->component($menu);
    }
}
```

多轮对话上下文是完全可编程的，既可以通过代码来定义，也可以基于配置文件动态生成。

## 4. 关于作者

CommuneChatbot 项目由 [ThirdGerb](https://github.com/thirdgerb) 基于个人兴趣设计并开发。

作者是一名服务端工程师，对于对话交互形式的应用有很强的兴趣，但想要开发的应用往往卡在复杂多轮对话问题上，而找到的解决方案还不够理想，因此自己动手开发了这个项目。

作者关于对话机器人的各种思考和观点，谨供参考。如果发现错谬之处，烦请批评指教，非常感谢！如有兴趣，可以加入讨论 QQ 群： 907985715