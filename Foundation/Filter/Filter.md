## NSPredicate

### 1. 比较运算符

* =、==：判断两个表达式是否相等，在谓词中=和==是相同的意思，没有赋值一说。
* \>=、=>：判断左边的值是否大于或等于右边
* <=、=<：判断左边的值是否小于或等于右边
* \>：判断左边的值是否大于右边
* <：判断左边的值是否小于右边
* !=、<>：判断两个表达式是否不相等
* BETWEEN：BETWEEN表达式必须满足表达式 BETWEEN {下限，上限}的格式，要求该表达式必须大于或等于下限，并小于或等于上限。

```
NSNumber *number = @123;
NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self = 123"];
BOOL result = [predicate evaluateWithObject:number];
//result is YES
```

### 2. 逻辑运算符

* AND、&&：逻辑与
* OR、||：逻辑或
* NOT、!：逻辑非

```
NSArray *array = @[@1, @2, @3, @4, @5, @6, @7];
NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self > 2 && self < 5"];
NSArray *filterArray = [array filteredArrayUsingPredicate:predicate];
//filterArray is @[@3, @4];
```

### 3. 字符串比较运算符

* BEGINSWITH：是否以指定字符串开头；
* ENDSWITH：是否以指定字符串结尾；
* CONTAINS：是否包含指定字符串；
* LIKE：是否匹配指定字符串模版；
* MATCHES：是否匹配指定的正则表达式；

>1.以abc开头：beginswith 'abc';
>2.匹配模版："name like 'abc'":表示name的值中包含abc则返回YES；"name like '?abc*'":表示name的第2、3、4个字符为abc时返回YES；
>3.正则表达式的效率最低，但功能最强大。

字符串比较都是区分大小写和重音符号的。如：café和cafe是不一样的，Cafe和cafe也是不一样的。如果希望字符串比较运算不区分大小写和重音符号，请在这些运算符后使用[c]，[d]选项。其中[c]是不区分大小写，[d]是不区分重音符号，其写在字符串比较运算符之后。

比如：name LIKE[cd] 'cafe'，那么不论name是cafe、Cafe还是café上面的表达式都会返回YES。

### 4. 集合运算符

* ANY、SOME：集合中任意一个元素满足条件，就返回YES。
* ALL：集合中所有的元素都满足条件，才返回YES。
* NONE：集合中没有任何元素满足条件就返回YES。
* IN：等价于SQL语句中的IN运算符。

```
NSArray *array = @[@1, @2, @3, @4, @5, @6, @7];
NSArray *filterArray = @[@1, @4, @8];
NSPredicate *predicate = [NSPredicate predicateWithFormat:@"not (self in %@)", filterArray];
NSArray *resultArray = [array filteredArrayUsingPredicate:predicate];
//resultArray is @[@2, @3, @5, @6, @7];
```

### 5. 保留字

AND、OR、IN、NOT、ALL、ANY、SOME、NONE、LIKE、CASEINSENSITIVE、CI、MATCHES、CONTAINS、BEGINSWITH、ENDSWITH、BETWEEN、NULL、NIL、SELF、TRUE、YES、FALSE、NO、FIRST、LAST、SIZE、ANYKEY、SUBQUERY、CAST、TRUEPREDICATE、FALSEPREDICATE

**注：虽然大小写都可以，但是更推荐使用大写来表示这些保留字**

### 6. 谓词中的占位符参数

* %K：用于动态传入属性名
* %@：用于动态设置属性值
* $VALUE：个人感觉是在声明变量

```
NSArray *array = @[[Person Person:@"张三" Age:12],
                   [Person Person:@"张云" Age:24],
                   [Person Person:@"李四" Age:25]];

NSString *property = @"name";
NSString *value = @"张";
//1.筛选出名字中包含"张"的;
NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K contains %@", property, value];
NSArray *resultArray = [array filteredArrayUsingPredicate:predicate];
//resultArray is "[name = 张三, age = 12], [name = 张云, age = 24]"

//2.筛选出年龄大于24的;
NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"%K > $Value", @"age"];
//必须加上下面这句，不然会报错。$Value(Value可以随便改，统一就行)个人感觉是声明一个变量，下面是给变量赋值。
predicate2 = [predicate2 predicateWithSubstitutionVariables:@{@"Value":@24}];
NSArray *resultArray2 = [array filteredArrayUsingPredicate:predicate2];
//resultArray2 is "[name = 李四, age = 25]"
```

