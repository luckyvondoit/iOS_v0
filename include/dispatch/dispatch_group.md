   

 
#  dispatch_group
dispatch_group的作用是将不同队列中的任务分到同一个组中，等全部任务完成之后发出通知用户。

 `dispatch_group` 的使用分为以下几步：

1. 创建 `dispatch_group` 组
2. 添加任务(并发)到group中
3. 添加监听group中任务结束时的回调

接下来，我们来具体看看 `dispatch_group` 相关的API与基本使用


## 一、创建dispatch_group

### dispatch_group_t

```
/*!
 * @typedef dispatch_group_t
 * @abstract
 * A group of blocks submitted to queues for asynchronous invocation.
 */
DISPATCH_DECL(dispatch_group);
复制代码
```

### dispatch_group_create

```
/*!
 * @function dispatch_group_create
 *
 * @abstract
 * Creates new group with which blocks may be associated.
 *
 * @discussion
 * This function creates a new group with which blocks may be associated.
 * The dispatch group may be used to wait for the completion of the blocks it
 * references. The group object memory is freed with dispatch_release().
 *
 * @result
 * The newly created group, or NULL on failure.
 */
API_AVAILABLE(macos(10.6), ios(4.0))
DISPATCH_EXPORT DISPATCH_MALLOC DISPATCH_RETURNS_RETAINED DISPATCH_WARN_RESULT
DISPATCH_NOTHROW
dispatch_group_t
dispatch_group_create(void);
复制代码
```

`dispatch_group_t` 其实就是提交到队列中用以进行异步调用的一组任务

我们可以使用 `dispatch_group_create` 方法来创建group

```
dispatch_group_t group = dispatch_group_create();
复制代码
```

## 二、添加任务到dispatch_group

添加任务有2种方式：

* 第一种是使用 `dispatch_group_async` 添加任务到一个特定的队列
* 第二种是人为的告诉 `group`,我们开始了一个任务（ `dispatch_group_enter` ），或者任务结束了（ `dispatch_group_leave` ）

### dispatch_group_async

```
#ifdef __BLOCKS__
API_AVAILABLE(macos(10.6), ios(4.0))
DISPATCH_EXPORT DISPATCH_NONNULL_ALL DISPATCH_NOTHROW
void
dispatch_group_async(dispatch_group_t group,
	dispatch_queue_t queue,
	dispatch_block_t block);
#endif /* __BLOCKS__ */
复制代码
```

这个函数有3个参数，第一个是管理这些异步任务的group,第二个是用于提交异步任务队列，第三个是我们提交的任务。

使用这个方法，我们可以定制我们的网络请求任务，添加到对应的并发队列，然后使用group管理这些任务，这样我们的异步并发网络请求的目的就实现了。

但是，我们平时的开发过程中，我们的网络请求基本上都是需要异步添加任务的，无法直接使用队列，这时我们就可以使用dispatch_group_enter `与` dispatch_group_leave ` 这一对API

### dispatch_group_enter/leave

```
/*!
 * @function dispatch_group_enter
 *
 * @abstract
 * Manually indicate a block has entered the group
 *
 * @discussion
 * Calling this function indicates another block has joined the group through
 * a means other than dispatch_group_async(). Calls to this function must be
 * balanced with dispatch_group_leave().
 *
 * @param group
 * The dispatch group to update.
 * The result of passing NULL in this parameter is undefined.
 */
API_AVAILABLE(macos(10.6), ios(4.0))
DISPATCH_EXPORT DISPATCH_NONNULL_ALL DISPATCH_NOTHROW
void
dispatch_group_enter(dispatch_group_t group);

/*!
 * @function dispatch_group_leave
 *
 * @abstract
 * Manually indicate a block in the group has completed
 *
 * @discussion
 * Calling this function indicates block has completed and left the dispatch
 * group by a means other than dispatch_group_async().
 *
 * @param group
 * The dispatch group to update.
 * The result of passing NULL in this parameter is undefined.
 */
