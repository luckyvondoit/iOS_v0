Person.h
```
#import <Foundation/Foundation.h>

@interface Person : NSObject
@property (nonatomic, copy) NSString *lastName;
@end
```
Person.m
```
#import "Person.h"

@implementation Person

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.lastName = @"";
    }
    return self;
}

- (void)setLastName:(NSString*)lastName
{
    NSLog(@"🔴类名与方法名：%s（在第%d行），描述：%@", __PRETTY_FUNCTION__, __LINE__, @"根本不会调用这个方法");
    _lastName = @"炎黄";
}

@end
```
ChenPerson.h
```
#import "Person.h"

@interface ChenPerson : Person
@end
```
ChenPerson.m
```
#import "ChenPerson.h"

@implementation ChenPerson

@synthesize lastName = _lastName;

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSLog(@"🔴类名与方法名：%s（在第%d行），描述：%@", __PRETTY_FUNCTION__, __LINE__, NSStringFromClass([self class]));
        NSLog(@"🔴类名与方法名：%s（在第%d行），描述：%@", __PRETTY_FUNCTION__, __LINE__, NSStringFromClass([super class]));
    }
    return self;
}

- (void)setLastName:(NSString*)lastName
{
    //设置方法一：如果setter采用是这种方式，就可能引起崩溃
//    if (![lastName isEqualToString:@"陈"])
//    {
//        [NSException raise:NSInvalidArgumentException format:@"姓不是陈"];
//    }
//    _lastName = lastName;
    
    //设置方法二：如果setter采用是这种方式，就可能引起崩溃
    _lastName = @"陈";
    NSLog(@"🔴类名与方法名：%s（在第%d行），描述：%@", __PRETTY_FUNCTION__, __LINE__, @"会调用这个方法,想一下为什么？");

}

@end
```
main.m
```
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        ChenPerson *chen = [[ChenPerson alloc] init];
        NSLog(@"%@",chen.lastName);//"陈"
    }
    return 0;
}
```
log
```
2020-04-15 23:55:05.450700+0800 self[98260:2785315] 🔴类名与方法名：-[ChenPerson setLastName:]（在第36行），描述：会调用这个方法,想一下为什么？
2020-04-15 23:55:05.450893+0800 self[98260:2785315] 🔴类名与方法名：-[ChenPerson init]（在第19行），描述：ChenPerson
2020-04-15 23:55:05.450995+0800 self[98260:2785315] 🔴类名与方法名：-[ChenPerson init]（在第20行），描述：ChenPerson
2020-04-15 23:55:05.451088+0800 self[98260:2785315] 陈
```
>*备注*       
>在子类ChenPerson的init方法中调用 [super init] 会来到父类Person的init中，因为调用对象是子类ChenPerson，所以父类Person的init中的self为ChenPerson对象，所以会调用ChenPerson的setLastName方法。
