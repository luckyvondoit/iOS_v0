# OC中的糖衣语法
糖衣语法，又叫’语法糖‘、’语法盐‘等等，是由英国计算机科学家彼得·约翰·兰达（Peter J.Landin）发明的一个术语，指计算机语言中添加的某种语法，这种语法对语言的功能并没有影响，但是更方便程序员使用。通常来说使用语法糖能够增加程序的可读性，从而减少程序代码出错的机会。

糖衣语法在各种语言中都有出现，最常用的就是数组的[ ]操作符的下标访问以及{ }操作符对数组的初始化，例如C语言中可以通过下标访问数组元素，这种类似[ ]和{ }操作符的符合程序员思维的简单表示方法就是所谓的糖衣语法：

```C
/* C中的数组操作 */
int a[3] = {1,2,3};
int b = a[2];
```

[ ]和{ }在JSON数据格式中最常见，[ ]一般封装一个数组，{ }一般封装一个整体对象。另外在OC中用到语法糖的一个非常重要的类型是NSNumber，一个将基本数据类型封装起来的对象类型，基本数据类型像‘@3’这种表达就是NSNumber的语法糖，也推荐这种用法。

糖衣语法在OC中又常叫做‘字面量’，主要用在NSString,NSNumber,NSArray,NSDictionary这些类中，使用字面量可以更清晰的看清数据的结构，而且大大减小了代码编写的复杂繁琐度，代码易读性更高。

OC中字面量的用法主要由以下几种情况，包括基本数据类型NSNumber、静态数组NSArray和字典NSDictionary、可变数组NSMultableArray和字典NSMultableDictionary。其中静态的数组和字典不能直接用[ ]操作符来通过下标访问元素或者通过键值访问元素，而可变长数组和字典可以；另外可变长数组和字典用字面量初始化时要进行multableCopy操作。

糖衣语法用法：

```objc
/** 糖衣语法【字典和数组元素中不可出现nil，会直接编译不通过】 **/
    
    /* 1.基本数据对象 */
    NSNumber *num_int = @1;
    NSNumber *num_float = @1.1f;
    NSNumber *num_bool = @YES;
    NSNumber *num_char = @'a';
    /* 类似还有：NSInteger, Double, Long, Short ... */
    
    /* 基本数据运算 */
    int operator_i = 3;
    float operator_f = 2.1f;
    NSNumber *expression = @(operator_i * operator_f);
    
    /* 2.静态数组、字典 */
    NSArray *array = @[@1, @2, @3];
    NSDictionary *dic = @{
                          @"KEY":@"VALUE",
                          @"KEY1":@"VALUE1"
                          };
    /* 访问但不可更新 */
    NSNumber *num = array[1];
    NSString *string = dic[@"KEY"];
    
    /* 3.可变数组、字典 */
    NSMutableArray *mulArray = [@[@"a", @"b", @"c"] mutableCopy];
    NSMutableDictionary *mulDic = [@{
                                     @"key": @"value",
                                     @"key1": @"value1"
                                     } mutableCopy];
    /* 可变数组元素的下标访问或键值访问以及元素更新 */
    NSString *mulstring = mulArray[1];
    mulArray[1] = @"d";
    NSString *dicstring = mulDic[@"key"];
    mulDic[@"key"] = @"value3";
```

原用法：

```objc
/** 对应的原语法【字典和数组元素中可以出现nil，nil会被过滤掉】 **/
    
    /* 1.基本数据对象 */
    NSNumber *num_int = [NSNumber numberWithInt:1];
    NSNumber *num_float = [NSNumber numberWithFloat:1.1f];
    NSNumber *num_bool = [NSNumber numberWithBool:YES];
    NSNumber *num_char = [NSNumber numberWithChar:'a'];
    // 类似还有：NSInteger, Double, Long, Short ...     
    /* 2.静态数组、字典 */
    NSArray *array = [[NSArray alloc]initWithObjects:@1, @2, @3, nil];
    NSDictionary *dic = [[NSDictionary alloc] initWithObjectsAndKeys:
                         @"VALUE", @"KEY",
                         @"VALUE1", @"KEY1", nil];
    /* 访问(静态数组元素不可更新) */
    NSNumber *num = [array objectAtIndex:1];
    NSString *string = [dic objectForKey:@"KEY"];
    
    /* 3.可变数组、字典 */
    NSMutableArray *mulArray = [[NSMutableArray alloc]initWithObjects:@"a", @"b", @"c", nil];
    NSMutableDictionary *mulDic = [[NSMutableDictionary alloc]initWithObjectsAndKeys:
                                   @"value", @"key",
                                   @"value1", @"key1", nil];
    
    /* 访问和更新 */
    NSNumber *mulnum = [mulArray objectAtIndex:1];
    [mulArray setObject:@"d" atIndexedSubscript:1];
    NSString *mulstring = [mulDic objectForKey:@"KEY"];
    [mulDic setObject:@"value2" forKey:@"key"];
```

问题： OC的数组或字典中，添加nil对象会有什么问题？
数组或字典如果通过addObject函数添加nil会崩溃，但初始化时通过initWithObjects方法里面的nil会被编译器过滤去掉不会有影响。另外如果使用糖衣语法初始化数组或字典也不可以有nil，此时nil不会被过滤掉也会崩溃。

```objc
/* 1.糖衣语法 */
NSArray *array = @[@1, @2, @3, nil]; // 错误，不可有nil，会编译不通过：void*不是Objective-C对象 NSDictionary *dic = @{
                      @"KEY":@"VALUE",
                      @"KEY1":@"VALUE1",
                      @"KEY2":nil
                       }; // 语法就是错误的，编译不通过                        
/* 2.原用法 */
NSMutableArray *mulArray = [[NSMutableArray alloc] initWithObjects:@1, @2, @3, nil]; // 正确，没毛病 NSMutableDictionary *mulDic = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                         @"VALUE", @"KEY",
                         @"VALUE1", @"KEY1", nil]; // 正确，没毛病 /* 下面添加nil都会编译警告，运行起来会崩溃 */
[mulArray addObject:nil];
[mulDic setObject:nil forKey:@"KEY2"];
```

问题： Objective-C中的可变和不可变类型是什么？

```
Objective-C中的mutable和immutable类型对应于动态空间分配和静态空间分配。最常见的例子是数组和字典。例如NSArray和NSMutableArray，前者为静态数组，初始化后长度固定，不可以再动态添加新元素改变数组长度；后者为动态数组，可以动态添加或者删除元素，动态申请新的空间或释放不需要的空间，伸缩数组长度。
```

问题： @[@"a",@"b"];该类型是？ 字符串对象 字典对象 数组对象 (right)

[OC中的糖衣语法](https://www.jianshu.com/p/0f0f63739807)