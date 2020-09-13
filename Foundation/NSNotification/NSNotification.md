# iOS NSNotification使用及原理实现

### 概述

`NSNotification` 是苹果提供的一种”同步“单向且线程安全的消息通知机制(并且消息可以携带信息)，观察者通过向单例的通知中心注册消息，即可接收指定对象或者其他任何对象发来的消息，可以实现”单播“或者”广播“消息机制，并且观察者和接收者可以完全解耦实现跨层消息传递；

> 同步：消息发送需要等待观察者处理完成消息后再继续执行；  

> 单向：发送者只发送消息，接收者不需要回复消息；  

> 线程安全：消息发送及接收都是在同一个线性完成，不需要处理线程同步问题，这个后面会详述；  

### 使用

#### NSNotification

`NSNotification` 包含了消息发送的一些信息，包括 `name` 消息名称、`object` 消息发送者、`userinfo` 消息发送者携带的额外信息，其类结构如下：

```
@interface NSNotification : NSObject <NSCopying, NSCoding>

@property (readonly, copy) NSNotificationName name;
@property (nullable, readonly, retain) id object;
@property (nullable, readonly, copy) NSDictionary *userInfo;

- (instancetype)initWithName:(NSNotificationName)name object:(nullable id)object userInfo:(nullable NSDictionary *)userInfo API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0)) NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;

@end

@interface NSNotification (NSNotificationCreation)

+ (instancetype)notificationWithName:(NSNotificationName)aName object:(nullable id)anObject;
+ (instancetype)notificationWithName:(NSNotificationName)aName object:(nullable id)anObject userInfo:(nullable NSDictionary *)aUserInfo;

- (instancetype)init /*API_UNAVAILABLE(macos, ios, watchos, tvos)*/;	/* do not invoke; not a valid initializer for this class */

@end
复制代码
```

可以通过实例方式构建 `NSNotification` 对象，也可以通过类方式构建；

#### NSNotificationCenter

`NSNotificationCenter` 消息通知中心，全局单例模式(每个进程都默认有一个默认的通知中心，用于进程内通信)，通过如下方法获取通知中心短息：

