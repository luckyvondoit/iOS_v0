# 关于性能优化需要知道的事

所谓性能，无非是一种指标，在软件开发过程中，该指标往往关注两个方面：效率和消耗。效率主要是指代码的执行效率、动画的流畅程度、应用的冷启动时间和热启动时间、网络通信的阻塞时间等等。消耗主要是指内存的消耗、有没有内存泄漏、CPU的占用率、耗电与应用程序包尺寸等等。

## 1.1 衡量应用程序性能优劣的一些标准

### 1.1.1 代码是执行效率

主要受如下几个方面的影响：

* 算法依据的数据基础。
* 编译器产生的代码质量和语言的执行效率。
* 问题的输入规模。
* 硬件的执行速度。

在通常情况下，问题是输入规模和算法的数学基础是开发者需要考虑的因素。“时间复杂度”是用来描述算法执行效率的一个重要指标。

### 1.1.2 内存占用

内存是一个程序运行的基础，在运行过程中，应用程序的代码、数据、资源等都要加载进内存。保证稳定合理的内存占用量是开发者需要关注的重点之一。

ARC(自动引用计数)可以帮助开发者避免最常见的内存泄漏问题，但是其也不是万能的，循环引用和CoreFoundation框架对象依然需要开发者手动处理。

### 1.1.3 CPU负担与能耗

在应用程序运行工程中，CPU占用率太高除了会是设备发热、耗电量增加之外，也极易造成崩溃。在Xcode中CPU Report可以监测CPU的占用率。

在iOS中，可以使用如下代码获取电池电量与状态：
```
[UIDevice currentDevice].batteryLevel //获取电池电量
[UIDevice currentDevice].batteryState //获取电池状态
```

batteryLevel将返回一个0~1之间的浮点数，表示电池的电量百分比。只有在真机上才有效，否则该值为-1。batteryState用来获取电池的状态，枚举如下：
```
typedef NS_ENUM(NSInteger, UIDeviceBatteryState) {
    UIDeviceBatteryStateUnknow,//电池状态未知
    UIDeviceBatteryStateUnplugged,//使用中，放电中
    UIDeviceBatteryStateCharging,//充电中，未充满
    UIDeviceBatteryStateFull,//电池充满状态
}
```

### 1.1.4 动画流畅度

动画流畅度也是应用程序的一个重要的性能指标。动画的流程程度主要取决于界面的刷新帧率。就是屏幕每秒的刷新次数。iOS系统的极限帧率是60FPS。

### 1.1.5

在应用程序中，网络请求往往是最为耗时的。若要在应用程序的使用过程中让用户体验到畅快的感觉，则对网络请求的优化是必不可少的。关于网络请求，我们通常可以从两个方面考虑：

* 从请求过程中寻求优化
* 从请求次数上寻求优化

## 1.2 Xcode断点与静态分析工具

### 1.2.1 添加自定义断点

在Xcodde中添加断点非常简单，直接在行号处点击左键，即可添加。

![](./PerformanceOptimization/imgs/BreakPoint_1.png)

对于自定义断点，开发者可以选择添加一些条件，例如，要实现只有循环中的i值大于5时才进入断点，可以在断点设置处进行条件设置，如下

![](./PerformanceOptimization/imgs/BreakPoint_2.png)

断点设置中还有一项Ignore设置，该值的作用是可以忽略指定次数的断点行为，即如果为3，第4次执行到此才中断。

### 1.2.2 为自定义断点添加行为

可以使用Log Message行为实现在执行到断点时Xcode额外输出一些内容。如下：

![](./PerformanceOptimization/imgs/BreakPoint_3.png)

如果选择“Speak Message”，Xcode工具会读出设置的断点信息，如果选择“Log Message to console”方式，则会将断点信息输出到控制台。

“%H”会输出断点触发次数。
“%B”会输出断点名称。
在两个“@”之间的部可以输入表达式。

用“Debug Command”功能可以设置调试命令，当断点触发时，执行调试命令并输出结果到控制台。如下图，断点每次被触发时都将输出字符串“Hello”，或者打印一个对象。

![](./PerformanceOptimization/imgs/BreakPoint_4.png)
![](./PerformanceOptimization/imgs/BreakPoint_5.png)

通过“AppleScript”行为可以设置执行到断点触发脚本。开发者也可以开启断点的Capture GPU Frame功能，当断点被触发时可以捕获GPU当前所绘制的帧。

### 1.2.3 添加全局类型的断点

在Xcode导航区的断点模块中可以选择添加全局断点类型，有6种：

![](./PerformanceOptimization/imgs/BreakPoint_6.png)

* Swift Error BreakPoint
Swift项目中常用的一种全局断点，如果开发者添加了此全局断点，则程序会暂停在使用throw抛出异常的代码处。

