//
//  main.m
//  Interview01-atomic
//
//  Created by MJ Lee on 2018/6/19.
//  Copyright © 2018年 MJ Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MJPerson.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        MJPerson *p = [[MJPerson alloc] init];
        
        
        for (int i = 0; i < 10; i++) {
            dispatch_async(NULL, ^{
                // 加锁
                p.data = [NSMutableArray array];
                // 解锁
            });
        }
        
        
        NSMutableArray *array = p.data;
        // 加锁
        [array addObject:@"1"];
        [array addObject:@"2"];
        [array addObject:@"3"];
        // 解锁
    }
    return 0;
}
