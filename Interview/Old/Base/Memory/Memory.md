## 目录
1. [iOS内存管理机制](#1)
2. [简述weak的实现原理](#2)
3. [block的分类，__block的作用,block循环引用产生的原因及解决办法](#3)

---

1. <span id="1">iOS内存管理机制</span>

<details>
<summary> 参考 </summary>
- iOS的内存管理用的是引用计数的方法，分为MRC(手动引用计数)和ARC(自动引用计数)。
- MRC:开发者手动地进行retain和release操作，对每个对象的retainCount进行+1,-1操作，当retainCount为0时，系统会自动释放对象内存。
- ARC:开发者通过声明对象的属性为strong,weak,retain,assign来管理对象的引用计数，被strong和retain修饰的属性变量系统会自动对所修饰变量的引用计数进行自增自减操作，同样地，retainCount为0时，系统会释放对象内存。

iOS内存管理机制的原理是引用计数，当这块内存被创建后，它的引用计数0->1，表示有一个对象或指针持有这块内存，拥有这块内存的所有权，如果这时候有另外一个对象或指针指向这块内存，那么为了表示这个后来的对象或指针对这块内存的所有权，引用计数1->2，之后若有一个对象或指针不再指向这块内存时，引用计数-1，表示这个对象或指针不再拥有这块内存的所有权，当一块内存的引用计数变为0，表示没有任何对象或指针持有这块内存，系统便会立刻释放掉这块内存。

- alloc、new ：类初始化方法，开辟新的内存空间，引用计数+1；
- retain ：实例方法，不会开辟新的内存空间，引用计数+1；
- copy : 实例方法，把一个对象复制到新的内存空间，新的内存空间引用计数+1，旧的不会；其中分为浅拷贝和深拷贝，浅拷贝只是拷贝地址，不会开辟新的内存空间；深拷贝是拷贝内容，会开辟新的内存空间；
- strong ：强引用； 引用计数+1；
- release ：实例方法，释放对象；引用计数-1；
- autorelease : 延迟释放；autoreleasepool自动释放池；当执行完之后引用计数-1；
还有是initWithFormat和stringWithFormat 字符串长度大于9时，引用计数+1；
- assign : 弱引用 ；weak也是弱引用，两者区别：assign不但能作用于对象还能作用于基本数据类型，但是所指向的对象销毁时不会将当前指向对象的指针指向nil，有野指针的生成；weak只能作用于对象，不能作用于基本数据类型，所指向的对象销毁时会将当前指向对象的指针指向nil，防止野指针的生成。

要注意循环引用导致的内存泄漏和野指针问题。

</details>

2. <span id="2">简述weak的实现原理</span>

<details>
<summary> 参考 </summary>

weak 关键字的作用弱引用，所引用对象的计数器不会加一，并在引用对象被释放的时候自动被设置为 nil;

weak是有Runtime维护的weak表;

weak被释放为nil，需要对对象整个释放过程了解，如下是对象释放的整体流程：

1. 调用objc_release
2. 因为对象的引用计数为0，所以执行dealloc
3. 在dealloc中，调用了_objc_rootDealloc函数
4. 在_objc_rootDealloc中，调用了object_dispose函数
5. 调用objc_destructInstance
6. 最后调用objc_clear_deallocating。

对象准备释放时，调用clearDeallocating函数。clearDeallocating函数首先根据对象地址获取所有weak指针地址的数组，然后遍历这个数组把其中的数据设为nil，最后把这个entry从weak表中删除，最后清理对象的记录。

其实Weak表是一个hash（哈希）表，然后里面的key是指向对象的地址，Value是Weak指针的地址的数组。

**总结**

weak是Runtime维护了一个hash(哈希)表，用于存储指向某个对象的所有weak指针。weak表其实是一个hash（哈希）表，Key是所指对象的地址，Value是weak指针的地址（这个地址的值是所指对象指针的地址）数组。

</details>

3. <span id="3">block的分类，__block的作用,block循环引用产生的原因及解决办法</span>

<details>
<summary> 参考 </summary>

- blcok分为全局blcok，堆block，栈block。
- 在 MRC下:只要没有访问外部变量，就是全局block。访问了外部变量，就是栈block。显示地调用[block copy]就是堆block。
- 在 ARC下:只要没有访问外部变量，就是全局block。如果访问了外部变量，那么在访问外部变量之前存储在栈区，访问外部变量之后存储在堆区。
- __block的作用:将外部变量的传递形式由值传递变为指针传递，从而可以获取并且修改外部变量的值。同样，外部变量的修改，也会影响block函数的输出。
- block循环引用问题：当一个类的对象持有block，block里面又引用了这个对象，那么就是一个循环引用的关系。可以用strong-weak-dance的方法解除循环引用。

</details>