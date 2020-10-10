# dispatch_semaphore
 `dispatch_semaphore` 俗称信号量，也称为信号锁，其作用主要包括：

* 控制并发数

比如同时进行5个下载任务。

>并发和并行的区别：
> 如果某个系统支持两个或者多个动作（Action）**同时存在**，那么这个系统就是一个**并发系统**。如果某个系统支持两个或者多个动作**同时执行**，那么这个系统就是一个**并行系统**。  
> 并发强调发字，同时发生；并行强调行字，同时执行。
> 并行是并发的一个子集。  

* 线程同步中加锁

如果并发数为1，就能保证串行执行，可以当做锁使用。

* 将异步操作变为同步操作

阻塞当前线程，等待异步回调执行后，方能继续往下执行。

## semaphore的三个方法

### dispatch_semaphore_create

```
/*!
 * @function dispatch_semaphore_create
 *
 * @abstract
 * Creates new counting semaphore with an initial value.
 *
 * @discussion
 * Passing zero for the value is useful for when two threads need to reconcile
 * the completion of a particular event. Passing a value greater than zero is
 * useful for managing a finite pool of resources, where the pool size is equal
 * to the value.
 *
 * @param value
 * The starting value for the semaphore. Passing a value less than zero will
 * cause NULL to be returned.
 *
 * @result
 * The newly created semaphore, or NULL on failure.
 */
API_AVAILABLE(macos(10.6), ios(4.0))
DISPATCH_EXPORT DISPATCH_MALLOC DISPATCH_RETURNS_RETAINED DISPATCH_WARN_RESULT
DISPATCH_NOTHROW
dispatch_semaphore_t
dispatch_semaphore_create(long value);
复制代码
```

`dispatch_semaphore_create` 方法用于创建一个带有初始值的信号量 `dispatch_semaphore_t` 。

对于这个方法的参数信号量的初始值（必须大于等于0，否则会崩溃），这里有如下几种情况：

1. 信号量初始值为0时，用以将异步操作变成同步操作。（尽量在子线程中进行，避免卡主线程）
2. 信号量初始值为1时：将并发数设置为1相当于串行执行。可以作为锁使用。
3. 信号量初始值为大于1时：控制并发数。比如为了性能考虑，只支持同时进行5个下载任务。

### dispatch_semaphore_wait

```
/*!
 * @function dispatch_semaphore_wait
 *
 * @abstract
 * Wait (decrement) for a semaphore.
 *
 * @discussion
 * Decrement the counting semaphore. If the resulting value is less than zero,
 * this function waits for a signal to occur before returning.
 *
 * @param dsema
 * The semaphore. The result of passing NULL in this parameter is undefined.
 *
 * @param timeout
 * When to timeout (see dispatch_time). As a convenience, there are the
 * DISPATCH_TIME_NOW and DISPATCH_TIME_FOREVER constants.
 *
 * @result
 * Returns zero on success, or non-zero if the timeout occurred.
 */
API_AVAILABLE(macos(10.6), ios(4.0))
DISPATCH_EXPORT DISPATCH_NONNULL_ALL DISPATCH_NOTHROW
long
dispatch_semaphore_wait(dispatch_semaphore_t dsema, dispatch_time_t timeout);
复制代码
```

`dispatch_semaphore_wait` 这个方法主要用于 `等待` 或 `减少` 信号量，每次调用这个方法，信号量的值都会减一，然后根据减一后的信号量的值的大小，来决定这个方法的使用情况，所以这个方法的使用同样也分为2种情况：

1. 当减一后的值小于0时，这个方法会一直等待，即阻塞当前线程，直到信号量+1或者直到超时。
2. 当减一后的值大于或等于0时，这个方法会直接返回，不会阻塞当前线程。

### dispatch_semaphore_signal

