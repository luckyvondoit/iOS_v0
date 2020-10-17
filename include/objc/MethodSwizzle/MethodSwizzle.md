# iOS 方法替换注意点

## 1.原理

> objc的方法本质是一个结构体，由SEL、IMP和method_types组成，方法的调用也是通过SEL到class的方法调度表中去找IMP然后执行IMP的实现；objc提供了运行时修改method的IMP的功能，使得我们可以通过修改函数的IMP来达到修改method的功能  

```
struct objc_method {
    SEL method_name                                          OBJC2_UNAVAILABLE;
    char *method_types                                       OBJC2_UNAVAILABLE;
    IMP method_imp                                           OBJC2_UNAVAILABLE;
}                                                            OBJC2_UNAVAILABLE;
```

## 2.实例

### 1.不安全的方法替换

```
@interface TestUnsafeSwizzle : NSObject

- (void)testMethod;

@end

@interface SubTestUnsafeSwizzle : TestUnsafeSwizzle

@end

@implementation TestUnsafeSwizzle

- (void)testMethod {
    NSLog(@"%s", __FUNCTION__);
}

@end

@implementation SubTestUnsafeSwizzle

+ (void)load {
    Method original = class_getInstanceMethod([self class], @selector(testMethod));
    Method replacement = class_getInstanceMethod([self class], @selector(test_testMethod));
    method_exchangeImplementations(original, replacement);
}

- (void)test_testMethod {
    [self test_testMethod];
    NSLog(@"swizzle~test");
}

@end
```

下面代码会有什么问题？

```
- (void)testUnsafeSwizzle {
    @try {
        [[TestUnsafeSwizzle new] testMethod];
    } @catch (NSException *exception) {
        NSLog(@"exception = %@", exception);
    }
    [SubTestUnsafeSwizzle load];
    [[SubTestUnsafeSwizzle new] testMethod];
}
```

**[[TestUnsafeSwizzle new] testMethod]会抛出异常**

1. `class_getInstanceMethod([self class], @selector(testMethod))` 由于子类中没有实现testMethod方法，返回的是父类的方法
2. `method_exchangeImplementations` 将子类的 `test_testMethod` 的指向了父类的 `testMethod` 的IMP，父类的 `testMethod` 指向了子类的 `test_testMethod` 的IMP
3. 这时候调用父类的 `testMethod` 调用的是 `test_testMethod` ，然而父类是没有实现这个方法的，所以导致闪退

**[[SubTestUnsafeSwizzle new] testMethod]调用的还是原方法**

1. 手动调用了load， `method_exchangeImplementations` 执行了2次，相当于没有交换

**总结**

1. 为了保证方法替换执行一次，我们通常会加上dispatch_once，否则当执行偶数次替换的时候，方法替换失效
2. 在子类没有实现父类方法，子类中替换父类方法的时候；我们用父类调用方法的时候会闪退

### 2.安全的方法替换

```
+ (void)swizzleInstanceMethodWithClass:(Class)clazz originalSel:(SEL)original replacementSel:(SEL)replacement {
    Method originalMethod = class_getInstanceMethod(clazz, original);// Note that this function searches superclasses for implementations, whereas class_copyMethodList does not!!如果子类没有实现该方法则返回的是父类的方法
    Method replacementMethod = class_getInstanceMethod(clazz, replacement);
    if (class_addMethod(clazz, original, method_getImplementation(replacementMethod), method_getTypeEncoding(replacementMethod))) {
        class_replaceMethod(clazz, replacement, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, replacementMethod);
    }
}
```

**解析**

* `class_addMethod` 尝试向类添加需要替换的原方法originalMethod，添加的方法的实现是replacementMethod的实现；
* 如果添加成功，表示类没有实现originalMethod，这时候 `class_replaceMethod` 再将replacementMethod实现改为originalMethod的实现，就达到了替换的效果；
* 如果添加失败，就直接 `method_exchangeImplementations` 替换两个方法的实现即可。

#### 3.多个子类替换一个方法

多个子类替换一个方法，测试按照继承链顺序替换和不按照继承链的顺序替换，看结果如何

```
@interface TestSubClassSwizzle : NSObject

- (void)testSubClassSwizzle;
- (void)s_testSubClassSwizzle;

@end

@interface TestASubClassSwizzle : TestSubClassSwizzle

- (void)a_testSubClassSwizzle;

@end

@interface TestBSubClassSwizzle : TestASubClassSwizzle

- (void)b_testSubClassSwizzle;

@end

@implementation TestSubClassSwizzle

- (void)testSubClassSwizzle {
    NSLog(@"%s", __FUNCTION__);
}

- (void)s_testSubClassSwizzle {
    [self s_testSubClassSwizzle];
}

@end

@implementation TestASubClassSwizzle

- (void)a_testSubClassSwizzle {
    [self a_testSubClassSwizzle];
    NSLog(@"%s", __FUNCTION__);
}

@end

@implementation TestBSubClassSwizzle

- (void)b_testSubClassSwizzle {
    [self b_testSubClassSwizzle];
    NSLog(@"%s", __FUNCTION__);
}

@end
```

以下代码输出什么？

