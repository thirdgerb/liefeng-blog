---
title: "在Swoole中使用双IoC容器实现无污染的依赖注入"
date: 2019-07-20T11:19:53+08:00
draft: false
tags: ["commune-chatbot", "swoole", "php", ]
series: ["commune开发笔记"]
categories: ["开发记录"]
img: ""
toc: true
summary: "在Swoole中使用IoC容器进行依赖注入, 一直存在单例和静态变量污染的问题. 多轮对话机器人框架CommuneChatbot 使用双容器策略来解决这个问题."
---

## 简介:

容器(container)技术(可以理解为全局的工厂方法), 已经是现代项目的标配. 基于容器, 可以进一步实现控制反转, 依赖注入. [Laravel](https://github.com/laravel/laravel) 的巨大成功就是构建在它非常强大的IoC容器 [illuminate/container](https://github.com/illuminate/container) 基础上的. 而 PSR-11 定义了标准的 [container](https://github.com/php-fig/container) , 让更多的 PHP 项目依赖容器实现依赖解耦, 面向接口编程.

另一方面, PHP 天生一个进程响应一次请求的模型, 已经不能完全适应开发的需要. 于是 [Swoole](https://www.swoole.com/), [reactPHP](https://reactphp.org/), [roadrunner](https://github.com/spiral/roadrunner) 也越来越流行. 它们共同的特点是一个 php worker 进程在生命周期内要响应多个请求, 甚至同一时间同时运行多个请求 (协程).

在这些引擎上使用传统只考虑单请求的容器技术, 就容易发生单例相互污染, 内存泄露等问题 (姑且称之为"IoC容器的请求隔离问题" ). 于是出现了各种策略以解决之.

多轮对话机器人框架 [CommuneChatbot](https://github.com/thirdgerb/chatbot-studio) 使用 swoole 做通信引擎, 同时非常广泛地使用了容器和依赖注入. 在本项目中使用了 "双容器策略" 来解决 "请求隔离问题" .


所谓"双容器策略", 总结如下:

-   同时运行 "进程级容器" 与 "请求级容器"
-   "进程级容器" :
    -   传统的IoC 容器, 例如 Illuminate/container
-   "请求级容器" :
    -   所有工厂方法注册到容器的静态属性上
    -   在 worker 进程初始化阶段 注册服务
    -   每个请求到来后, 实例化一个请求容器.
    -   请求中生成的单例, 挂载到容器的动态属性上.
    -   持有"进程级容器", 当绑定不存在时, 到"进程级容器" 上查找之.
    -   请求结束时进行必要清理, 防止内存泄露


解决方案的代码在 [https://github.com/thirdgerb/container](https://github.com/thirdgerb/container) 创建了一个 composer 包 [commune/container](https://packagist.org/packages/commune/container)


## 容器的"请求隔离"问题



### 关于容器, 控制反转与依赖注入

为防止部分读者不了这些概念, 简单说明一下.

所谓容器, 相当于一个全局的工厂. 可以在这里 "注册" 各种服务的工厂方法, 再使用容器统一地获取. 例如

    $container = new Container();

    // 绑定一个单例
    $container->singleton(
        // 绑定对象的ID, 通常是 interface, 以实现面向接口编程.
        UserInterface::class,
        // 生成实例的工厂方法.
        function() {
            return new class implements UserInterface{};
        }
    );

    // 从容器中获取实例
    $user = $container->get(UserInterfacle::class);

    $user instanceof UserInterface; //  true


当一个类的实例在容器中生成, 或者一个方法被容器调用时, 就可以方便地实现依赖注入.

简单来说, 容器通过反射机制可获取目标方法的依赖  ( laravel 用反射来获取 typehint 类型约束, 而 [Swoft](https://github.com/swoft-cloud/swoft) 项目似乎与spring 相似, 是从注释上获取的).

然后容器查找是否已注册了 依赖 (dependency) 的实现 (resolver), 如果已注册, 就从容器中生成该依赖, 再注入给目标方法.

具有依赖注入能力的容器, 我们称之为 IoC (控制反转) 容器. 关于IoC 容器的好处不是本文重点, 先跳过去了.


### IoC 容器的请求隔离问题

容器最典型的应用场景之一, 就是持有单例. 但在 swoole 等引擎上, 一个 worker 进程要响应多个请求, 单例的数据就容易相互污染.

例如我们把 session 的数据放在 一个 SessionInterface 中, 每个逻辑调用时都用容器来取:

    $sessionInstance = container()->make(SessionInterface::class);

由于单例在容器内只生成一次, 那第二次请求时, 容器会给出第一次请求的session单例, 从而逻辑就乱套了.


所以容器要运行在 swoole 等引擎上, 必须做到请求与请求相隔离.


### 常见的解决策略

由于 Laravel 等使用了IoC 容器的项目能带来极好的工程体验, 而Swoole 能带来极大的性能提升, 于是有许多试图结合两者的项目, 都面临了 "请求隔离问题".


我个人看到过的解决策略有以下三种, 都能一定程度解决问题, 但也有美中不足之处.

-   克隆策略:
    -   方案: 每次请求, 克隆一个新的 container
    -   问题:
        -   要递归地 clone 属性, 才能避免浅拷贝导致的污染
        -   无法区分进程共享的单例, 和请求隔离的单例.
-   清洗策略:
    -   方案: 每次请求结束时, 主动清洗掉已注册的单例
    -   问题:
        -   定义类时就要考虑清洗逻辑, 可能要实现interface, 耦合较重
        -   swoole 发展到协程后, 同时可能相应多个请求, 清晰策略失效了.
-   重新注册:
    -   方案: 每个请求到来时, 实例化一个新容器, 重新注册所有服务
    -   问题:
        -   注册服务其实开销很大, 尤其是需要大量读文件的初始化(比如翻译组件)
        -   无法区分进程共享的单例, 和请求隔离的单例.
        -   利用不了 swoole 的优势, 比起多进程模型只少了 composer autoloader 的加载.


### CommuneChatbot 遇到的请求隔离问题

多轮对话机器人框架 [CommuneChatbot](https://github.com/thirdgerb/chatbot-studio) 在启动时需要加载大量多轮对话的逻辑, 消耗时间长 (>100ms), 但实际响应对话的时间不到 10ms. 所以本项目 必须使用 swoole 这类引擎, 不可能用PHP天生的多进程, 那样就只是一个低性能的玩具了.

另一方面, 为了实现

- 可配置化
- 组件化
- 面向接口编程
- 灵活的闭包

等 feature, [CommuneChatbot](https://github.com/thirdgerb/chatbot-studio) 严重依赖 IoC 容器. 所以识别要解决请求隔离的问题.


由于原有三种策略的不足之处都是本项目无法绕开的, 因此设计了 "双容器策略".


## CommuneChatbot 的双容器策略

本项目使用的双容器策略是一个通用的策略, 代码在 [https://github.com/thirdgerb/container](https://github.com/thirdgerb/container), 是由 Illuminate/Container 项目修改而来.

暂未发布版本, clone 后可以查看实现.

简单来说, 就是在一个 worker 进程中, 存在两种级别的容器:

-   进程级容器:  一个进程只有一个实例
-   请求级容器:  每一个请求拥有一个独立的实例

### "进程级" 与 "请求级" 容器分开注册服务

CommuneChatbot 中, 类似 laravel 的 serviceProvider 分两处注册.


    // 在worker中注册的服务, 多个请求共享
    'processProviders' => [

        // 基础组件加载
        Studio\Providers\StudioServiceProvider::class,
        // 默认的情感单元, 可以把意图或者message 映射成情感
        Studio\Providers\FeelingServiceProvider::class,

    ],

    // 在conversation开始时才注册服务, 其单例在每个请求之间是隔离的.
    'conversationProviders' => [

        // 数据读写的组件, 用到了laravel DB 的redis 和 mysql
        \Commune\Chatbot\Laravel\Providers\LaravelDBServiceProvider::class,
        // 各种权限功能的管理.
        Studio\Providers\AbilitiesServiceProvider::class,

    ],

服务开发者不需要太多考虑是进程级, 还是请求级, 只要避免用到静态属性. 系统搭建者才要考虑

### "请求级"容器持有"进程级"容器

CommuneChatbot 使用 trait 改造了 laravel 的 illuminate/container, 以此为基础实现了 [递归容器 RecursiveContainer](https://github.com/thirdgerb/container/blob/master/src/RecursiveContainer.php).

    trait RecursiveContainer
    {
        use ContainerTrait;
        /**
         * 不用静态属性, 静态属性在子类继承上会有问题.
         *
         * @var ContainerContract
         */
        protected $parentContainer;
        /**
         * RecursiveContainer constructor.
         * @param ContainerContract $parentContainer
         */
        public function __construct(ContainerContract $parentContainer)
        {
            $this->parentContainer = $parentContainer;
        }

        public function getParentContainer() : ContainerContract
        {
            return $this->parentContainer;
        }

        public function has($abstract)
        {
            return $this->bound($abstract) || $this->parentContainer->has($abstract);
        }

        /**
         * @param string $abstract
         * @param array $parameters
         * @return mixed
         * @throws
         */
        public function make(string $abstract, array $parameters = [])
        {
            // 做个最高效的判断环节. 绝大部分都是单例.
            if (isset($this->shared[$abstract])) {
                return $this->shared[$abstract];
            }
            // 优先自己绑定的对象.
            // 只有自己没有绑定, 且父容器有绑定的情况下, 才通过父类来做实例化.
            if (!$this->bound($abstract) && $this->parentContainer->has($abstract)) {
                return $this->parentContainer->make($abstract, $parameters);
            }
            return $this->resolve($abstract, $parameters);
        }

简单来说, 每个递归容器都可以持有一个父容器. 如果某个服务调用 在自己内未注册, 就会到父容器里查找. 父容器也是递归容器的话, 就会递归式查找.

这样, 进程级共享的单例, 就可以注册到 "进程级容器" . 而请求相互隔离的单例, 就注册到 "请求级容器".

请求内都用 "请求级容器" 来获取实例, 这样就充分灵活了.



### "请求级" 容器用静态属性注册服务, 动态属性持有单例

伪代码如下:

    trait ContainerTrait
    {

       /**
        * 请求级容器持有的单例
        * @var array
        */
       protected $shared = [];

       /**
        * 请求级容器注册的服务
        *
        * @var callable[]
        */
       private static $bindings = [];


这样, 所有服务只需要注册一次, 但服务的单例在每个请求内会重新生成一次.


### "请求级容器" 在worker进程初期boot, 每个请求到来时实例化

CommuneChatbot 中的一个[代码示例](https://github.com/thirdgerb/chatbot/blob/master/src/Chatbot/App/Platform/SwooleConsole/SwooleConsoleServer.php)

伪代码如下:

    class SwoolServer
    {
        /**
         * Swoole/Server
         */
        protected $server;

        protected $app;

        public function run()
        {
            $this->bootstrap();
        }

        public function bootstrap()
        {
            // 注册 service provider
            // 运行 service provider 的boot 方法
            // 进程级和请求级都在这个环节完成初始化
            $this->app->bootWorker();

            $this->server->on(
                'receive',
                function($server, $fd, $rid, $data){

                    // 获取 请求级容器 的 公共容器.
                    $container = $this->app->getRequestContainer();

                    // 实例化一个请求隔离的 容器
                    $requestContainer = $container->new($server, $fd, $rid, $data);

                    // 运行请求内的逻辑
                    $requestContainer->run();
                }
            );
        }


    }


### 使用 Laravel Application 作为 进程级容器

CommuneChatbot 的 framework 是不依赖大型项目的. 但在开发 Studio 时, 发现还是需要一个类似 Laravel 的全栈框架.

所以直接使用了 Laravel 的 Application 做 "进程级容器", 确保自己请求中用到的核心业务逻辑都不注册到 laravel中, 避免污染.

由于双容器策略基于共同的 interface 开发, 所以只需要为 Laravel Application 定制一个 [illuminateAdapter](https://github.com/thirdgerb/container/blob/master/src/IlluminateAdapter.php) 就可以了

### 防止内存泄露

使用 swoole, 如果逻辑写得不好导致一些对象相互持有, 无法释放, 则会导致内存泄露. 而且 php 目前排查内存泄露挺有难度.

使用双容器技术, 反而某种意义上方便了排查内存泄露.

因为 CommuneChatbot 是基于依赖注入来启动, 运行的, 请求内生成的绝大多数对象都来自于 IoC 容器, 并为之持有.

一旦 IoC 容器自身在请求结束后无法释放, 就一定发生了请求内的内存泄露.

[CommuneChatbot](https://github.com/thirdgerb/chatbot-studio) 定义的 [请求级容器](https://github.com/thirdgerb/chatbot/blob/master/src/Chatbot/Framework/Conversation/ConversationImpl.php), 在 __construct 和 __destruct 方法中做了简单的埋点, 伪代码如下:


    class Container {

        protected static $running = [];

        protected $traceId;

        public function __construct(string $traceId)
        {
            $this->traceId = $traceId;
            self::$running[$traceId] = true;
        }


        public function __destruct()
        {
            unset(self::$running[$this->traceId]);
        }
    }


就可以通过静态属性查看运行中的 container 实例个数.

[CommuneChatbot](https://github.com/thirdgerb/chatbot-studio) 甚至在 Demo 中提供了一个 ```#runningSpy -a ``` 的命令. 在公众号中随时输入它, 可以查看当前 worker 进程中几个关键对象的实例数量.


如果实例数随请求线性上升, 那就一定是严重的内存泄露了. 如果只是很少概率的内存泄露, 问题还不大.  Swoole 有参数 [max_request](https://wiki.swoole.com/wiki/page/p-max_request.html) 定期重启 worker 进程.


就我发现, 最容易导致内存泄露的两种情况:

-   某个闭包在每次请求时生成一个闭包实例, 被每个容器持有
-   容器生成的某个服务是匿名类, 导致相互持有

简单来说, 就是定义闭包和匿名类时, 慎重考虑内存泄露的可能性就行.


### 双容器策略在 CommuneChatbot 项目中的效果


[CommuneChatbot](https://github.com/thirdgerb/chatbot-studio) 目前使用双容器, Demo 在微信公众号 CommuneChatbot 上运行.

项目默认启动要 80 ms 以上, 而不用读写数据库完成单个请求平均在 3ms 左右.

    [2019-07-20 12:20:03] chatbot.INFO: end chat pipe {"gap":2791,"memory":10485760}


Swoole 除了免去了每次请求启动系统的开销之外, 还带来了额外的性能提升:

由于大量使用 PHP 的反射特性来实现复杂的依赖注入, 所以反射本应该是性能开销的大头. 但 PHP 其实有个内部机制, 反射调用一次就会缓存起来, 下次调用的开销是之前的几十分之一.

所以用swoole, 还可能提升了整体依赖注入的性能.


微信公众号上的 CommuneChatbot Demo 目前运行了数千个请求, 查看日志还没有发生一例内存泄露.

进程级容器 Laravel Application 也与 CommuneChatbot 自己的 ConversationContainer 结合得很好. 目前没发现任何问题.

整体结果令人乐观, 对我而言这是目前最合适的解决策略.


## 关于作者

由作者 thirdgerb@gmail.com 开发的多轮对话机器人框架 [CommuneChatbot](https://github.com/thirdgerb/chatbot-studio) 已开始 Demo 的测试. 可以通过关注微信公众号 CommuneChatbot 进行测试.

二维码:

![qrcode](/img/commune-qrcode.bmp)

对项目感兴趣, 可关注公众号, 未来会持续分享与本项目有关的技术内容.


QQ交流群: 907985715 .

微信交流群二维码:

![wqrcode](/img/wqrcode.jpeg)



