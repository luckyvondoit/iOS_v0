# GCD详解

## GCD概述

### GCD简介

>Grand Central Dispatch（GCD） 是 Apple 开发的一个多核编程的较新的解决方法。它主要用于优化应用程序以支持多核处理器以及其他对称多处理系统。它是一个在线程池模式的基础上执行的并发任务。在 Mac OS X 10.6 雪豹中首次推出，也可在 iOS 4 及以上版本使用。

### GCD优势

* GCD 可用于多核的并行运算；
* GCD 会自动利用更多的 CPU 内核（比如双核、四核）；
* GCD 会自动管理线程的生命周期（创建线程、调度任务、销毁线程）；
* 程序员只需要告诉 GCD 想要执行什么任务，不需要编写任何线程管理代码。

### GCD任务和队列

学习 GCD 之前，先来了解 GCD 中两个核心概念：**任务** 和 **队列**。

**任务**：就是执行操作的意思，换句话说就是你在线程中执行的那段代码。在 GCD 中是放在 block 中的。执行任务有两种方式：**同步执行** 和 **异步执行**。两者的主要**区别**是：是否等待队列的任务执行结束，以及是否具备开启新线程的能力。

* 同步执行（sync）
  * 同步添加任务到指定的队列中，在添加的任务执行结束之前，会一直等待，直到队列里面的任务完成之后再继续执行。
  * 只能在当前线程中执行任务，不具备开启新线程的能力。
* 异步执行（async）
  * 异步添加任务到指定的队列中，它不会做任何等待，可以继续执行任务。
  * 可以在新的线程中执行任务，具备开启新线程的能力。

>注意：异步执行（async）虽然具有开启新线程的能力，但是并不一定开启新线程。这跟任务所指定的队列类型有关

**队列（Dispatch Queue）**：这里的队列指执行任务的等待队列，即用来存放任务的队列。队列是一种特殊的线性表，采用 FIFO（先进先出）的原则，即新任务总是被插入到队列的末尾，而读取任务的时候总是从队列的头部开始读取。每读取一个任务，则从队列中释放一个任务。

在 GCD 中有两种队列：**串行队列** 和 **并发队列**。两者都符合 FIFO（先进先出）的原则。两者的主要**区别**是：执行顺序不同，以及开启线程数不同。

* 串行队列（Serial Dispatch Queue）
  * 每次只有一个任务被执行。让任务一个接着一个地执行。（只开启一个线程，一个任务执行完毕后，再执行下一个任务）
* 并发队列（Concurrent Dispatch Queue）
  * 可以让多个任务并发（同时）执行。（可以开启多个线程，并且同时执行任务）

>注意：并发队列 的并发功能只有在异步（dispatch_async）方法下才有效。

## GCD的使用步骤

GCD 的使用步骤其实很简单，只有两步：

1. 创建一个队列（串行队列或并发队列）
2. 将任务追加到任务的等待队列中，然后系统就会根据任务类型执行任务（同步执行或异步执行）。

### 队列的创建方法 / 获取方法

可以使用 `dispatch_queue_create` 方法来创建队列。该方法需要传入两个参数：
* 第一个参数表示队列的唯一标识符，用于 DEBUG，可为空。队列的名称推荐使用应用程序 ID 这种逆序全程域名。
* 第二个参数用来识别是串行队列还是并发队列。`DISPATCH_QUEUE_SERIAL` 表示串行队列，`DISPATCH_QUEUE_CONCURRENT` 表示并发队列。

```
// 串行队列的创建方法
dispatch_queue_t queue = dispatch_queue_create("com.ifx.testQueue", DISPATCH_QUEUE_SERIAL);
// 并发队列的创建方法
dispatch_queue_t queue = dispatch_queue_create("com.ifx.testQueue", DISPATCH_QUEUE_CONCURRENT);
```

对于串行队列，GCD 默认提供了：**主队列（Main Dispatch Queue）**。

* 所有放在主队列中的任务，都会放到主线程中执行。
* 可使用 `dispatch_get_main_queue()` 方法获得主队列。

>注意：**主队列其实并不特殊**。 主队列的实质上就是一个普通的串行队列，只是因为默认情况下，当前代码是放在主队列中的，然后主队列中的代码，有都会放到主线程中去执行，所以才造成了主队列特殊的现象。

```
// 主队列的获取方法
dispatch_queue_t queue = dispatch_get_main_queue();
```

对于并发队列，GCD 默认提供了 **全局并发队列（Global Dispatch Queue）**。

* 可以使用 `dispatch_get_global_queue` 方法来获取全局并发队列。需要传入两个参数。第一个参数表示队列优先级，一般用 `DISPATCH_QUEUE_PRIORITY_DEFAULT`。第二个参数暂时没用，用 0 即可。

```
// 全局并发队列的获取方法
dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
```

### 任务的创建方法

GCD 提供了同步执行任务的创建方法 `dispatch_sync` 和异步执行任务创建方法 `dispatch_async`。

```
// 同步执行任务创建方法
dispatch_sync(queue, ^{
    // 这里放同步执行任务代码
});
// 异步执行任务创建方法
dispatch_async(queue, ^{
    // 这里放异步执行任务代码
});
```

虽然使用 GCD 只需两步，但是既然我们有两种队列（串行队列 / 并发队列），两种任务执行方式（同步执行 / 异步执行），那么我们就有了四种不同的组合方式。这四种不同的组合方式是：

* 同步执行 + 并发队列
* 异步执行 + 并发队列
* 同步执行 + 串行队列
* 异步执行 + 串行队列

实际上，刚才还说了两种默认队列：全局并发队列、主队列。全局并发队列可以作为普通并发队列来使用。但是当前代码默认放在主队列中，所以主队列很有必要专门来研究一下，所以我们就又多了两种组合方式。这样就有六种不同的组合方式了。

* 同步执行 + 主队列
* 异步执行 + 主队列

### 任务和队列不同组合方式的区别

我们先来考虑最基本的使用，也就是当前线程为 **主线程** 的环境下，**不同队列** + **不同任务** 简单组合使用的不同区别。暂时不考虑 **队列中嵌套队列** 的这种复杂情况。

**主线程**中，**不同队列** + **不同任务** 简单组合的区别：

区别 | 并发队列 | 串行队列 | 主队列
- | - | - | -
同步（sync） | 没有开启新线程，串行执行任务	| 没有开启新线程，串行执行任务 | 死锁卡住不执行
异步（async） | 有开启新线程，并发执行任务 | 有开启新线程（1条），串行执行任务 | 没有开启新线程，串行执行任务

>注意：从上边可看出： 『主线程』 中调用 『主队列』+『同步执行』 会导致死锁问题。这是因为主队列中追加的同步任务和主线程本身的任务两者之间相互等待，阻塞了 『主队列』，最终造成了主队列所在的线程（主线程）死锁问题。而如果我们在 『其他线程』 调用 『主队列』+『同步执行』，则不会阻塞 『主队列』，自然也不会造成死锁问题。最终的结果是：不会开启新线程，串行执行任务。

### 队列嵌套情况下，不同组合方式区别

除了上边提到的『主线程』中调用『主队列』+『同步执行』会导致死锁问题。实际在使用『串行队列』的时候，也可能出现阻塞『串行队列』所在线程的情况发生，从而造成死锁问题。这种情况多见于同一个串行队列的嵌套使用。

比如下面代码这样：在『异步执行』+『串行队列』的任务中，又嵌套了『当前的串行队列』，然后进行『同步执行』。

```
dispatch_queue_t queue = dispatch_queue_create("test.queue", DISPATCH_QUEUE_SERIAL);
dispatch_async(queue, ^{    // 异步执行 + 串行队列
    dispatch_sync(queue, ^{  // 同步执行 + 当前串行队列
        // 追加任务 1
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"1---%@",[NSThread currentThread]);      // 打印当前线程
    });
});
```

>执行上面的代码会导致 串行队列中追加的任务 和 串行队列中原有的任务 两者之间相互等待，阻塞了『串行队列』，最终造成了串行队列所在的线程（子线程）死锁问题。
>主队列造成死锁也是基于这个原因，所以，这也进一步说明了主队列其实并不特殊。

关于 『队列中嵌套队列』这种复杂情况，这里也简单做一个总结。不过这里只考虑同一个队列的嵌套情况。

『不同队列』+『不同任务』 组合，以及 『队列中嵌套队列』 使用的区别：

