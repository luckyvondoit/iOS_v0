# 4、KVC

## 4.1 概述

>KVC的全称是Key-Value Coding，俗称“键值编码”，可以通过一个key来访问某个属性

常见的API有

```
- (void)setValue:(id)value forKeyPath:(NSString *)keyPath;
- (void)setValue:(id)value forKey:(NSString *)key;
- (id)valueForKeyPath:(NSString *)keyPath;
- (id)valueForKey:(NSString *)key;
```
## 4.2 setValue:forKey:的原理

![](./imgs/4/4.2_1.png)

* accessInstanceVariablesDirectly方法的默认返回值是YES


## 4.3 valueForKey:的原理

![](./imgs/4/4.3_1.png)

## 面试题

### 通过KVC修改属性会触发KVO么？

```
通过KVO监听某个属性，如果修改属性，会触发KVO，如果用 -> 直接修改成员变量，不会触发KVO。
如果通过KVC修改类的变量，不管是属性还是成员变量，只要通过KVO监听这个变量都会触发KVO。（即都会收到属性变化的通知）
kVO监听某个属性，系统通过runtime生成`NSKVONotififying_XXX`子类重写set方法。发通知（见上面kvo原理）
kvc在setValue:forKey/setValue:forKeyPath中调用willChangeValueForKey、didChangeValueForKey（必须成对出现，要不然不会发通知），在didChangeValueForKey中会发通知变量改变
```

### KVC的赋值和取值过程是怎样的？原理是什么？
