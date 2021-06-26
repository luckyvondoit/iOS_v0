# iOS编译原理

## 1 编译器

把一种编程语言(原始语言)转换为另一种编程语言(目标语言)的程序叫做编译器. 大多数编译器由两部分组成: 前端和后端.

* 前端负责词法分析，语法分析，生成中间代码；
* 后端以中间代码作为输入，进行和架构无关的代码优化，接着针对不同架构生成不同的机器码。

前后端依赖统一格式的中间代码(IR), 使得前后端可以独立的变化. 新增一门语言只需要修改前端, 而新增一个CPU架构只需要修改后端即可. Objective C/C/C++使用的编译器前端是clang, swift是swift, 后端都是LLVM.

### 1.1 LLVM

LLVM的核心库提供了现代化的source-target-independent优化器和支持诸多流行CPU架构的代码生成器. Clang 和 LLDB都是基于LLVM衍生的子项目.

### 1.2 Clang

Clang是C语言家族的编译器前端，诞生之初是为了替代GCC，提供更快的编译速度。一张图了解clang编译的大致流程:

![](./imgs/37ed1e0d8177f88af9dea23eb6061f5c.png)

大致看来, Clang可以分为一下几个步骤: 预处理 -> 词法分析 -> 语法分析 -> 静态分析 -> 生成中间代码和优化 -> 汇编 -> 链接

#### 1.2.1 预处理(preprocessor)

预处理会进行如下操作:

* 头文件引入, 递归将头文件引用替换为头文件中的实际内容, 所以尽量减少头文件中的＃import, 使用@class替代, 把＃import放到.m文件中.
* 宏替换, 在源码中使用的宏定义会被替换为对应#define的内容, 不要在需要预处理的代码中加入太多的内联代码逻辑
* 注释处理, 在预处理的时候, 注释被删除
* 条件编译, (＃if, ＃else, ＃endif)

#### 1.2.2 词法分析(lexical anaysis)

这一步把源文件中的代码转化为特殊的标记流. 词法分析器读入源文件的字符流, 将他们组织称有意义的词素(lexeme)序列，对于每个词素，此法分析器产生词法单元（token）作为输出.

源码被分割成一个一个的字符和单词, 在行尾Loc中都标记出了源码所在的对应源文件和具体行数, 方便在报错时定位问题. 类似于下面:

```
int 'int'     [StartOfLine]    Loc=<main.m:14:1>
identifier 'main'     [LeadingSpace]    Loc=<main.m:14:5>
l_paren '('        Loc=<main.m:14:9>
int 'int'        Loc=<main.m:14:10>
identifier 'argc'     [LeadingSpace]    Loc=<main.m:14:14>
comma ','        Loc=<main.m:14:18>
char 'char'     [LeadingSpace]    Loc=<main.m:14:20>
star '*'     [LeadingSpace]    Loc=<main.m:14:25>
```

#### 1.2.3 语法分析(semantic analysis)

词法分析的Token流会被解析成一颗抽象语法树(abstract syntax tree - AST). 在这里面每一节点也都标记了其在源码中的位置.

有了抽象语法树，clang就可以对这个树进行分析，找出代码中的错误。比如类型不匹配，亦或Objective C中向target发送了一个未实现的消息.

AST是开发者编写clang插件主要交互的数据结构，clang也提供很多API去读取AST.[Introduction to the Clang AST](https://clang.llvm.org/docs/IntroductionToTheClangAST.html)

#### 1.2.4 静态分析(CodeGen)

把源码转化为抽象语法树之后，编译器就可以对这个树进行分析处理。静态分析会对代码进行错误检查，如出现方法被调用但是未定义、定义但是未使用的变量等，以此提高代码质量. 也可以使用 Xcode 自带的静态分析工具（Product -> Analyze).

常见的操作有:

* 当在代码中使用 ARC 时，编译器在编译期间，会做许多的类型检查. 最常见的是检查程序是否发送正确的消息给正确的对象，是否在正确的值上调用了正常函数。如果你给一个单纯的 NSObject* 对象发送了一个 hello 消息，那么 clang 就会报错，同样，给属性设置一个与其自身类型不相符的对象，编译器会给出一个可能使用不正确的警告.

>一般会把类型分为两类：动态的和静态的。动态的在运行时做检查，静态的在编译时做检查。以往，编写代码时可以向任意对象发送任何消息，在运行时，才会检查对象是否能够响应这些消息。由于只是在运行时做此类检查，所以叫做动态类型。
>
> 至于静态类型，是在编译时做检查。当在代码中使用 ARC 时，编译器在编译期间，会做许多的类型检查：因为编译器需要知道哪个对象该如何使用。