区别 | 『异步执行+并发队列』嵌套『同一个并发队列』 | 『同步执行+并发队列』嵌套『同一个并发队列』	| 『异步执行+串行队列』嵌套『同一个串行队列』 | 『同步执行+串行队列』嵌套『同一个串行队列』
- | - | - | - | -
同步（sync） | 没有开启新的线程，串行执行任务 | 没有开启新线程，串行执行任务	 | 死锁卡住不执行 | 死锁卡住不执行
异步（async） | 有开启新线程，并发执行任务 | 有开启新线程，并发执行任务 | 有开启新线程（1 条），串行执行任务 | 有开启新线程（1 条），串行执行任务

## GCD的基本使用

先来讲讲并发队列的两种执行方式。

### 同步执行 + 并发队列

在当前线程中执行任务，不会开启新线程，执行完一个任务，再执行下一个任务。

```
/**
 * 同步执行 + 并发队列
 * 特点：在当前线程中执行任务，不会开启新线程，执行完一个任务，再执行下一个任务。
 */
- (void)syncConcurrent {
    NSLog(@"currentThread---%@",[NSThread currentThread]);  // 打印当前线程
    NSLog(@"syncConcurrent---begin");
    
    dispatch_queue_t queue = dispatch_queue_create("net.bujige.testQueue", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_sync(queue, ^{
        // 追加任务 1
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"1---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    dispatch_sync(queue, ^{
        // 追加任务 2
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"2---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    dispatch_sync(queue, ^{
        // 追加任务 3
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"3---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    NSLog(@"syncConcurrent---end");
}
```

>输出结果：
2019-08-08 14:32:53.542816+0800 YSC-GCD-demo[16332:4171500] currentThread---<NSThread: 0x600002326940>{number = 1, name = main}
2019-08-08 14:32:53.542964+0800 YSC-GCD-demo[16332:4171500] syncConcurrent---begin
2019-08-08 14:32:55.544329+0800 YSC-GCD-demo[16332:4171500] 1---<NSThread: 0x600002326940>{number = 1, name = main}
2019-08-08 14:32:57.545779+0800 YSC-GCD-demo[16332:4171500] 2---<NSThread: 0x600002326940>{number = 1, name = main}
2019-08-08 14:32:59.547154+0800 YSC-GCD-demo[16332:4171500] 3---<NSThread: 0x600002326940>{number = 1, name = main}
2019-08-08 14:32:59.547365+0800 YSC-GCD-demo[16332:4171500] syncConcurrent---end

从 **同步执行** + **并发队列** 中可看到：

* 所有任务都是在当前线程（主线程）中执行的，没有开启新的线程（**同步执行**不具备开启新线程的能力）。
* 所有任务都在打印的 `syncConcurrent---begin` 和 `syncConcurrent---end` 之间执行的（**同步任务** 需要等待队列的任务执行结束）。
* 任务按顺序执行的。按顺序执行的原因：虽然 **并发队列** 可以开启多个线程，并且同时执行多个任务。但是因为本身不能创建新线程，只有当前线程这一个线程（**同步任务** 不具备开启新线程的能力），所以也就不存在并发。而且当前线程只有等待当前队列中正在执行的任务执行完毕之后，才能继续接着执行下面的操作（**同步任务** 需要等待队列的任务执行结束）。所以任务只能一个接一个按顺序执行，不能同时被执行。

###  异步执行 + 并发队列

可以开启多个线程，任务交替（同时）执行。

```
/**
 * 异步执行 + 并发队列
 * 特点：可以开启多个线程，任务交替（同时）执行。
 */
- (void)asyncConcurrent {
    NSLog(@"currentThread---%@",[NSThread currentThread]);  // 打印当前线程
    NSLog(@"asyncConcurrent---begin");
    
    dispatch_queue_t queue = dispatch_queue_create("net.bujige.testQueue", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(queue, ^{
        // 追加任务 1
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"1---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    dispatch_async(queue, ^{
        // 追加任务 2
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"2---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    dispatch_async(queue, ^{
        // 追加任务 3
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"3---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    NSLog(@"asyncConcurrent---end");
}
```

>输出结果：
2019-08-08 14:36:37.747966+0800 YSC-GCD-demo[17232:4187114] currentThread---<NSThread: 0x60000206d380>{number = 1, name = main}
2019-08-08 14:36:37.748150+0800 YSC-GCD-demo[17232:4187114] asyncConcurrent---begin
2019-08-08 14:36:37.748279+0800 YSC-GCD-demo[17232:4187114] asyncConcurrent---end
2019-08-08 14:36:39.752523+0800 YSC-GCD-demo[17232:4187204] 2---<NSThread: 0x600002010980>{number = 3, name = (null)}
2019-08-08 14:36:39.752527+0800 YSC-GCD-demo[17232:4187202] 3---<NSThread: 0x600002018480>{number = 5, name = (null)}
2019-08-08 14:36:39.752527+0800 YSC-GCD-demo[17232:4187203] 1---<NSThread: 0x600002023400>{number = 4, name = (null)}

在 **异步执行** + **并发队列** 中可以看出：

* 除了当前线程（主线程），系统又开启了 3 个线程，并且任务是交替/同时执行的。（**异步执行** 具备开启新线程的能力。且 **并发队列** 可开启多个线程，同时执行多个任务）。
* 所有任务是在打印的 `syncConcurrent---begin` 和 `syncConcurrent---end` 之后才执行的。说明当前线程没有等待，而是直接开启了新线程，在新线程中执行任务（**异步执行** 不做等待，可以继续执行任务）。

接下来再来讲讲串行队列的两种执行方式。

### 同步执行 + 串行队列

不会开启新线程，在当前线程执行任务。任务是串行的，执行完一个任务，再执行下一个任务。

```
/**
 * 同步执行 + 串行队列
 * 特点：不会开启新线程，在当前线程执行任务。任务是串行的，执行完一个任务，再执行下一个任务。
 */
- (void)syncSerial {
    NSLog(@"currentThread---%@",[NSThread currentThread]);  // 打印当前线程
    NSLog(@"syncSerial---begin");
    
    dispatch_queue_t queue = dispatch_queue_create("net.bujige.testQueue", DISPATCH_QUEUE_SERIAL);
    
    dispatch_sync(queue, ^{
        // 追加任务 1
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"1---%@",[NSThread currentThread]);      // 打印当前线程
    });
    dispatch_sync(queue, ^{
        // 追加任务 2
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"2---%@",[NSThread currentThread]);      // 打印当前线程
    });
    dispatch_sync(queue, ^{
        // 追加任务 3
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"3---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    NSLog(@"syncSerial---end");
}
```

>输出结果为：
2019-08-08 14:39:31.366815+0800 YSC-GCD-demo[17285:4197645] currentThread---<NSThread: 0x600001b5e940>{number = 1, name = main}
2019-08-08 14:39:31.366952+0800 YSC-GCD-demo[17285:4197645] syncSerial---begin
2019-08-08 14:39:33.368256+0800 YSC-GCD-demo[17285:4197645] 1---<NSThread: 0x600001b5e940>{number = 1, name = main}
2019-08-08 14:39:35.369661+0800 YSC-GCD-demo[17285:4197645] 2---<NSThread: 0x600001b5e940>{number = 1, name = main}
2019-08-08 14:39:37.370991+0800 YSC-GCD-demo[17285:4197645] 3---<NSThread: 0x600001b5e940>{number = 1, name = main}
2019-08-08 14:39:37.371192+0800 YSC-GCD-demo[17285:4197645] syncSerial---end

在 **同步执行** + **串行队列** 可以看到：

* 所有任务都是在当前线程（主线程）中执行的，并没有开启新的线程（**同步执行** 不具备开启新线程的能力）。
* 所有任务都在打印的 `syncConcurrent---begin` 和 `syncConcurrent---end` 之间执行（**同步任务** 需要等待队列的任务执行结束）。
* 任务是按顺序执行的（**串行队列** 每次只有一个任务被执行，任务一个接一个按顺序执行）。

### 异步执行 + 串行队列

会开启新线程，但是因为任务是串行的，执行完一个任务，再执行下一个任务

```
/**
 * 异步执行 + 串行队列
 * 特点：会开启新线程，但是因为任务是串行的，执行完一个任务，再执行下一个任务。
 */
- (void)asyncSerial {
    NSLog(@"currentThread---%@",[NSThread currentThread]);  // 打印当前线程
    NSLog(@"asyncSerial---begin");
    
    dispatch_queue_t queue = dispatch_queue_create("net.bujige.testQueue", DISPATCH_QUEUE_SERIAL);
    
    dispatch_async(queue, ^{
        // 追加任务 1
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"1---%@",[NSThread currentThread]);      // 打印当前线程
    });
    dispatch_async(queue, ^{
        // 追加任务 2
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"2---%@",[NSThread currentThread]);      // 打印当前线程
    });
    dispatch_async(queue, ^{
        // 追加任务 3
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"3---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    NSLog(@"asyncSerial---end");
}
```

