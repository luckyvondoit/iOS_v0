### @property 的本质是什么？
```
@property = ivar + getter + setter;
```
下面解释下：
```
“属性” (property)有两大概念：ivar（实例变量）、存取方法（access method ＝ getter + setter）。
```
“属性” (property)作为 Objective-C 的一项特性，主要的作用就在于封装对象中的数据。 Objective-C 对象通常会把其所需要的数据保存为各种实例变量。实例变量一般通过“存取方法”(access method)来访问。实例变量通过`.`语法访问和修改属性值，本质上是实例变量通过“存取方法”访问和修改实例变量（也叫成员变量）。
例如下面这个类：
```
//.h
@interface IFXPerson : NSObject

@property NSString *name;
@property NSUInteger age;

@end

//.m
#import "IFXPerson.h"

@implementation IFXPerson

@end
```

###ivar、getter、setter 是如何生成并添加到这个类中的?

>“自动合成”( autosynthesis)

完成属性定义后，编译器会自动编写访问这些属性所需的方法，此过程叫做“自动合成”(autosynthesis)。需要强调的是，这个过程由编译 器在编译期执行，所以编辑器里看不到这些“合成方法”(synthesized method)的源代码。除了生成方法代码 getter、setter 之外，编译器还要自动向类中添加适当类型的实例变量，并且在属性名前面加下划线，以此作为实例变量的名字。在前例中，会生成两个实例变量，其名称分别为 _name与 _age。

补全编译器生成的代码如下：

```
//.h
@interface IFXPerson : NSObject
{
    NSString *_name;
    NSUInteger _age;
}

@property NSString *name;
@property NSUInteger age;

- (void)setName:(NSString *)name;
- (NSString *)name;

- (void)setAge:(NSUInteger)age;
- (NSUInteger)age;

@end

//.m
@implementation IFXPerson

- (void)setName:(NSString *)name {
    _name = name;
}
- (NSString *)name {
    return _name;
}

- (void)setAge:(NSUInteger)age {
    _age = age;
}
- (NSUInteger)age {
    return _age;
}

@end
```

### ARC与MRC的setter方法的差异

```
@interface Model : NSObject

@property(nonatomic, strong) NSString *name;

@end
```

在看下ARC下的setter方法:

```

@implementation Model

@synthesize name = _name;

- (NSString *)name {
    return _name;
}

- (void)setName:(NSString *)name {
    if (_name != name) {
        [_name release];
        _name = [name retain];
    }
}

@end
```

在看下ARC下的setter方法:

```
@implementation Model

@synthesize name = _name;

- (NSString *)name {
    return _name;
}

- (void)setName:(NSString *)name {
    _name = name;
}

@end
```

**小结**

1. 一旦你重写了getter.setter方法,你必须使用@synthesize variable = _variable来区分属性名与方法名.
2. ARC与MRC的getter方法一致,就setter方法有着略微区别.


### @synthesize
@synthesize关键字主要有两个作用，在ARC下已经很少用了。


1. 在MRC下，@synthesize str这样，编译器才会自动合成str的存取方法。不过在ARC下就不必了，无论你是否@synthesize str，编译器都会自动合成str的存取方法。

```
//.m
@implementation IFXPerson

@synthesize name = _name;
@synthesize age = _age;

@end
```

2. 如果你声明的属性是str，系统自动给你添加的成员变量是_str，如果你对这个变量名字不满，可以这样@synthesize str = mystr;，自己给个名字。这样系统给添加的成员变量就是myStr，而不是_str，但是变量的存取方法没有变化。不过建议最好不要这么办，因为都按照约定成俗的方式来命名变量，代码的可读性较高，大家都理解，所以我建议大家最好不要用这个关键字。


### @dynamic
@dynamic 关键字主要是告诉编译器不用为我们自动合成变量的存起方法， 我们会自己实现。即使我们没有实现，编译器也不会警告，因为它相信在运行阶段会实现。如果我们没有实现还调用了，就会报这个错误`-[XXX setStr:]: unrecognized selector sent to instance 0x10040af10`。

@dynamic还有一个应用。

父类
```
#import <Foundation/Foundation.h>

@interface Father : NSObject

@property (nonatomic, strong) NSString *str;

@end
```

子类

```
#import "Father.h"

@interface Son : Father

@property (nonatomic, strong) NSString *str;

@end
```

如果我们在子类中重写父类的属性，就会报下面的警告

```
Auto property synthesis will not synthesize property 'str'; it will be implemented by its superclass, use @dynamic to acknowledge intention
```

因为我们同时在父类和子类中同时声明了str的属性，系统就不知道该在哪里（父类Father还是子类Son？）自动合成str的存取方法，系统默认是在父类中声明，因为子类可以调用。不过，系统希望我们显式的声明这一点，这样有利于提高代码的可读性。

```
#import "Son.h"

@implementation Son

@dynamic str;

@end
```

### @property修饰符
关于ARC下，不显示指定属性关键字时，默认关键字： 
1. 基本数据类型：atomic readwrite assign 
2. 普通OC对象： atomic readwrite strong


修饰符的种类包括：

#### 1. 原子性 --- `nonatomic`、`atomic`

atomic 修饰的 property，getter 和 setter 都加锁了，而且是同一个锁，因此任一时刻，有且仅有一个线程，可以访问 getter 和 setter。

