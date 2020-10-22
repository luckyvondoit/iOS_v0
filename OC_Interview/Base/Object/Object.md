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