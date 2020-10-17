# copy/mutableCopy

## 1、几点说明

如果类想要支持copy操作，则必须实现NSCopying协议，也就是说实现copyWithZone方法。

如果类想要支持mutableCopy操作，则必须实现NSMutableCopying协议，也就是说实现mutableCopyWithZone方法。

iOS系统中的一些类已经实现了NSCopying或者NSMutableCopying协议的方法，如果向未实现相应方法的系统类或者自定义类发送copy或者mutableCopy消息，则会crash。

```
*** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: '-[Person copyWithZone:]: unrecognized selector sent to instance 0x6080000314c0'
```

发送copy和mutableCopy消息，均是进行拷贝操作，但是对不可变对象的非容器类、可变对象的非容器类、可变对象的容器类、不可变对象的容器类中复制的方式略有不同。但如下两点是相同的：

* 发送copy消息，拷贝出来的是不可变对象;

* 发送mutableCopy消息，拷贝出来的是可变对象;

故如下的操作会导致crash

```
NSMutableString *test1 = [[NSMutableString alloc]initWithString:@"11111"];
NSMutableString *test2 = [test1 copy];
[test2 appendString:@"22222"];
```
```
*** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: '-[NSTaggedPointerString appendString:]: unrecognized selector sent to
```

**浅拷贝与深拷贝**

对于浅拷贝（Swallow Copy）与深拷贝（Deep Copy），经常看到这样的说法：浅复制是指针拷贝，仅仅拷贝指向对象的指针；深复制是内容拷贝，会拷贝对象本身。 这句话并没有说错，但需要注意的是 **指针/内容拷贝针对的是谁** ，无论浅拷贝还是深拷贝，被拷贝的对象都会被复制一份，有新的对象产生，而在复制对象的内容时，对于被拷贝对象中的指针类型的成员变量，浅拷贝只是复制指针，而深拷贝除了复制指针外，会复制指针指向的内容。下面我们以 Apple 官方文档中的图片进行说明：

![](./imgs/1525411945289069.png)

对普通对象 ObjectA 进行 copy，无论浅拷贝还是深拷贝，都会复制出一个新的对象 ObjectB，只是浅拷贝时 ObjectA 与 ObjectB 中的 textColor 指针还指向同一个 NSColor 对象，而深拷贝时 ObjectA 和 ObjectB 中的 textColor 指针分别指向各自的 NSColor 对象（NSColor 对象被复制了一份）。

![](./imgs/1525412065130329.png)

对集合对象 Array1 进行 copy，无论浅拷贝还是深拷贝，都会复制出一个新的对象 Array2，只是浅拷贝时 Array1 与 Array2 中各个元素的指针还指向同一个对象，而深拷贝时 Array1 和 Array2 中各个元素的指针分别指向各自的对象（对象被复制了一份）。

**Copy 与 MutableCopy**

在说明 copy 与 mutableCopy 之前，我们思考一下：拷贝的目的是什么？在动态库加载时，只读的 TEXT 段是被所有使用动态库的程序共享的， 而可写的 DATA 段会使用 COW（Copy On Write）技术，当某个程序需要修改 DATA 段时会拷贝一份，供此程序专用。因此，拷贝的目的主要用于拷贝一份新的数据进行修改，而不会影响到原有的数据。如果不修改，拷贝就没有必要。

在 iOS 中，有一些系统类根据是否可变进行了区分，例如 NSString 与 NSMutableString，NSArray 与 NSMutableArray 等。为了在两者之间进行转换（我理解这是主要目的），NSObject 提供了 copy 与 mutableCopy 方法， copy 复制后对象是不可变对象，mutableCopy 复制后对象是可变对象。对象有不可变对象和可变对象，复制方法有 copy 和 mutableCopy，因此存在四种情况：

* 不可变对象 copy：对象是不可变的，再复制出一份不可变对象没有意义，因此根本没有发生任何拷贝，对象只有一份。

* 不可变对象 mutableCopy：可变对象的能够修改，原来的不可变对象不支持，因此需要复制出一个新对象，是深拷贝。

* 可变对象 copy：不可变对象不能修改，原来的可变对象不支持，因此需要复制出新对象，是深拷贝。

* 可变对象 mutableCopy：可变对象的修改不应该影响到原来的可变对象，因此需要复制出新对象，是深拷贝。

**如何进行深拷贝呢？**

## 2、系统非容器类

系统提供的非容器类中，如NSString,NSMutableString，有如下特性：

* 向不可变对象发送copy，是浅拷贝；向不可变对象发送mutalbeCopy消息，是深拷贝；

```
NSString *s1 = @"123";
NSString *s2 = [s1 copy];
NSMutableString *ms3 = [s1 mutableCopy];

NSLog(@"s1指针的地址：%p，s1所指对象的地址：%p",&s1, s1);
NSLog(@"s2指针的地址：%p，s2所指对象的地址：%p",&s2, s2);
NSLog(@"ms3指针的地址：%p，ms3所指对象的地址：%p",&ms3, ms3);

s1指针的地址：0x7ffeefbff4e8，s1所指对象的地址：0x100002098
s2指针的地址：0x7ffeefbff4e0，s2所指对象的地址：0x100002098
ms3指针的地址：0x7ffeefbff4d8，ms3所指对象的地址：0x102858240
```

* 向可变对象发送copy和mutableCopy消息，均是深拷贝

