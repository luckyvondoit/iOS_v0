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

需要强调一点，如果使用了属性但是又不想让编译器自动合成存取方法，那么有以下两种方法：
1. 自己实现存取方法。如果只实现了其中一个存取方法，那么另一个还会由编译器自动生成。
2. 使用@dynamic关键字。

### 传统的C++类实例变量的定义形式

原本的类实例变量定义形式如下，类是实例变量和方法的集合，变量的定义可以通过public、private和protected等语义关键词来修饰限定变量的定义域，实现对变量的封装。OC中仍然保留了这种定义方式，其中关键字改为：@public、@private、@protected以及@package等，在头文件中的变量默认是@protected，在.m文件中的变量默认是@private。

```
@interface Test : NSObject {
    @public
    NSString *_name;
    @private
    NSString *_job;
    @protected
    NSString *_favourite;
    @package
    NSString *_lover;
}
```

以上这种传统定义形式的缺点如下：

* 每个变量都要手写getter和setter，代码冗余。
* 这种类变量定义的方式属于”硬编码“，即对象内部的变量定义和布局已经写死了编译期，编译后不可再更改，否则会报错。因为上面的”硬编码“是指类中的变量会被编译器定义为距对象初始指针地址的偏移量（offset），编译之后变量是通过地址偏移来寻找的，如果想要在类中插入新的变量，那么必须要重新编译计算每个变量的偏移量，否则顺序被打乱会读取错误的变量。

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

1. 一旦你同时重写了getter、setter方法,你必须使用@synthesize variable = _variable来区分属性名与方法名.
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

### getter方法中为何不能用self

有经验的开发者应该都知道这一点，在getter方法中是不能使用self.的，比如：

```
- (NSString *)name
{
    NSLog(@"rewrite getter");
    return self.name;  // 错误的写法，会造成死循环
}
```

原因代码注释中已经写了，这样会造成死循环。这里需要注意的是：self.name实际上就是执行了属性name的getter方法，getter方法中又调用了self.name， 会一直递归调用，直到程序崩溃。通常程序中使用：

```
self.name = @"aaa";
```

这样的方式，setter方法会被调用。

### @property修饰符

关于ARC下，不显示指定属性关键字时，默认关键字： 
1. 基本数据类型：atomic readwrite assign 
2. 普通OC对象： atomic readwrite strong


修饰符的种类包括：

#### 1. 原子性 --- `nonatomic`、`atomic`

atomic 修饰的 property，getter 和 setter 都加锁了，而且是同一个锁，因此任一时刻，有且仅有一个线程，可以访问 getter 和 setter。

atomic 之前是用自旋锁 OSSpinLock 实现的，由于存在优先级反转的问题（低优先级线程加锁，又来了个高优先级的线程被cpu优先执行，但是需要等低优先级线程解锁，而低优先级线程无法执行，造成死锁），iOS 10 后改用 os_unfair_lock 实现了。

atomic只能保证读写操作的原子性，不会出现写了一半就开始读取而造成的数据紊乱问题（读写安全）,不是线程安全的。

atomic是对整个对象（self）进行加锁，效率低，而且无法保证线程安全，基本不使用。

