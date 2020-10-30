## 目录

<!-- 直接复制下面的标签， cmd + / 打开注释-->

<!-- <span id=""></span> -->

<!-- 下面需要全部选中在打开注释 -->

<!-- <details>
<summary> 参考 </summary>
</details> -->

1. [#include、#import、@class的区别?](#1)
2. [id 和 instancetype的区别?](#2)
3. [New 作用是什么?](#3)
4. [@proprety的作用](#4)
5. [NSObject和id的区别?](#5)
6. [id类型, nil , Nil ,NULL和NSNULL的区别?](#6)
7. [僵尸对象和野指针](#7)
8. [什么是内存泄露?](#8)
9. [NSMutableDictionary 中使用setValueForKey 和 setObjectForKey有什么区别?](#9)
10. [NSCache 和NSDictionary 区别](#10)
11. [Notification 和KVO区别](#11)
12. [说一下静态库和动态库之间的区别](#12)
13. [如何访问并修改一个类的私有属性？](#13)
14. [如何把一个包含自定义对象的数组序列化到磁盘？](#14)
15. [iOS 的沙盒目录结构是怎样的？ App Bundle 里面都有什么？](#15)
16. [什么是 Protocol，Delegate 一般是怎么用的？](#16)
17. [为什么 NotificationCenter 要 removeObserver? 如何实现自动 remove?](#17)
18. [有哪些常见的 Crash 场景？](#18)

---

1. <span id="1">#include、#import、@class的区别?</span>

<details>
<summary> 参考 </summary>

- 在C 语言中, 我们使用 `#include` 来引入头文件,如果需要防止重复导入需要使用`#ifndef...#define...#endif`
- 在OC语言中, 我们使用`#import`来引入头文件,可以防止重复引入头文件,可以避免出现头文件递归引入的现象。
- `@class`仅用来告诉编译器，有这样一个类，编译代码时，不报错,不会拷贝头文件.如果需要使用该类或者内部方法需要使用 `#import` 导入

</details>

2. <span id="2">id 和 instancetype的区别?</span>

<details>
<summary> 参考 </summary>

- `id`可以作为方法的返回以及参数类型 也可以用来定义变量
- `instancetype`只能作为函数或者方法的返回值
- `instancetype`对比`id`的好处就是: 能精确的限制返回值的具体类型

</details>

3. <span id="">New 作用是什么?</span>

<details>
<summary> 参考 </summary>

1. 向计算机(堆区)申请内存空间;
2. 给实例变量初始化;
3. 返回所申请空间的首地址;

</details>

4. <span id="4">@proprety的作用</span>

<details>
<summary> 参考 </summary>

- [Property](./Property.md)

</details>

5. <span id="5">NSObject和id的区别?</span>

<details>
<summary> 参考 </summary>

- id可以指向任何对象，包括NSObject和NSProxy继承串，NSObject只能指向NSObject及其子类。
- NSObject对象会在编译时进行检查,需要强制类型转换
- id类型不需要编译时检查,不需要强制类型转换
- 

</details>

6. <span id="6">id类型, nil , Nil ,NULL和NSNULL的区别?</span>

<details>
<summary> 参考 </summary>

- id类型: 是一个独特的数据类型，可以转换为任何数据类型，id类型的变量可以存放任何数据类型的对象，在内部处理上，这种类型被定义为指向对象的指针，实际上是一个指向这种对象的实例变量的指针; id 声明的对象具有运行时特性，既可以指向任意类型的对象
- nil 是一个实例对象值;如果我们要把一个对象设置为空的时候,就用nil
- Nil 是一个类对象的值,如果我们要把一个class的对象设置为空的时候,就用Nil
- NULL 指向基本数据类型的空指针(C语言的变量的指针为空)
- NSNull 是一个对象,它用在不能使用nil的场合

</details>

7. <span id="7">僵尸对象和野指针</span>

<details>
<summary> 参考 </summary>

- 僵尸对象：已经被销毁的对象(不能再使用的对象),内存已经被回收的对象。简而言之，就是过度释放的对象。
- 野指针：指向僵尸对象(不可用内存/已经释放的内存地址)的指针

</details>

8. <span id="8">什么是内存泄露?</span>

<details>
<summary> 参考 </summary>

- 内存泄露 :一个对象不再使用,但是这个对象却没有被销毁,空间没有释放,则这个就叫做内存泄露.
- ARC导致的循环引用 block,delegate,NSTimer等.
</details>

9. <span id="9">NSMutableDictionary 中使用setValueForKey 和 setObjectForKey有什么区别?</span>

<details>
<summary> 参考 </summary>

- `- (void)setValue:(id)value forKey:(NSString *)key;`
@end
  - value 为 nil ，调用 removeObject:forKey:
  - value不为nil时调用 setObject：forKey：
  - key为NSString类型。
- `- (void)setObject:(id)anObject forKey:(id <NSCopying>)aKey;`
  - anobject不能为nil，而且key是一个id类型，不仅限于NSString类型

**两者的区别**：

- （1）setObject：forkey：中value是不能够为nil的；setValue：forKey：中value能够为nil，但是当value为nil的时候，会自动调用removeObject：forKey方法
- （2）setValue：forKey：中key只能够是NSString类型，而setObject：forKey：的可以是任何类型

</details>

10. <span id="10">NSCache 和NSDictionary 区别?</span>

<details>
<summary> 参考 </summary>

- NSCache可以提供自动删减缓存功能，而且保证线程安全，与字典不同，不会拷贝键。
- NSCache可以设置缓存上限，限制对象个数和总缓存开销。定义了删除缓存对象的时机。这个机制只对NSCache起到指导作用，不会一定执行。
- NSPurgeableData搭配NSCache使用，可以自动清除数据。
- 只有那种“重新计算很费劲”的数据才值得放入缓存。

</details>

11. <span id="11">Notification 和KVO区别</span>

<details>
<summary> 参考 </summary>

- KVO提供一种机制,当指定的被观察的对像的属性被修改后,KVO会自动通知响应的观察者,KVC(键值编码)是KVO的基础
- 通知:是一种广播机制,在实践发生的时候,通过通知中心对象,一个对象能够为所有关心这个时间发生的对象发送消息,两者都是观察者模式,不同在于KVO是被观察者直接发送消息给观察者,是对象间的直接交互,通知则是两者都和通知中心对象交互,对象之间不知道彼此
- 本质区别,底层原理不一样.kvo 基于 runtime, 通知则是有个通知中心来进行通知

</details>

12. <span id="12">说一下静态库和动态库之间的区别</span>

<details>
<summary> 参考 </summary>

**静态库**：
- 以.a 和 .framework为文件后缀名。
- 链接时会被完整的复制到可执行文件中，被多次使用就有多份拷贝。

**动态库**：
- 以.tbd(之前叫.dylib) 和 .framework 为文件后缀名。
- 链接时不复制，程序运行时由系统动态加载到内存，系统只加载一次，多个程序共用（如系统的UIKit.framework等），节省内存。

静态库.a 和 framework区别:
- .a 主要是二进制文件,不包含资源,需要自己添加头文件
- .framework 可以包含头文件+资源信息

</details>

13. <span id="13">如何访问并修改一个类的私有属性？</span>

<details>
<summary> 参考 </summary>

- 有两种方法可以访问私有属性,一种是通过KVC获取,一种是通过runtime访问并修改私有属性
- 创建一个Father类,声明一个私有属性name,并重写description打印name的值,在另外一个类中通过runtime来获取并修改Father中的属性

```objc
@interface Father ()
@property (nonatomic, copy) NSString *name;
@end
@implementation Father

- (NSString *)description
{
    return [NSString stringWithFormat:@"name:%@",_name];
}

@implementation ViewController

- (void)viewDidLoad {

    [super viewDidLoad];

    Father *father = [Father new];  
    // count记录变量的数量IVar是runtime声明的一个宏
    unsigned int count = 0;
    // 获取类的所有属性变量
    Ivar *menbers = class_copyIvarList([Father class], &count);
    
    for (int i = 0; i < count; i++) {
        Ivar ivar = menbers[i];
        // 将IVar变量转化为字符串,这里获得了属性名
        const char *memberName = ivar_getName(ivar);
        NSLog(@"%s",memberName);
        
        Ivar m_name = menbers[0];
        // 修改属性值
        object_setIvar(father, m_name, @"zhangsan");
        // 打印后发现Father中name的值变为zhangsan
        NSLog(@"%@",[father description]);
    }

}
```


</details>


14. <span id="">如何把一个包含自定义对象的数组序列化到磁盘？</span>

<details>
<summary> 参考 </summary>

自定义对象只需要实现NSCoding协议即可

```objc
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    User *user = [User new];
    Account *account = [Account new];
    NSArray *userArray = @[user, account];
    // 存到磁盘
    NSData * tempArchive = [NSKeyedArchiver archivedDataWithRootObject: userArray];
}
// 自定义对象中的代理方法
- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.user = [aDecoder decodeObjectForKey:@"user"];
        self.account = [aDecoder decodeObjectForKey:@"account"];
    }
    return self;
}
// 代理方法
-(void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.user forKey:@"user"];
    [aCoder encodeObject:self.account forKey:@"account"];
}
```

</details>



15. <span id="">iOS 的沙盒目录结构是怎样的？ App Bundle 里面都有什么？</span>

<details>
<summary> 参考 </summary>

**1.沙盒结构**
  - Application：存放程序源文件，上架前经过数字签名，上架后不可修改
  - Documents：常用目录，iCloud备份目录，存放数据,这里不能存缓存文件,否则上架不被通过
  - Library
    - Caches：存放体积大又不需要备份的数据,SDWebImage缓存路径就是这个
    - Preference：设置目录，iCloud会备份设置信息
  - tmp：存放临时文件，不会被备份，而且这个文件下的数据有可能随时被清除的可能

**2. App Bundle 里面有什么**

- Info.plist:此文件包含了应用程序的配置信息.系统依赖此文件以获取应用程序的相关信息
- 可执行文件:此文件包含应用程序的入口和通过静态连接到应用程序target的代码
- 资源文件:图片,声音文件一类的
- 其他:可以嵌入定制的数据资源


</details>

16. <span id="16">什么是 Protocol，Delegate 一般是怎么用的？</span>

<details>
<summary> 参考 </summary>

- Protocol表示遵循了某个协议

</details>

17. <span id="17">为什么 NotificationCenter 要 removeObserver? 如何实现自动 remove?</span>

<details>
<summary> 参考 </summary>

1. 如果不移除的话,万一注册通知的类被销毁以后又发了通知,程序会崩溃.因为向野指针发送了消息
2. 在iOS 9(更新的系统版本有待考证)之后，苹果对其做了优化，会在响应者调用dealloc方法的时候执行removeObserver:方法。也可以通过如下方式实现：

```swift
/// Wraps the observer token received from 
/// NotificationCenter.addObserver(forName:object:queue:using:)
/// and unregisters it in deinit.
final class NotificationToken: NSObject {
    let notificationCenter: NotificationCenter
    let token: Any

    init(notificationCenter: NotificationCenter = .default, token: Any) {
        self.notificationCenter = notificationCenter
        self.token = token
    }

    deinit {
        notificationCenter.removeObserver(token)
    }
}
```

现在我们将 observer 封装在了 NotificationToken 中，在 NotificationToken 创建的时候添加 observer， 销毁前自动移除该 observer，这样我们就可以通过管理 NotificationToken 对象的生命周期来实现移除 observer 操作。使用的时候只需要把 NotificationToken 存在一个私有属性中，当持有 NotificationToken 的对象销毁的时候 NotificationToken 会自动移除内部的观察者（当然我们可以主动向该私有属性赋 nil 来移除 observer）。

</details>

18. <span id="18">有哪些常见的 Crash 场景？</span>

<details>
<summary> 参考 </summary>

- 访问了僵尸对象
- 访问了不存在的方法
- 数组越界
- 在定时器下一次回调前将定时器释放,会Crash

</details>
