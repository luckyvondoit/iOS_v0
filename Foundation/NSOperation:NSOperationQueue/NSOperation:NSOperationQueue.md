# NSOperation 与 NSOperationQueue 解析

## 为什么要使用`NSOperation` ?

`NSOperation` 提供任务的封装， `NSOperationQueue` 顾名思义，提供执行队列，可以自动实现多核并行计算，自动管理线程的生命周期，如果是并发的情况，其底层也使用线程池模型来管理，基本上可以说这两个类提供的功能覆盖了 `GCD` ，并且提供了更多可定制的开发方式，开发者可以按需选择。
`NSOperation` 把封装好的任务交给不同的 `NSOperationQueue` 即可进行串行或并发队列的执行。
通常情况下，任务会交给 `NSOperation` 类的一个方法， `main` 或者 `start` 方法，所以我们要自定义继承 `NSOperation` 类的话，需要重写相关方法。

## `NSOperation` 常用属性和方法

**重写的方法**

```
// 对于并发的Operation需要重写改方法
- (void)start;

// 非并发的Operation需要重写该方法
- (void)main;
复制代码
```

**相关属性**

```
// 任务是否取消（只读） 自定义子类，需重写该属性
@property (readonly, getter=isCancelled) BOOL cancelled;

// 可取消操作，实质是标记 isCancelled 状态，自定义子类，需利用该方法标记取消状态
- (void)cancel;

// 任务是否正在执行（只读），自定义子类，需重写该属性
@property (readonly, getter=isExecuting) BOOL executing;

// 任务是否结束（只读），自定义子类，需重写该属性
// 如果为YES，则队列会将任务移除队列
@property (readonly, getter=isFinished) BOOL finished;

// 判断任务是否为并发（只读），默认返回NO
// 自定义子类，需重写getter方法，并返回YES
@property (readonly, getter=isAsynchronous) BOOL asynchronous;

// 任务是否准备就绪（只读）
// 对于加入队列的任务来说，ready为YES，则表示该任务即将开始执行
// 如果存在依赖关系的任务没有执行完，则ready为NO
@property (readonly, getter=isReady) BOOL ready;
复制代码
```

**操作同步**

```
// 添加任务依赖
- (void)addDependency:(NSOperation *)op;

// 删除任务依赖
- (void)removeDependency:(NSOperation *)op;

typedef NS_ENUM(NSInteger, NSOperationQueuePriority) {
	NSOperationQueuePriorityVeryLow = -8L,
	NSOperationQueuePriorityLow = -4L,
	NSOperationQueuePriorityNormal = 0,
	NSOperationQueuePriorityHigh = 4,
	NSOperationQueuePriorityVeryHigh = 8
};
// 任务在队列里的优先级
@property NSOperationQueuePriority queuePriority;

// 会在当前操作执行完毕时调用completionBlock
@property (nullable, copy) void (^completionBlock)(void);

// 阻塞当前线程，直到该操作结束，可用于线程执行顺序的同步
- (void)waitUntilFinished;
复制代码
```

## `NSOperationQueue` 常用属性和方法

**添加任务**

```
// 向队列中添加一个任务
- (void)addOperation:(NSOperation *)op;

// 向队列中添加操作数组，wait 标志是否阻塞当前线程直到所有操作结束
- (void)addOperations:(NSArray<NSOperation *> *)ops waitUntilFinished:(BOOL)wait;

//  向队列中添加一个 block 类型操作对象。
- (void)addOperationWithBlock:(void (^)(void))block;

复制代码
```

**相关属性**

```
// 获取队列中所有任务（只读）
@property (readonly, copy) NSArray<__kindof NSOperation *> *operations;

// 获取队列中任务数量（只读）
@property (readonly) NSUInteger operationCount;

// 队列支持的最大任务并发数
@property NSInteger maxConcurrentOperationCount;

// 队列是否挂起
@property (getter=isSuspended) BOOL suspended;

// 队列名字
@property (nullable, copy) NSString *name
复制代码
```

**相关方法**

```
// 取消队列中所有的任务
- (void)cancelAllOperations;

// 阻塞当前线程，直到所有任务完成
- (void)waitUntilAllOperationsAreFinished;

// 类属性，获取当前队列
@property (class, readonly, strong, nullable) NSOperationQueue *currentQueue;

// 类属性，获取主队列（并发数为1）
@property (class, readonly, strong) NSOperationQueue *mainQueue;

复制代码
```

# 自定义NSOperation子类

在官方文档中支出，自定义 `NSOperation` 子类有两种方式， **并发和非并发** 。 非并发只需要继承 `NSOperation` 后，实现 `main` 方法即可。而并发的操作相对较多一点，下面将详细描述。

