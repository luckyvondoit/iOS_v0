### 了解Objective-C起源

该语言使用“消息结构”（message structure）而非“函数调用”（founction calling）
```
//message structure
Object *obj = [Object new];
[obj performWith:p1 and:p2];

//founction calling
Object *obj = [Object new];
obj->perform(p1, p2);
```

关键区别在于：
