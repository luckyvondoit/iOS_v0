//
//  MJProxy1.m
//  Interview03-定时器
//
//  Created by MJ Lee on 2018/6/19.
//  Copyright © 2018年 MJ Lee. All rights reserved.
//

#import "MJProxy1.h"

@implementation MJProxy1

+ (instancetype)proxyWithTarget:(id)target
{
    MJProxy1 *proxy = [[MJProxy1 alloc] init];
    proxy.target = target;
    return proxy;
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    return self.target;
}

@end