## 非并发的NSOperation子类

> 官方文档描述：  
> **Methods to Override**  
> For non-concurrent operations, you typically override only one method: **main**  
> Into this method, you place the code needed to perform the given task.  

在官方文档中指出，非并发任务，直接将需要执行的任务放在 `main` 方法中，然后直接调用即可。 这样直接调用 `main` 方法会存在一个问题，由于没有实现 `finished` 属性，所以获取 `finished` 属性时，只会返回NO，而且任务加入到队列后，不会被删除，另外任务执行完后，回调也不会被执行，所以最好不要只实现一个 `main` 方法来使用。 而且，其实也没有必要使用这种非并发的 `NSOperation` 子类，实在想不出有什么场景需要来用它，毕竟不方便。

## 并发的NSOperation子类

> 官方文档描述：  
> **Methods to Override**  
> If you are creating a concurrent operation, you need to override the following methods and properties at a minimum:  
> **start**  
> **asynchronous**  
> **executing**  
> **finished**  

通过官方文档可以知道，实现并发的自定义子类，需要重写下面几个方法或属性：

* `start` ：把需要执行的任务放在 `start` 方法里，任务加到队列后，队列会管理任务并在线程被调度后，调用 `start` 方法，不需要调用父类的方法
* `asynchronous` ：表示是否并发执行
* `executing` ：表示任务是否正在执行，需要手动调用KVO方法来进行通知，方便其他类监听了任务的该属性
* `finished` ：表示任务是否结束，需要手动调用KVO方法来进行通知，队列也需要监听改属性的值，用于判断任务是否结束

**相关代码**：

```
@interface ZBOperation : NSOperation

@property (nonatomic, readwrite, getter=isExecuting) BOOL executing;
@property (nonatomic, readwrite, getter=isFinished) BOOL finished;

@end

@implementation ZBOperation
// 因为父类的属性是Readonly的，重载时如果需要setter的话则需要手动合成。
@synthesize executing = _executing;
@synthesize finished = _finished;

- (void)start {
    @autoreleasepool{
    self.executing = YES;
        if (self.cancelled) {
            [self done];
            return;
        }
        // 任务。。。
    }
    // 任务执行完成，手动设置状态
    [self done];
}

- (void)done {
    self.finished = YES;
    self.executing = NO;
}

#pragma mark - setter -- getter
- (void)setExecuting:(BOOL)executing {
    //调用KVO通知
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    //调用KVO通知
    [self didChangeValueForKey:@"isExecuting"];
}

- (BOOL)isExecuting {
    return _executing;
}

- (void)setFinished:(BOOL)finished {
    if (_finished != finished) {
        [self willChangeValueForKey:@"isFinished"];
        _finished = finished;
        [self didChangeValueForKey:@"isFinished"];
    }
}

- (BOOL)isFinished {
    return _finished;
}

// 返回YES 标识为并发Operation
- (BOOL)isAsynchronous {
    return YES;
}

// 调用类
- (void)congfigOperation {
    self.queue = [[NSOperationQueue alloc] init];
    [self.queue setMaxConcurrentOperationCount:2];
    
    self.zbOperation = [[ZBOperation alloc] init];
    [self.queue addOperation:self.zbOperation];
}
复制代码
```

关于 `NSOperation` 和 `NSOperationQueue` 的自定义子类的使用基本上描述完了，一些比较细节的东西，可以参考官方文档。

有关 `NSOperation` 和 `NSOperationQueue` 的应用，我们可以阅读有关 `AFNetworking` 和 `SDWebImage` 的源码，源码中使用了大量的 `NSOperation` 操作。