>输出结果为：
2019-08-08 14:40:53.944502+0800 YSC-GCD-demo[17313:4203018] currentThread---<NSThread: 0x6000015da940>{number = 1, name = main}
2019-08-08 14:40:53.944615+0800 YSC-GCD-demo[17313:4203018] asyncSerial---begin
2019-08-08 14:40:53.944710+0800 YSC-GCD-demo[17313:4203018] asyncSerial---end
2019-08-08 14:40:55.947709+0800 YSC-GCD-demo[17313:4203079] 1---<NSThread: 0x6000015a0840>{number = 3, name = (null)}
2019-08-08 14:40:57.952453+0800 YSC-GCD-demo[17313:4203079] 2---<NSThread: 0x6000015a0840>{number = 3, name = (null)}
2019-08-08 14:40:59.952943+0800 YSC-GCD-demo[17313:4203079] 3---<NSThread: 0x6000015a0840>{number = 3, name = (null)}


在 **异步执行** + **串行队列** 可以看到：

* 开启了一条新线程（**异步执行** 具备开启新线程的能力，**串行队列** 只开启一个线程）。
* 所有任务是在打印的 `syncConcurrent---begin` 和 `syncConcurrent---end` 之后才开始执行的（异步执行 不会做任何等待，可以继续执行任务）。
任务是按顺序执行的（串行队列 每次只有一个任务被执行，任务一个接一个按顺序执行）。

下边讲讲刚才我们提到过的：**主队列**。

主队列：GCD 默认提供的 **串行队列**。

* 默认情况下，平常所写代码是直接放在主队列中的。
* 所有放在主队列中的任务，都会放到主线程中执行。
* 可使用 `dispatch_get_main_queue()` 获得主队列。

### 同步执行 + 主队列

**同步执行** + **主队列** 在不同线程中调用结果也是不一样，在主线程中调用会发生死锁问题，而在其他线程中调用则不会。

#### 在主线程中调用 同步执行 + 主队列

互相等待卡住不可行

```
/**
 * 同步执行 + 主队列
 * 特点(主线程调用)：互等卡主不执行。
 * 特点(其他线程调用)：不会开启新线程，执行完一个任务，再执行下一个任务。
 */
- (void)syncMain {
    
    NSLog(@"currentThread---%@",[NSThread currentThread]);  // 打印当前线程
    NSLog(@"syncMain---begin");
    
    dispatch_queue_t queue = dispatch_get_main_queue();
    
    dispatch_sync(queue, ^{
        // 追加任务 1
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"1---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    dispatch_sync(queue, ^{
        // 追加任务 2
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"2---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    dispatch_sync(queue, ^{
        // 追加任务 3
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"3---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    NSLog(@"syncMain---end");
}
```

>输出结果
2019-08-08 14:43:58.062376+0800 YSC-GCD-demo[17371:4213562] currentThread---<NSThread: 0x6000026e2940>{number = 1, name = main}
2019-08-08 14:43:58.062518+0800 YSC-GCD-demo[17371:4213562] syncMain---begin
(lldb)

在主线程中使用 **同步执行** + **主队列** 可以惊奇的发现：

追加到主线程的任务 1、任务 2、任务 3 都不再执行了，而且 `syncMain---end` 也没有打印，在 XCode 9 及以上版本上还会直接报崩溃。这是为什么呢？

这是因为我们在主线程中执行 `syncMain` 方法，相当于把 `syncMain` 任务放到了主线程的队列中。而 **同步执行** 会等待当前队列中的任务执行完毕，才会接着执行。那么当我们把 `任务 1` 追加到主队列中，`任务 1` 就在等待主线程处理完 `syncMain` 任务。而`syncMain` 任务需要等待 `任务 1` 执行完毕，才能接着执行。

那么，现在的情况就是 `syncMain` 任务和 `任务 1` 都在等对方执行完毕。这样大家互相等待，所以就卡住了，所以我们的任务执行不了，而且 `syncMain---end` 也没有打印。


#### 在其他线程中调用 同步执行 + 主队列

```
// 使用 NSThread 的 detachNewThreadSelector 方法会创建线程，并自动启动线程执行 selector 任务
[NSThread detachNewThreadSelector:@selector(syncMain) toTarget:self withObject:nil];
```

>输出结果：
2019-08-08 14:51:38.137978+0800 YSC-GCD-demo[17482:4237818] currentThread---<NSThread: 0x600001dd6c00>{number = 3, name = (null)}
2019-08-08 14:51:38.138159+0800 YSC-GCD-demo[17482:4237818] syncMain---begin
2019-08-08 14:51:40.149065+0800 YSC-GCD-demo[17482:4237594] 1---<NSThread: 0x600001d8d380>{number = 1, name = main}
2019-08-08 14:51:42.151104+0800 YSC-GCD-demo[17482:4237594] 2---<NSThread: 0x600001d8d380>{number = 1, name = main}
2019-08-08 14:51:44.152583+0800 YSC-GCD-demo[17482:4237594] 3---<NSThread: 0x600001d8d380>{number = 1, name = main}
2019-08-08 14:51:44.152767+0800 YSC-GCD-demo[17482:4237818] syncMain---end

在其他线程中使用 **同步执行** + **主队列** 可看到：

*所有任务都是在主线程（非当前线程）中执行的，没有开启新的线程（所有放在主队列中的任务，都会放到主线程中执行）。
* 所有任务都在打印的 `syncConcurrent---begin` 和 `syncConcurrent---end` 之间执行（同步任务 需要等待队列的任务执行结束）。
任务是按顺序执行的（主队列是 串行队列，每次只有一个任务被执行，任务一个接一个按顺序执行）。

为什么现在就不会卡住了呢？

因为`syncMain` 任务 放到了其他线程里，而 `任务 1`、`任务 2`、`任务 3` 都在追加到主队列中，这三个任务都会在主线程中执行。`syncMain` 任务 在其他线程中执行到追加 `任务 1` 到主队列中，因为主队列现在没有正在执行的任务，所以，会直接执行主队列的 `任务1`，等 `任务1` 执行完毕，再接着执行 `任务 2`、`任务 3`。所以这里不会卡住线程，也就不会造成死锁问题。

### 异步执行 + 主队列

只在主线程中执行任务，执行完一个任务，再执行下一个任务。

```
/**
 * 异步执行 + 主队列
 * 特点：只在主线程中执行任务，执行完一个任务，再执行下一个任务
 */
- (void)asyncMain {
    NSLog(@"currentThread---%@",[NSThread currentThread]);  // 打印当前线程
    NSLog(@"asyncMain---begin");
    
    dispatch_queue_t queue = dispatch_get_main_queue();
    
    dispatch_async(queue, ^{
        // 追加任务 1
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"1---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    dispatch_async(queue, ^{
        // 追加任务 2
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"2---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    dispatch_async(queue, ^{
        // 追加任务 3
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"3---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    NSLog(@"asyncMain---end");
}
```

>输出结果：
2019-08-08 14:53:27.023091+0800 YSC-GCD-demo[17521:4243690] currentThread---<NSThread: 0x6000022a1380>{number = 1, name = main}
2019-08-08 14:53:27.023247+0800 YSC-GCD-demo[17521:4243690] asyncMain---begin
2019-08-08 14:53:27.023399+0800 YSC-GCD-demo[17521:4243690] asyncMain---end
2019-08-08 14:53:29.035565+0800 YSC-GCD-demo[17521:4243690] 1---<NSThread: 0x6000022a1380>{number = 1, name = main}
2019-08-08 14:53:31.036565+0800 YSC-GCD-demo[17521:4243690] 2---<NSThread: 0x6000022a1380>{number = 1, name = main}
2019-08-08 14:53:33.037092+0800 YSC-GCD-demo[17521:4243690] 3---<NSThread: 0x6000022a1380>{number = 1, name = main}

在 **异步执行** + **主队列** 可以看到：

* 所有任务都是在当前线程（主线程）中执行的，并没有开启新的线程（虽然 **异步执行** 具备开启线程的能力，但因为是主队列，所以所有任务都在主线程中）。
* 所有任务是在打印的 `syncConcurrent---begin` 和 `syncConcurrent---end` 之后才开始执行的（异步执行不会做任何等待，可以继续执行任务）。
任务是按顺序执行的（因为主队列是 **串行队列**，每次只有一个任务被执行，任务一个接一个按顺序执行）。

