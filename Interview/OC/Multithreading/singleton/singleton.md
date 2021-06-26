# iOS 最稳的单例写法
```
@interface ShareObject : NSObject<NSCopying, NSMutableCopying> 

@end
```

```
@implementation ShareObject
+ (instancetype) shareInstance {
    static ShareObject *share = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        share = [[super allocWithZone:NULL] init];
    });
    return share;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [self shareInstance];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    return self;
}

@end
```

[iOS 最稳的单例写法](https://juejin.cn/post/6844903752441266184)