```
/*!
 * @function dispatch_semaphore_signal
 *
 * @abstract
 * Signal (increment) a semaphore.
 *
 * @discussion
 * Increment the counting semaphore. If the previous value was less than zero,
 * this function wakes a waiting thread before returning.
 *
 * @param dsema The counting semaphore.
 * The result of passing NULL in this parameter is undefined.
 *
 * @result
 * This function returns non-zero if a thread is woken. Otherwise, zero is
 * returned.
 */
API_AVAILABLE(macos(10.6), ios(4.0))
DISPATCH_EXPORT DISPATCH_NONNULL_ALL DISPATCH_NOTHROW
long
dispatch_semaphore_signal(dispatch_semaphore_t dsema);
复制代码
```

`dispatch_semaphore_signal` 方法用于让信号量的值加一，然后直接返回。如果先前信号量的值小于0，那么这个方法还会唤醒先前等待的线程。

## semaphore使用篇

### 将异步操作变为同步操作

这种情况在我们的开发中也是挺常见的，当主线程中有一个异步网络任务，我们需要等这个网络请求成功拿到数据后，才能继续做后面的处理，这时我们就可以使用信号量这种方式来进行线程同步。

```
- (IBAction)threadSyncTask:(UIButton *)sender {
    
    NSLog(@"threadSyncTask start --- thread:%@",[NSThread currentThread]);
    
    //1.创建一个初始值为0的信号量
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    //2.定制一个异步任务
    //开启一个异步网络请求
    NSLog(@"开启一个异步网络请求");
    NSURLSession *session = [NSURLSession sharedSession];
    NSURL *url =
    [NSURL URLWithString:[@"https://www.baidu.com/" stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", [error localizedDescription]);
        }
        if (data) {
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            NSLog(@"%@", dict);
        }
        NSLog(@"异步网络任务完成---%@",[NSThread currentThread]);
        //4.调用signal方法，让信号量+1,然后唤醒先前被阻塞的线程
        NSLog(@"调用dispatch_semaphore_signal方法");
        dispatch_semaphore_signal(semaphore);
    }];
    [dataTask resume];
    
    //3.调用wait方法让信号量-1，这时信号量小于0，这个方法会阻塞当前线程，直到信号量等于0时，唤醒当前线程
    NSLog(@"调用dispatch_semaphore_wait方法");
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    NSLog(@"threadSyncTask end --- thread:%@",[NSThread currentThread]);
}
复制代码
```

运行之后的log如下：

```
2019-04-27 17:24:27.050077+0800 GCD(四) dispatch_semaphore[34482:6102243] threadSyncTask end --- thread:<NSThread: 0x6000028aa7c0>{number = 1, name = main}
2019-04-27 17:24:27.050227+0800 GCD(四) dispatch_semaphore[34482:6102243] 开启一个异步网络请求
2019-04-27 17:24:27.050571+0800 GCD(四) dispatch_semaphore[34482:6102243] 调用dispatch_semaphore_wait方法
2019-04-27 17:24:27.105069+0800 GCD(四) dispatch_semaphore[34482:6105851] (null)
2019-04-27 17:24:27.105262+0800 GCD(四) dispatch_semaphore[34482:6105851] 异步网络任务完成---<NSThread: 0x6000028c6ec0>{number = 6, name = (null)}
2019-04-27 17:24:27.105401+0800 GCD(四) dispatch_semaphore[34482:6105851] 调用dispatch_semaphore_signal方法
2019-04-27 17:24:27.105550+0800 GCD(四) dispatch_semaphore[34482:6102243] threadSyncTask end --- thread:<NSThread: 0x6000028aa7c0>{number = 1, name = main}
复制代码
```

从log中我们可以看出，wait方法会阻塞主线程，直到异步任务完成调用signal方法，才会继续回到主线程执行后面的任务。

配合group，所有并行的异步回调执行完成后发通知。