### GCD 线程间的通信

在 iOS 开发过程中，我们一般在主线程里边进行 UI 刷新，例如：点击、滚动、拖拽等事件。我们通常把一些耗时的操作放在其他线程，比如说图片下载、文件上传等耗时操作。而当我们有时候在其他线程完成了耗时操作时，需要回到主线程，那么就用到了线程之间的通讯。

```
/**
 * 线程间通信
 */
- (void)communication {
    // 获取全局并发队列
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    // 获取主队列
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    
    dispatch_async(queue, ^{
        // 异步追加任务 1
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"1---%@",[NSThread currentThread]);      // 打印当前线程
        
        // 回到主线程
        dispatch_async(mainQueue, ^{
            // 追加在主线程中执行的任务
            [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
            NSLog(@"2---%@",[NSThread currentThread]);      // 打印当前线程
        });
    });
}
```

>输出结果：
2019-08-08 14:56:22.973318+0800 YSC-GCD-demo[17573:4253201] 1---<NSThread: 0x600001846080>{number = 3, name = (null)}
2019-08-08 14:56:24.973902+0800 YSC-GCD-demo[17573:4253108] 2---<NSThread: 0x60000181e940>{number = 1, name = main}

可以看到在其他线程中先执行任务，执行完了之后回到主线程执行主线程的相应操作。

## Dispatch Framework

### Queues and Tasks

#### Dispatch Queue

##### Creating a Dispatch Queue

* dispatch_get_main_queue


>SDK iOS 8.0+ 
>dispatch_queue_main_t dispatch_get_main_queue(void);

```
dispatch_queue_t mainQueue =  dispatch_get_main_queue();
```

* dispatch_get_global_queue

>SDK iOS 4.0+
>dispatch_queue_global_t dispatch_get_global_queue(long identifier, unsigned long flags);

```
dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
```

* dispatch_queue_create

>SDK iOS 4.0+
>dispatch_queue_t dispatch_queue_create(const char *label, dispatch_queue_attr_t attr);

```
// 串行队列的创建方法
dispatch_queue_t queue = dispatch_queue_create("net.bujige.testQueue", DISPATCH_QUEUE_SERIAL);
// 并发队列的创建方法
dispatch_queue_t queue = dispatch_queue_create("net.bujige.testQueue", DISPATCH_QUEUE_CONCURRENT);
```

* dispatch_queue_create_with_target

>SDK iOS 10.0+
>dispatch_queue_t dispatch_queue_create_with_target(const char *label, dispatch_queue_attr_t attr, dispatch_queue_t target);

```
dispatch_queue_t queue =  dispatch_queue_create_with_target("com.ifx", DISPATCH_QUEUE_CONCURRENT, dispatch_get_main_queue());
dispatch_async(queue, ^{
    NSLog(@"1 %@ %@",[NSThread currentThread],queue);
});

dispatch_async(queue, ^{
    NSLog(@"2 %@ %@",[NSThread currentThread],queue);
});

dispatch_async(queue, ^{
    NSLog(@"3 %@ %@",[NSThread currentThread],queue);
});

log:

2020-05-03 17:43:23.471945+0800 IFXFramework[3751:4922662] 1 <NSThread: 0x600001726d00>{number = 1, name = main} <OS_dispatch_queue_concurrent: com.ifx>
2020-05-03 17:43:23.472165+0800 IFXFramework[3751:4922662] 2 <NSThread: 0x600001726d00>{number = 1, name = main} <OS_dispatch_queue_concurrent: com.ifx>
2020-05-03 17:43:23.472442+0800 IFXFramework[3751:4922662] 3 <NSThread: 0x600001726d00>{number = 1, name = main} <OS_dispatch_queue_concurrent: com.ifx>

和 dispatch_set_target_queue 的第二层用法一致
```

* dispatch_queue_t

>typedef NSObject<OS_dispatch_queue> *dispatch_queue_t;



##### Configuring Queue Execution Paramters

* dispatch_queue_attr_make_with_qos_class

>SDK iOS 8.0+
>dispatch_queue_attr_t dispatch_queue_attr_make_with_qos_class(dispatch_queue_attr_t attr, dispatch_qos_class_t qos_class, int relative_priority);

```
设置队列的优先级
dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, 0);
dispatch_queue_t queue = dispatch_queue_create("com.starming.gcddemo.qosqueue", attr);

The global queue priorities map to the following quality-of-service classes:

DISPATCH_QUEUE_PRIORITY_HIGH maps to the QOS_CLASS_USER_INITIATED class.

DISPATCH_QUEUE_PRIORITY_DEFAULT maps to the QOS_CLASS_DEFAULT class.

DISPATCH_QUEUE_PRIORITY_LOW maps to the QOS_CLASS_UTILITY class.

DISPATCH_QUEUE_PRIORITY_BACKGROUND maps to the QOS_CLASS_BACKGROUND class.
```

* dispatch_queue_get_qos_class

>dispatch_qos_class_t dispatch_queue_get_qos_class(dispatch_queue_t queue, int *relative_priority_ptr);

```
获取某个队列的dispatch_qos_class_t
```

* dispatch_queue_attr_make_initially_inactive

>SDK iOS 10.0+
>dispatch_queue_attr_t dispatch_queue_attr_make_initially_inactive(dispatch_queue_attr_t attr);

* dispatch_queue_attr_make_with_autorelease_frequency

>SDKs iOS 10.0+
>dispatch_queue_attr_t dispatch_queue_attr_make_with_autorelease_frequency(dispatch_queue_attr_t attr, dispatch_autorelease_frequency_t frequency);

##### Executing Tasks Asynchronously

* dispatch_async

>SDK iOS 4.0+
>void dispatch_async(dispatch_queue_t queue, dispatch_block_t block);

* dispatch_async_f

>SDK iOS 4.0+
>void dispatch_async_f(dispatch_queue_t queue, void *context, dispatch_function_t work);

* dispatch_after

>SDK iOS 4.0+
>void dispatch_after(dispatch_time_t when, dispatch_queue_t queue, dispatch_block_t block);

```
dispatch_after只是延时提交block，不是延时立刻执行。

 double delayInSeconds = 2.0;
 dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, (int64_t) (delayInSeconds * NSEC_PER_SEC));
 dispatch_after(time, dispatch_get_main_queue(), ^(void){
     //...
 });
```

* dispatch_after_f

>SDK iOS 4.0+
>void dispatch_after_f(dispatch_time_t when, dispatch_queue_t queue, void *context, dispatch_function_t work);

* dispatch_function_t

>typedef void (*dispatch_function_t)(void *);

* dispatch_block_t

> typedef void (^dispatch_block_t)(void);

##### Executing Tasks Synchronously

* dispatch_sync

>SDK iOS 4.0+
>void dispatch_sync(dispatch_queue_t queue, dispatch_block_t block);

* dispatch_sync_f

>SDK iOS 4.0+
>void dispatch_sync_f(dispatch_queue_t queue, void *context, dispatch_function_t work);

##### Executing a Task Only Once

* dispatch_once

>SDK iOS 4.0+
>void dispatch_once(dispatch_once_t *predicate, dispatch_block_t block);

```
//单例
+ (instancetype)sharedManager{
     static GCDManager *manager;
     //只运行一次
     static dispatch_once_t onceToken;
     dispatch_once(&onceToken, ^{
          manager = [[GCDManager allock] init];
     });
     return manager;
}
```

* dispatch_once_f

>SDK iOS 4.0+
>void dispatch_once_f(dispatch_once_t *predicate, void *context, dispatch_function_t function);

* dispatch_once_t

>SDK iOS 4.0+
>typedef intptr_t dispatch_once_t;

##### Executing a Task In Parallel

* dispatch_apply

>SDK iOS 4.0+
>void dispatch_apply(size_t iterations, dispatch_queue_t queue, void (^block)(size_t));

`dispatch_apply`函数是`dispatch_sync`函数和`Dispatch Group`的关联API,该函数按指定的次数将指定的`Block`追加到指定的`Dispatch Queue`中,并等到全部的处理执行结束.

```
dispatch_queue_t queue = dispatch_get_global_queu(0, 0);
dispatch_apply(10, queue, ^(size_t index){
NSLog(@"%@", @(index));
});
```

* dispatch_apply_f

>SDK iOS 4.0+
>void dispatch_apply_f(size_t iterations, dispatch_queue_t queue, void *context, void (*work)(void *, size_t));

