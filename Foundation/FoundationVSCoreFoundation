Foundation对象是Objective-c对象，而Core Foundation对象是C对象。二者可以通过`__bridge`、`__bridge_transfer`、`__bridge_retained`等关键字转换。

二者更重要的区别是内存管理问题。在非ARC下两者都需要手动管理内存。但在ARC下，系统只会自动管理Foundation对象的释放，而不支持Core Foundation的管理。

下面以NSString（Foundation）和CFStringRef（Core Foundation）为例，介绍两者的转换和内存管理权移交问题。

1）在非ARC下，NSString和CFStringRef对象可以直接进行强制转换，都是手动管理内存，无需关心内存管理权的移交问题。

2）在ARC下，NSString和CFStringRef对象在相互转换时，需要选择使用`__bridge`、`__bridge_transfer`、`__bridge_retained`来确定对象的管理权转移问题，
三者的作用语义分别如下：

1. `__bridge`关键字最常用，它的含义是不改变对象的管理权所有者，本来由ARC管理的Foundation对象，转换成Core Foundation对象后依然由ARC管理；本来由开发者
手动管理的Core Foundation对象转成Foundation对象后继续由开发者手动管理。


