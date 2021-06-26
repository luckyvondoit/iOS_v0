# iOS原理 App的启动优化1：优化建议

## 基本概念

App的启动优化指的是减少App的启动时间，启动方式分为两种：『 **冷启动** 』和『 **热启动** 』。

* `冷启动` ：App启动时，如果在内存中没有App的相关数据，必须要从磁盘中重新载入到内存中，这种启动方式叫做冷启动。在iOS中，杀掉App后重新打开即为冷启动方式。
* `热启动` ：App启动时，如果内存中已包含App的相关数据，不需要从磁盘中载入，这种启动方式叫做热启动。在iOS中，通过home键退出App后再打开，即为热启动方式。

一般来说启动优化指的是针对冷启动方式的优化，启动时间也分为两个阶段：『 **main()函数之前** 』和『 **main()函数之后** 』。

## Main()函数之前

`main()函数之前` 即 `pre-main` 阶段，这个阶段的启动时间是没法自主统计的，只能由系统反馈，在Xcode中通过简单配置即可查看。

在Xcode中新建一个项目，然后在菜单中，选择 `Product` --> `Scheme` --> `Edit Scheme` ，找到 `Run` --> `Environment Variables` ，在这里添加一个name为 `DYLD_PRINT_STATISTICS` 的环境变量，并将其value设置为 `1` 。再运行项目，即可在console中查看到下面所示的 `pre-main time` 。

```
Total pre-main time: 121.09 milliseconds (100.0%)
         dylib loading time:  31.90 milliseconds (26.3%)
        rebase/binding time:  37.44 milliseconds (30.9%)
            ObjC setup time:   6.25 milliseconds (5.1%)
           initializer time:  45.49 milliseconds (37.5%)
           slowest intializers :
             libSystem.B.dylib :   7.99 milliseconds (6.6%)
   libBacktraceRecording.dylib :  10.73 milliseconds (8.8%)
    libMainThreadChecker.dylib :  23.81 milliseconds (19.6%)
```

从输出结果可知，pre-main总共耗时123.40ms，分为如下4个阶段：

* `dylib loading` ：加载动态库。

> 动态库越多，越耗时。

* `rebase/binding` ：偏移修正和符号绑定。

> * `rebase（偏移修正）` ：App在编译时，会生成二进制文件，在文件内部的所有方法和函数，都记录了一个偏移地址。在运行时，系统会为二进制文件分配一个 `ASLR随机值（Address Space Layout Randomization，地址空间布局随机化）` ，并将随机值插入到二进制文件的开头，每个方法和函数加载在内存中的真实地址即为： `ASLR随机值 + 偏移值` 。这样，每次运行，都会重新分配 `ASLR随机值` ，都要偏移修正重新加载，这就导致耗时。
> * `binding（符号绑定）` ：在MacOS和iOS中，方法和函数并不是直接访问的，而是通过其在 `MachO` 文件中对应的符号来访问。比如说， `NSLog` 是存在于Foundation动态库的方法，在编译期，会在Mach0文件里创建一个与之对应的符号 `!NSLog` ，此时符号指向一个无意义的随机地址，MacO文件也是存在于磁盘中。然后在运行时，MacO文件会被拷贝加载到内存中，此时会将 `NSLog` 方法在内存中的真实地址和符号 `!NSLog` 关联起来，这就是符号绑定，在这个过程中也存在耗时。


* `ObjC setup` ：OC类的注册。

> OC类越多，耗时越久。

* `initializer` ：执行 `load` 方法和构造函数。

> 从输出结果可知这个 `initializer` 过程耗时最多的是 `libSystem.B.dylib`、`libBacktraceRecording.dylib` 以及 `libMainThreadChecker.dylib` 这三个动态库。

针对这个阶段，优化建议如下：

* 除了系统自带的动态库，开发过程中尽量不要自己添加外部动态库，苹果官方建议项目中使用的外部动态库最好不要超过6个，如果超过6个，需要合并动态库。
* 减少自定义的OC类，对于老项目，及时删掉废弃的类和方法。
* 尽量少使用 `+load` 方法，将相关操作放在 `+initialize` 方法中实现。
* 对于 `swift` 来说，多使用 `struct` 。
* 二进制重排，减少内存访问的耗时。

## Main()函数之后

从 `main()` 函数开始至 `applicationWillFinishLaunching` 结束，统一称为 `main()` 函数之后的部分。耗时因素主要是以下几种：

* 执行 `main()` 函数的耗时
* 执行 `applicationWillFinishLaunching` 的耗时
* `rootViewController` 及其 `childViewController` 的加载、`view` 及其 `subviews` 的加载

这个阶段的启动时间可以自主统计，根据各App的业务代码来决定。优化建议如下：

* 优化代码逻辑，能懒加载的懒加载，能延迟的延迟，能放后台初始化的放后台，能使用多线程来初始化的，就使用多线程,，尽量不要占用主线程的启动时间。
* 尽量使用纯代码来开发，少用 `Xib` 或者 `Storyboard` 。
* 对于比较复杂的首页，先加载本地缓存进行显示，再在数据请求成功后更新最新信息。

#### 推荐阅读

[1. iOS原理 App的启动优化2：二进制重排](https://www.jianshu.com/p/8d7f22a11c71)
[2. iOS App 启动性能优化](https://links.jianshu.com/go?to=https%3A%2F%2Fmp.weixin.qq.com%2Fs%2FKf3EbDIUuf0aWVT-UCEmbA)
[3. iOS中的动态库和静态库](https://links.jianshu.com/go?to=https%3A%2F%2Fblog.csdn.net%2Fheipingguowenkong%2Farticle%2Fdetails%2F90522049)

[iOS原理 App的启动优化1：优化建议](https://www.jianshu.com/p/7f1a26ea133d)