##### Managing Queue In Attributes

* dispatch_queue_get_label

>SDK iOS 4.0+
>const char * dispatch_queue_get_label(dispatch_queue_t queue);

```
看过SDWebImage源码的应该看过它里面有这样一个宏：

#ifndef dispatch_queue_async_safe
#define dispatch_queue_async_safe(queue, block)\
    if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(queue)) {\
        block();\
    } else {\
        dispatch_async(queue, block);\
    }
#endif

#ifndef dispatch_main_async_safe
#define dispatch_main_async_safe(block) dispatch_queue_async_safe(dispatch_get_main_queue(), block)
#endif

其中通过如下一句代码来判断当前是否是在主线程

strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(dispatch_get_main_queue())) == 0
```

* dispatch_set_target_queue

>SDK iOS 4.0+
>void dispatch_set_target_queue(dispatch_object_t object, dispatch_queue_t queue);

1. 系统的`Global Queue`是可以指定优先级的，那我们可以用到`dispatch_set_target_queue`这个方法来指定自己创建队列的优先级

```
dispatch_queue_t serialDiapatchQueue=dispatch_queue_create("com.GCD_demo.www", DISPATCH_QUEUE_SERIAL);
dispatch_queue_t dispatchgetglobalqueue=dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
dispatch_set_target_queue(serialDiapatchQueue, dispatchgetglobalqueue);
dispatch_async(serialDiapatchQueue, ^{
  NSLog(@"我优先级低，先让让");
});
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
  NSLog(@"我优先级高,我先block");
});
```

执行结果
```
2016-07-21 17:22:02.512 GCD_Demo[9902:1297023] 我优先级高,我先block
2016-07-21 17:22:02.512 GCD_Demo[9902:1297035] 我优先级低，先让让
```

2. `dispatch_set_target_queue`除了能用来设置队列的优先级之外，还能够创建队列的层次体系，当我们想让不同队列中的任务同步的执行时，我们可以创建一个串行队列，然后将这些队列的target指向新创建的队列即可

```
dispatch_queue_t targetQueue = dispatch_queue_create("target_queue", DISPATCH_QUEUE_SERIAL);
dispatch_queue_t queue1 = dispatch_queue_create("queue1", DISPATCH_QUEUE_SERIAL);
dispatch_queue_t queue2 = dispatch_queue_create("queue2", DISPATCH_QUEUE_CONCURRENT);

dispatch_set_target_queue(queue1, targetQueue);
dispatch_set_target_queue(queue2, targetQueue);

dispatch_async(queue1, ^{
  [NSThread sleepForTimeInterval:3.f];
  NSLog(@"do job1");
  
});
dispatch_async(queue2, ^{
  [NSThread sleepForTimeInterval:2.f];
  NSLog(@"do job2");
  
});
dispatch_async(queue2, ^{
  [NSThread sleepForTimeInterval:1.f];
  NSLog(@"do job3");
  
});
```

执行结果

```
2016-07-21 17:28:54.327 GCD_Demo[10043:1303853] do job1
2016-07-21 17:28:56.331 GCD_Demo[10043:1303853] do job2
2016-07-21 17:28:57.335 GCD_Demo[10043:1303853] do job3
```

##### Getting And Setting Contextual Data

* dispatch_get_specific

>SDK iOS 5.0+
>void * dispatch_get_specific(const void *key);

获取当前调度队列的上下文键/值数据。

* dispatch_queue_set_specific

>SDK iOS 5.0+
>void dispatch_queue_set_specific(dispatch_queue_t queue, const void *key, void *context, dispatch_function_t destructor);


使用此方法将自定义的上下文与队列关联，运行中的队列可用dispatch_get_specific检索。

* dispatch_queue_get_specific

>SDK iOS 5.0+
>void * dispatch_queue_get_specific(dispatch_queue_t queue, const void *key);

是获取指定调度队列的上下文键/值数据。

```
static void *queueKey1 = "queueKey1";

dispatch_queue_t queue1 = dispatch_queue_create(queueKey1, DISPATCH_QUEUE_SERIAL);
dispatch_queue_set_specific(queue1, queueKey1, &queueKey1, NULL);

NSLog(@"1. 当前线程是: %@, 当前队列是: %@ 。",[NSThread currentThread],dispatch_get_current_queue());

if (dispatch_get_specific(queueKey1)) {
    //当前队列是主队列，不是queue1队列，所以取不到queueKey1对应的值，故而不执行
    NSLog(@"2. 当前线程是: %@, 当前队列是: %@ 。",[NSThread currentThread],dispatch_get_current_queue());
    [NSThread sleepForTimeInterval:1];
}else{
    NSLog(@"3. 当前线程是: %@, 当前队列是: %@ 。",[NSThread currentThread],dispatch_get_current_queue());
    [NSThread sleepForTimeInterval:1];
}

dispatch_sync(queue1, ^{
    NSLog(@"4. 当前线程是: %@, 当前队列是: %@ 。",[NSThread currentThread],dispatch_get_current_queue());
    [NSThread sleepForTimeInterval:1];
    
    if (dispatch_get_specific(queueKey1)) {
         //当前队列是queue1队列，所以能取到queueKey1对应的值，故而执行
        NSLog(@"5. 当前线程是: %@, 当前队列是: %@ 。",[NSThread currentThread],dispatch_get_current_queue());
        [NSThread sleepForTimeInterval:1];
    }else{
        NSLog(@"6. 当前线程是: %@, 当前队列是: %@ 。",[NSThread currentThread],dispatch_get_current_queue());
        [NSThread sleepForTimeInterval:1];
    }
});
dispatch_async(queue1, ^{
    NSLog(@"7. 当前线程是: %@, 当前队列是: %@ 。",[NSThread currentThread],dispatch_get_current_queue());
    [NSThread sleepForTimeInterval:1];
});
```

>注：dispatch_get_current_queue()已经被遗弃了。
>
>通过如下一句代码来判断当前是否是在主线程
>strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(dispatch_get_main_queue())) == 0

输出结果：

```
2016-02-19 14:31:23.390 gcd[96865:820267] 1.当前线程是: <NSThread: 0x1001053e0>{number = 1, name = main},当前队列是: <OS_dispatch_queue: com.apple.main-thread[0x100059ac0]>。

2016-02-19 14:31:23.391 gcd[96865:820267] 3.当前线程是: <NSThread: 0x1001053e0>{number = 1, name = main},当前队列是: <OS_dispatch_queue: com.apple.main-thread[0x100059ac0]>。

2016-02-19 14:31:24.396 gcd[96865:820267] 4.当前线程是: <NSThread: 0x1001053e0>{number = 1, name = main},当前队列是: <OS_dispatch_queue: queueKey1[0x103000000]>。

2016-02-19 14:31:25.400 gcd[96865:820267] 5.当前线程是: <NSThread: 0x1001053e0>{number = 1, name = main},当前队列是: <OS_dispatch_queue: queueKey1[0x103000000]>。

2016-02-19 14:31:26.402 gcd[96865:820367] 7.当前线程是: <NSThread: 0x100105e10>{number = 2, name = (null)},当前队列是: <OS_dispatch_queue: queueKey1[0x103000000]>。
```

##### Managing the Main Dispatch Queue

* dispatch_main

>SDK iOS 4.0+
>void dispatch_main(void);

dispatch_main()的作用。退出主线程，让其他线程来执行主线程的任务。

**主线程和主队列的关系。**

有这么几个问题。
1. 主线程中的任务一定在主队列中执行吗？
2. 如何保证一定在主线程中执行？
3. 如何保证既在主线程中执行又在主队列中执行？

先来认识这几个方法

```
//给指定的队列设置标识
dispatch_queue_set_specific(dispatch_queue_t queue, const void *key,
        void *_Nullable context, dispatch_function_t _Nullable destructor);
queue：需要关联的queue，不允许传入NULL。
key：唯一的关键字。
context：要关联的内容，可以为NULL。
destructor：释放context的函数，当新的context被设置时，destructor会被调用

//获取当前所在队列的标识，根据唯一的key取出当前queue的context，如果当前queue没有key对应的context，则去queue的target queue取，取不着返回NULL，如果对全局队列取，也会返回NULL。
dispatch_get_specific(key)
//获取指定队列的标识
dispatch_queue_get_specific(dispatch_queue_t queue, const void *key);
```

**第一种情况**

