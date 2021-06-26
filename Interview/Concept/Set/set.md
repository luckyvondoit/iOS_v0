- [1.断点续传怎么实现？需要设置什么？](#1断点续传怎么实现需要设置什么)
- [2.HTTP请求的请求方式](#2http请求的请求方式)
- [3.进程间通信](#3进程间通信)
- [4.如何检测应用是否卡顿](#4如何检测应用是否卡顿)
- [5.崩溃的常见类型](#5崩溃的常见类型)
- [6.NSThread，GCD，NSOperation相关的。开启一条线程的方法？线程可以取消吗？](#6nsthreadgcdnsoperation相关的开启一条线程的方法线程可以取消吗)
- [7.GCD，NSOperation的区别](#7gcdnsoperation的区别)
- [8.死锁的四个必要条件和解决办法](#8死锁的四个必要条件和解决办法)
- [9.进程和线程的区别](#9进程和线程的区别)
- [10.iOS视图控制器的生命周期](#10ios视图控制器的生命周期)
- [11.http协议中GET和POST的区别](#11http协议中get和post的区别)


## 1.断点续传怎么实现？需要设置什么？
<details>
<summary> 参考 </summary>

[下载](../Download/download.md)

</details>

## 2.HTTP请求的请求方式

<details>
<summary> 参考 </summary>

1、OPTIONS
返回服务器针对特定资源所支持的HTTP请求方法，也可以利用向web服务器发送‘*’的请求来测试服务器的功能性
2、HEAD
向服务器索与GET请求相一致的响应，只不过响应体将不会被返回。这一方法可以再不必传输整个响应内容的情况下，就可以获取包含在响应小消息头中的元信息。
3、GET
向特定的资源发出请求。注意：GET方法不应当被用于产生“副作用”的操作中，例如在Web Application中，其中一个原因是GET可能会被网络蜘蛛等随意访问。Loadrunner中对应get请求函数：web_link和web_url
4、POST
向指定资源提交数据进行处理请求（例如提交表单或者上传文件）。数据被包含在请求体中。POST请求可能会导致新的资源的建立和/或已有资源的修改。 Loadrunner中对应POST请求函数：web_submit_data,web_submit_form
5、PUT
向指定资源位置上传其最新内容
6、DELETE
请求服务器删除Request-URL所标识的资源
7、TRACE
回显服务器收到的请求，主要用于测试或诊断
8、CONNECT
HTTP/1.1协议中预留给能够将连接改为管道方式的代理服务器。
注意：
1）方法名称是区分大小写的，当某个请求所针对的资源不支持对应的请求方法的时候，服务器应当返回状态码405（Mothod Not Allowed）；当服务器不认识或者不支持对应的请求方法时，应返回状态码501（Not Implemented）。
2）HTTP服务器至少应该实现GET和HEAD/POST方法，其他方法都是可选的，此外除上述方法，特定的HTTP服务器支持扩展自定义的方法。

</details>

## 3.进程间通信

<details>
<summary> 参考 </summary>

**套接字（ socket ）** ： 套接口也是一种进程间通信机制，与其他通信机制不同的是，它可用于不同机器间的进程通信。

</details>

## 4.如何检测应用是否卡顿

<details>
<summary> 参考 </summary>

主要是监控主线程卡顿，包括：
1. FPS（FPS每秒刷新次数是否能稳定在60，CADisplayLink，每秒调用次数稳定在60次）
2. Runloop（从进入休眠到被唤醒的时间间隔是否超过某个阈值，不能超过WatchDog的最大时长，一般设置为3s）

</details>

## 5.崩溃的常见类型

<details>
<summary> 参考 </summary>

APP的崩溃可以分为两类：信号可捕捉崩溃 和 信号不可捕捉崩溃。

**信号可捕捉的崩溃**

- 数组越界：取数据时候索引越界，APP发生崩溃。给数组添加nil会崩溃。
- 多线程问题：多个线程进行数据的存取，可能会崩溃。例如有一个线程在置空数据的同时另一个线程在读取数据。
野指针问题：指针指向一个已删除的对象访问内存区域时，会出现野- 指针崩溃。野指针问题是导致 App 崩溃的最常见，也是最难定位的一种情况。
- NSNotification线程问题：NSNotification 有很多种线程实现方式，同步、异步、聚合，所以不恰当的线程发送和接收会出现崩溃问题。
- KVO问题：‘If your app targets iOS 9.0 and later or OS X v10.11 and later, you don't need to unregister an observer in its deallocation method。’ 在9.0之前需要手动remove 观察者，如果没有移除会出现观察者崩溃情况。
**信号不可捕捉的崩溃**

- 后台任务超时
- App超过系统限制的内存大小被杀死
- 主线程卡顿被杀死
</details>

## 6.NSThread，GCD，NSOperation相关的。开启一条线程的方法？线程可以取消吗？

<details>
<summary> 参考 </summary>

**NSThread 停止线程**

```
  if ([[NSThreadcurrentThread] isCancelled])
  {
      [NSThread exit];
  }
```
这样线程就会停止掉了。cancel只是一个标记位，真正的退出线程需要我们根据这个标记位判断，然后使用exit退出。

**取消GCD任务**

- 第一种：dispatch_block_cancel

iOS8以后能够调用`dispatch_block_cancel`来取消（须要注意必须用`dispatch_block_create`建立`dispatch_block_t`）

 代码示例：

 ```
 - (void)gcdBlockCancel{
    
    dispatch_queue_t queue = dispatch_queue_create("com.gcdtest.www", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_block_t block1 = dispatch_block_create(0, ^{
        sleep(5);
        NSLog(@"block1 %@",[NSThread currentThread]);
    });
    
    dispatch_block_t block2 = dispatch_block_create(0, ^{
        NSLog(@"block2 %@",[NSThread currentThread]);
    });
    
    dispatch_block_t block3 = dispatch_block_create(0, ^{
        NSLog(@"block3 %@",[NSThread currentThread]);
    });
    
    dispatch_async(queue, block1);
    dispatch_async(queue, block2);
    dispatch_block_cancel(block3);
}
```

打印结果：

```
2017-07-08 13:59:39.935 beck.wang[2796:284866] block2 <NSThread: 0x6180000758c0>{number = 3, name = (null)}
2017-07-08 13:59:44.940 beck.wang[2796:284889] block1 <NSThread: 0x618000074f80>{number = 4, name = (null)}
```

**dispatch_block_cancel也只能取消还没有执行的任务，对正在执行的任务不起做用。**

- 第二种：定义外部变量，用于标记block是否须要取消

该方法是模拟NSOperation，在执行block前先检查isCancelled = YES ？在block中及时的检测标记变量，当发现须要取消时，终止后续操做（如直接返回return）。

```
- (void)gcdCancel{
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    __block BOOL isCancel = NO;
    
    dispatch_async(queue, ^{
        NSLog(@"任务001 %@",[NSThread currentThread]);
    });
    
    dispatch_async(queue, ^{
        NSLog(@"任务002 %@",[NSThread currentThread]);
    });
    
    dispatch_async(queue, ^{
        NSLog(@"任务003 %@",[NSThread currentThread]);
        isCancel = YES;
    });
    
    dispatch_async(queue, ^{
        // 模拟：线程等待3秒，确保任务003完成 isCancel＝YES
        sleep(3);
        if(isCancel){
            NSLog(@"任务004已被取消 %@",[NSThread currentThread]);
        }else{
            NSLog(@"任务004 %@",[NSThread currentThread]);
        }
    });
}
```
打印结果：

```
2017-07-08 15:33:54.017 beck.wang[3022:333990] 任务002 <NSThread: 0x60800007f740>{number = 4, name = (null)}
2017-07-08 15:33:54.017 beck.wang[3022:333989] 任务001 <NSThread: 0x600000261d80>{number = 3, name = (null)}
2017-07-08 15:33:54.017 beck.wang[3022:333992] 任务003 <NSThread: 0x618000261800>{number = 5, name = (null)}
2017-07-08 15:34:02.266 beck.wang[3022:334006] 任务004已被取消 <NSThread: 0x608000267100>{number = 6, name = (null)}
```

</details>

## 7.GCD，NSOperation的区别

<details>
<summary> 参考 </summary>

NSOperation是苹果封装的一套多线程的东西，不像GCD是纯C语言的，这个是OC的。但相比较之下GCD会更快一些，但本质上NSOPeration是多GDC的封装。

**NSOperation与GCD的比较**

GCD是基于c的底层api，NSOperation属于object-c类。ios首先引入的是NSOperation，IOS4之后引入了GCD和NSOperationQueue并且其内部是用gcd实现的。

**GCD优点**：GCD主要与block结合使用。代码简洁高效。执行效率稍微高点。

**NSOperation相对于GCD：**

1，NSOperation拥有更多的函数可用，具体查看api。NSOperationQueue是在GCD基础上实现的，只不过是GCD更高一层的抽象。
2，在NSOperationQueue中，可以建立各个NSOperation之间的依赖关系。
3，NSOperationQueue支持KVO。可以监测operation是否正在执行（isExecuted）、是否结束（isFinished），是否取消（isCanceld）
4，GCD 只支持FIFO 的队列，而NSOperationQueue可以调整队列的执行顺序（通过调整权重）。NSOperationQueue可以方便的管理并发、NSOperation之间的优先级。
</details>

## 8.死锁的四个必要条件和解决办法

<details>
<summary> 参考 </summary>

**死锁概念及产生原理**

**概念：** 多个并发进程因争夺系统资源而产生相互等待的现象。
**原理：** 当一组进程中的每个进程都在等待某个事件发生，而只有这组进程中的其他进程才能触发该事件，这就称这组进程发生了死锁。
**本质原因：**
1. 系统资源有限。
2. 进程推进顺序不合理。

**死锁产生的4个必要条件**

**1、互斥：** 某种资源一次只允许一个进程访问，即该资源一旦分配给某个进程，其他进程就不能再访问，直到该进程访问结束。
**2、占有且等待：** 一个进程本身占有资源（一种或多种），同时还有资源未得到满足，正在等待其他进程释放该资源。
**3、不可抢占：** 别人已经占有了某项资源，你不能因为自己也需要该资源，就去把别人的资源抢过来。
**4、循环等待：** 存在一个进程链，使得每个进程都占有下一个进程所需的至少一种资源。

当以上四个条件均满足，必然会造成死锁，发生死锁的进程无法进行下去，它们所持有的资源也无法释放。这样会导致CPU的吞吐量下降。所以死锁情况是会浪费系统资源和影响计算机的使用性能的。那么，解决死锁问题就是相当有必要的了。

</details>

## 9.进程和线程的区别

<details>
<summary> 参考 </summary>

进程是资源分配的最小单位，线程是CPU调度的最小单位。

</details>

## 10.iOS视图控制器的生命周期

<details>
<summary> 参考 </summary>

这是一个ViewController完整的声明周期，其实里面还有好多地方需要我们注意一下：

1：initialize函数并不会每次创建对象都调用，只有在这个类第一次创建对象时才会调用，做一些类的准备工作，再次创建这个类的对象，initalize方法将不会被调用，对于这个类的子类，如果实现了initialize方法，在这个子类第一次创建对象时会调用自己的initalize方法，之后不会调用，如果没有实现，那么它的父类将替它再次调用一下自己的initialize方法，以后创建也都不会再调用。因此，如果我们有一些和这个相关的全局变量，可以在这里进行初始化。

2：init方法和initCoder方法相似，只是被调用的环境不一样，如果用代码进行初始化，会调用init，从nib文件或者归档进行初始化，会调用initCoder。

3：loadView方法是开始加载视图的起始方法，除非手动调用，否则在ViewController的生命周期中没特殊情况只会被调用一次。

4：viewDidLoad方法是我们最常用的方法的，类中成员对象和变量的初始化我们都会放在这个方法中，在类创建后，无论视图的展现或消失，这个方法也是只会在将要布局时调用一次。

5：viewWillAppare：视图将要展现时会调用。

6：viewWillLayoutSubviews：在viewWillAppare后调用，将要对子视图进行布局。

7：viewDidLayoutSubviews：已经布局完成子视图。

8：viewDidAppare：视图完成显示时调用。

9：viewWillDisappare：视图将要消失时调用。

10：viewDidDisappare：视图已经消失时调用。

11：dealloc：controller被释放时调用。

</details>

## 11.http协议中GET和POST的区别

<details>
<summary> 参考 </summary>

**1:缓存**
get:会被浏览器缓存
post:不会被缓存

**2:编码**
get:仅支持 urlencode 编码
post:支持各种编码

**3:请求长度(严格来说是浏览器的限制,不能算协议的限制)**
get:浏览器限制了get请求的请求长度(各个浏览器限制的长度不一样)
post:无限制

**4:安全性(只是相对安全)**
get:
 1.信息会明文展示在地址栏上,他人可以直接看到/复制
 2.会受到CSRF(跨站点请求伪造)的共计
>CSRF请参考链接: https://www.cnblogs.com/collin/articles/9637999.html

post:相对get会安全一点,但并不是绝对安全

**附:底层传输**
get:浏览器会把http header和data一并发送出去，服务器响应200（返回数据）
post:浏览器先发送header，服务器响应100 continue，浏览器再发送data，服务器响应200 ok（返回数据）

</details>