关注下面的标签，发现更多相似文章
[iOS](https://juejin.im/tag/iOS)

  [佐笾](https://juejin.im/user/2436173498429287)  工程师 @ iOS开发工程师
[发布了 62 篇专栏 ·](https://juejin.im/user/2436173498429287/posts)  获得点赞 758 ·   获得阅读 63,104 

关注

[安装掘金浏览器插件](https://juejin.im/extension/?utm_source=juejin.im&amp;utm_medium=post&amp;utm_campaign=extension_promotion) 打开新标签页发现好内容，掘金、GitHub、Dribbble、ProductHunt 等站点内容轻松获取。快来安装掘金浏览器插件获取高质量内容吧！

 
[Corbin__](https://juejin.im/user/78820566645534) 
iOS开发 @ 字节跳动

如果需要加锁，是否可以用其他高性能点的锁，不要用@autoreleasepool，我看SDWebImage的源码也是用@autoreleasepool，不知道为啥

6月前  · 删除

回复

 
[Corbin__](https://juejin.im/user/78820566645534) 
iOS开发 @ 字节跳动

【- (void)start {@autoreleasepool{】，这个需要加锁吗，好像在哪里看过说这个是线程安全的，印象有点模糊了，还是说系统的两个子类是线程安全的，我们自己实现如果要线层安全就需要加锁

6月前  · 删除

回复

 
[dfdffa41b38911e98da4d1391af1c391](https://juejin.im/user/1151943917699277)

[内容违规]

1年前  · 删除

回复

 

相关推荐
	* [zhangjiezhi_](https://juejin.im/user/2955079655922125)

	* 16小时前
	* [iOS](https://juejin.im/tag/iOS)

[App崩溃现场取变量名和其实际值对应关系（不只是寄存器）](https://juejin.im/post/6883160410736820231)
	* [8]()
	* [3](https://juejin.im/post/6883160410736820231#comment)
	* 微博
	* 微信扫一扫

	* [QiShare](https://juejin.im/user/641770521630270)

	* 12小时前
	* [iOS](https://juejin.im/tag/iOS)

[2020年10月14日 iPhone12&HomePod mini 发布会](https://juejin.im/post/6883209900814499847)
	* [1]()
	* 
	* 微博
	* 微信扫一扫

	* [Chouee](https://juejin.im/user/2981531266326599)

	* 1天前
	* [iOS](https://juejin.im/tag/iOS)

[一次简单的iOS自动化构建尝试](https://juejin.im/post/6883023186837897230)
	* [3]()
	* 
	* 微博
	* 微信扫一扫

	* [卖馍工程师](https://juejin.im/user/3518029609051710)

	* 2天前
	* [iOS](https://juejin.im/tag/iOS)

[iOS 应用程序加载](https://juejin.im/post/6882647026188222471)
	* [19]()
	* [3](https://juejin.im/post/6882647026188222471#comment)
	* 微博
	* 微信扫一扫

	* [小谷先森](https://juejin.im/user/958429872270599)

	* 21小时前
	* [iOS](https://juejin.im/tag/iOS)

[iOS底层探索--dyld与objc的关联](https://juejin.im/post/6883077259171725319)
	* [6]()
	* 
	* 微博
	* 微信扫一扫

	* [Gavin_Kang](https://juejin.im/user/1433418895468397)

	* 1天前
	* [iOS](https://juejin.im/tag/iOS)

[iOS 自定义 Xcode 初始化的模板](https://juejin.im/post/6882678008415518734)
	* [10]()
	* [4](https://juejin.im/post/6882678008415518734#comment)
	* 微博
	* 微信扫一扫

	* [iOS一叶](https://juejin.im/user/1899557248829438)

	* 2天前
	* [iOS](https://juejin.im/tag/iOS)

[iOS 14-Widget开发](https://juejin.im/post/6882598825966436366)
	* [9]()
	* [1](https://juejin.im/post/6882598825966436366#comment)
	* 微博
	* 微信扫一扫

	* [Gavin_Kang](https://juejin.im/user/1433418895468397)

	* 1月前
	* [iOS](https://juejin.im/tag/iOS)

[从 0 开始手把手教你制作自己的 Pod 库](https://juejin.im/post/6868910104620728333)
	* [9]()
	* 
	* 微博
	* 微信扫一扫

	* [伯文丶](https://juejin.im/user/940837683069549)

	* 2天前
	* [iOS](https://juejin.im/tag/iOS)

[iOS开发: Workspace管理多个Project的简单使用](https://juejin.im/post/6882638131670040589)
	* [5]()
	* [2](https://juejin.im/post/6882638131670040589#comment)
	* 微博
	* 微信扫一扫

	* [RayJiang97](https://juejin.im/user/3192637496776167)

	* 5天前
	* [iOS](https://juejin.im/tag/iOS)

[为什么不推荐使用 PHPicker](https://juejin.im/post/6881513652176814093)
	* [7]()
	* [6](https://juejin.im/post/6881513652176814093#comment)
	* 微博
	* 微信扫一扫

	* [你二师兄会飞](https://juejin.im/user/8451824288398)

	* 22小时前
	* [iOS](https://juejin.im/tag/iOS)

[objc_msgSend理解分析](https://juejin.im/post/6883068251250065422)
	* [1]()
	* 
	* 微博
	* 微信扫一扫

	* [鳄鱼不怕_牙医不怕](https://juejin.im/user/1591748569076078)

	* 2天前
	* [iOS](https://juejin.im/tag/iOS)

[iOS 从源码解析Runtime (十三)：聚焦 objc_class(objc_class函数相关内容篇)](https://juejin.im/post/6882652698144538631)
	* [1]()
	* 
	* 微博
	* 微信扫一扫

	* [Potato_土豆](https://juejin.im/user/2647279732277095)

	* 2天前
	* [iOS](https://juejin.im/tag/iOS)

[objc_class 中 cache 原理分析](https://juejin.im/post/6882309253105713165)
	* [5]()
	* [2](https://juejin.im/post/6882309253105713165#comment)
	* 微博
	* 微信扫一扫

	* [洒水水](https://juejin.im/user/2260251636925528)

	* 2天前
	* [iOS](https://juejin.im/tag/iOS)

[密码技术之基本介绍](https://juejin.im/post/6882356437705162759)
	* [2]()
	* [1](https://juejin.im/post/6882356437705162759#comment)
	* 微博
	* 微信扫一扫

	* [iHTCboy](https://juejin.im/user/1908407915780989)

	* 1天前
	* [iOS](https://juejin.im/tag/iOS)

[Apple Developer 开发者账号申请&实名认证【2020】](https://juejin.im/post/6882758114513256461)
	* 
	* 
	* 微博
	* 微信扫一扫

	* [iOS___枫杰](https://juejin.im/user/1635674432482312)

	* 3天前
	* [iOS](https://juejin.im/tag/iOS)

[【Swift】WKWebView与JS的交互使用](https://juejin.im/post/6882228408781291528)
	* [6]()
	* [1](https://juejin.im/post/6882228408781291528#comment)
	* 微博
	* 微信扫一扫

	* [良眸](https://juejin.im/user/3562073406865261)

	* 18小时前
	* [iOS](https://juejin.im/tag/iOS)

[ios-对象的原理探索十-消息转发流程](https://juejin.im/post/6883120462805762062)
	* 
	* 
	* 微博
	* 微信扫一扫

	* [LazyLoad](https://juejin.im/user/3949101498240344)

	* 4天前
	* [iOS](https://juejin.im/tag/iOS)

[获取App的ipa安装包](https://juejin.im/post/6881897870643953672)
	* [3]()
	* 
	* 微博
	* 微信扫一扫

	* [iOS一叶](https://juejin.im/user/1899557248829438)

	* 18天前
	* [iOS](https://juejin.im/tag/iOS)

[百度App组件化之路](https://juejin.im/post/6876676078157430798)
	* [44]()
	* [6](https://juejin.im/post/6876676078157430798#comment)
	* 微博
	* 微信扫一扫

	* [大橙学iOS](https://juejin.im/user/4248168660731352)

	* 5天前
	* [iOS](https://juejin.im/tag/iOS)

[多线程的那些事](https://juejin.im/post/6881501266965463053)
	* [5]()
	* 
	* 微博
	* 微信扫一扫

关于作者
[佐笾](https://juejin.im/user/2436173498429287) 工程师 @ iOS开发工程师

获得点赞758
文章被阅读63,104

 
![](NSOperation:NSOperationQueue/post.7cb7332.png)
[下载掘金客户端 一个帮助开发者成长的社区](https://juejin.im/app)

![](NSOperation:NSOperationQueue/default.1fb7a71.png)

相关文章
[iOS 圆角，最后一次研究它了，真的  58  17](https://juejin.im/post/6844904031916130311) [OpenGL/OpenGL ES 入门：图形API以及专业名词解析  32  3](https://juejin.im/post/6844903843180838920) [iOS 渲染框架  51  5](https://juejin.im/post/6844903710913462279) [笔记-iOS设置圆角方法以及指定位置设圆角  41  15](https://juejin.im/post/6844903710888312845) [OpenGL ES入门：滤镜篇 - 漩涡、马赛克  26  0](https://juejin.im/post/6844903877272158215)

目录
* [NSOperation 与 NSOperationQueue 解析](https://juejin.im/post/6844903887279751176#heading-0)

	* [NSOperation 常用属性和方法](https://juejin.im/post/6844903887279751176#heading-1)
	* [NSOperationQueue 常用属性和方法](https://juejin.im/post/6844903887279751176#heading-2)

* [自定义NSOperation子类](https://juejin.im/post/6844903887279751176#heading-3)

	* [非并发的NSOperation子类](https://juejin.im/post/6844903887279751176#heading-4)
	* [并发的NSOperation子类](https://juejin.im/post/6844903887279751176#heading-5)

分享

[juejin.im](https://juejin.im/post/6844903887279751176)