```
//给主队列设置标识
dispatch_queue_set_specific(dispatch_get_main_queue(), key, @"main", NULL);
//放到同步队列中 全局并发队列中
dispatch_sync(dispatch_get_global_queue(0, 0), ^{
  NSLog(@"main thread: %d", [NSThread isMainThread]);
  // 判断是否是主队列
  void *value = dispatch_get_specific(key);//返回与当前分派队列关联的键的值。
  NSLog(@"main queue: %d", value != NULL);
});
```

打印的结果：

```
main thread: 1 //是主线程
main queue: 0 //不是主队列
```

**分析**：不是主队列是因为 在全局并发队列中，但是在全局并发队列中，为何又在主线程执行呢？经过查阅资料发现，苹果是为了性能，所以在主线程执行，线程切换是耗性能的。

**第二种情况**

```
//异步加入到全局并发队列中
dispatch_async(dispatch_get_global_queue(0, 0), ^{
//异步加入到主队列中
  dispatch_async(dispatch_get_main_queue(), ^{
      NSLog(@"main thread: %d", [NSThread isMainThread]);
      NSLog(@"%@",[NSThread currentThread]);
      // 判断是否是主队列
      void *value = dispatch_get_specific(key);//返回与当前分派队列关联的键的值。
      NSLog(@"main queue: %d", value != NULL);
  });
});
NSLog(@"dispatch_main会堵塞主线程");
dispatch_main();
NSLog(@"查看是否堵塞主线程");
```

打印结果：

```
dispatch_main会堵塞主线程
main thread: 0  //不是主线程
<NSThread: 0x600000b73b80>{number = 3, name = (null)}//不是主线程
main queue: 1   //是主队列
```

**分析**：明明是在dispatch_get_main_queue()中，为何不是在主线程执行呢？是不是很颠覆三观？原因再 dispatch_main()这个函数。这个函数的作用，经过查阅资料和读文档获取：

```
/*!
 * @function dispatch_main
 *
 * @abstract
 * Execute blocks submitted to the main queue.
 * 执行提交给主队列的任务blocks
 *
 * @discussion
 * This function "parks" the main thread and waits for blocks to be submitted
 * 
 * to the main queue. This function never returns.
 * 
 * Applications that call NSApplicationMain() or CFRunLoopRun() on the
 * main thread do not need to call dispatch_main().
 *
 */
API_AVAILABLE(macos(10.6), ios(4.0))
DISPATCH_EXPORT DISPATCH_NOTHROW DISPATCH_NORETURN
void
dispatch_main(void);
这个函数会阻塞主线程并且等待提交给主队列的任务blocks完成，这个函数永远不会返回.
这个方法会阻塞主线程，然后在其它线程中执行主队列中的任务，这个方法永远不会返回（意思会卡住主线程）.
```

也就是说，把主队列中的任务在其他线程中执行。所以用了dispatch_get_main_queue也不一定是主线程的。

添加如下代码

```
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSLog(@"1");
}
```

我们会发现打印这句话

```
Attempting to wake up main runloop, but the main thread as exited. This message will only log once. Break on _CFRunLoopError_MainThreadHasExited to debug.
```

这就完全验证了dispatch_main()的作用。退出主线程，让其他线程来执行主线程的任务。

当我们把dispatch_main()注释掉之后。上面那段代码的打印

```
dispatch_main会堵塞主线程
查看是否堵塞主线程
 main thread: 1 //是主线程
 <NSThread: 0x600001596b80>{number = 1, name = main}//是主线程
main queue: 1//是主队列
```

**经过上面几种情况的分析，到底我们需要怎么搞才能确定是保证线程安全的呢？**

查阅了sdwebimage 3.8版本和 4.4.2版本，发现了两种不同的写法

**3.8版本**

```
#define dispatch_main_sync_safe(block)\
if ([NSThread isMainThread]) {\
  block();\
} else {\
  dispatch_sync(dispatch_get_main_queue(), block);\
}

#define dispatch_main_async_safe(block)\
if ([NSThread isMainThread]) {\
  block();\
} else {\
  dispatch_async(dispatch_get_main_queue(), block);\
}
```

**4.4.2版本**

```
#ifndef dispatch_queue_async_safe
#define dispatch_queue_async_safe(queue, block)\
if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(queue)) {\
  block();\
} else {\
  dispatch_async(queue, block);\
}
#endif

#ifndef dispatch_main_async_safe
#define dispatch_main_async_safe(block) dispatch_queue_async_safe(dispatch_get_main_queue(), block)
#endif
```

那么到底上面两个版本哪个版本才是最安全的呢？
既然sdwebImage最新版本换了方式，那么肯定，4.2.2是最安全的。

