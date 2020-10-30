## 目录

<!-- <span id=""></span> -->

<!-- <details>
<summary> 参考 </summary>
</details> -->

1. [NSNotificationCenter通知中心的实现原理？](#1)
2. [苹果推送如何实现的？](#2)
3. [响应者链](#3)
4. [什么是“应用瘦身”](#4)
5. [Cocoa Touch的四层架构及其服](#5)
6. [为什么说Objective-C是一门动态的语言？](#6)
7. [autorelease 对象在什么情况下会被释放？](#7)

---

1. <span id="1">NSNotificationCenter通知中心的实现原理？</span>

<details>
<summary> 参考 </summary>

[通知原理](https://github.com/luckyvondoit/iOS/blob/master/Foundation/NSNotification/NSNotification.md)

</details>

2. <span id="1">苹果推送如何实现的？</span>

<details>
<summary> 参考 </summary>

1. 由App向iOS设备发送一个注册通知，用户需要同意系统发送推送。
2. iOS应用向APNS远程推送服务器发送App的Bundle Id和设备的UDID。
3. APNS根据设备的UDID和App的Bundle Id生成deviceToken再发回给App。
4. App再将deviceToken发送给远程推送服务器(自己的服务器), 由服务器保存在数据库中。
5. 当自己的服务器想发送推送时, 在远程推送服务器中输入要发送的消息并选择发给哪些用户的deviceToken，由远程推送服务器发送给APNS。
6. APNS根据deviceToken发送给对应的用户。

</details>

3. <span id="3">响应者链</span>

<details>
<summary> 参考 </summary>

[响应者链]()

</details>

4. <span id="4">什么是“应用瘦身”</span>

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

5. <span id="5">Cocoa Touch的四层架构及其服务</span>

<details>
<summary> 参考 </summary>

| 架构层 | 服务 |
|  ----  | ----  |
| Cocoa Touch 架构层 | UI组件、触摸处理和事件驱动、系统接口 |
| Media 媒体层 | 音频视频播放、动画、2D和3D图像 |
| Core Server | 核心服务层、底层特性、文件、网络、位置服务等 |
| Core OS 系统层 | 内存管理、底层网络、硬件管理 |

</details>

6. <span id="6">为什么说Objective-C是一门动态的语言？</span>

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

7. <span id="7">autorelease 对象在什么情况下会被释放？</span>

分两种情况：手动干预释放和系统自动释放

- 手动干预释放就是指定autoreleasepool,当前作用域大括号结束就立即释放
-系统自动去释放:不手动指定autoreleasepool,Autorelease对象会在当前的 runloop 迭代结束时释放
  - kCFRunLoopEntry(1):第一次进入会自动创建一个autorelease
  - kCFRunLoopBeforeWaiting(32):进入休眠状态前会自动销毁一个autorelease,然后重新创建一个新的autorelease
  - kCFRunLoopExit(128):退出runloop时会自动销毁最后一个创建的autorelease

<details>
<summary> 参考 </summary>
</details>