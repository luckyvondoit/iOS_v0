//
//  ViewController.m
//  Interview04-线程同步
//
//  Created by MJ Lee on 2018/6/7.
//  Copyright © 2018年 MJ Lee. All rights reserved.
//

#import "ViewController.h"
#import "MJBaseDemo.h"
#import "OSSpinLockDemo.h"
#import "OSSpinLockDemo2.h"
#import "OSUnfairLockDemo.h"
#import "MutexDemo.h"
#import "MutexDemo2.h"
#import "MutexDemo3.h"
#import "NSLockDemo.h"
#import "NSConditionDemo.h"


@interface ViewController ()
@property (strong, nonatomic) MJBaseDemo *demo;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    MJBaseDemo *demo = [[NSConditionDemo alloc] init];
//    [demo ticketTest];
//    [demo moneyTest];
    [demo otherTest];
}

@end
