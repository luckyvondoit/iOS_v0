
- [1.NSNotificationCenter通知中心的实现原理？](#1nsnotificationcenter通知中心的实现原理)
- [2.苹果推送如何实现的？](#2苹果推送如何实现的)
- [3.响应者链](#3响应者链)
- [4.什么是“应用瘦身”](#4什么是应用瘦身)
- [5.Cocoa Touch的四层架构及其服务](#5cocoa-touch的四层架构及其服务)
- [6.为什么说Objective-C是一门动态的语言？](#6为什么说objective-c是一门动态的语言)
- [7.autorelease 对象在什么情况下会被释放？](#7autorelease-对象在什么情况下会被释放)
- [8.iOS设备指纹历史变迁](#8ios设备指纹历史变迁)
- [9.你认为开发中那些导致crash?](#9你认为开发中那些导致crash)
- [10.大文件离线下载怎么处理?会遇到哪些问题?又如何解决](#10大文件离线下载怎么处理会遇到哪些问题又如何解决)
- [11.熟悉CocoaPods么？能大概讲一下工作原理么？](#11熟悉cocoapods么能大概讲一下工作原理么)
- [12.测试都有哪些方式?优缺点呢？](#12测试都有哪些方式优缺点呢)
- [13.Xcode8开始后自动配置开发证书过程?](#13xcode8开始后自动配置开发证书过程)

## 1.NSNotificationCenter通知中心的实现原理？

<details>
<summary> 参考 </summary>

[通知原理](https://github.com/luckyvondoit/iOS/blob/master/Foundation/NSNotification/NSNotification.md)

</details>

## 2.苹果推送如何实现的？

<details>
<summary> 参考 </summary>

1. 由App向iOS设备发送一个注册通知，用户需要同意系统发送推送。
2. iOS应用向APNS远程推送服务器发送App的Bundle Id和设备的UDID。
3. APNS根据设备的UDID和App的Bundle Id生成deviceToken再发回给App。
4. App再将deviceToken发送给远程推送服务器(自己的服务器), 由服务器保存在数据库中。
5. 当自己的服务器想发送推送时, 在远程推送服务器中输入要发送的消息并选择发给哪些用户的deviceToken，由远程推送服务器发送给APNS。
6. APNS根据deviceToken发送给对应的用户。

</details>

## 3.响应者链

<details>
<summary> 参考 </summary>

[响应者链]()

</details>

## 4.什么是“应用瘦身”

<details>
<summary> 参考 </summary>

“应用瘦身”（App thinning）是美国苹果公司自iOS9发布的新特性，它能针对Apple Store和操作系统进行优化，它根据用户的具体设备型号，在保证应用特性完整的情况下，尽可能地压缩和减少应用程序安装包的体积，也就是尽可能减少应用程序对用户设备内存的占用，从而减小用户下载应用程序的负担。

App thinning的实现主要有以下3中方式：Slicing、Bitcode和On-Demand Resource。

1. Slicing

在开发者将完整的应用安装包发布到Apple Store之后，Apple Store会根据下载用户的目标设备型号创建相应的应用变体（variants of the app bundle）。这些变体只包含可执行的结构和资源等必要部分，而不需要让用户下载开发者提供的完整安装包。

2. Bitcode

Bitcode是iOS中开发者的一个可选项，如果工程中开启了Bitcode，那么苹果会对开发者编译后的应用二进制文件进行二次优化，将其转换成一种中间代码，在Apple Store上进行编译和链接。Bitcode属于官方的一种新的优化技术，由于很多第三方库不支持Bitcode，所以很多时候不得不关闭Bitcode以保证程序的正常运行。

3. On-Demand Resource

它是一种“按需供给”的资源加载方式，用户下载应用程序时不需要下载应用程序完整的资源，而是在用户使用过程中到了某个阶段需要用到某些资源时，才从后台的服务器下载。这种方式在游戏等对资源使用量大的应用程序中效果最明显。

</details>

## 5.Cocoa Touch的四层架构及其服务

<details>
<summary> 参考 </summary>

| 架构层 | 服务 |
|  ----  | ----  |
| Cocoa Touch 架构层 | UI组件、触摸处理和事件驱动、系统接口 |
| Media 媒体层 | 音频视频播放、动画、2D和3D图像 |
| Core Server | 核心服务层、底层特性、文件、网络、位置服务等 |
| Core OS 系统层 | 内存管理、底层网络、硬件管理 |

</details>

## 6.为什么说Objective-C是一门动态的语言？

<details>
<summary> 参考 </summary>

1. 什么是动态语言？

动态语言（Dynamic Programming Language -动态语言或动态编程语言），是指程序在运行时可以改变其结构。
动态类型语言（Dynamically Typed Language），所谓的动态类型语言，是指类型的检查是在运行时做的。
静态语言与静态类型语言与上述描述相反。

2. OC是动态语言的原因

Objective-C 是 C的超集，在C语言的基础上添加了面向对象特性，并且利用Runtime这个运行时机制，为Objective-C增添了动态的特性。

3. Objective-C的动态运行性

它的动态性主要体现在一下三个方面：

- 动态类型
即运行时再决定对象的类型。举个程序中的实例，即 id 类型，任何对象都可以被 id 指针所指，只有在运行时才能决定是什么类型。而静态类型在编译时就能确定是什么类型，如 int , NSString 等，若程序发生了类型不对应的问题，编译器就会发出警告。而动态类型在编译器编译的时候是不能被识别的，要等到运行时（run time）根据语境来识别确定。

总结：动态语言的类型确定在运行时，而静态语言在编译时确定。

- 动态绑定
在 Objective-C 中,一个对象能否调用指定的方法不是由编译器决定而是由运行时决定，这被称作是方法的动态绑定。基于动态类型，在某个实例对象被确定后，其类型便被确定了。该对象对应的属性和响应的消息也被完全确定，比如我们一般向一个 NSObject 对象发送 -respondsToSelector: 消息来确定对象是否可以对某个 SEL 作出响应，而在 OC 消息转发机制被触发之前，对应的类的 +resolveClassMethod: 将会被调用，在此时有机会动态地向类或实例中添加新的方法，也就是说，类的实现是可以动态绑定的。

总结：函数调用是由编译器决定，消息发送在运行时决定。

- 动态加载

让程序在运行时添加代码模块和资源，程序员可以根据需要执行一些可执行代码和资源，而不是在启动时就加载所有组件。举个非常通俗易懂的例子，开发的时候，需要为某种 icon 提供多个不同大小的图片，@2x，@3x，以保证设备更换的时候，图片也会自动地更换，这也体现了其动态加载的特性。也可以动态生成类比如kvo的实现原理。

</details>

## 7.autorelease 对象在什么情况下会被释放？

<details>
<summary> 参考 </summary>

分两种情况：手动干预释放和系统自动释放

- 手动干预释放就是指定autoreleasepool,当前作用域大括号结束就立即释放
-系统自动去释放:不手动指定autoreleasepool,Autorelease对象会在当前的 runloop 迭代结束时释放
  - kCFRunLoopEntry(1):第一次进入会自动创建一个autorelease
  - kCFRunLoopBeforeWaiting(32):进入休眠状态前会自动销毁一个autorelease,然后重新创建一个新的autorelease
  - kCFRunLoopExit(128):退出runloop时会自动销毁最后一个创建的autorelease

</details>

## 8.iOS设备指纹历史变迁

<details>
<summary> 参考 </summary>


**1)UDID**

UDID的全称是Unique Device Identifier，它是苹果iOS设备的唯一识别码，由40位16进制数的字母和数字组成。iOS 2.0版本开始，系统提供了获取设备唯一标识符的方法uniqueIdentifier，通过该方法我们可以获取设备的序列号。

但是，许多开发者把UDID跟用户的真实姓名、密码、住址等数据关联起来；网络窥探者也会从多个应用收集这些数据，然后顺藤摸瓜得到这个人的许多隐私数据；并且大部分应用也在频繁传输UDID和私人信息。所以，从IOS5.0开始，苹果禁用了该方法。

**2)OpenUDID**

当UDID不可用后，OpenUDID成为了当时使用最广泛的开源UDID替代方案。

OpenUDID利用了一个非常巧妙的方法来确保不同程序间的设备ID唯一，那就是在粘贴板中用一个特殊的名称来存储该设备标示符。通过这种方法，使用了OpenUDID的其他App，知道去什么地方获取已经生成的标示符，这样就保证了不同App间设备ID的共享。

但是，如果把使用了OpenUDID方案的App全部删除，再重新获取OpenUDID，此时的OpenUDID就发送了变化，也无法保证稳定性。

同时，iOS7增加了对剪贴板的限制，导致同一个设备上不同App间，无法再共享同一个OpenUDID，这也导致该方案逐渐被抛弃。

**3)MAC**

MAC地址在网络上用来区分设备的唯一性，接入网络的设备都有一个MAC地址，他们肯定都是不同的，是唯一的。

而MAC地址跟UDID一样，存在隐私问题，从iOS7开始，如果请求Mac地址都会返回一个固定值，所以也就不能作为设备唯一标识了。

**4)IDFV**

IDFV:Identifier for Vendor。它是Vendor标示符，是给Vendor标识用户用的，每个设备在所属同一个Vender的应用里，都有相同的值。

在同一个设备上不同的 vendor 下的应用获取到的 IDFV 是不一样的，而同一个 vendor 下的不同应用获取的 IDFV 都是一样的。但如果用户删除了这个 vendor 的所有应用，再重新安装它们，IDFV 就会被重置，和之前的不一样，所以，也不能确保设备指纹的唯一性。

**5)IDFA**

广告标示符，是从iOS6开始提供的一个方法:advertisingIdentifier。在同一个设备上的所有App都会取到相同的值，是苹果专门给各广告提供商用来追踪用户而设的。

但在下面的情况下，会重新生成广告标示符，依然无法保证设备指纹唯一：

一是，重置系统（设置 -> 通用 -> 还原 -> 抹掉所有内容和设置）

二是，重置广告标识符（设置 -> 隐私 -> 广告 -> 还原广告标识符）

特别是，从iOS14开始，需要先请求跟踪权限，用户同意后才能获取到广告标识符。如果用户不同意的话，是不能获取IDFA的。


取设备标识的常用三种方法

```
/**  卸载应用重新安装后会不一致*/
+ (NSString *)getUUID1{ CFUUIDRef uuid = CFUUIDCreate(NULL); NSString *UUID = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, uuid); CFRelease(uuid); return UUID;
}
 
/**  卸载应用重新安装后会不一致*/
+ (NSString *)getUUID2{ return [UIDevice currentDevice].identifierForVendor.UUIDString;;
}
 
/** 不会因为应用卸载改变 * 但是用户在设置-隐私-广告里面限制广告跟踪后会变成@"00000000-0000-0000-0000-000000000000"
  * 重新打开后会变成另一个，还原广告标识符也会变
  */
+ (NSString *)getUUID3{ return [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
}
```

我们看这三个方法是不是都不稳妥，可能都会改变，那我们得想个办法把值存好了，存到钥匙串（getUUID3）。

</details>

## 9.你认为开发中那些导致crash?

<details>
<summary> 参考内容 </summary>

> 当iOS设备上的App应用闪退时，操作系统会生成一个crash日志，保存在设备上。crash日志上有很多有用的信息，比如每个正在执行线程的完整堆栈跟踪信息和内存映像，这样就能够通过解析这些信息进而定位crash发生时的代码逻辑，从而找到App闪退的原因。

> 通常来说，crash产生来源于两种问题：违反iOS系统规则导致的crash和App代码逻辑BUG导致的crash

**应用逻辑的Bug**

- SEGV：（Segmentation Violation，段违例），无效内存地址，比如空指针，未初始化指针，栈溢出等；
- SIGABRT：收到Abort信号，可能自身调用abort()或者收到外部发送过来的信号；
- SIGBUS：总线错误。与SIGSEGV不同的是，SIGSEGV访问的是无效地址（比如虚存映射不到物理内存），而SIGBUS访问的是有效地址，但总线访问异常（比如地址对齐问题）；
- SIGILL：尝试执行非法的指令，可能不被识别或者没有权限；
- SIGFPE：Floating Point Error，数学计算相关问题（可能不限于浮点计算），比如除零操作；
- SIGPIPE：管道另一端没有进程接手数据；
常见的崩溃原因基本都是代码逻辑问题或资源问题，比如数组越界，访问野指针或者资源不存在，或资源大小写错误等

**违反iOS系统规则产生crash的三种类型**
- 内存报警闪退
	- 当iOS检测到内存过低时，它的VM系统会发出低内存警告通知，尝试回收一些内存；如果情况没有得到足够的改善，iOS会终止后台应用以回收更多内存；最后，如果内存还是不足，那么正在运行的应用可能会被终止掉。在Debug模式下，可以主动将客户端执行的动作逻辑写入一个log文件中，这样程序童鞋可以将内存预警的逻辑写入该log文件，当发生如下截图中的内存报警时，就是提醒当前客户端性能内存吃紧，可以通过Instruments工具中的Allocations 和 Leaks模块库来发现内存分配问题和内存泄漏问题。

- 响应超时
	- 当应用程序对一些特定的事件（比如启动、挂起、恢复、结束）响应不及时，苹果的Watchdog机制会把应用程序干掉，并生成一份相应的crash日志。

- 用户强制退出
  - 一看到“用户强制退出”，首先可能想到的双击Home键，然后关闭应用程序。不过这种场景一般是不会产生crash日志的，因为双击Home键后，所有的应用程序都处于后台状态，而iOS随时都有可能关闭后台进程，当应用阻塞界面并停止响应时这种场景才会产生crash日志。这里指的“用户强制退出”场景，是稍微比较复杂点的操作：先按住电源键，直到出现“滑动关机”的界面时，再按住Home键，这时候当前应用程序会被终止掉，并且产生一份相应事件的crash日志。

</details>  


## 10.大文件离线下载怎么处理?会遇到哪些问题?又如何解决

<details>
<summary> 参考 </summary>

- NSURLSessionDataTask 大文件离线断点下载 (AFN等框架,旧的connection类已经废弃)

- 内存飙升问题:(apple 默认实现机制导致),在下载文件的过程中，系统会先把文件保存在内存中，等到文件下载完毕之后再写入到磁盘! 在下载文件时，`一边下载一边写入到磁盘`，减小内存使用

- 具体实现方法:
  - 1.NSFileHandle 文件句柄
  - 2.NSOutputStream 输出流

```
 // code copy from jianshu 
 ///: 1. NSFileHandle
 -(void)URLSession:(NSURLSession *)session dataTask:(nonnull NSURLSessionDataTask *)dataTask 
 didReceiveResponse:(nonnull NSURLResponse *)response 
 completionHandler:(nonnull void (^)(NSURLSessionResponseDisposition))completionHandler {
       //接受到响应的时候 告诉系统如何处理服务器返回的数据
       completionHandler(NSURLSessionResponseAllow);
       //得到请求文件的数据大小
       self.totalLength = response.expectedContentLength;
       //拼接文件的全路径
       NSString *fileName = response.suggestedFilename;
       NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
       NSString *fullPath = [cachePath stringByAppendingPathComponent:fileName];
 
       //【1】在沙盒中创建一个空的文件
       [[NSFileManager defaultManager] createFileAtPath:fullPath contents:nil attributes:nil];
       //【2】创建一个文件句柄指针指向该文件（默认指向文件开头）
       self.handle = [NSFileHandle fileHandleForWritingAtPath:fullPath];
 }
 -(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
       //【3】使用文件句柄指针来写数据（边写边移动）
       [self.handle writeData:data];
       //累加已经下载的文件数据大小
       self.currentLength += data.length;
       //计算文件的下载进度 = 已经下载的 / 文件的总大小
       self.progressView.progress = 1.0 * self.currentLength / self.totalLength;
 }
 -(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
       //【4】关闭文件句柄
       [self.handle closeFile];
 }
 ///:NSOutputStream
 -(void)URLSession:(NSURLSession *)session dataTask:(nonnull NSURLSessionDataTask *)dataTask 
 didReceiveResponse:(nonnull NSURLResponse *)response 
 completionHandler:(nonnull void (^)(NSURLSessionResponseDisposition))completionHandler {
       //接受到响应的时候 告诉系统如何处理服务器返回的数据
       completionHandler(NSURLSessionResponseAllow);
       //得到请求文件的数据大小
       self.totalLength = response.expectedContentLength;
       //拼接文件的全路径
       NSString *fileName = response.suggestedFilename;
       NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
       NSString *fullPath = [cachePath stringByAppendingPathComponent:fileName];
 
       //（1）创建输出流，并打开
       self.outStream = [[NSOutputStream alloc] initToFileAtPath:fullPath append:YES];
       [self.outStream open];
 }
 -(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
       //（2）使用输出流写数据
       [self.outStream write:data.bytes maxLength:data.length];
       //累加已经下载的文件数据大小
       self.currentLength += data.length;
       //计算文件的下载进度 = 已经下载的 / 文件的总大小
       self.progressView.progress = 1.0 * self.currentLength / self.totalLength;
 }
 -(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
       //（3）关闭输出流
       [self.outStream close];
 }

```

- 开始(resume) | 暂停(suspend) | 取消 | 恢复等
  
```
[self.dataTask cancel];
//默认情况下取消下载不能进行恢复，若要取消之后还可以恢复，可以清空下载任务，再新建
self.dataTask = nil;
```

</details>

## 11.熟悉CocoaPods么？能大概讲一下工作原理么？

<details>
<summary> 参考内容 </summary>

> **Podfile.lock**：在pod install以后会生成一个Podfile.lock的文件,这个文件在多人协作开发的时候就不建议加入在.gitignore中,因为这个文件会锁定当前各依赖库的版本,就算之后再pod install也不会更改版本,不提交上去的话就可以防止第三方库升级后造成大家各自的第三方库版本不同

**CocoaPods原理** 

> CocoaPods的原理是将所有的依赖库都放到另一个名为Pods的项目中，然后让主项目依赖Pods项目，这样，源码管理工作都从主项目移到了Pods项目中。Pods项目最终会编译成一个名为libPods.a的文件，主项目只需要依赖这个.a文件即可。

* 运行pre-install hook

* 生成Pod Project

* 将该pod文件添加到工程中

* 添加对应的framework、.a库、bundle等

* 链接头文件，生成Target

* 运行post-install hook

* 生成podfile.lock ，之后生成文件副本mainfest.lock并将其放在Pod文件夹内。（如果出现 The sandbox is not sync with the podfile.lock这种错误，则表示manifest.lock和podfile.lock文件不一致），此时一般需要重新运行pod install命令。

* 配置原有的project文件(add build phase)

* 添加了 Embed Pods Frameworks

* 添加了 Copy Pod Resources 其中，pre-install hook和post-install hook可以理解成回调函数，是在podfile里对于install之前或者之后（生成工程但是还没写入磁盘）可以执行的逻辑，逻辑为：
  * pre_install do |installer| # 做一些安装之前的hook end
  * post_install do |installer| # 做一些安装之后的hook end 

</details>

## 12.测试都有哪些方式?优缺点呢？

<details>

<summary> 参考内容 </summary>

- 联机调试 (一般而言适用于开发人员)
  - 之前需要插线
  - 后期版本可以无线调试！
- 蒲公英等分发平台(就是需要提供参与app测试人员的设备UDID) 缺点:开发者需要将这些设备的UDID添加到开发者中心，每次有新的测试人员加入，需要重新生成profiles
- TestFlight进行App Beta版测试 (apple 官方,iOS8及以上版本的iOS设备才能运行):
  - 优点: 无需UUID,外部测试人员的上限是10000人（2018年后又扩大了测试上限）,只需要参与app测试人员提供一个邮箱

</details>

## 13.Xcode8开始后自动配置开发证书过程?

<details>

<summary> 参考 </summary>

- Xcode会在本机钥匙串寻找team对应的开发证书，如果本地钥匙串存在该证书则加载使用
- 不存在：则从开发者中心寻找本机对应的开发证书，如果开发者中心没有则自动生成一个并下载到钥匙串使用

</details>