```
- (void)test {
    
    __weak typeof(self) weakSelf = self;
    
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_block_t block1 = ^(){
        [weakSelf requesWithIdentifier:@"1" completion:^{
        }];
    };
    
    dispatch_block_t block2 = ^(){
        [weakSelf requesWithIdentifier:@"2" completion:^{
        }];
    };
    
    dispatch_block_t block3 = ^(){
        [weakSelf requesWithIdentifier:@"3" completion:^{
        }];
    };
    
    dispatch_queue_t queue = dispatch_queue_create("myQ", DISPATCH_QUEUE_CONCURRENT);
    
    
    dispatch_group_async(group, queue, block1);
    dispatch_group_async(group, queue, block2);
    dispatch_group_async(group, queue, block3);
    

    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSLog(@"request done");
    });
    
}


- (void)requesWithIdentifier:(NSString *)identifier completion:(void(^)(void))block {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    NSInteger time = arc4random() %3 + 1;
    NSLog(@"start --- %@ time = %@ thread = %@" ,identifier,@(time),[NSThread currentThread]);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"stop --- %@, thread = %@",identifier,[NSThread currentThread]);
        if (block) {
            block();
        }
        
        dispatch_semaphore_signal(semaphore);
    });
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}
```


### 资源加锁

当一个资源可以被多个线程读取修改时，就会很容易出现多线程访问修改数据出现结果不一致甚至崩溃的问题。为了处理这个问题，我们通常使用的办法，就是使用 `NSLock` ， `@synchronized` 给这个资源加锁，让它在同一时间只允许一个线程访问资源。其实信号量也可以当做一个锁来使用，而且比 `NSLock` 还有 `@synchronized` 代价更低一些,接下来我们来看看它的基本使用

第一步，定义2个宏，将 `wait` 与 `signal` 方法包起来，方便下面的使用

```
#ifndef ZED_LOCK
#define ZED_LOCK(lock) dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
#endif

#ifndef ZED_UNLOCK
#define ZED_UNLOCK(lock) dispatch_semaphore_signal(lock);
#endif
复制代码
```

第二步，声明与创建共享资源与信号锁

```
/* 需要加锁的资源 **/
@property (nonatomic, strong) NSMutableDictionary *dict;

/* 信号锁 **/
@property (nonatomic, strong) dispatch_semaphore_t lock;
复制代码
```

```
//创建共享资源
self.dict = [NSMutableDictionary dictionary];
//初始化信号量,设置初始值为1
self.lock = dispatch_semaphore_create(1);
复制代码
```

第三步，在即将使用共享资源的地方添加 `ZED_LOCK` 宏，进行信号量减一操作,在共享资源使用完成的时候添加 `ZED_UNLOCK` ，进行信号量加一操作。

```
- (IBAction)resourceLockTask:(UIButton *)sender {
    
    NSLog(@"resourceLockTask start --- thread:%@",[NSThread currentThread]);
    
    //使用异步执行并发任务会开辟新的线程的特性，来模拟开辟多个线程访问贡献资源的场景
    
    for (int i = 0; i < 3; i++) {
        
        NSLog(@"异步添加任务:%d",i);
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            ZED_LOCK(self.lock);
            //模拟对共享资源处理的耗时
            [NSThread sleepForTimeInterval:1];
            NSLog(@"i:%d --- thread:%@ --- 将要处理共享资源",i,[NSThread currentThread]);
            [self.dict setObject:@"semaphore" forKey:@"key"];
            NSLog(@"i:%d --- thread:%@ --- 共享资源处理完成",i,[NSThread currentThread]);
            ZED_UNLOCK(self.lock);
            
        });
    }
    
    NSLog(@"resourceLockTask end --- thread:%@",[NSThread currentThread]);
}
复制代码
```

在这一步中，我们使用异步执行并发任务会开辟新的线程的特性，来模拟开辟多个线程访问贡献资源的场景，同时使用了线程休眠的API来模拟对共享资源处理的耗时。这里我们开辟了3个线程来并发访问这个共享资源，代码运行的log如下：

