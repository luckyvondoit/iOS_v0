## NSPredicate的基本用法

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

### 6. 正则表达式

[正则表达式-菜鸟教程](https://www.runoob.com/regexp/regexp-tutorial.html)

```
- (BOOL)checkPhoneNumber:(NSString *)phoneNumber {
    NSString *regex = @"^[1][3-8]\\d{9}$";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [pred evaluateWithObject:phoneNumber];
}
```