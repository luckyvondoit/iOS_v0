- [1.Socket建立网络连接的步骤](#1socket建立网络连接的步骤)
- [2.项目中你是怎么处理网络速度慢、中断抖动等网络请求中的问题?](#2项目中你是怎么处理网络速度慢中断抖动等网络请求中的问题)

## 1.Socket建立网络连接的步骤

<details>
<summary> 参考内容 </summary>


> 建立Socket连接至少需要一对套接字，其中一个运行于客户端，称为ClientSocket ，另一个运行于服务器端，称为ServerSocket 。套接字之间的连接过程分为三个步骤：服务器监听，客户端请求，连接确认。(知名的框架 AsyncSocket)

- 服务器监听：服务器端套接字并不定位具体的客户端套接字，而是处于等待连接的状态，实时监控网络状态，等待客户端的连接请求

- 客户端请求：指客户端的套接字提出连接请求，要连接的目标是服务器端的套接字。为此，客户端的套接字必须首先描述它要连接的服务器的套接字，指出服务器端套接字的地址和端口号，然后就向服务器端套接字提出连接请求

- 连接确认：当服务器端套接字监听到或者说接收到客户端套接字的连接请求时，就响应客户端套接字的请求，建立一个新的线程，把服务器端套接字的描述发给客户端，一旦客户端确认了此描述，双方就正式建立连接。而服务器端套接字继续处于监听状态，继续接收其他客户端套接字的连接请求

- AsyncSocket 相关代码

```

// socket连接
-(void)socketConnectHost{}
    self.socket    = [[AsyncSocket alloc] initWithDelegate:self];
    NSError *error = nil;
    [self.socket connectToHost:self.socketHost onPort:self.socketPort withTimeout:-1 error:&error];
}

心跳通过计时器来实现 // NStimer
-(void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString     *)host port:(UInt16)port
{

    LFLog(@"socket连接成功");
    // 每隔1s像服务器发送心跳包
    self.connectTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(longConnectToSocket) userInfo:nil repeats:YES];
    // 在longConnectToSocket方法中进行长连接需要向服务器发送的讯息
    [self.connectTimer fire];
}

// socket发送数据是以栈的形式存放，所有数据放在一个栈中，存取时会出现粘包的现象，所以很多时候服务器在收发数据时是以先发送内容字节长度，再发送内容的形式，得到数据时也是先得到一个长度，再根据这个长度在栈中读取这个长度的字节流，如果是这种情况，发送数据时只需在发送内容前发送一个长度，发送方法与发送内容一样
NSData   *dataStream  = [@8 dataUsingEncoding:NSUTF8StringEncoding];

[self.socket writeData:dataStream withTimeout:1 tag:1];
// 接收数据

-(void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    // 对得到的data值进行解析与转换即可
    [self.socket readDataWithTimeout:30 tag:0];

}

```

</details>


## 2.项目中你是怎么处理网络速度慢、中断抖动等网络请求中的问题?

<details>

<summary> 参考 </summary>

- 01.用Reachability判断网络状态，网络状态不好时直接返回失败

- 02.设置等待时间，然后重试；

首先可以使用Reachability判断网络连通性，如果网络不通直接返回错误；

保存未完成请求的对象，如果在网络请求过程中网络中断，可以让用户重试；

有条件的话，在2的基础上构建一个请求队列，对于不是必须马上发送的内容（发微博之类）可以存起来，然后等网络连通后执行

</details>