atomic 之前是用自旋锁 OSSpinLock 实现的，由于存在优先级反转的问题（低优先级线程加锁，又来了个高优先级的线程被cpu优先执行，但是需要等低优先级线程解锁，而低优先级线程无法执行，造成死锁），iOS 10 后改用 os_unfair_lock 实现了。

atomic只能保证读写操作的原子性，不会出现写了一半就开始读取而造成的数据紊乱问题（读写安全）。

atomic是对整个对象（self）进行加锁，效率低，而且无法保证线程安全，基本不使用。

参考：
[从源代码理解atomic为什么不是线程安全
](https://cloud.tencent.com/developer/article/1445940)

#### 2. 读写权限 --- `readonly`、`readwrite`

readonly告诉编译器只生成get方法。

readwrite告诉编译器生成get和set方法。


#### 3. 内存管理语义 --- `assign`、`strong`、 `weak`、`unsafe_unretained`、`copy`

**strong**表示一种“拥有关系”。为属性设置新值的时候，设置方法会先保留新值（新值的引用计数加一），并释放旧值（旧值的引用计数减一），然后将新值赋值上去。相当于MRC下的retain。

**weak**表示一种“非拥有关系”。用weak修饰属性的时候，为属性设置新值的时候，设置方法既不会保留新值（新值的引用计数加一），也不会释放旧值（旧值的引用计数减一）。当属性所指的对象释放的时候，属性也会被置为nil。用于修饰UI控件，代理(delegate)。

**assign**可以同时用来修饰基本数据(NSInteger，CGFloat等)类型和对象。当assign用来修饰对象的时候，和weak类似。唯一的区别就是当属性所指的对象释放的时候，属性不会被置为nil，这就会产生野指针。

**copy**修饰的属性设置新值的时候，当新值是不可变的，和strong是一模一样的。当新值是可变的(开头是NSMutable)，设置方法不会保留新值（新值的引用计数加一），而是对新值copy一份，不会影响新值的引用计数。copy常用来修饰NSString，因为当新值是可变的，防止属性在不知不觉中被修改。

**unsafe_unretained**用来修饰属性的时候，和assing修饰对象的时候是一模一样的。为属性设置新值的时候，设置方法既不会保留新值（新值的引用计数加一），也不会释放旧值（旧值的引用计数减一）。唯一的区别就是当属性所指的对象释放的时候，属性不会被置为nil，这就会产生野指针，所以是不安全的。

#### 方法名 --- `getter=<name>` 、`setter=<name>`

`getter=<name>`的样式：

```
@property (nonatomic, getter=isOn) BOOL on;
```
~~（ `setter=`这种不常用，也不推荐使用。故不在这里给出写法。）~~

`setter=<name>`一般用在特殊的情境下，比如：

在数据反序列化、转模型的过程中，服务器返回的字段如果以 init 开头，所以你需要定义一个 init 开头的属性，但默认生成的 setter 与 getter 方法也会以 init 开头，而编译器会把所有以 init 开头的方法当成初始化方法，而初始化方法只能返回 self 类型，因此编译器会报错。

这时你就可以使用下面的方式来避免编译器报错：

```
@property(nonatomic, strong, getter=p_initBy, setter=setP_initBy:)NSString *initBy;
```

另外也可以用关键字进行特殊说明，来避免编译器报错：

```
@property(nonatomic, readwrite, copy, null_resettable) NSString *initBy;
- (NSString *)initBy __attribute__((objc_method_family(none)));
```


#### 不常用的 --- `nonnull`、`null_resettable`、`nullable`

设置属性是否可以为空，和swift混编时会用到。

### 面试题

#### 什么情况使用 weak 关键字，相比 assign 有什么不同？

什么情况使用 weak 关键字？

1. 在 ARC 中,在有可能出现循环引用的时候,往往要通过让其中一端使用 weak 来解决,比如: delegate 代理属性
2. 自身已经对它进行一次强引用,没有必要再强引用一次,此时也会使用 weak,自定义 IBOutlet 控件属性一般也使用 weak；当然，也可以使用strong。在下文也有论述：[《IBOutlet连出来的视图属性为什么可以被设置成weak?》](https://upload-images.jianshu.io/upload_images/1322408-f9a65f0baa774b86.jpg?imageMogr2/auto-orient/strip|imageView2/2/w/506/format/webp)

不同点：

1. weak 此特质表明该属性定义了一种“非拥有关系” (nonowning relationship)。为这种属性设置新值时，设置方法既不保留新值，也不释放旧值。此特质同assign类似， 然而在属性所指的对象遭到摧毁时，属性值也会清空(nil out)。 而 assign 的“设置方法”只会执行针对“纯量类型” (scalar type，例如 CGFloat 或 NSlnteger 等)的简单赋值操作。
2. assign 可以用非 OC 对象,而 weak 必须用于 OC 对象


### 怎么用 copy 关键字？
用途：
1. NSString、NSArray、NSDictionary 等等经常使用copy关键字，是因为他们有对应的可变类型：NSMutableString、NSMutableArray、NSMutableDictionary；
2. block 也经常使用 copy 关键字，具体原因见官方文档：Objects Use Properties to Keep Track of Blocks：