* 检查是否有定义了，但是从未使用过的变量
* 检查在 你的初始化方法中中调用 self 之前, 是否已经调用 [self initWith…] 或 [super init] 了

此处遍历语法树，最终生成LLVM IR代码。 *LLVM IR是前端的输出，后端的输入. Objective C代码在这一步会进行runtime的桥接：property合成，ARC处理等*

LLVM 会去做些优化工作, 在 Xcode 的编译设置里也可以设置优化级别-01，-03，-0s，还可以写些自己的 Pass.

如果开启了 Bitcode 苹果会做进一步的优化. 虽然Bitcode仅仅只是一个中间码不能在任何平台上运行, 但是它可以转化为任何被支持的CPU架构, 包括现在还没被发明的CPU架构. iOS Apps中Enable Bitcode 为可选项, WatchOS和tvOS, Bitcode必须开启. 如果你的App支持Bitcode, App Bundle（项目中所有的target）中的所有的 Apps 和 frameworks 都需要支持Bitcode.

#### 1.2.5 生成汇编指令

LLVM对IR进行优化后，会对代码进行编译优化例如针对全局变量优化、循环优化、尾递归优化等, 然后会针对不同架构生成不同的目标代码，最后以汇编代码的格式输出.

#### 1.2.6 汇编

在这一阶段，汇编器将上一步生成的可读的汇编代码转化为机器代码。最终产物就是 以 .o 结尾的目标文件。使用Xcode构建的程序会在DerivedData目录中找到这个文件

>Tips：什么是符号(Symbols)? 符号就是指向一段代码或者数据的名称。还有一种叫做WeakSymols，也就是并不一定会存在的符号，需要在运行时决定。比如iOS 12特有的API，在iOS11上就没有.

#### 1.2.7 链接

目标文件(.o)和引用的库(dylib,a,tbd)链接起来, 最终生成可执行文件(mach-o), 链接器解决了目标文件和库之间的链接.

这时可执行文件的符号表信息已经有了, 会在运行时动态绑定.

#### 1.2.8 Mach-O文件

Mach-O是OS X中二进制文件的原生可执行格式，是传送代码的首选格式。可执行格式决定了二进制文件中的代码和数据读入内存的顺序。代码和数据的顺序会影响内存使用和分页活动，从而直接影响程序的性能.

Mach-O是记录编译后的可执行文件，对象代码，共享库，动态加载代码和内存转储的文件格式。不同于 xml 这样的文件，它只是二进制字节流，里面有不同的包含元信息的数据块，比如字节顺序，cpu 类型，块大小等。文件内容是不可以修改的，因为在 .app 目录中有个 _CodeSignature 的目录，里面包含了程序代码的签名，这个签名的作用就是保证签名后 .app 里的文件，包括资源文件，Mach-O 文件都不能够更改.

Mach-O 文件包含三个区域:

* Mach-O Header: 包含字节顺序，magic，cpu 类型，加载指令的数量等.
* Load Commands: 包含很多内容的表，包括区域的位置，符号表，动态符号表等。每个加载指令包含一个元信息，比如指令类型，名称，在二进制中的位置等.
* Data: 最大的部分，包含了代码，数据，比如符号表，动态符号表等.

Mach-O文件的结构如下：

![](./imgs/172db115a7a70dd6.png)

**Header**

保存了Mach-O的一些基本信息，包括了平台、文件类型、LoadCommands的个数等等.
使用otool -v -h a.out查看其内容：

![](./imgs/172db1184a2a4414.png)

**Load commands**

这一段紧跟Header，加载Mach-O文件时会使用这里的数据来确定内存的分布

**Data**

包含 Load commands 中需要的各个 segment，每个 segment 中又包含多个 section。当运行一个可执行文件时，虚拟内存 (virtual memory) 系统将 segment 映射到进程的地址空间上.
使用`xcrun size -x -l -m a.out`查看segment中的内容：

![](./imgs/172db11a509eaf2e.png)

- Segment __PAGEZERO。
大小为 4GB，规定进程地址空间的前 4GB 被映射为不可读不可写不可执行。


- Segment __TEXT。
包含可执行的代码，以只读和可执行方式映射。


- Segment __DATA。
包含了将会被更改的数据，以可读写和不可执行方式映射。


- Segment __LINKEDIT。
包含了方法和变量的元数据，代码签名等信息。