API_AVAILABLE(macos(10.6), ios(4.0))
DISPATCH_EXPORT DISPATCH_NONNULL_ALL DISPATCH_NOTHROW
void
dispatch_group_leave(dispatch_group_t group);
复制代码
```

`dispatch_group_enter` 表示这个任务已经添加到group中

`dispatch_group_leave` 表示添加到group中的这个任务已经执行完成

我们经常会使用这组API，将一些异步的网络请求的任务包装起来放进group中(早版本的AFNetworking中执行异步任务)：

```
NSLog(@"使用dispatch_group_enter方式追加任务3");
    dispatch_group_enter(self.group);

    //开启一个网络请求
    NSURLSession *session = [NSURLSession sharedSession];
    NSURL *url =
    [NSURL URLWithString:[@"https://www.baidu.com/" stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    
    NSLog(@"3---start---%@",[NSThread currentThread]);
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", [error localizedDescription]);
        }
        if (data) {
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            NSLog(@"%@", dict);
        }
        NSLog(@"3---end---%@",[NSThread currentThread]);
        dispatch_group_leave(self.group);
    }];
    [dataTask resume];
复制代码
```

这组API必须配对调用，否则，group中任务执行完成的指令永远不会调用。

## 三、添加监听group中任务结束时的回调

这里也有2种方式， `dispatch_group_wait` 与 `dispatch_group_notify`

### dispatch_group_wait

这种方式会阻塞当前的线程，直到group中的任务全部完成，程序才会继续往下执行。

### dispatch_group_notify

这种方式是添加一个异步执行的任务作为结束任务，当group中的任务全部完成，才会执行 `dispatch_group_notify` 中添加的异步任务，这种方式不会阻塞当前线程，同时有一个单独的异步回调，代码组织性更好，使用也更新广泛一些。

## 四、代码实战 & 使用小结

接下来，我们看看完整的测试代码：

```
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSLog(@"ZEDDispatchGroupViewController viewDidLoad");
    
    //第一步：创建group
    NSLog(@"初始化group");
    self.group = dispatch_group_create();
    
    //第二步：追加任务到group
    NSLog(@"使用dispatch_group_async方式追加任务1");
    dispatch_group_async(self.group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        for (int i = 0; i < 2; ++i) {
            [NSThread sleepForTimeInterval:2];                        // 模拟耗时操作
            NSLog(@"1---%@",[NSThread currentThread]);      // 打印当前线程
        }
        NSLog(@"任务1完成");
    });
    
    NSLog(@"使用dispatch_group_async方式追加任务2");
    dispatch_group_async(self.group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        for (int i = 0; i < 2; ++i) {
            [NSThread sleepForTimeInterval:2];                        // 模拟耗时操作
            NSLog(@"2---%@",[NSThread currentThread]);      // 打印当前线程
        }
        NSLog(@"任务2完成");
    });
    
    NSLog(@"使用dispatch_group_enter方式追加任务3");
    //dispatch_group_enter与dispatch_group_leave必须成对出现
    dispatch_group_enter(self.group);

    //开启一个网络请求
    NSURLSession *session = [NSURLSession sharedSession];
    NSURL *url =
    [NSURL URLWithString:[@"https://www.baidu.com/" stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    
    NSLog(@"3---start---%@",[NSThread currentThread]);
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", [error localizedDescription]);
        }
        if (data) {
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            NSLog(@"%@", dict);
        }
        NSLog(@"3---end---%@",[NSThread currentThread]);
        NSLog(@"任务3完成");
        dispatch_group_leave(self.group);
    }];
    [dataTask resume];
    
    
    //第三步：添加group中任务全部完成的回调
    NSLog(@"使用dispatch_group_notify添加异步任务全部完成的监听");
    //dispatch_group_notify 的方式不会阻塞当前线程
    dispatch_group_notify(self.group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"---所有任务全部执行完毕---");
        
    });
    
    //dispatch_group_wai会阻塞当前线程，直到group中的任务全部完成，才能继续往主队列中追加任务
