//
//  ViewController.m
//  Interview03-线程保活
//
//  Created by MJ Lee on 2018/6/3.
//  Copyright © 2018年 MJ Lee. All rights reserved.
//

#import "ViewController.h"
#import "MJPermenantThread.h"

@interface ViewController ()
@property (strong, nonatomic) MJPermenantThread *thread;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    self.thread = [[MJPermenantThread alloc] init];
    
    [self gcd_test];
    
}

- (void)gcd_test {
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    dispatch_async(queue, ^{
        NSLog(@"1");
        [self performSelector:@selector(test) withObject:nil afterDelay:.0];
        NSLog(@"3");
        [[NSRunLoop currentRunLoop] addPort:[[NSPort alloc] init] forMode:NSDefaultRunLoopMode];
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    });
    
}

- (void)test {
    NSLog(@"2");
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.thread executeTask:^{
        NSLog(@"执行任务 - %@", [NSThread currentThread]);
    }];
    
    // AFN 2.X 版本
    // 串行
    // 非并发
}

- (IBAction)stop {
    [self.thread stop];
}

- (void)dealloc
{
    NSLog(@"%s", __func__);
}

@end