```
2019-04-27 18:36:25.275060+0800 GCD(四) dispatch_semaphore[35944:6315957] resourceLockTask start --- thread:<NSThread: 0x60000130e940>{number = 1, name = main}
2019-04-27 18:36:25.275312+0800 GCD(四) dispatch_semaphore[35944:6315957] 异步添加任务:0
2019-04-27 18:36:25.275508+0800 GCD(四) dispatch_semaphore[35944:6315957] 异步添加任务:1
2019-04-27 18:36:25.275680+0800 GCD(四) dispatch_semaphore[35944:6315957] 异步添加任务:2
2019-04-27 18:36:25.275891+0800 GCD(四) dispatch_semaphore[35944:6315957] resourceLockTask end --- thread:<NSThread: 0x60000130e940>{number = 1, name = main}
2019-04-27 18:36:26.276757+0800 GCD(四) dispatch_semaphore[35944:6316211] i:0 --- thread:<NSThread: 0x6000013575c0>{number = 3, name = (null)} --- 将要处理共享资源
2019-04-27 18:36:26.277004+0800 GCD(四) dispatch_semaphore[35944:6316211] i:0 --- thread:<NSThread: 0x6000013575c0>{number = 3, name = (null)} --- 共享资源处理完成
2019-04-27 18:36:27.282099+0800 GCD(四) dispatch_semaphore[35944:6316212] i:1 --- thread:<NSThread: 0x600001357800>{number = 4, name = (null)} --- 将要处理共享资源
2019-04-27 18:36:27.282357+0800 GCD(四) dispatch_semaphore[35944:6316212] i:1 --- thread:<NSThread: 0x600001357800>{number = 4, name = (null)} --- 共享资源处理完成
2019-04-27 18:36:28.283769+0800 GCD(四) dispatch_semaphore[35944:6316214] i:2 --- thread:<NSThread: 0x600001369280>{number = 5, name = (null)} --- 将要处理共享资源
2019-04-27 18:36:28.284041+0800 GCD(四) dispatch_semaphore[35944:6316214] i:2 --- thread:<NSThread: 0x600001369280>{number = 5, name = (null)} --- 共享资源处理完成
复制代码
```

从多次log中我们可以看出：

添加信号锁之后，每个线程对于共享资源的操作都是有序的，并不会出现2个线程同时访问锁中的代码区域。

我把上面的实现代码简化一下，方便分析这种锁的实现原理：

```
//step_1
    ZED_LOCK(self.lock);
    //step_2
    NSLog(@"执行任务");
    //step_3
    ZED_UNLOCK(self.lock);
复制代码
```

* 信号量初始化的值为1，当一个线程过来执行step_1的代码时，会调用信号量的值减一的方法，这时，信号量的值为0，它会直接返回，然后执行step_2的代码去完成去共享资源的访问，然后再使用step_3中的signal方法让信号量加一，信号量的值又会回归到初始值1。这就是一个线程过来访问的调用流程。
* 当线程1过来执行到step_2的时候，这时又有一个线程2它也从step_1处来调用这段代码，由于线程1已经调用过step_1的wait方法将信号量的值减一，这时信号量的值为0。同时线程2进入然后调用了step_1的wait方法又将信号量的值减一，这时的信号量的值为-1，由于信号量的值小于0时会阻塞当前线程（线程2），所以，线程2就会一直等待，直到线程1执行完step_3中的方法，将信号量加一，才会唤醒线程2，继续执行下面的代码。这就是为什么信号量可以对共享资源加锁的原因，如果我们可以允许n个线程同时访问，我们就需要在初始化这个信号量时把信号量的值设为n，这样就限制了访问共享资源的线程数。

通过上面的分析，我们可以知道，如果我们使用信号量来进行线程同步时，我们需要把信号量的初始值设为0，如果要对资源加锁，限制同时只有n个线程可以访问的时候，我们就需要把信号量的初始值设为n。

## semaphore的释放

在我们平常的开发过程中，如果对semaphore使用不当，就会在它释放的时候遇到奔溃问题。

首先我们来看2个例子：

```
- (IBAction)crashScene1:(UIButton *)sender {
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    //在使用过程中将semaphore置为nil
    semaphore = nil;
}
复制代码
```

```
- (IBAction)crashScene2:(UIButton *)sender {
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    //在使用过程中对semaphore进行重新赋值
    semaphore = dispatch_semaphore_create(3);
}
复制代码
```