```
- (void)testSubClassSwizzleMethod {
#define kSwizzleByInherit 1
#if !kSwizzleByInherit
    /*
     struct {TestBSubClassSwizzle.testSubClassSwizzle, b_testSubClassSwizzle.imp}
     struct {TestBSubClassSwizzle.b_testSubClassSwizzle, TestSubClassSwizzle.testSubClassSwizzle.imp}
     */
    [MethodSwizzleUtil swizzleInstanceMethodWithClass:[TestBSubClassSwizzle class] originalSel:@selector(testSubClassSwizzle) replacementSel:@selector(b_testSubClassSwizzle)];
    /*
     struct {TestASubClassSwizzle.testSubClassSwizzle, a_testSubClassSwizzle.imp}
     struct {TestASubClassSwizzle.a_testSubClassSwizzle, TestSubClassSwizzle.testSubClassSwizzle.imp}
     */
    [MethodSwizzleUtil swizzleInstanceMethodWithClass:[TestASubClassSwizzle class] originalSel:@selector(testSubClassSwizzle) replacementSel:@selector(a_testSubClassSwizzle)];
    /*
     struct {TestSubClassSwizzle.testSubClassSwizzle, s_testSubClassSwizzle.imp}
     struct {TestSubClassSwizzle.s_testSubClassSwizzle, TestSubClassSwizzle.testSubClassSwizzle.imp}
     */
    [MethodSwizzleUtil swizzleInstanceMethodWithClass:[TestSubClassSwizzle class] originalSel:@selector(testSubClassSwizzle) replacementSel:@selector(s_testSubClassSwizzle)];
#else
    /*
     struct {TestSubClassSwizzle.testSubClassSwizzle, s_testSubClassSwizzle.imp}
     struct {TestSubClassSwizzle.s_testSubClassSwizzle, testSubClassSwizzle.imp}
     */
    [MethodSwizzleUtil swizzleInstanceMethodWithClass:[TestSubClassSwizzle class] originalSel:@selector(testSubClassSwizzle) replacementSel:@selector(s_testSubClassSwizzle)];
    /*
     struct {TestASubClassSwizzle.testSubClassSwizzle, a_testSubClassSwizzle.imp}
     struct {TestASubClassSwizzle.a_testSubClassSwizzle, TestSubClassSwizzle.testSubClassSwizzle.imp}
     */
    [MethodSwizzleUtil swizzleInstanceMethodWithClass:[TestASubClassSwizzle class] originalSel:@selector(testSubClassSwizzle) replacementSel:@selector(a_testSubClassSwizzle)];
    /*
     struct {TestBSubClassSwizzle.testSubClassSwizzle, b_testSubClassSwizzle.imp}
     struct {TestBSubClassSwizzle.b_testSubClassSwizzle, TestASubClassSwizzle.testSubClassSwizzle.imp}
     */
    [MethodSwizzleUtil swizzleInstanceMethodWithClass:[TestBSubClassSwizzle class] originalSel:@selector(testSubClassSwizzle) replacementSel:@selector(b_testSubClassSwizzle)];
#endif
    [[TestBSubClassSwizzle new] testSubClassSwizzle];
    /*
     总结
     按照继承链swizzle和不按照继承链swizzle，会产生不同的效果，所以我们会在load方法中做swizzle，利用了load的特性，父类load先于子类调用
     */
}
```

**输出结果**

> kSwizzleWithInherit == 1时 2019-02-20 17:22:14.367353+0800 RuntimeLearning[11749:2242513] -[TestSubClassSwizzle testSubClassSwizzle] 2019-02-20 17:22:14.367436+0800 RuntimeLearning[11749:2242513] -[TestASubClassSwizzle a_testSubClassSwizzle] 2019-02-20 17:22:14.367497+0800 RuntimeLearning[11749:2242513] -[TestBSubClassSwizzle b_testSubClassSwizzle] kSwizzleWithInherit == 0时 2019-02-20 17:24:25.400826+0800 RuntimeLearning[11990:2245916] -[TestSubClassSwizzle testSubClassSwizzle]  

> 2019-02-20 17:24:25.400920+0800 RuntimeLearning[11990:2245916] -[TestBSubClassSwizzle b_testSubClassSwizzle]  

**分析** 
当我们按照继承链来做方法替换时，输出的结果是我们预期的结果；当我们不按照继承链来替换时，输出的不符合预期，具体原因见上面的源码，用struct {SEL, IMP}来表示方法； `[[TestBSubClassSwizzle new] testSubClassSwizzle]` 的执行流程b_testSubClassSwizzle.imp --> TestSubClassSwizzle.testSubClassSwizzle.imp

**总结**
我们在做方法替换的时候，最好是能按照继承链的顺序来执行，那么 `initialize` 和 `load` 都能达到这个效果；为什么选择 `load` ？

1. 在子类没有实现 `initialize` 时候，父类的 `initialize` 会执行多次，假如在这里做替换就会出现偶数次替换，方法替换失效的问题；
2. 类别中实现了 `initialize` 会覆盖类中的方法，如果有多个类别都在 `initialize` 中做处理的话，那么只有一个会生效其他都会失效，具体哪个生效看compile source中哪个在最后。

以上这两个副作用，load都没有，所以还是选择在 `load` 中处理，虽然load会很微弱的影响启动时间。

#### 3.结论

* dispatch_once+load保证替换执行一次
* load保证在继承关系中替换时，按照继承链来替换
* 方法替换时检查类中是否实现了原方法，避免子类中没有实现，替换子类的方法时，将父类的方法替换了

[iOS 方法替换注意点](https://www.jianshu.com/p/7daa1a95d106?utm_campaign=maleskine&utm_content=note&utm_medium=seo_notes&utm_source=recommendation)