* Exception BreakPoint
用来捕获程序中的异常，当应用程序发生如数组越界、设置了非空参数为nil等异常问题时，Xcode通常会崩溃在main()函数中，如果设置了这个断点，则Xcode会暂停在异常发生处。

* Symbolic Breakpoint
符号断点，这是最强大的一种全局断点。使用了符号断点时，开发者不用找到具体代码处，设置只要执行到某个函数就触发断点即可。例如，将测试代码修改如下：

```
void myPrint() {
    printf("hello");
}

int main(int argc, char * argv[]) {
    @autoreleasepool {        
        for (int i = 0; i < 10; i++) {
            myPrint();
        }
    }
    return 0;
}
```

符号断点设置如下图，运行程序，每次执行myPrint()函数时，都会暂停。

![](./PerformanceOptimization/imgs/BreakPoint_7.png)

需要注意的是，并非只有C函数可以设置，OC方法也行，直接写方法名即可，例如：“init:”。也可以通过指定具体是某个类方法实现，例如“[UIView initWithFrame:]”

* Constraint Error BreakPoint
约束错误断点。

* Test Failure Breakpoint
测试错误断点。

### 1.2.4 Xcode静态分析工具

Xcode提供代码的静态分析工具Analyze，所谓静态分析，是指不进行编译对代码的逻辑、有效性、内存泄漏风险和调用是否异常进行分析。

在Xcode开发工具的Product菜单中可以启动Analyze工具，其功能包括：
* 分析出代码中存在的内存泄漏问题。
* 检查出一些无效的数据。
* 检查出一些逻辑错误。

## 1.3 Instruments：性能分析和测试工具

## 1.4 使用LLDB测试工具
LLDB是高性能的程序调试器，其默认集成在Xcode工具中，支持对C语言、OC语言和C++语言程序代码进行调试，包括查看变量、修改变量、执行指令等功能。当Xcode触发断点时，程序会自动进入LLDB调试环境，开发者可以在控制台进行LLDB指令的执行。

### 1.4.1 使用expression指令进行动态代码执行

在LLDB调速器中，expression指令可能是最常用的调试指令，其作用是用来动态执行行代码，可以在运行时修改内存中变量的值，改变程序的运行轨迹。

例如下面的代码，正常运行后将结果打印为 3。

```
int main(int argc, char * argv[]) {
    @autoreleasepool {
        int a = 1;
        int b = 2;
        int c = a + b;
        printf("%d\n",c);
    }
    return 0
}
```


下面在定义变量c的地方打一个断点，再次运行程序，当程序中断时，Xcode会自动进入LLDB调试模式。

在LLDB指令区输入如下指令，按回车键执行：
```
expression a
```

上面的指令的作用是查看内存中变量a的值。
```
(lldb) expression a
(int) $0 = 1
(lldb) 
```

如上所示，在输出的内容中，（int）表明了变量的内容，$0是LLDB自动生成的一个临时符号，这个符号即表示变量a的值是1，之后在LLDB调试器中，可以直接通过$0来获取到值1。也可以使用expression指令来修改变量a。例如：
```
expression a = 10
```

之后继续向下执行代码，最终可以看到控制台输出变量的值为12。

通过使用expression命令，在调试过程中，不仅不需要添加额外的打印代码，也不需要直接修改源代码。在调试区进行多次调试，直到找到正确的修改方法后再对源代码修改一次即可。

### 1.4.2 使用frame指令查看代码帧信息

frame指令是LLDB中非常强大的一个调试指令，开发者通过它可以查看当前代码帧信息，查看函数名称、参数和所在位置信息，并且可以进行代码回溯调试。

```
//打印当前数据帧块的信息
frame info

//获取当前数据帧中的变量信息
frame variable

//count 为对应数据帧的标号，切换后，可以访问对应数据帧中的变量
frame select [count]
```

### 1.4.3 使用thread相关指令操作线程

查看当前线程中的所有数据帧

```
thread backtrace
```

使用下面的命令可以查看当前所有被激活的线程：

```
thread list
```

使用下面的指令可以查看当前正在调试的线程信息

```
thread info
```

同样的，我们也可以切换调试的线程

```
thead select [count]
```

### 其他LLDB常用指令

help指令提供了帮助文档，例如要查看thread相关指令的用法，可以使用如下指令：

```
help thread
```

还有一些常用的指令，如使用print指令可以对变量进行打印，使用r指令可以重新运行程序，quit指令用于结束LLDB调试等。可以通过使用help文档深入研究更多的高级功能。

## 1.5 日志与埋点

### 1.5.1 异常分析

在程序启动时，可以向系统中注册异常捕获函数。

### 1.5.2 使用Buly异常捕获工具

### 1.5.3 应用程序埋点

### 1.5.4 使用Fabric分析工具