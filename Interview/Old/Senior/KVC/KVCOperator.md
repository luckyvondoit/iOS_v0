# KVC中集合运算符
在项目中，遇到求和、求平均数等时，我们经常会用for循环来做，比如下面：

```
NSArray *score = @[@(89),@(80),@(20),@(56),@(89),@(100),@(89),@(89)];
int sum = 0;
for (NSNumber *scoreTag in score){
     sum+= scoreTag.intValue;
}
NSLog(@"%d",sum);//sum=612
```

这样写当然也没有错，但是有点复杂，不太简洁。幸运的是，苹果提供了一种更为简洁的方法，那就是集合运算符。因此，对上面的代码可以用下面来表示：

```
sum=[score valueForKeyPath:@"@sum.self"];//sum=612
```

一行代码搞定，是不是很爽！！！

## 1. 集合运算符

KVC集合运算符允许在valueForKeyPath:方法中使用集合运算符执行方法。无论什么时候你在key path中看见了@，它都代表了一个特定的集合方法。集合运算符必须用在集合对象上或普通对象的集合属性上

##### 集合运算符会根据其返回值的不同分为以下三种类型：

* 简单的集合运算符 返回的是strings, number, 或者 dates
* 对象运算符返回的是一个数组
* 数组和集合运算符 返回的是一个数组或者集合

### 2. 简单集合操作符

* @count: 返回一个值为集合中对象总数的NSNumber对象。
* @sum: 首先把集合中的每个对象都转换为double类型，然后计算其- 总，最后返回一个值为这个总和的NSNumber对象。
* @avg: 把集合中的每个对象都转换为double类型，返回一个值为平均值的NSNumber对象。
* @max: 使用compare:方法来确定最大值。所以为了让其正常工作，集合中所有的对象都必须支持和另一个对象的比较。
* @min: 和@max一样，但是返回的是集合中的最小值。
* 实例：前言的例子中用简单集合操作符如下：

```objc
NSLog(@"%@",[score valueForKeyPath:@"@count.self"]);//8
NSLog(@"%@",[score valueForKeyPath:@"@sum.self"]);//612
NSLog(@"%@",[score valueForKeyPath:@"@max.self"]);//100
NSLog(@"%@",[score valueForKeyPath:@"@min.self"]);//20
NSLog(@"%@",[score valueForKeyPath:@"@avg.self"]);//76.5
```

### 3. 对象操作符

* @unionOfObjects/ @distinctUnionOfObjects: 返回一个由操作符右边的key path所指定的对象属性组成的数组。其中@distinctUnionOfObjects会对数组去重, 而@unionOfObjects不会。
* 实例：假如有一个person对象，有name，age，position等属性

```
Person *person1 = [[Person alloc] init];
person1.name = @"王五";
person1.age = 10;
person1.position = @"学生";

Person *person2 = [[Person alloc] init];
person2.name = @"赵六";
person2.age = 19;
person2.position = @"学生";

Person *person3 = [[Person alloc] init];
person3.name = @"张三";
person3.age = 30;
person3.position = @"公司高管";

Person *person4 = [[Person alloc] init];
person4.name = @"李四";
person4.age = 25;
person4.position = @"软件开发";

Person *person5 = [[Person alloc] init];
person5.name = @"七七";
person5.age = 19;
person5.position = @"学生";

NSArray *personArr = @[person1,person2,person3,person4,person5];

NSLog(@"%@",[personArr valueForKeyPath:@"@distinctUnionOfObjects.age"]);
 输出结果为：10, 30,  19, 25（去重）
NSLog(@"%@",[personArr valueForKeyPath:@"@unionOfObjects.age"]);
 输出结果为：10, 19, 30,25, 19（没有去重）
```

### 4. 数组和集合操作符

数组和集合操作符与对象操作符相似。只不过它是在NSArray和NSSet所组成的集合中工作的。

* @distinctUnionOfArrays / @unionOfArrays: 返回了一个数组，其中包含这个集合中每个数组对于这个操作符右面指定的key path进行操作之后的值。distinct版本会移除重复的值。
* @distinctUnionOfSets: 和@distinctUnionOfArrays差不多, 但是它期望的是一个包含着NSSet对象的NSSet，并且会返回一个NSSet对象。因为集合不能包含重复的值，所以它只有distinct操作。
* 实例：在上述person对象的基础上，在增加一个Studentd对象，有name，age等属性

```
Student *student1 = [[Student alloc] init];
student1.name = @"张三";
student1.age = 25;

Student *student2 = [[Student alloc] init];
student2.name = @"呵呵";
student2.age = 30;

Student *student3 = [[Student alloc] init];
student3.name = @"李四";
student3.age = 28;
NSArray *studentArr = @[student1,student2,student3];

NSLog(@"%@",[@[studentArr,personArr] valueForKeyPath:@"@distinctUnionOfArrays.age"]);
输出结果：10, 19,28,25,30//两个数组合并去重后
NSLog(@"%@",[@[studentArr,personArr] valueForKeyPath:@"@unionOfArrays.age"]);
输出结果：25,30, 28, 10,19, 30,25,19//两个数组合并

NSSet *studentSet = [NSSet setWithArray:studentArr];
NSSet *personSet = [NSSet setWithArray:personArr];
NSSet *allSet = [NSSet setWithObjects:studentSet,personSet, nil];
NSLog(@"%@",[allSet valueForKeyPath:@"@distinctUnionOfSets.age"]);
输出结果：10, 19,28,25,30//和distinctUnionOfArrays效果一样，只不过是NSSet
```

OK，一切搞定。有点遗憾的是，目前还不能自定义集合操作符，泪奔...。不过，总是能找到解决方案： [解决方案](https://link.jianshu.com?t=http%3A%2F%2Fkickingbear.com%2Fblog%2Farchives%2F9) 。

项目demo已上传到git [查看源代码](https://link.jianshu.com?t=https%3A%2F%2Fgithub.com%2FSXMmeng230%2FKVCCollentionOperators.git) 。

[KVC中集合运算符](https://www.jianshu.com/p/3560552d841e)