> 对于macOS系统，每个进程都有一个默认的分布式通知中心 `NSDistributedNotificationCenter` ，具体可参见   [NSDistributedNotificationCenter](https://developer.apple.com/documentation/foundation/nsdistributednotificationcenter)  

```
+ (NSNotificationCenter *)defaultCenter
复制代码
```

具体的注册通知消息方法如下：

```
//注册观察者
- (void)addObserver:(id)observer selector:(SEL)aSelector name:(nullable NSNotificationName)aName object:(nullable id)anObject;
- (id <NSObject>)addObserverForName:(nullable NSNotificationName)name object:(nullable id)obj queue:(nullable NSOperationQueue *)queue usingBlock:(void (^)(NSNotification *note))block API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
复制代码
```

注册观察者方法提供了两种形式： `selector` 及 `block` ，对于添加指定观察者对象的方式， `observer` 不能为 `nil` ； `block` 方式会执行 `copy` 方法，返回的是使用的匿名观察者对象，且指定观察者处理消息的操作对象 `NSOperationQueue` ；

对于指定的消息名称 `name` 及发送者对象 `object` 都可以为空，即接收所有消息及所有发送对象发送的消息；若指定其中之一或者都指定，则表示接收指定消息名称及发送者的消息；

对于 `block` 方式指定的 `queue` 队列可为 `nil` ，则默认在发送消息线程处理；若指定主队列，即主线程处理，避免执行 `UI` 操作导致异常；

*注意：注册观察者通知消息应避免重复注册，会导致重复处理通知消息，且`block` 对持有外部对象，因此需要避免引发循环引用问题；*

消息发送方法如下:

```
//发送消息
- (void)postNotification:(NSNotification *)notification;
- (void)postNotificationName:(NSNotificationName)aName object:(nullable id)anObject;
- (void)postNotificationName:(NSNotificationName)aName object:(nullable id)anObject userInfo:(nullable NSDictionary *)aUserInfo;
复制代码
```

可以通过 `NSNotification` 包装的通知消息对象发送消息，也可以分别指定消息名称、发送者及携带的信息来发送，且为 **同步执行模式，需要等待所有注册的观察者处理完成该通知消息，方法才会返回继续往下执行，且对于`block` 形式处理通知对象是在注册消息指定的队列中执行，对于非 `block` 方式是在同一线程处理；**

*注意：消息发送类型需要与注册时类型一致，即若注册观察者同时指定了消息名称及发送者，则发送消息也需要同时指定，否则无法接收到消息；*

移除观察者方法如下：

```
//移除观察者
- (void)removeObserver:(id)observer;
- (void)removeObserver:(id)observer name:(nullable NSNotificationName)aName object:(nullable id)anObject;
复制代码
```

可移除指定的观察者所有通知消息，即该观察者不再接收任何消息，一般用于观察者对象 `dealloc` 释放后调用，但在 `ios9` 及 `macos10.11` 之后不需要手动调用， `dealloc` 已经自动处理；

> If your app targets iOS 9.0 and later or macOS 10.11 and later, you don't need to unregister an observer in its [dealloc]() method. Otherwise, you should call this method or [removeObserver:name:object:]() before observer or any object specified in [addObserverForName:object:queue:usingBlock:]() or [addObserver:selector:name:object:]() is deallocated.  

也可以指定消息名称或者发送者移除单一或者所有的消息(通过置 `nil` 可移除对应类型下的所有消息)；

#### NSNotificationQueue

`NSNotificationQueue` 通知队列实现了通知消息的管理，如消息发送时机、消息合并策略，并且为先入先出方式管理消息，但实际消息发送仍然是通过 `NSNotificationCenter` 通知中心完成；

```
@interface NSNotificationQueue : NSObject
@property (class, readonly, strong) NSNotificationQueue *defaultQueue;

- (instancetype)initWithNotificationCenter:(NSNotificationCenter *)notificationCenter NS_DESIGNATED_INITIALIZER;

- (void)enqueueNotification:(NSNotification *)notification postingStyle:(NSPostingStyle)postingStyle;
- (void)enqueueNotification:(NSNotification *)notification postingStyle:(NSPostingStyle)postingStyle coalesceMask:(NSNotificationCoalescing)coalesceMask forModes:(nullable NSArray<NSRunLoopMode> *)modes;

- (void)dequeueNotificationsMatching:(NSNotification *)notification coalesceMask:(NSUInteger)coalesceMask;
复制代码
```

可以通过 `defaultQueue` 获取当前线程绑定的通知消息队列，也可以通过 `initWithNotificationCenter:` 来指定通知管理中心，具体的消息管理策略如下：

`NSPostingStyle` ：用于配置通知什么时候发送

* NSPostASAP：在当前通知调用或者计时器结束发出通知
* NSPostWhenIdle：当runloop处于空闲时发出通知
* NSPostNow：在合并通知完成之后立即发出通知。

`NSNotificationCoalescing` （注意这是一个NS_OPTIONS）：用于配置如何合并通知

* NSNotificationNoCoalescing：不合并通知
* NSNotificationCoalescingOnName：按照通知名字合并通知
* NSNotificationCoalescingOnSender：按照传入的object合并通知

对于 `NSNotificationQueue` 通知队列若不是指定 `NSPostNow` 立即发送模式，则可以通过 `runloop` 实现异步发送；

#### NSNotification与多线程

对于 `NSNotification` 与多线程官方文档说明如下：

> In a multithreaded application, notifications are always delivered in the thread in which the notification was posted, which may not be the same thread in which an observer registered itself.  

即是 `NSNotification` 的发送与接收处理都是在同一个线程中，对于 `block` 形式则是接收处理在指定的队列中处理，上面已说明这点，这里重点说明下如何接收处理在其他线程处理。

> For example, if an object running in a background thread is listening for notifications from the user interface, such as a window closing, you would like to receive the notifications in the background thread instead of the main thread. In these cases, you must capture the notifications as they are delivered on the default thread and redirect them to the appropriate thread.  

如官方说明；对于处理通知线程不是主线程的，如后台线程，存在此处理场景，并且官方也提供了具体的实施方案：

> 一种重定向的实现思路是自定义一个通知队列(注意，不是NSNotificationQueue对象，而是一个数组)，让这个队列去维护那些我们需要重定向的Notification。我们仍然是像平常一样去注册一个通知的观察者，当Notification来了时，先看看post这个Notification的线程是不是我们所期望的线程，如果不是，则将这个Notification存储到我们的队列中，并发送一个mach信号到期望的线程中，来告诉这个线程需要处理一个Notification。指定的线程在收到信号后，将Notification从队列中移除，并进行处理。  

官方demo如下：

```
@interface MyThreadedClass: NSObject
/* Threaded notification support. */
@property NSMutableArray *notifications;
@property NSThread *notificationThread;
@property NSLock *notificationLock;
@property NSMachPort *notificationPort;
 
- (void) setUpThreadingSupport;
- (void) handleMachMessage:(void *)msg;
- (void) processNotification:(NSNotification *)notification;
@end
复制代码
```

通知线程定义类 `MyThreadedClass` 包含了用于记录所有通知消息的通知消息队列 `notifications` ，记录当前通知接收线程 `notificationThread` ，多线程并发处理需要的互斥锁 `NSLock` ，用于线程间通信通知处理线程处理通知消息的 `NSMachPort` ；并提供了设置线程属性、处理mach消息及处理通知消息的实例方法；

对于 `setUpThreadSupport` 方法如下：

```
- (void) setUpThreadingSupport {
    if (self.notifications) {
        return;
    }
    self.notifications      = [[NSMutableArray alloc] init];
    self.notificationLock   = [[NSLock alloc] init];
    self.notificationThread = [NSThread currentThread];
 
    self.notificationPort = [[NSMachPort alloc] init];
    [self.notificationPort setDelegate:self];
    [[NSRunLoop currentRunLoop] addPort:self.notificationPort
            forMode:(NSString __bridge *)kCFRunLoopCommonModes];
}
复制代码
```

主要是初始化类属性，并指定 `NSMachPort` 代理及添加至处理线程的 `runloop` 中；若mach消息到达而接收线程的 `runloop` 没有运行时，内核会保存此消息，直到下一次 `runloop` 运行；也可以通过 `performSelectro:inThread:withObject:waitUtilDone:modes` 实现，不过对于子线程需要开启 `runloop` ，否则该方法失效，且需指定 `waitUtilDone` 参数为 `NO` 异步调用;

`NSMachPortDelegate` 协议方法处理如下：

```
- (void) handleMachMessage:(void *)msg {
    [self.notificationLock lock];
 
    while ([self.notifications count]) {
        NSNotification *notification = [self.notifications objectAtIndex:0];
        [self.notifications removeObjectAtIndex:0];
        [self.notificationLock unlock];
        [self processNotification:notification];
        [self.notificationLock lock];
    };
 
    [self.notificationLock unlock];
}
复制代码
```

`NSMachPort` 协议方法主要是检查需要处理的任何通知消息并迭代处理(防止并发发送大量端口消息，导致消息丢失)，处理完成后同步从消息队列中移除；

通知处理方法如下：

```
- (void)processNotification:(NSNotification *)notification {
    if ([NSThread currentThread] != notificationThread) {
        // Forward the notification to the correct thread.
        [self.notificationLock lock];
        [self.notifications addObject:notification];
        [self.notificationLock unlock];
        [self.notificationPort sendBeforeDate:[NSDate date]
                components:nil
                from:nil
                reserved:0];
    }
    else {
        // Process the notification here;
    }
}
复制代码
```

为区分 `NSMachPort` 协议方法内部调用及通知处理消息回调，需要通过判定当前处理线程来处理不同的通知消息处理方式；对于通知观察回调，将消息添加至消息队列并发送线程间通信mach消息；其实本方案的核心就是通过线程间异步通信 `NSMachPort` 来通知接收线程处理通知队列中的消息；

对于接收线程需要调用如下方法启动通知消息处理：

```
[self setupThreadingSupport];
[[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(processNotification:)
        name:@"NotificationName"//通知消息名称，可自定义
        object:nil];
复制代码
```

官方也给出了此方案的问题及思考：

> First, all threaded notifications processed by this object must pass through the same method ( `processNotification:` ). Second, each object must provide its own implementation and communication port. A better, but more complex, implementation would generalize the behavior into either a subclass of `NSNotificationCenter` or a separate class that would have one notification queue for each thread and be able to deliver notifications to multiple observer objects and methods  

其中指出更好地方式是自己去子类化一个NSNotficationCenter(github上有人实现了此方案，可参考 [GYNotificationCenter](https://github.com/zachwangb/GYNotificationCenter) )或者单独写一个类类处理这种转发。

### 原理解析

通知开源 [gnustep-base-1.25.0](http://wwwmain.gnustep.org/resources/downloads.php?site=ftp%3A%2F%2Fftp.gnustep.org%2Fpub%2Fgnustep%2F) 代码来分析通知的具体实现；

`_GSIMapTable` 映射表数据结构图如下：

![](./imgs/171e0286b4bcd5cd.jpeg)
相关的数据结构如下：

```
typedef struct _GSIMapBucket GSIMapBucket_t;
typedef struct _GSIMapNode GSIMapNode_t;

typedef GSIMapBucket_t *GSIMapBucket;
typedef GSIMapNode_t *GSIMapNode;

typedef struct _GSIMapTable GSIMapTable_t;
typedef GSIMapTable_t *GSIMapTable;

struct	_GSIMapNode {
    GSIMapNode	nextInBucket;	/* Linked list of bucket.	*/
    GSIMapKey	key;
#if	GSI_MAP_HAS_VALUE
    GSIMapVal	value;
#endif
};

struct	_GSIMapBucket {
    uintptr_t	nodeCount;	/* Number of nodes in bucket.	*/
    GSIMapNode	firstNode;	/* The linked list of nodes.	*/
};

struct	_GSIMapTable {
  NSZone	*zone;
  uintptr_t	nodeCount;	/* Number of used nodes in map.	*/
  uintptr_t	bucketCount;	/* Number of buckets in map.	*/
  GSIMapBucket	buckets;	/* Array of buckets.		*/
  GSIMapNode	freeNodes;	/* List of unused nodes.	*/
  uintptr_t	chunkCount;	/* Number of chunks in array.	*/
  GSIMapNode	*nodeChunks;	/* Chunks of allocated memory.	*/
  uintptr_t	increment;
#ifdef	GSI_MAP_EXTRA
  GSI_MAP_EXTRA	extra;
#endif
};
复制代码
```

`GSIMapTable` 映射表包含了指向 `GSIMapNode` 单链表节点的指针数组 `nodeChunks` ，通过 `buckets` 数组记录单链表节点指针数组的各个链表的节点数量及链表首部地址，其中 `bucketCount`、`nodeCount` 及 `chunkCount` 分别记录了 `node` 节点、节点单链表信息数组、节点单链表指针数组的数目；

具体的从映射表中添加/删除的代码如下：

```
GS_STATIC_INLINE GSIMapBucket
GSIMapPickBucket(unsigned hash, GSIMapBucket buckets, uintptr_t bucketCount)
{
    return buckets + hash % bucketCount;
}

GS_STATIC_INLINE GSIMapBucket
GSIMapBucketForKey(GSIMapTable map, GSIMapKey key)
{
    return GSIMapPickBucket(GSI_MAP_HASH(map, key),
                            map->buckets, map->bucketCount);
}

GS_STATIC_INLINE void
GSIMapLinkNodeIntoBucket(GSIMapBucket bucket, GSIMapNode node)
{
    node->nextInBucket = bucket->firstNode;
    bucket->firstNode = node;
}

GS_STATIC_INLINE void
GSIMapUnlinkNodeFromBucket(GSIMapBucket bucket, GSIMapNode node)
{
    if (node == bucket->firstNode)
    {
        bucket->firstNode = node->nextInBucket;
    }
    else
    {
        GSIMapNode	tmp = bucket->firstNode;
        
        while (tmp->nextInBucket != node)
        {
            tmp = tmp->nextInBucket;
        }
        tmp->nextInBucket = node->nextInBucket;
    }
    node->nextInBucket = 0;
}
复制代码
```

其实就是一个 `hash` 表结构，既可以以数组的形式取到每个单链表首元素，也可以以链表的形式获取，通过数组能够方便取到每个单向链表，再利用链表结构增删。

通知全局对象表结构如下：

```
typedef struct NCTbl {
    Observation		*wildcard;	/* Get ALL messages*/
    GSIMapTable		nameless;	/* Get messages for any name.*/
    GSIMapTable		named;		/* Getting named messages only.*/
    unsigned		lockCount;	/* Count recursive operations.	*/
    NSRecursiveLock	*_lock;		/* Lock out other threads.	*/
    Observation		*freeList;
    Observation		**chunks;
    unsigned		numChunks;
    GSIMapTable		cache[CACHESIZE];
    unsigned short	chunkIndex;
    unsigned short	cacheIndex;
} NCTable;
复制代码
```

其中数据结构中重要的是两张 `GSIMapTable` 表： `named`、`nameless` ，及单链表 `wildcard` ；

* `named` ，保存着传入通知名称的通知 `hash` 表；
* `nameless` ，保存没有传入通知名称的 `hash` 表；
* `wildcard` ，保存既没有通知名称又没有传入 `object` 的通知单链表；

保存含有通知名称的通知表 `named` 需要注册 `object` 对象，因此该表结构体通过传入的 `name` 作为 `key` ，其中 `value` 同时也为 `GSIMapTable` 表用于存储对应的 `object` 对象的 `observer` 对象；

对没有传入通知名称只传入 `object` 对象的通知表 `nameless` 而言，只需要保存 `object` 与 `observer` 的对应关系，因此 `object` 作为 `key` 用 `observer` 作为 `value` ；

具体的添加观察者的核心函数( `block` 形式只是该函数的包装)大致代码如下：

```
- (void) addObserver: (id)observer
            selector: (SEL)selector
                name: (NSString*)name
              object: (id)object
{
    Observation	*list;
    Observation	*o;
    GSIMapTable	m;
    GSIMapNode	n;

    //入参检查异常处理
    ...
		//table加锁保持数据一致性
    lockNCTable(TABLE);
		//创建Observation对象包装相应的调用函数
    o = obsNew(TABLE, selector, observer);
		//处理存在通知名称的情况
    if (name)
    {
        //table表中获取相应name的节点
        n = GSIMapNodeForKey(NAMED, (GSIMapKey)(id)name);
        if (n == 0)
        {
           //未找到相应的节点，则创建内部GSIMapTable表，以name作为key添加到talbe中
          m = mapNew(TABLE);
          name = [name copyWithZone: NSDefaultMallocZone()];
          GSIMapAddPair(NAMED, (GSIMapKey)(id)name, (GSIMapVal)(void*)m);
          GS_CONSUMED(name)
        }
        else
        {
            //找到则直接获取相应的内部table
          	m = (GSIMapTable)n->value.ptr;
        }

        //内部table表中获取相应object对象作为key的节点
        n = GSIMapNodeForSimpleKey(m, (GSIMapKey)object);
        if (n == 0)
        {
          	//不存在此节点，则直接添加observer对象到table中
            o->next = ENDOBS;//单链表observer末尾指向ENDOBS
            GSIMapAddPair(m, (GSIMapKey)object, (GSIMapVal)o);
        }
        else
        {
          	//存在此节点，则获取并将obsever添加到单链表observer中
            list = (Observation*)n->value.ptr;
            o->next = list->next;
            list->next = o;
        }
    }
    //只有观察者对象情况
    else if (object)
    {
      	//获取对应object的table
        n = GSIMapNodeForSimpleKey(NAMELESS, (GSIMapKey)object);
        if (n == 0)
        {
          	//未找到对应object key的节点，则直接添加observergnustep-base-1.25.0
            o->next = ENDOBS;
            GSIMapAddPair(NAMELESS, (GSIMapKey)object, (GSIMapVal)o);
        }
        else
        {
          	//找到相应的节点则直接添加到链表中
            list = (Observation*)n->value.ptr;
            o->next = list->next;
            list->next = o;
        }
    }
    //处理即没有通知名称也没有观察者对象的情况
    else
    {
      	//添加到单链表中
        o->next = WILDCARD;
        WILDCARD = o;
    }
		//解锁
    unlockNCTable(TABLE);
}
复制代码
```

对于 `block` 形式代码如下：

```
- (id) addObserverForName: (NSString *)name 
                   object: (id)object 
                    queue: (NSOperationQueue *)queue 
               usingBlock: (GSNotificationBlock)block
{
    GSNotificationObserver *observer = 
        [[GSNotificationObserver alloc] initWithQueue: queue block: block];

    [self addObserver: observer 
             selector: @selector(didReceiveNotification:) 
                 name: name 
               object: object];

    return observer;
}

- (id) initWithQueue: (NSOperationQueue *)queue 
               block: (GSNotificationBlock)block
{
    self = [super init];
    if (self == nil)
        return nil;

    ASSIGN(_queue, queue);
    _block = Block_copy(block);
    return self;
}

- (void) didReceiveNotification: (NSNotification *)notif
{
    if (_queue != nil)
    {
        GSNotificationBlockOperation *op = [[GSNotificationBlockOperation alloc] 
            initWithNotification: notif block: _block];

        [_queue addOperation: op];
    }
    else
    {
        CALL_BLOCK(_block, notif);
    }
}
复制代码
```

对于 `block` 形式通过创建 `GSNotificationObserver` 对象，该对象会通过 `Block_copy` 拷贝 `block` ，并确定通知操作队列，通知的接收处理函数 `didReceiveNotification` 中是通过 `addOperation` 来实现指定操作队列处理，否则直接执行 `block` ；

发送通知的核心函数大致逻辑如下：

```
- (void) _postAndRelease: (NSNotification*)notification
{
    //入参检查校验
    //创建存储所有匹配通知的数组GSIArray
   	//加锁table避免数据一致性问题
    //获取所有WILDCARD中的通知并添加到数组中
    //查找NAMELESS表中指定对应观察者对象object的通知并添加到数组中
		//查找NAMED表中相应的通知并添加到数组中
    //解锁table
    //遍历整个数组并依次调用performSelector:withObject处理通知消息发送
    //解锁table并释放资源
}
复制代码
```

上面发送的重点就是获取所有匹配的通知，并通过 `performSelector:withObject` 发送通知消息，因此通知发送和接收通知的线程是同一个线程( `block` 形式通过操作队列来指定队列处理)；

### Reference

[Notification Programming Topics](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Notifications/Introduction/introNotifications.html#//apple_ref/doc/uid/10000043-SW1)

[NotificationCenter](https://developer.apple.com/documentation/foundation/notificationcenter)

[Foundation: NSNotificationCenter](http://southpeak.github.io/2015/03/20/cocoa-foundation-nsnotificationcenter/)

[Notification与多线程](http://southpeak.github.io/2015/03/14/nsnotification-and-multithreading/)

[NSDistributedNotificationCenter](https://developer.apple.com/documentation/foundation/nsdistributednotificationcenter)

[深入理解iOS NSNotification](https://www.jianshu.com/p/83770200d476)

[深入理解NSNotificationCenter](https://www.dazhuanlan.com/2019/10/16/5da6c30609297/)

[iOS通讯模式（KVO、Notification、Delegate、Block、Target-Action的区别）](https://blog.csdn.net/hqqsk8/article/details/51911713)
