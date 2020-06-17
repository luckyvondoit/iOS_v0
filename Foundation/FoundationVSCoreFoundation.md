Foundation对象是Objective-c对象，而Core Foundation对象是C对象。二者可以通过`__bridge`、`__bridge_transfer`、`__bridge_retained`等关键字转换。

二者更重要的区别是内存管理问题。在非ARC下两者都需要手动管理内存。但在ARC下，系统只会自动管理Foundation对象的释放，而不支持Core Foundation的管理。

下面以NSString（Foundation）和CFStringRef（Core Foundation）为例，介绍两者的转换和内存管理权移交问题。

1）在非ARC下，NSString和CFStringRef对象可以直接进行强制转换，都是手动管理内存，无需关心内存管理权的移交问题。

2）在ARC下，NSString和CFStringRef对象在相互转换时，需要选择使用`__bridge`、`__bridge_transfer`、`__bridge_retained`来确定对象的管理权转移问题，
三者的作用语义分别如下：

1. `__bridge`关键字最常用，它的含义是不改变对象的管理权所有者，本来由ARC管理的Foundation对象，转换成Core Foundation对象后依然由ARC管理；本来由开发者
手动管理的Core Foundation对象转成Foundation对象后继续由开发者手动管理。

```
//ARC管理的Foundation对象
 NSString *s1 = @"string";
 //转换后依然由ARC管理释放
 CFStringRef cfstring = (__bridge CFStringRef)s1;
 //开发者手动管理的Core Foundation对象
 CFStringRef s2 = CFStringCreateWithCString(NULL, "string", kCFStringEncodingASCII);
 //转换后依然需要开发者手动管理释放
 NSString *fstring = (__bridge NSString *)s2;
```

2. `__bridge_transfer`用在将Core Foundation对象转换成Foundation对象时，用于进行内存管理权的移交，即本来需由开发者手动管理释放的Core Foundation对象在转换成Foundation对象后，交由ARC来管理对象的释放，开发者不用再关心对象的释放问题。

```
//开发者手动管理的Core Foundation对象
CFStringRef s2 = CFStringCreateWithCString(NULL, "string", kCFStringEncodingASCII);
//转换后改由ARC管理对象的释放，不用担心内存泄漏
NSString *fstring = (__bridge_transfer NSString *)s2;
//NSString *fstring = (NSString *)CFBridgingRelease(s2);//另一种等效写法
```

3. `__bridge_retained`用在将Foundation对象转换成Core Foundation对象时，进行ARC内存管理权的剥夺，即本来由ARC管理的Foundation对象在转换成Core Foundation对象后，ARC不在继续管理对象，需要开发者自己进行手动释放该对象，否则会发生内存泄漏。

```
//ARC管理的Foundation对象
NSString *s1 = @"string";
//转换后ARC不再继续管理，需要手动释放
CFStringRef cfstring = (__bridge_retained CFStringRef)s1;
//CFStringRef cfstring = (CFStringRef)CFBridgingRetain(s1);//另一种等效写法
```