[iOS UI 操作在主线程不一定安全？](https://www.jianshu.com/p/cb3dbeaa8b18)

**第一种方案**

```
static void *mainQueueKey = "mainQueueKey";
dispatch_queue_set_specific(dispatch_get_main_queue(), mainQueueKey, &mainQueueKey, NULL);
if (dispatch_get_specific(mainQueueKey)) {
    // do something in main queue
    //通过这样判断，就可以真正保证(我们在不主动搞事的情况下)，任务一定是放在主队列中的
} else {
    // do something in other queue
}
```

**第二种方案 ，sdwebImage的方案**

```
//获取主队列名
const char *main_queue_name = dispatch_queue_get_label(dispatch_get_main_queue());
const char *other_queue_name = "other_queue_name";
NSLog(@"\nmain_queue_name====%s", main_queue_name);
//创建一个和主队列名字一样的串行队列
dispatch_queue_t customSerialQueue = dispatch_queue_create(other_queue_name, DISPATCH_QUEUE_SERIAL);
if (strcmp(dispatch_queue_get_label(customSerialQueue), dispatch_queue_get_label(dispatch_get_main_queue())) == 0) {
  //名字一样
  NSLog(@"\ncutomSerialQueue is main queue");
  dispatch_async(customSerialQueue, ^{
      //将更新UI的操作放到这个队列
      if ([NSThread isMainThread]) {
          NSLog(@"i am mainThread ");
      }

      NSLog(@"\nUI Action Finished");
  });
  
} else {
  //名字不一样
  NSLog(@"cutomSerialQueue is main queue");
  NSLog(@"main thread: %d", [NSThread isMainThread]);
  // 判断是否是主队列
  void *value = dispatch_get_specific(key);//返回与当前分派队列关联的键的值。
  NSLog(@"main queue: %d", value != NULL);
  
}
```

**总结**：我们都知道主队列是串行队列，所以串行队列肯定不会开辟新的线程，也就是说主队列一定会是在主线程执行。

对于更新UI这种操作，要保证在主线程执行，也就是要保证在主队列执行。
1. 主线程中的任务一定在主队列中执行吗？
不是。

2. 如何保证一定在主线程中执行？
只要保证在主队列中执行就可以了。

3. 如何保证既在主线程中执行又在主队列中执行？
保证在主队列中就会及在主线程又在主队列。

#### Dispatch Work Item

##### Creating a Work Item

* dispatch_block_create

>SDK iOS 8.0+
>dispatch_block_t dispatch_block_create(dispatch_block_flags_t flags, dispatch_block_t block);


* dispatch_block_create_with_qos_class

>SDK iOS 8.0+
>dispatch_block_t dispatch_block_create_with_qos_class(dispatch_block_flags_t flags, dispatch_qos_class_t qos_class, int relative_priority, dispatch_block_t block);

* dispatch_block_t

>SDK iOS 4.0+
>typedef void (^dispatch_block_t)(void);

* dispatch_block_flags_t

>SDK iOS 8.0+
>Flags
>DISPATCH_BLOCK_ASSIGN_CURRENT
>DISPATCH_BLOCK_BARRIER
>DISPATCH_BLOCK_DETACHED
>DISPATCH_BLOCK_ENFORCE_QOS_CLASS
>DISPATCH_BLOCK_INHERIT_QOS_CLASS
>DISPATCH_BLOCK_NO_QOS_CLASS

**创建block**

**第一种方式如下：**

```
dispatch_block_t dispatch_block_create(dispatch_block_flags_t flags, dispatch_block_t block);
```

在该函数中，`flags` 参数用来设置 `block` 的标记，`block` 参数用来设置具体的任务。`flags` 的类型为 `dispatch_block_flags_t` 的枚举，用于设置 `block` 的标记，定义如下：

```
DISPATCH_ENUM(dispatch_block_flags, unsigned long,
    DISPATCH_BLOCK_BARRIER = 0x1,
    DISPATCH_BLOCK_DETACHED = 0x2,
    DISPATCH_BLOCK_ASSIGN_CURRENT = 0x4,
    DISPATCH_BLOCK_NO_QOS_CLASS = 0x8,
    DISPATCH_BLOCK_INHERIT_QOS_CLASS = 0x10,
    DISPATCH_BLOCK_ENFORCE_QOS_CLASS = 0x20,
);
```

**另一种方式如下:**

```
dispatch_block_t dispatch_block_create_with_qos_class(dispatch_block_flags_t flags, dispatch_qos_class_t qos_class, int relative_priority, dispatch_block_t block);
```

相比于 `dispatch_block_create` 函数，这种方式在创建 `block` 的同时可以指定了相应的优先级。`dispatch_qos_class_t` 是 `qos_class_t` 的别名，定义如下：

```
#if __has_include(<sys/qos.h>)
typedef qos_class_t dispatch_qos_class_t;
#else
typedef unsigned int dispatch_qos_class_t;
#endif
```

而 `qos_class_t` 是一种枚举，有以下类型：

* QOS_CLASS_USER_INTERACTIVE：`user interactive` 等级表示任务需要被立即执行，用来在响应事件之后更新 UI，来提供好的用户体验。这个等级最好保持小规模。

* QOS_CLASS_USER_INITIATED：`user initiated` 等级表示任务由 UI 发起异步执行。适用场景是需要及时结果同时又可以继续交互的时候。

* QOS_CLASS_DEFAULT：`default` 默认优先级

* QOS_CLASS_UTILITY：`utility` 等级表示需要长时间运行的任务，伴有用户可见进度指示器。经常会用来做计算，I/O，网络，持续的数据填充等任务。这个任务节能。

* QOS_CLASS_BACKGROUND：`background` 等级表示用户不会察觉的任务，使用它来处理预加载，或者不需要用户交互和对时间不敏感的任务。

* QOS_CLASS_UNSPECIFIED：`unspecified` 未指明

事例：

```
dispatch_queue_t concurrentQuene = dispatch_queue_create("concurrentQuene", DISPATCH_QUEUE_CONCURRENT);

dispatch_block_t block = dispatch_block_create(0, ^{
    NSLog(@"normal do some thing...");
});
dispatch_async(concurrentQuene, block);

//
dispatch_block_t qosBlock = dispatch_block_create_with_qos_class(0, QOS_CLASS_DEFAULT, 0, ^{
    NSLog(@"qos do some thing...");
});
dispatch_async(concurrentQuene, qosBlock);
```

##### Scheduling Work Items

* dispatch_block_perform

>SDK iOS 8.0+
>void dispatch_block_perform(dispatch_block_flags_t flags, dispatch_block_t block);

```
DISPATCH_OPTIONS(dispatch_block_flags, unsigned long,
	DISPATCH_BLOCK_BARRIER
			DISPATCH_ENUM_API_AVAILABLE(macos(10.10), ios(8.0)) = 0x1,
	DISPATCH_BLOCK_DETACHED
			DISPATCH_ENUM_API_AVAILABLE(macos(10.10), ios(8.0)) = 0x2,
	DISPATCH_BLOCK_ASSIGN_CURRENT
			DISPATCH_ENUM_API_AVAILABLE(macos(10.10), ios(8.0)) = 0x4,
	DISPATCH_BLOCK_NO_QOS_CLASS
			DISPATCH_ENUM_API_AVAILABLE(macos(10.10), ios(8.0)) = 0x8,
	DISPATCH_BLOCK_INHERIT_QOS_CLASS
			DISPATCH_ENUM_API_AVAILABLE(macos(10.10), ios(8.0)) = 0x10,
	DISPATCH_BLOCK_ENFORCE_QOS_CLASS
			DISPATCH_ENUM_API_AVAILABLE(macos(10.10), ios(8.0)) = 0x20,
);
```

创建一个dispatch_block_t变量，并在该任务队列中以同步的方式来执行block中的内容。

```
dispatch_block_perform(DISPATCH_BLOCK_BARRIER, ^{
        NSLog(@"Start");
        [NSThread sleepForTimeInterval:3];
        NSLog(@"End");
});
```

上面的代码以下代码效果一样

```
dispatch_block_t b = dispatch_block_create(flags, block);
b();
Block_release(b);
```

但是`dispatch_block_perform`方法可以以更加高效的方式来进行以上步骤，而不需要在对象分配时将block拷贝到指定堆中。

##### Adding a Completion Handler

* dispatch_block_notify

>SDK iOS 8.0+
>void dispatch_block_notify(dispatch_block_t block, dispatch_queue_t queue, dispatch_block_t notification_block);

dispatch_block_notify 函数不会阻塞当前线程

```
NSLog(@"---- 开始设置任务 ----");
dispatch_queue_t serialQueue =   dispatch_queue_create("com.xh.serialqueue",   DISPATCH_QUEUE_SERIAL);
// 耗时任务
dispatch_block_t taskBlock = dispatch_block_create(0, ^{
    NSLog(@"开始耗时任务");
    [NSThread sleepForTimeInterval:2.f];
    NSLog(@"完成耗时任务");
});

dispatch_async(serialQueue, taskBlock);
// 更新 UI
dispatch_block_t refreshUI = dispatch_block_create(0, ^{
    NSLog(@"更新 UI");
});
// 设置监听
dispatch_block_notify(taskBlock, dispatch_get_main_queue(), refreshUI);
NSLog(@"---- 完成设置任务 ----");
```

##### Delaying Execution of a Work Item

* dispatch_block_wait

>SDK iOS 8.0+
>long dispatch_block_wait(dispatch_block_t block, dispatch_time_t timeout);

1. 同步地等待，直到执行指定的调度块已经完成，或者直到指定的超时已经过去。
2. 该函数会阻塞当前线程进行等待。传入需要设置的 block 和等待时间 timeout 。timeout 参数表示函数在等待 block 执行完毕时，应该等待多久。如果执行 block 所需的时间小于 timeout ，则返回 0，否则返回非 0 值。此参数也可以取常量DISPATCH_TIME_FOREVER ，这表示函数会一直等待 block 执行完，而不会超时。可以使用 dispatch_time 函数和 DISPATCH_TIME_NOW 常量来方便的设置具体的超时时间。
3. 如果 block 执行完成， dispatch_block_wait 就会立即返回。不能使用 dispatch_block_wait 来等待同一个 block 的多次执行全部结束；这种情况可以考虑使用dispatch_group_wait 来解决。也不能在多个线程中，同时等待同一个 block 的结束。同一个 block 只能执行一次，被等待一次。
4. 注意：因为 dispatch_block_wait 会阻塞当前线程，所以不应该放在主线程中调用

```
dispatch_queue_t concurrentQuene = dispatch_queue_create("concurrentQuene", DISPATCH_QUEUE_CONCURRENT);

dispatch_async(concurrentQuene, ^{
  dispatch_queue_t allTasksQueue = dispatch_queue_create("allTasksQueue", DISPATCH_QUEUE_CONCURRENT);
  
  dispatch_block_t block = dispatch_block_create(0, ^{
      NSLog(@"开始执行");
      [NSThread sleepForTimeInterval:3];
      NSLog(@"结束执行");
  });
  
  dispatch_async(allTasksQueue, block);
  // 等待时长，10s 之后超时
  dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC));
  long resutl = dispatch_block_wait(block, timeout);
  if (resutl == 0) {
      NSLog(@"执行成功");
  } else {
      NSLog(@"执行超时");
  }
});
```

##### Canceling a Working Item

* dispatch_block_cancel

>SDK iOS 8.0+
>void dispatch_block_cancel(dispatch_block_t block);

这个函数用异步的方式取消指定的block

```
dispatch_queue_t myQueue = dispatch_queue_create("myqueue", DISPATCH_QUEUE_SERIAL);
// 耗时任务
dispatch_block_t firstBlock = dispatch_block_create(0, ^{
    NSLog(@"开始第一个任务:%d",[NSThread isMainThread]);
    [NSThread sleepForTimeInterval:1.5f];
    NSLog(@"结束第一个任务");
});
// 耗时任务
dispatch_block_t secBlock = dispatch_block_create(0, ^{
    NSLog(@"开始第二个任务:%d",[NSThread isMainThread]);
    [NSThread sleepForTimeInterval:2.f];
    NSLog(@"结束第二个任务");
});
dispatch_async(myQueue, firstBlock);
dispatch_async(myQueue, secBlock);
// 等待 1s，让第一个任务开始运行,因为myQueue是串行队列，遵守fifo先进先出的规则，所以必须先执行完block1，才能执行block2
[NSThread sleepForTimeInterval:1];
NSLog(@"休眠：%d",[NSThread isMainThread]);
dispatch_block_cancel(firstBlock);
NSLog(@"准备取消第一个任务");
dispatch_block_cancel(secBlock);
NSLog(@"准备取消第二个任务");
```

打印的结果为：

```
2017-07-06 18:32:04.046 多线程-GCD[6427:205689] 开始第一个任务:0
2017-07-06 18:32:05.047 多线程-GCD[6427:205642] 休眠：1
2017-07-06 18:32:05.047 多线程-GCD[6427:205642] 准备取消第一个任务
2017-07-06 18:32:05.047 多线程-GCD[6427:205642] 准备取消第二个任务
2017-07-06 18:32:05.547 多线程-GCD[6427:205689] 结束第一个任务

可见 dispatch_block_cancel 对已经在执行的任务不起作用，只能取消尚未执行的任务
```

* dispatch_block_testcancel

>SDK iOS 8.0+
>long dispatch_block_testcancel(dispatch_block_t block);

测试指定的 block 是否被取消。返回非0代表已被取消；返回0代表没有取消。

```
dispatch_queue_t queue = dispatch_queue_create("queue", DISPATCH_QUEUE_SERIAL);
dispatch_block_t block1 = dispatch_block_create(0, ^{
    NSLog(@"block1 begin");
    [NSThread sleepForTimeInterval:1];
    NSLog(@"block1 done");
});
dispatch_block_t block2 = dispatch_block_create(0, ^{
    NSLog(@"block2");
});
dispatch_async(queue, block1);
dispatch_async(queue, block2);
//取消block2
dispatch_block_cancel(block2);
//测试block2是否被取消
NSLog(@"block2是否被取消:%ld",dispatch_block_testcancel(block2));
```

输出:

```
2020-02-01 20:29:42.118735+0800 多线程[7018:1278505] block1 begin
2020-02-01 20:29:42.118750+0800 多线程[7018:1278469] block2是否被取消:1
2020-02-01 20:29:43.122961+0800 多线程[7018:1278505] block1 done
```

#### Dispatch Group

##### Creating a Dispatch Group

>SDK iOS 4.0+

* dispatch_group_create

>dispatch_group_t dispatch_group_create(void);

* dispatch_group_t

>typedef NSObject<OS_dispatch_group> *dispatch_group_t;

* OS_dispatch_group

>@protocol OS_dispatch_group

##### Adding Work to Group

* dispatch_group_async

>void dispatch_group_async(dispatch_group_t group, dispatch_queue_t queue, dispatch_block_t block);

* dispatch_group_async_f

>void dispatch_group_async_f(dispatch_group_t group, dispatch_queue_t queue, void *context, dispatch_function_t work);

##### Add a Complition Handler

* dispatch_group_notify

>void dispatch_group_notify(dispatch_group_t group, dispatch_queue_t queue, dispatch_block_t block);

* dispatch_group_notify_f

>void dispatch_group_notify_f(dispatch_group_t group, dispatch_queue_t queue, void *context, dispatch_function_t work);

```
dispatch_queue_t serialQueue = dispatch_queue_create("serialQueue", DISPATCH_QUEUE_SERIAL);
dispatch_queue_t conCurrentQueue =  dispatch_queue_create("conCurrentQueue", DISPATCH_QUEUE_CONCURRENT);
dispatch_group_t group = dispatch_group_create();
dispatch_group_async(group, serialQueue, ^{
    NSLog(@"串行队列任务一开始");
    [NSThread sleepForTimeInterval:2];
    
    NSLog(@"串行队列任务一快结束:%@",[NSThread currentThread]);
});
dispatch_group_async(group, serialQueue, ^{
    NSLog(@"串行队列任务二开始");
    [NSThread sleepForTimeInterval:2];
    
    NSLog(@"串行队列任务二快结束:%@",[NSThread currentThread]);
});

dispatch_group_async(group, conCurrentQueue, ^{
   
    NSLog(@"并行队列任务二开始");
    [NSThread sleepForTimeInterval:2];
    
    NSLog(@"并行队列任务二快结束:%@",[NSThread currentThread]);
    
});
dispatch_group_notify(group, conCurrentQueue, ^{
   
    NSLog(@"被通知的并行队列任务三");
});  
//结果时“被通知的并行队列任务三”是在所有任务都执行完成后才执行
```

##### Waiting for Tasks to Finish Executing

* dispatch_group_wait

>long dispatch_group_wait(dispatch_group_t group, dispatch_time_t timeout);

```
dispatch_queue_t conCurrentQueue =  dispatch_queue_create("conCurrentQueue", DISPATCH_QUEUE_CONCURRENT);
dispatch_group_t group = dispatch_group_create();
dispatch_group_async(group, conCurrentQueue, ^{
    NSLog(@"任务一开始");
    [NSThread sleepForTimeInterval:2];
    
    NSLog(@"任务一快结束");
});
dispatch_group_async(group, conCurrentQueue, ^{
    NSLog(@"任务二开始");
    [NSThread sleepForTimeInterval:6];
    
    NSLog(@"任务二快结束");
});

dispatch_time_t time=dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC));
long result=dispatch_group_wait(group, time);
if (result==0) {
    NSLog(@"组的block全部执行完成");
}
else{
    NSLog(@"组的block没有全部执行完成，是timeout返回");
}
NSLog(@"-----------");
```

##### Update the Group Manually

* dispatch_group_enter

>void dispatch_group_enter(dispatch_group_t group);

* dispatch_group_leave

>void dispatch_group_leave(dispatch_group_t group);

1. 用这个方法指定一个操作将要加到 `group` 中,用来替代 `dispatch_group_async` ,注意它只能和 `dispatch_group_leave` 配对使用.
2. 这种方式比 `dispatch_group_async` 更加灵活.比如我们可以在任务的完成回调里面写 `dispatch_group_leave()`

```
dispatch_queue_t conCurrentQueue =  dispatch_queue_create("conCurrentQueue", DISPATCH_QUEUE_CONCURRENT);
dispatch_group_t group = dispatch_group_create();

dispatch_group_enter(group);
dispatch_async(conCurrentQueue, ^{
  NSLog(@"任务一开始");
  [NSThread sleepForTimeInterval:2];
  
  NSLog(@"任务一快结束");
  dispatch_group_leave(group);
});

dispatch_group_enter(group);
dispatch_async(conCurrentQueue, ^{
  NSLog(@"任务二开始");
  [NSThread sleepForTimeInterval:2];
  
  NSLog(@"任务二快结束");
  dispatch_group_leave(group);
});

dispatch_group_notify(group, conCurrentQueue, ^{
  NSLog(@"被通知任务开始");
});
NSLog(@"-----");
```

### Quality of Server

* dispatch_qos_class_t

>SDK iOS 8.0+
>typedef qos_class_t dispatch_qos_class_t;

* dispatch_queue_priority_t

>SDK iOS 4.3+
>typedef long dispatch_queue_priority_t;


>* DISPATCH_QUEUE_PRIORITY_HIGH
>* DISPATCH_QUEUE_PRIORITY_DEFAULT
>* DISPATCH_QUEUE_PRIORITY_LOW
>* DISPATCH_QUEUE_PRIORITY_BACKGROUND

### System Event Monitoring

#### Dispatch Source

##### Creating a Dispatch Source

* dispatch_source_create

>SDK iOS 4.0+
>dispatch_source_t dispatch_source_create(dispatch_source_type_t type, uintptr_t handle, unsigned long mask, dispatch_queue_t queue);

* dispatch_source_t

>SDK iOS 4.0+
>typedef NSObject<OS_dispatch_source> *dispatch_source_t;

* dispatch_source_type_t

>SDK iOS 4.0+
>typedef const struct dispatch_source_type_s *dispatch_source_type_t;

>* DISPATCH_SOURCE_TYPE_TIMER
>* DISPATCH_SOURCE_TYPE_READ
>* DISPATCH_SOURCE_TYPE_WRITE
>* DISPATCH_SOURCE_TYPE_VNODE
>* DISPATCH_SOURCE_TYPE_SIGNAL
>* DISPATCH_SOURCE_TYPE_PROC
>* DISPATCH_SOURCE_TYPE_MEMORYPRESSURE
>* DISPATCH_SOURCE_TYPE_MACH_SEND
>* DISPATCH_SOURCE_TYPE_MACH_RECV
>* DISPATCH_SOURCE_TYPE_DATA_ADD
>* DISPATCH_SOURCE_TYPE_DATA_OR