### 7. 正则表达式

[正则表达式-菜鸟教程](https://www.runoob.com/regexp/regexp-tutorial.html)

```
- (BOOL)checkPhoneNumber:(NSString *)phoneNumber {
    NSString *regex = @"^[1][3-8]\\d{9}$";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [pred evaluateWithObject:phoneNumber];
}
```

## NSSortDescriptor

### 简介

NSSortDescriptor 用于指定集合内数据的排序规则 <按照指定的 key 进行排序>。 iOS 的集合对象均可使用 NSSortDescriptor 进行排序。

相关 API：

1. NSSet、NSMutableSet、NSArray、NSOrderedSet

```
-(NSArray<ObjectType> *)sortedArrayUsingDescriptors:(NSArray<NSSortDescriptor *> *)sortDescriptors
```

2. NSMutableArray、NSMutableOrderedSet

```
-(void)sortUsingDescriptors:(NSArray<NSSortDescriptor *> *)sortDescriptors;
```

### 示例

#### 1.创建 Student 对象

```
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Student : NSObject

@property (assign, nonatomic) int stu_age;
@property (copy,   nonatomic) NSString *stu_name;
@end

NS_ASSUME_NONNULL_END
```

#### 2.创建待排序的数据

```
#import "ViewController.h"
#import "Student.h"

@interface ViewController ()

@property (strong, nonatomic) NSMutableArray *students;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.students = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < 10; i++) {
        
        int random_age  = arc4random()%3 + 10;
        int random_name = arc4random()%10;
        
        Student *student = [[Student alloc] init];
        student.stu_age  = random_age;
        student.stu_name = [NSString stringWithFormat:@"stu_%d", random_name];
        
        [self.students addObject:student];
    }
}
```

#### 3.单一规则排序

```
- (void)sortByStuAge {
    // 按照 stu_age 进行排序
    // key --> 指定排序规则，ascending --> YES：升序   NO：降序
    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"stu_age" ascending:YES];
    [self.students sortUsingDescriptors:@[sd]];
    
    // 排序结果
    /**
     stu_age -> 10   stu_name -> stu_0
     stu_age -> 10   stu_name -> stu_6
     stu_age -> 10   stu_name -> stu_1
     stu_age -> 10   stu_name -> stu_4
     stu_age -> 10   stu_name -> stu_9
     stu_age -> 11   stu_name -> stu_5
     stu_age -> 11   stu_name -> stu_5
     stu_age -> 11   stu_name -> stu_9
     stu_age -> 11   stu_name -> stu_8
     stu_age -> 11   stu_name -> stu_9
     */
}
```

#### 4.组合规则排序

API 排序规则参数是数组类型，所以我们可以一次性传入多个排序规则。这些规则按照在数组参数内的顺序依次生效

```
- (void)sortByCombination {
    // 先按照 stu_name 进行排序，当 stu_name 一致时，再按照 stu_age 进行排序
    NSSortDescriptor *sd_name = [[NSSortDescriptor alloc] initWithKey:@"stu_name" ascending:YES];
    NSSortDescriptor *sd_age  = [[NSSortDescriptor alloc] initWithKey:@"stu_age"  ascending:YES];
    [self.students sortUsingDescriptors:@[sd_name, sd_age]];
    
    // 排序结果
    /**
     stu_age -> 12   stu_name -> stu_0
     stu_age -> 12   stu_name -> stu_0
     stu_age -> 11   stu_name -> stu_3
     stu_age -> 10   stu_name -> stu_4
     stu_age -> 10   stu_name -> stu_4
     stu_age -> 11   stu_name -> stu_5
     stu_age -> 12   stu_name -> stu_5
     stu_age -> 10   stu_name -> stu_7
     stu_age -> 11   stu_name -> stu_7
     stu_age -> 12   stu_name -> stu_8
     */
}
```

## KVC

### 关键字

* @min：最小值
* @max ：最大值
* @avg ：平均值
* @sum：总和

### 基础运算

```
NSInteger min = [[self.sources valueForKeyPath:@"@min.monry"] integerValue];
NSInteger max = [[self.sources valueForKeyPath:@"@max.monry"] integerValue] ;
NSInteger sum =[[self.sources valueForKeyPath:@"@sum.monry"] integerValue];
double avg = [[self.sources valueForKeyPath:@"@avg.monry"] doubleValue] ;
```