我们打开 [测试代码](https://github.com/ZuoerdingCoder/GCDTest) ，找到semaphore对应的target，然后运行一下代码，然后点击后面2个按钮调用一下上面的代码，然后我们可以发现，代码在运行到 `semaphore = nil;` 与 `semaphore = dispatch_semaphore_create(3);` 时奔溃了。然后我们使用 `lldb` 的 `bt` 命令查看一下调用栈。

```
(lldb) bt
* thread #1, queue = 'com.apple.main-thread', stop reason = EXC_BAD_INSTRUCTION (code=EXC_I386_INVOP, subcode=0x0)
    frame #0: 0x0000000111c31309 libdispatch.dylib`_dispatch_semaphore_dispose + 59
    frame #1: 0x0000000111c2fb06 libdispatch.dylib`_dispatch_dispose + 97
  * frame #2: 0x000000010efb113b GCD(四) dispatch_semaphore`-[ZEDDispatchSemaphoreViewController crashScene1:](self=0x00007fdcfdf0add0, _cmd="crashScene1:", sender=0x00007fdcfdd0a3d0) at ZEDDispatchSemaphoreViewController.m:117
    frame #3: 0x0000000113198ecb UIKitCore`-[UIApplication sendAction:to:from:forEvent:] + 83
    frame #4: 0x0000000112bd40bd UIKitCore`-[UIControl sendAction:to:forEvent:] + 67
    frame #5: 0x0000000112bd43da UIKitCore`-[UIControl _sendActionsForEvents:withEvent:] + 450
    frame #6: 0x0000000112bd331e UIKitCore`-[UIControl touchesEnded:withEvent:] + 583
    frame #7: 0x00000001131d40a4 UIKitCore`-[UIWindow _sendTouchesForEvent:] + 2729
    frame #8: 0x00000001131d57a0 UIKitCore`-[UIWindow sendEvent:] + 4080
    frame #9: 0x00000001131b3394 UIKitCore`-[UIApplication sendEvent:] + 352
    frame #10: 0x00000001132885a9 UIKitCore`__dispatchPreprocessedEventFromEventQueue + 3054
    frame #11: 0x000000011328b1cb UIKitCore`__handleEventQueueInternal + 5948
    frame #12: 0x0000000110297721 CoreFoundation`__CFRUNLOOP_IS_CALLING_OUT_TO_A_SOURCE0_PERFORM_FUNCTION__ + 17
    frame #13: 0x0000000110296f93 CoreFoundation`__CFRunLoopDoSources0 + 243
    frame #14: 0x000000011029163f CoreFoundation`__CFRunLoopRun + 1263
    frame #15: 0x0000000110290e11 CoreFoundation`CFRunLoopRunSpecific + 625
    frame #16: 0x00000001189281dd GraphicsServices`GSEventRunModal + 62
    frame #17: 0x000000011319781d UIKitCore`UIApplicationMain + 140
    frame #18: 0x000000010efb06a0 GCD(四) dispatch_semaphore`main(argc=1, argv=0x00007ffee0c4efc8) at main.m:14
    frame #19: 0x0000000111ca6575 libdyld.dylib`start + 1
    frame #20: 0x0000000111ca6575 libdyld.dylib`start + 1
(lldb) 
复制代码
```

从上面的调用栈我们可以看出，奔溃的地方都处于 `libdispatch` 库调用 `dispatch_semaphore_dispose` 方法释放信号量的时候，为什么在信号量使用过程中对信号量进行重新赋值或置空操作会crash呢，这个我们就需要从GCD的源码层面来分析了，GCD的源码库 `libdispatch` 在苹果的 [开源代码库](https://opensource.apple.com/tarballs/libdispatch/) 可以下载，我在自己的 `Github` 也放了一份 [libdispatch-187.10](https://github.com/ZuoerdingCoder/libdispatch-187.10) 版本的，下面的源码分析都是基于这个版本的。

首先我们来看一下 `dispatch_semaphore_t` 的结构体 `dispatch_semaphore_s` 的结构体定义

```
struct dispatch_semaphore_s {
	DISPATCH_STRUCT_HEADER(dispatch_semaphore_s, dispatch_semaphore_vtable_s);
	long dsema_value; //当前的信号值
	long dsema_orig;  //初始化的信号值
	size_t dsema_sent_ksignals;
#if USE_MACH_SEM && USE_POSIX_SEM
#error "Too many supported semaphore types"
#elif USE_MACH_SEM
	semaphore_t dsema_port; //当前mach_port_t信号
	semaphore_t dsema_waiter_port; //休眠时mach_port_t信号
#elif USE_POSIX_SEM
	sem_t dsema_sem;
#else
#error "No supported semaphore type"
#endif
	size_t dsema_group_waiters;
	struct dispatch_sema_notify_s *dsema_notify_head;//链表头部
	struct dispatch_sema_notify_s *dsema_notify_tail;//链表尾部
};
复制代码
```

这里我们需要关注2个值的变化， `dsema_value` 与 `dsema_orig`,它们分别代表当前的信号值与初始化时的信号值。

当我们调用 `dispatch_semaphore_create` 方法创建信号量时，这个方法内部会把传入的参数存储到 `dsema_value` (当前的value)和 `dsema_orig` (初始value)中，条件是value的值必须大于或等于0。

```
dispatch_semaphore_t
dispatch_semaphore_create(long value)
{
	dispatch_semaphore_t dsema;

	// If the internal value is negative, then the absolute of the value is
	// equal to the number of waiting threads. Therefore it is bogus to
	// initialize the semaphore with a negative value.
	if (value < 0) {//初始值不能小于0
		return NULL;
	}

	dsema = calloc(1, sizeof(struct dispatch_semaphore_s));//申请信号量的内存

	if (fastpath(dsema)) {//信号量初始化赋值
		dsema->do_vtable = &_dispatch_semaphore_vtable;
		dsema->do_next = DISPATCH_OBJECT_LISTLESS;
		dsema->do_ref_cnt = 1;
		dsema->do_xref_cnt = 1;
		dsema->do_targetq = dispatch_get_global_queue(
				DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		dsema->dsema_value = value;//当前的值
		dsema->dsema_orig = value;//初始值
#if USE_POSIX_SEM
		int ret = sem_init(&dsema->dsema_sem, 0, 0);//内存空间映射
		DISPATCH_SEMAPHORE_VERIFY_RET(ret);
#endif
	}

	return dsema;
}
复制代码
```

然后调用 `dispatch_semaphore_wait` 与 `dispatch_semaphore_signal` 时会对 `dsema_value` 做加一或减一操作。当我们对信号量置空或者重新赋值操作时，会调用 `dispatch_semaphore_dispose` 释放信号量，我们来看看对应的源码

```
static void
_dispatch_semaphore_dispose(dispatch_semaphore_t dsema)
{
	if (dsema->dsema_value < dsema->dsema_orig) {//当前的信号值如果小于初始值就会crash
		DISPATCH_CLIENT_CRASH(
				"Semaphore/group object deallocated while in use");
	}

#if USE_MACH_SEM
	kern_return_t kr;
	if (dsema->dsema_port) {
		kr = semaphore_destroy(mach_task_self(), dsema->dsema_port);
		DISPATCH_SEMAPHORE_VERIFY_KR(kr);
	}
	if (dsema->dsema_waiter_port) {
		kr = semaphore_destroy(mach_task_self(), dsema->dsema_waiter_port);
		DISPATCH_SEMAPHORE_VERIFY_KR(kr);
	}
#elif USE_POSIX_SEM
	int ret = sem_destroy(&dsema->dsema_sem);
	DISPATCH_SEMAPHORE_VERIFY_RET(ret);
#endif

	_dispatch_dispose(dsema);
}
复制代码
```

从源码中我们可以看出，当 `dsema_value` 小于 `dsema_orig` 时，即信号量还在使用时，会直接调用 `DISPATCH_CLIENT_CRASH` 让APP奔溃。

**所以，我们在使用信号量的时候，不能在它还在使用的时候，进行赋值或者置空的操作。**