```
NSMutableString *ms4 = [NSMutableString stringWithString:@"123"];
NSString *s5 = [ms4 copy];
NSMutableString *ms6 = [ms4 mutableCopy];

NSLog(@"ms4指针的地址：%p，ms4所指对象的地址：%p",&ms4, ms4);
NSLog(@"s5指针的地址：%p，s5所指对象的地址：%p",&s5, s5);
NSLog(@"ms6指针的地址：%p，ms6所指对象的地址：%p",&ms6, ms6);

ms4指针的地址：0x7ffeefbff4d0，ms4所指对象的地址：0x100615d60
s5指针的地址：0x7ffeefbff4c8，s5所指对象的地址：0x88ce4b7032c9108f
ms6指针的地址：0x7ffeefbff4c0，ms6所指对象的地址：0x100616090
```

## 3、系统容器类

系统提供的容器类中，如NSArray,NSDictionary，有如下特性：

* 不可变对象copy，是浅拷贝；发送mutableCopy，是深拷贝。

```
NSArray *array = [NSArray arrayWithObjects:@"1", nil];
NSArray *copyArray = [array copy];
NSMutableArray *mutableCopyArray = [array mutableCopy];
NSLog(@"array is %p, copyArray is %p, mutableCopyArray is %p", array, copyArray, mutableCopyArray);
array is 0x60800001e580, copyArray is 0x60800001e580, mutableCopyArray is 0x608000046ea0
```

* 可变对象copy和mutableCopy均是单层深拷贝，也就是说单层的内容拷贝；

```
NSMutableArray *element = [NSMutableArray arrayWithObject:@1];
NSMutableArray *array = [NSMutableArray arrayWithObject:element];
NSArray *copyArray = [array copy];
NSMutableArray *mutableCopyArray = [array mutableCopy];
NSLog(@"array is %p, copyArray is %p, mutableCopyArray is %p", array, copyArray, mutableCopyArray);
[mutableCopyArray[0] addObject:@2];
NSLog(@"element is %@, array is %@, copyArray is %@, mutableCopyArray is %@", element,array,copyArray, mutableCopyArray);
 
2017-02-22 11:53:25.286 test[91520:3915695] array is 0x600000057670, copyArray is 0x600000000bc0, mutableCopyArray is 0x6080000582a0
2017-02-22 11:53:25.287 test[91520:3915695] element is (
1,
2
), array is (
 (
 1,
 2
)
), copyArray is (
 (
 1,
 2
)
), mutableCopyArray is (
 (
 1,
 2
)
)
```

## 4、自定义的类

**重要说明：**

1. 所以的代码设计均是针对业务需求。

2. 对于自定义的类，决定能否向对象发送copy和mutableCopy消息也是如此；

### 1、@property 声明中用 copy 修饰

不得不说下copy和strong在复制时候的区别，此处不讲引用计数的问题。

copy：拷贝一份不可变副本赋值给属性；所以当原对象值变化时，属性值不会变化；

strong：有可能指向一个可变对象,如果这个可变对象在外部被修改了,那么会影响该属性；

```
@interface Person : NSObject 
@property (nonatomic, copy) NSString *familyname;
@property (nonatomic, strong) NSString *nickname;
@end
Person *p1 = [[Person alloc]init];
 
NSMutableString *familyname = [[NSMutableString alloc]initWithString:@"张三"];
p1.familyname = familyname;
[familyname appendString:@"峰"];
 
NSLog(@"p1.familyname is %@",p1.familyname);
 
NSMutableString *nickname = [[NSMutableString alloc]initWithString:@"二狗"];
p1.nickname = nickname;
[nickname appendString:@"蛋儿"];
 
NSLog(@"p1.nickname is %@", p1.nickname);
2017-02-22 13:53:58.979 test[98299:3978965] p1.familyname is 张三
2017-02-22 13:53:58.979 test[98299:3978965] p1.nickname is 二狗蛋儿
```

### 2、类的对象的copy

此处唯一需要说明的一点就是注意类的继承。

1. 类直接继承自NSObject，无需调用[super copyWithZone:zone]
2. 父类实现了copy协议，子类也实现了copy协议，子类需要调用[super copyWithZone:zone]
3. 父类没有实现copy协议，子类实现了copy协议，子类无需调用[super copyWithZone:zone]
4. copyWithZone方法中要调用[[[self class] allocWithZone:zone] init]来分配内存

### 3、NSCopying

NSCopying是对象拷贝的协议。

类的对象如果支持拷贝，该类应遵守并实现NSCopying协议。

```
NSCopying协议中的方法只有一个，如下：
- (id)copyWithZone:(NSZone *)zone { 
 Person *model = [[[self class] allocWithZone:zone] init];
 model.firstName = self.firstName;
 model.lastName = self.lastName;
 //未公开的成员
 model->_nickName = _nickName;
 return model;
}
```

### 4、NSMutableCopying

当自定义的类有一个属性是可变对象时，对此属性复制时要执行mutableCopyWithZone操作。

```
- (id)copyWithZone:(NSZone *)zone {
 AFHTTPRequestSerializer *serializer = [[[self class] allocWithZone:zone] init];
 serializer.mutableHTTPRequestHeaders = [self.mutableHTTPRequestHeaders mutableCopyWithZone:zone];
 serializer.queryStringSerializationStyle = self.queryStringSerializationStyle;
 serializer.queryStringSerialization = self.queryStringSerialization;
 
 return serializer;
}
```

[浅谈iOS中几个常用协议 NSCopying/NSMutableCopying](https://www.yisu.com/zixun/198444.html)