参考：
[从源代码理解atomic为什么不是线程安全
](https://cloud.tencent.com/developer/article/1445940)

#### 2. 读写权限 --- `readonly`、`readwrite`

readonly告诉编译器只生成get方法。

readwrite告诉编译器生成get和set方法。


#### 3. 内存管理语义 --- `assign`、`strong`、 `weak`、`unsafe_unretained`、`copy`

**assign** 直接简单赋值，不会增加对象的引用计数。主要修饰基础数据类型（eg NSInter）和C数据类型（eg：int,float,double,char等）。当assign用来修饰对象的时候（非ARC下的delegate使用此关键字），和weak类似，避免循环引用。唯一的区别就是当属性所指的对象释放的时候，属性不会被置为nil，这就会产生野指针。

**strong**表示一种“拥有关系”。为属性设置新值的时候，设置方法会先保留新值（新值的引用计数加一），并释放旧值（旧值的引用计数减一），然后将新值赋值上去。相当于MRC下的retain。

**weak** 修饰弱引用类型，不增加引用对象的引用计数，主要可以用于避免循环引用。当属性所指的对象释放的时候，属性会被置为nil，防止产生野指针。通常用来修饰delegate、IBOutlet对象。

**copy**修饰的属性设置新值的时候，当新值是不可变的，和strong是一模一样的。当新值是可变的(开头是NSMutable)，设置方法不会保留新值（新值的引用计数加一），而是对新值copy一份，不会影响新值的引用计数。copy常用来修饰NSString，因为当新值是可变的，防止属性在不知不觉中被修改。

**unsafe_unretained**用来修饰属性的时候，和assing修饰对象的时候是一模一样的。为属性设置新值的时候，设置方法既不会保留新值（新值的引用计数加一），也不会释放旧值（旧值的引用计数减一）。唯一的区别就是当属性所指的对象释放的时候，属性不会被置为nil，这就会产生野指针，所以是不安全的。

#### 4. 方法名 --- `getter=<name>` 、`setter=<name>`

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


#### 5. 不常用的 --- `nonnull`、`null_resettable`、`nullable`

设置属性是否可以为空，和swift混编时会用到。


### weak和assign区别

经常会有面试题问weak和assign的区别，这里介绍一下。

weak和strong是对应的，一个是强引用，一个是弱引用。weak和assign的区别主要是体现在两者修饰OC对象时的差异。上面也介绍过，assign通常用来修饰基本数据类型，如int、float、BOOL等，weak用来修饰OC对象，如UIButton、UIView等。

**基本数据类型用weak来修饰**

假设声明一个int类型的属性，但是用weak来修饰，会发生什么呢？

```
@property (nonatomic, weak) int age;
```

Xcode会直接提示错误，错误信息如下：

```
Property with 'weak' attribute must be of object type
```

也就是说，weak只能用来修饰对象，不能用来修饰基本数据类型，否则会发生编译错误。

**对象使用assign来修饰**

假设声明一个UIButton类型的属性，但是用assign来修饰，会发生什么呢？

```
@property (nonatomic, assign) UIButton *assignBtn;
```

编译，没有问题，运行也没有问题。我们再声明一个UIButton,使用weak来修饰，对比一下：

```
@interface ViewController ()

@property (nonatomic, assign) UIButton *assignBtn;

@property (nonatomic, weak) UIButton *weakButton;

@end
```

正常初始化两个button：

```
UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(100,100,100,100)];
[btn setTitle:@"Test" forState:UIControlStateNormal];
btn.backgroundColor = [UIColor lightGrayColor];
self.assignBtn = btn;
self.weakButton = btn;
```

此时打印两个button，没有区别。释放button：

```
btn = nil;
```

释放之后打印self.weakBtn和self.assignBtn

```
NSLog(@"self.weakBtn = %@",self.weakButton);
NSLog(@"self.assignBtn = %@",self.assignBtn);
```

运行，执行到self.assignBtn的时候崩溃了，崩溃信息是

```
EXC_BAD_ACCESS (code=EXC_I386_GPFLT)
 ```

weak和assign修饰对象时的差别体现出来了。

weak修饰的对象，当对象释放之后，即引用计数为0时，对象会置为nil

```
2018-12-06 16:17:05.774298+0800 TestClock[15863:192570] self.weakBtn = (null)
```

而向nil发送消息是没有问题的，不会崩溃。

assign修饰的对象，当对象释放之后，即引用计数为0时，对象会变为野指针，不知道指向哪，再向该对象发消息，非常容易崩溃。

因此，当属性类型是对象时，不要使用assign，会带来一些风险。

**堆和栈**

上面说到，属性用assign修饰，当被释放后，容易变为野指针，容易带来崩溃问题，那么，为何基本数据类型可以用assign来修饰呢？这就涉及到堆和栈的问题。

相对来说，堆的空间大，通常是不连续的结构，使用链表结构。使用堆中的空间，需要开发者自己去释放。OC中的对象，如 UIButton 、UILabel ，[[UIButton alloc] init] 出来的，都是分配在堆空间上。

栈的空间小，约1M左右，是一段连续的结构。栈中的空间，开发者不需要管，系统会帮忙处理。iOS开发 中 int、float等变量分配内存时是在栈上。如果栈空间使用完，会发生栈溢出的错误。

由于堆、栈结构的差异，栈和堆分配空间时的寻址方式也是不一样的。因为栈是连续的控件，所以栈在分配空间时，会直接在未使用的空间中分配一段出来，供程序使用；如果剩下的空间不够大，直接栈溢出；堆是不连续的，堆寻找合适空间时，是顺着链表结点来寻找，找到第一块足够大的空间时，分配空间，返回。根据两者的数据结构，可以推断，堆空间上是存在碎片的。

回到问题，为何assign修饰基本数据类型没有野指针的问题？因为这些基本数据类型是分配在栈上，栈上空间的分配和回收都是系统来处理的，因此开发者无需关注，也就不会产生野指针的问题。

### copy、strong、mutableCopy

**可变对象和不可变对象**

Objective-C中存在可变对象和不可变对象的概念。像NSArray、NSDictionary、NSString这些都是不可变对象，像NSMutableArray、NSMutableDictionary、NSMutableString这些是可变对象。可变对象和不可变对象的区别是，不可变对象的值一旦确定就不能再修改。

OC的动态性直到运行时才去做类型检查，如果我们将NSMutableString赋值给一个NSString变量，在程序执行过程中在类外修改了NSMutableString，类内的NSString变量也会跟着变化。可能会在不知情的情况下修改了属性的值，造成意想不到的bug。

**深拷贝和浅拷贝**

编译器做了优化，对于不可变的对象调用copy，只会进行指针copy。对可变的对象调用copy，会进行值copy

**copy和mutableCopy**

对可变和不可不对象进行copy，生成的都是不可变对象。
对可变和不可不对象进行mutableCopy，生成的都是可变对象。

可以看出，对不可变对象的copy操作是浅拷贝，其余的都为深拷贝。

**自定义对象如何支持copy方法**

项目开发中经常会有自定义对象的需求，那么自定义对象是否可以copy呢？如何支持copy？

自定义对象可以支持copy方法，我们所需要做的是：自定义对象遵守NSCopying协议，且实现copyWithZone方法。NSCopying协议是系统提供的，直接使用即可。

遵守NSCopying协议：

```
@interface Student : NSObject <NSCopying>
{
    NSString *_sex;
}

@property (atomic, copy) NSString *name;

@property (nonatomic, copy) NSString *sex;

@property (nonatomic, assign) int age;

@end
```

实现CopyWithZone方法：

```
- (instancetype)initWithName:(NSString *)name age:(int)age sex:(NSString *)sex
{
    if(self = [super init]){
        self.name = name;
        _sex = sex;
        self.age = age;
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    // 注意，copy的是自己，因此使用自己的属性
    Student *stu = [[Student allocWithZone:zone] initWithName:self.name age:self.age sex:_sex];
    return stu;
}
```

测试代码：

```
- (void)testStudent
{
    Student *stu1 = [[Student alloc] initWithName:@"Wang" age:18 sex:@"male"];
    Student *stu2 = [stu1 copy];
    NSLog(@"stu1 = %p stu2 = %p",stu1,stu2);
}
```

输出结果：

```
stu1 = 0x600003a41e60 stu2 = 0x600003a41fc0
```

这里是一个深拷贝，根据copyWithZone方法的实现，应该很容易明白为何是深拷贝。

除了NSCopying协议和copyWithZone方法，对应的还有NSMutableCopying协议和mutableCopyWithZone方法，实现都是类似的，不做过多介绍。