//    dispatch_group_wait(self.group, DISPATCH_TIME_FOREVER);
    
    NSLog(@"---测试结束了---");
}
复制代码
```

测试结果log如下：

```
2019-04-25 17:07:21.432220+0800 GCD(三) dispatch_group[28759:5272759] libMobileGestalt MobileGestalt.c:890: MGIsDeviceOneOfType is not supported on this platform.
2019-04-25 17:07:21.543885+0800 GCD(三) dispatch_group[28759:5272759] ZEDDispatchGroupViewController viewDidLoad
2019-04-25 17:07:21.544044+0800 GCD(三) dispatch_group[28759:5272759] 初始化group
2019-04-25 17:07:21.544161+0800 GCD(三) dispatch_group[28759:5272759] 使用dispatch_group_async方式追加任务1
2019-04-25 17:07:21.544286+0800 GCD(三) dispatch_group[28759:5272759] 使用dispatch_group_async方式追加任务2
2019-04-25 17:07:21.544391+0800 GCD(三) dispatch_group[28759:5272759] 使用dispatch_group_enter方式追加任务3
2019-04-25 17:07:21.547318+0800 GCD(三) dispatch_group[28759:5272759] 3---start---<NSThread: 0x600002f86c00>{number = 1, name = main}
2019-04-25 17:07:21.548050+0800 GCD(三) dispatch_group[28759:5272759] 使用dispatch_group_notify添加异步任务全部完成的监听
2019-04-25 17:07:21.548173+0800 GCD(三) dispatch_group[28759:5272759] ---测试结束了---
2019-04-25 17:07:21.700314+0800 GCD(三) dispatch_group[28759:5272797] (null)
2019-04-25 17:07:21.700490+0800 GCD(三) dispatch_group[28759:5272797] 3---end---<NSThread: 0x600002fe0940>{number = 5, name = (null)}
2019-04-25 17:07:21.700611+0800 GCD(三) dispatch_group[28759:5272797] 任务3完成
2019-04-25 17:07:23.547004+0800 GCD(三) dispatch_group[28759:5272796] 1---<NSThread: 0x600002fde480>{number = 6, name = (null)}
2019-04-25 17:07:23.547076+0800 GCD(三) dispatch_group[28759:5272798] 2---<NSThread: 0x600002fde4c0>{number = 7, name = (null)}
2019-04-25 17:07:25.547612+0800 GCD(三) dispatch_group[28759:5272798] 2---<NSThread: 0x600002fde4c0>{number = 7, name = (null)}
2019-04-25 17:07:25.547634+0800 GCD(三) dispatch_group[28759:5272796] 1---<NSThread: 0x600002fde480>{number = 6, name = (null)}
2019-04-25 17:07:25.547901+0800 GCD(三) dispatch_group[28759:5272796] 任务1完成
2019-04-25 17:07:25.547910+0800 GCD(三) dispatch_group[28759:5272798] 任务2完成
2019-04-25 17:07:25.548138+0800 GCD(三) dispatch_group[28759:5272798] ---所有任务全部执行完毕---
复制代码
```

> `dispatch_group_async` 与 `dispatch_group_enter` 都是异步添加任务，不会阻塞当前线程  

> `dispatch_group_notify` 不会阻塞当前线程， `dispatch_group_wait` 会阻塞当前线程  

> `dispatch_group_enter` 与 `dispatch_group_leave` 必须成对出现，否则group中的任务永远不会完成  

### 在所有接口异步请求完成之后刷新UI

```
- (void)test {
    
    __weak typeof(self) weakSelf = self;
    
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_block_t block1 = ^(){
        dispatch_group_enter(group);
        [weakSelf requesWithIdentifier:@"1" completion:^{
            dispatch_group_leave(group);
        }];
    };
    
    dispatch_block_t block2 = ^(){
        dispatch_group_enter(group);
        [weakSelf requesWithIdentifier:@"2" completion:^{
            dispatch_group_leave(group);
        }];
    };
    
    dispatch_block_t block3 = ^(){
        dispatch_group_enter(group);
        [weakSelf requesWithIdentifier:@"3" completion:^{
            dispatch_group_leave(group);
        }];
    };
    
    dispatch_queue_t queue = dispatch_queue_create("myQ", DISPATCH_QUEUE_CONCURRENT);
    
    //这里需要注意，如果改成dispatch_async则无法达到预期效果dispatch_group_async和dispatch_group_enter、dispatch_group_leave同时使用，才能实现预期效果。

    dispatch_group_async(group, queue, block1);
    dispatch_group_async(group, queue, block2);
    dispatch_group_async(group, queue, block3);
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSLog(@"request done");
    });
    
}

- (void)requesWithIdentifier:(NSString *)identifier completion:(void(^)(void))block {
    
    NSInteger time = arc4random() %3 + 1;
    NSLog(@"start --- %@ time = %@",identifier,@(time));
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"stop --- %@",identifier);
        if (block) {
            block();
        }
    });
}
```