[Mach-O 文件格式探索](https://www.desgard.com/iOS-Source-Probe/C/mach-o/Mach-O%20%E6%96%87%E4%BB%B6%E6%A0%BC%E5%BC%8F%E6%8E%A2%E7%B4%A2.html)
[趣探 Mach-O：加载过程](https://www.jianshu.com/p/8498cec10a41)

#### 1.2.9 dyld动态链接

生成可执行文件后就是在启动时进行动态链接了, 进行符号和地址的绑定. 首先会加载所依赖的 dylibs，修正地址偏移，因为 iOS 会用 ASLR 来做地址偏移避免攻击，确定 Non-Lazy Pointer 地址进行符号地址绑定，加载所有类，最后执行 load 方法和 clang attribute 的 constructor 修饰函数.

#### 1.2.10 dSYM

在每次编译后都会生成一个 dSYM 文件，程序在执行中通过地址来调用方法函数，而 dSYM 文件里存储了函数地址映射，这样调用栈里的地址可以通过 dSYM 这个映射表能够获得具体函数的位置。一般都会用来处理 crash 时获取到的调用栈 .crash 文件将其符号化

当release的版本 crash的时候,会有一个日志文件,包含出错的内存地址, 使用symbolicatecrash工具能够把日志和dSYM文件转换成可以阅读的log信息,也就是将内存地址,转换成程序里的函数或变量和所属于的 文件名.

[这里](https://www.jianshu.com/p/0b6f5148dab8) 是一篇通过dsym来解析crash文件的教程.

## 2 Xcode编译

按下Command+B, 在XCode的Report Navigator模块中, 可以找到编译的详细日志:

* 创建Product.app的文件夹
* 把Entitlements.plist写入到DerivedData里，处理打包的时候需要的信息（比如application-identifier）. Entitlements.plist保存了App需要使用的特殊权限，比如iCloud，远程通知，Siri等
* 创建一些辅助文件，比如各种.hmap，这是headermap文件，具体作用下文会讲解。
* 执行CocoaPods的编译前脚本：检查Manifest.lock文件。
* 编译.m文件，生成.o文件。
* 链接动态库，o文件，生成一个mach o格式的可执行文件。
* 编译assets，编译storyboard，链接storyboard
* 拷贝动态库Logger.framework，并且对其签名
* 执行CocoaPods编译后脚本：拷贝CocoaPods Target生成的Framework
* 对Demo.App签名，并验证（validate）
* 生成Product.app

## 3 编译顺序

XCode是根据下面的依赖关系, 尽可能的利用多核性能, 多Target并发编译:

* Target Dependencies - 显式声明的依赖关系
* Linked Frameworks and Libraries - 隐式声明的依赖关系
* Build Phase - 定义了编译一个Target的每一步

XCode会对每一个Task生成一个哈希值, 只有哈希值改变的时候才会重新编译. 所以是 *增量编译* 速度很快, 

## 4 头文件

头文件对于编译器来说就是一个promise. 头文件里的声明, 编译会认为有对应实现, 在链接的时候再解决具体实现的位置. 当只有声明，没有实现的时候，链接器就会报错。

Objective C的方法要到运行时才会报错，因为Objective C是一门动态语言，编译器无法确定对应的方法名(SEL)在运行时到底有没有实现(IMP).

日常开发中，两种常见的头文件引入方式:

```
#include "CustomClass.h" //自定义
#include <Foundation/Foundation.h> //系统或者内部framework
```

这里有个文件类型叫做heademap, headermap是帮助编译器找到头文件的辅助文件: 存储这头文件到其物理路径的映射关系.

* clang发现#import “TestView.h”的时候, 先在headermap(Demo-generated-files.hmap,Demo-project-headers.hmap)里查找, 如果headermap文件找不到，接着在own target的framework里找
* 系统的头文件查找的时候也是优先headermap，headermap查找不到会查找own target framework，最后查找SDK目录
* 以#import <Foundation/Foundation.h>为例，在SDK目录查找时首先查找framework是否存在, 如果framework存在，再在headers目录里查找头文件是否存在

[＃import””与＃import<>的区别]()

## 5 Clang Module

传统的＃include/＃import都是文本语义: 预处理器在处理的时候会把这一行替换成对应头文件的文本, 这样就导致:

* 大量的预处理消耗。假如有N个头文件，每个头文件又#include了M个头文件，那么整个预处理的消耗是N*M。
* 文件导入后，宏定义容易出现问题。因为是文本导入，并且按照include依次替换，当一个头文件定义了#define std hello_world，而第另一个头文件刚好又是C++标准库，那么include顺序不同，可能会导致所有的std都会被替换。
* 边界不明显。拿到一组.a和.h文件，很难确定.h是属于哪个.a的，需要以什么样的顺序导入才能正确编译

clang module不再使用文本模型, 而是采用更高效的语义模型。clang module提供了一种新的导入方式:@import，module会被作为一个独立的模块编译，并且产生独立的缓存，从而大幅度提高预处理效率，这样时间消耗从M*N变成了M+N.

XCode创建的Target是Framework的时候，默认define module会设置为YES，从而支持module，当然像Foundation等系统的framwork同样支持module.

`#import <Foundation/NSString.h>` 的时候，编译器会检查NSString.h是否在一个module里，如果是的话，这一行会被替换成 `@import Foundation`.

modulemap文件描述了一组头文件如何转换为一个module. swift是可以直接import一个clang module的，比如你有一些C库，需要在Swift中使用，就可以用modulemap的方式.

## 6 Swift编译

编译一个Swift头文件，需要解析module中所有的Swift文件，找到对应的声明. 这也就是swift没有头文件又是怎么找到声明的原因.

### 6.1 Swift调用OC

Swift的编译器内部使用了clang，所以swift可以直接使用clang module，从而支持直接import Objective C编写的framework. swift编译器会从objective c头文件里查找符号，头文件的来源分为两大类:

* Bridging-Header.h中暴露给swfit的头文件
* framework中公开的头文件，根据编写的语言不同，可能从modulemap或者umbrella header查找

XCode提供了宏定义NS_SWIFT_NAME来让开发者定义Objective C => Swift的符号映射，可以通过Related Items -> Generate Interface来查看转换后的结果

### 6.2 OC调用Swift

xcode会以module为单位，为swift自动生成头文件，供Objective C引用，通常这个文件命名为ProductName-Swift.h

swift提供了关键词@objc来把类型暴露给Objective C和Objective C Runtime.

## 7 深入理解链接(Linker)

链接器会把编译器编译生成的多个文件，链接成一个可执行文件。链接并不会产生新的代码，只是在现有代码的基础上做移动和补丁.

链接器的输入可能是以下几种文件:

* object file(.o)，单个源文件的编辑结果，包含了由符号表示的代码和数据。
* 动态库(.dylib)，mach o类型的可执行文件，链接的时候只会绑定符号，动态库会被拷贝到app里，运行时加载
* 静态库(.a)，由ar命令打包的一组.o文件，链接的时候会把具体的代码拷贝到最后的mach-o
* tbd，只包含符号的库文件

以打印 `hello world` 为例, 在.o文件中字符串”hello world\n”作为一个符号(l_.str)被引用，汇编代码读取的时候按照l_.str所在的页加上偏移量的方式读取，然后调用printf符号。到这一步，CPU还不知道怎么执行，因为还有两个问题没解决:

* l_.str在可执行文件的哪个位置？
* printf函数来自哪里

但是链接之后的mach o文件中确可以正常执行, 是因为:

* 链接后，不再是以页+偏移量的方式读取字符串，而是直接读虚拟内存中的地址，解决了l_.str的位置问题。
* 链接后，不再是调用符号_printf，而是在DATA段上创建了一个函数指针_printf$ptr，初始值为0x0(null)，代码直接调用这个函数指针。启动的时候，dyld会把DATA段上的指针进行动态绑定，绑定到具体虚拟内存中的_printf地址

Mach-O有一个区域叫做LINKEDIT，这个区域用来存储启动的时dyld需要动态修复的一些数据: 比如刚刚提到的printf在内存中的地址.

参考资料:
1.[深入浅出iOS编译](https://juejin.im/post/5c22eaf1f265da611b5863b2)
2.[iOS编译过程](https://juejin.im/post/5c17720af265da615304adc0)
3.[深入理解iOS App的启动过程](https://blog.csdn.net/Hello_Hwc/article/details/78317863)
4.[命令行工具解析Crash文件,dSYM文件进行符号化](https://www.jianshu.com/p/0b6f5148dab8)
5.[Mach-O 文件格式探索](https://www.desgard.com/iOS-Source-Probe/C/mach-o/Mach-O%20%E6%96%87%E4%BB%B6%E6%A0%BC%E5%BC%8F%E6%8E%A2%E7%B4%A2.html)
6.[趣探 Mach-O：加载过程](https://www.jianshu.com/p/8498cec10a41)
7.[探秘 Mach-O 文件](https://juejin.im/post/5ab47ca1518825611a406a39)
8.[iOS编译过程](https://developerdoc.com/essay/LLDB/LLVM%E6%95%99%E7%A8%8B/)
9.[编译器](https://objccn.io/issue-6-2/)
10.[Mach-O可执行文件](https://objccn.io/issue-6-3/)
11.[iOS编译过程的原理和应用](https://github.com/LeoMobileDeveloper/Blogs/blob/master/iOS/iOS%E7%BC%96%E8%AF%91%E8%BF%87%E7%A8%8B%E7%9A%84%E5%8E%9F%E7%90%86%E5%92%8C%E5%BA%94%E7%94%A8.md)

[iOS编译原理](http://hchong.net/2019/07/30/iOS%E7%BC%96%E8%AF%91%E5%8E%9F%E7%90%86/)