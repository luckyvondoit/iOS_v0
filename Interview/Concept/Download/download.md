# iOS 下载
* 1.文件下载Block方式 (不能获取到下载进度)
* 2.文件下载delegate方式 (能获取到下载进度,能断点续传)
	* 2.1 使用NSURLSessionDataTask下载方式(不可以后台下载)

	* 2.2 使用NSURLSessionDownloadTask下载方式(可以后台下载)

* 3.断点续传
* 4.后台下载

## 1.文件下载Block方式

```
///1.创建NSURLSession
self.seesion = [NSURLSession sharedSession]
///2.下载url 
NSString *urlString = @"https://product-downloads.atlassian.com/software/sourcetree/ga/Sourcetree_4.0.2_236.zip";
///3.创建NSURLRequest
NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
///4.根据NSURLSession创建下载
NSURLSessionDownloadTask *downloadTask = [self.seesion downloadTaskWithRequest:request completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
 }];
///5.开始下载
[downloadTask resume];

```

**优势**
该下载完成后会直接存储到沙盒中方式并且通过一个block回调里面参数 `location` 是下载完成文件存储的地址,使用起来非常的方便,适合小文件下载 
**劣势**
不适合大文件下载,无法拿到下载进度

## 2.文件下载delegate方式

### 2.1 使用NSURLSessionDataTask下载方式

```
 ///1.创建NSURLSession默认配置
NSURLSessionConfiguration* cfg = [NSURLSessionConfiguration defaultSessionConfiguration];

 ///2.创建NSURLSession,设置代理和队列
self.seesion = [NSURLSession sessionWithConfiguration:cfg delegate:self delegateQueue:[NSOperationQueue mainQueue]];

 ///3.创建请求
 NSString *urlString = @"https://product-downloads.atlassian.com/software/sourcetree/ga/Sourcetree_4.0.2_236.zip";
 NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
 
 ///4.创建下载任务
 NSURLSessionDataTask *dataTask = [self.seesion dataTaskWithRequest:request];
 
 ///5.获取文件管理类,用来操作我们存储的文件
 self.fileManager = [NSFileManager defaultManager];
 
 //设置下载文件路径
 NSString *caches = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,  NSUserDomainMask, YES) lastObject];
 NSString *file = [caches stringByAppendingPathComponent:@"sss"];
 
 ///6.通过NSOutputStream流向文件写出数据,path是我们写入文件存储的路径,append是否向尾部追加下载的数据
 self.stream = [[NSOutputStream alloc] initToFileAtPath:file append:YES];
 
 ///开始请求
 [self.dataTask resume];
 
 //NSURLSessionDelegate
////下载成功和失败都会来
 - (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error{
    NSLog(@"%@",error);
    //成功或失败都要关闭流
    [self.stream close];
}

//NSURLSessionDataDelegate
///获取服务器返回的响应信息
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler{
    NSLog(@"%@",response);
    //获取到服务器信息后,打开流.
    [self.stream open];
    //block回调允许接收下载数据
    completionHandler(NSURLSessionResponseAllow);
}
//下载数据的回调
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
    NSLog(@"%@",data);
    //获取到数据流
    [self.stream write:[data bytes] maxLength:data.length];
}

```

这里我们实现了文件下载功能

**流程**
* 先获取NSURLSession
* 通过NSURLSession对象获取下载对象NSURLSessionDataTask
* 通过下载对象resume方法开始下载,会走响应的代理方法
* 首先会走获取服务器返回的响应信息的代理方法,在这个代理方法里面会拿到下载文件的相关信息,在这里我们就要打开写入数据的流,然后允许接收下载数据.
* 允许接收数据就会来到下载数据的回调的代理方法,在这个代理方法里面我们获取到每一次下载数据,然后通过流写入.
* 最后走下载完成的代理方法.

**NSOutputStream**

1.创建一个NSOutputStream实例 参数一制定目标文件路径。 第二个参数shouldAppend如果传递的为YES，意味着每次往文件以流的方式写入都是拼接在内容结尾。

```
- (nullable instancetype)initToFileAtPath:(NSString *)path append:(BOOL)shouldAppend;
```

2.开启NSOutputStream 在写文件前需要先打开流。

```
- (void)open;
```

3.写入数据 第一个参数传入一个二进制的字节数组，比如NSData的bytes。第二个写入数据的字节长度。

```
- (NSInteger)write:(const uint8_t *)buffer maxLength:(NSUInteger)len;
```

4.关闭流

```
- (void)close;
```

### 2.2 使用NSURLSessionDownloadTask下载方式

```
 ///1.创建NSURLSession默认配置
NSURLSessionConfiguration* cfg = [NSURLSessionConfiguration defaultSessionConfiguration];

 ///2.创建NSURLSession,设置代理和队列
self.seesion = [NSURLSession sessionWithConfiguration:cfg delegate:self delegateQueue:[NSOperationQueue mainQueue]];

 ///3.创建请求
 NSString *urlString = @"https://product-downloads.atlassian.com/software/sourcetree/ga/Sourcetree_4.0.2_236.zip";
 NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
 
 ///4.创建下载任务
 NSURLSessionDataTask *dataTask = [self.seesion dataTaskWithRequest:request];
 
 ///5.开始请求
 [self.dataTask resume];
 
 ///NSURLSessionDownloadDelegate
 /**
 *  下载完毕会调用
 *
 *  @param location     文件临时地址
 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
///下载完毕存储路径地址
    NSLog(@"%@",location);
///需要把文件的临时地址移动到Caches文件夹里面
}

/**
 *  每次写入沙盒完毕调用
 *  在这里面监听下载进度，totalBytesWritten/totalBytesExpectedToWrite
 *
 *  @param bytesWritten              这次写入的大小
 *  @param totalBytesWritten         已经写入沙盒的大小
 *  @param totalBytesExpectedToWrite 文件总大小
 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    //获取下载进度
    float progress = (double)totalBytesWritten/totalBytesExpectedToWrite;
}
```

**流程**
* 先获取NSURLSession
* 通过NSURLSession对象获取下载对象NSURLSessionDownloadTask
* 通过下载对象resume方法开始下载,会走响应的代理方法
* 系统会边下载边写入沙盒,然后回调代理方法,这个代理方法可以拿到,下载的进度.
* 下载完成会回调代理方法,返回一个路径,这个路径是临时路径,可以随时会删除掉,所以我们要把路径里面文件移走.

## 断点续传

**原理** 
每次向服务器下载数据的时候,告诉服务器从整个文件数据流的某个还未下载的位置开始下载,然后服务器就返回从那个位置开始的数据流.

**实现**

通过设置请求头Range可以指定每次从服务器下载数据包的大小.

**Range示例** 
bytes = 0-499 从0到499的头500个字节 
bytes = 500-999 从500到999第二个500个字节 
bytes = 1000- 从1000字节以后所有的字节 
bytes = -500 最后500个字节 
bytes = 0-499,500-999 同时指定几个范围

* -用于分割 ,前面数字表示起始字节,后面数字表示截止字节,没有表示从头到末尾

* ,用于分组,一次可以指定多个范围,基本不用.

### NSURLSessionDataTask 方式断点续传

**代码**
```objc

  ///1.创建NSURLSession默认配置
NSURLSessionConfiguration* cfg = [NSURLSessionConfiguration defaultSessionConfiguration];

 ///2.创建NSURLSession,设置代理和队列
self.seesion = [NSURLSession sessionWithConfiguration:cfg delegate:self delegateQueue:[NSOperationQueue mainQueue]];

 ///3.创建请求
 NSString *urlString = @"https://product-downloads.atlassian.com/software/sourcetree/ga/Sourcetree_4.0.2_236.zip";
 NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
 
 ///设置请求头 ,获取保存的下载的进度
  NSString *range = [NSString stringWithFormat:@"bytes=%lld-", self.currentLength];
 [request setValue:range forHTTPHeaderField:@"Range"];
 
 ///4.创建下载任务
 NSURLSessionDataTask *dataTask = [self.seesion dataTaskWithRequest:request];
 
 ///5.获取文件管理类,用来操作我们存储的文件
 self.fileManager = [NSFileManager defaultManager];
 
 //设置下载文件路径
 NSString *caches = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,  NSUserDomainMask, YES) lastObject];
 NSString *file = [caches stringByAppendingPathComponent:@"sss"];
 
 ///6.通过NSOutputStream流向文件写出数据,path是我们写入文件存储的路径,append是否向尾部追加下载的数据
 self.stream = [[NSOutputStream alloc] initToFileAtPath:file append:YES];
 
 ///开始请求
 [self.dataTask resume];
 
 //NSURLSessionDelegate
////下载成功和失败都会来
 - (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error{
    NSLog(@"%@",error);
    //成功或失败都要关闭流
    [self.stream close];
    self.stream = nil;
}

#pragma mark -- NSURLSessionDataDelegate
///获取服务器返回的响应信息
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler{
    NSLog(@"%@",response);
    //转换下类型为了取allHeaderFields
    NSHTTPURLResponse *response1 = (NSHTTPURLResponse*)response;
    //获取已下载文件大小
    NSDictionary *attributeDict = [_fileManager attributesOfItemAtPath:self.file error:nil];
    NSInteger resumeDataLength = [attributeDict[NSFileSize] integerValue];
    self.currentLength = resumeDataLength;
    //获取文件的总大小 = 服务端返回的大小 + 已经下载的大小
    self.totalLength = [response1.allHeaderFields[@"Content-Length"] integerValue] + resumeDataLength;
    //获取到服务器信息后,打开流.
    [self.stream open];
    //block回调允许接收下载数据
    completionHandler(NSURLSessionResponseAllow);
}
//下载数据的回调
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
    //获取已经下载文件大小
     NSDictionary *attributeDict = [_fileManager attributesOfItemAtPath:self.file error:nil];
     NSInteger resumeDataLength = [attributeDict[NSFileSize] integerValue];
     self.currentLength = resumeDataLength;
    //进度
     float progress = (double)resumeDataLength/self.totalLength;
     //写入数据
     [self.stream write:[data bytes] maxLength:data.length];
}
```

**重点** 
代码重点其实就是在暂停,失败时候保存好已经下载好的长度,下次请求的时候把保存好的下载长度放进请求头Range中.里面都是用的成员变量来保存,实际项目在(暂停,取消)应该把当前下载进度保存到本地,每次从本地取数据.

### NSURLSessionDownloadTask方式断点续传

`- (NSURLSessionDownloadTask *)downloadTaskWithResumeData:(NSData *)resumeData;` 主要使用这个方法来实现断点续传,这样就不需要设置请求头,这个方法系统为我们处理好了,这个方法会返回一个新的NSURLSessionDownloadTask对象,需要重新resume.
`- (void)cancelByProducingResumeData:(void (^)(NSData *resumeData))completionHandler;` 取消下载,会有一个bolck带了一个resumeData里面记录下载的URL地址和已下载的总共的字节数两部分,我们需要保存好这个resumeData,用做断点续传.

**代码**

```
  ///1.创建NSURLSession默认配置
NSURLSessionConfiguration* cfg = [NSURLSessionConfiguration defaultSessionConfiguration];

 ///2.创建NSURLSession,设置代理和队列
self.seesion = [NSURLSession sessionWithConfiguration:cfg delegate:self delegateQueue:[NSOperationQueue mainQueue]];

 ///3.创建请求
 NSString *urlString = @"https://product-downloads.atlassian.com/software/sourcetree/ga/Sourcetree_4.0.2_236.zip";
 NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
 NSURLSessionDownloadTask *downloadTask = [self.seesion downloadTaskWithRequest:request];
[downloadTask resume];

#pragma mark -- clik
- (IBAction)取消:(id)sender {
    [self.downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
        self.resumeData = resumeData;
    }];
}

- (IBAction)继续:(id)sender {

   self.downloadTask = [self.seesion downloadTaskWithResumeData:self.resumeData];
    [self.downloadTask resume];

}

#pragma mark -- NSURLSessionDownloadDelegate
//该方法下载成功和失败都会回调，只是失败的是error是有值的，
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error{
    NSLog(@"%@",error);
    //进入后台失去连接,恢复下载
      if (error.code == -1001) {
        // 
        if ([error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData]) {
            NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
            NSURLSessionTask *task = [session downloadTaskWithResumeData:resumeData];
            [task resume];
        }
    }
}
/**
 *  下载完毕会调用
 *
 *  @param location     文件临时地址
 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
//把文件移动我们指定的路径下
 NSFileManager *manager = [NSFileManager defaultManager];
 [manager moveItemAtPath:location.path toPath:file error:nil];
    NSLog(@"%@",location);
}

/**
 *  每次写入沙盒完毕调用
 *  在这里面监听下载进度，totalBytesWritten/totalBytesExpectedToWrite
 *
 *  @param bytesWritten              这次写入的大小
 *  @param totalBytesWritten         已经写入沙盒的大小
 *  @param totalBytesExpectedToWrite 文件总大小
 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    NSLog(@"bytesWritten %lld \n totalBytesWritten %lld \n totalBytesExpectedToWrite %lld ",bytesWritten,totalBytesWritten , totalBytesExpectedToWrite);
    
    float progress = (double)totalBytesWritten/totalBytesExpectedToWrite;
}

/**
 *  恢复下载后调用，
 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes
{
    
}
```

## 断点下载几个问题：

* 如何暂停下载，暂停后，如何继续下载？

* 下载失败后，如何恢复下载？

* 应用被用户杀掉后，如何恢复之前的下载？

### 如何暂停下载，暂停后，如何继续下载？
暂停
`- (void)cancelByProducingResumeData:(void (^)(NSData * resumeData))completionHandler;`
`[self.downloadTask suspend];` 继续下载

`- (NSURLSessionDownloadTask *)downloadTaskWithResumeData:(NSData *)resumeData`

`[self.downloadTask resume];`

### 下载失败后，如何恢复下载？

一般下载失败后会回调在下面的方法中,只要error有值说明失败,根据错误的code来判断是否需要继续下载

`- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error`

```
//获取到resumeData恢复下载.
if ([error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData]) {
          NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
          NSURLSessionTask *task = [session downloadTaskWithResumeData:resumeData];
          [task resume];
}

```

### 应用被用户杀掉后，如何恢复之前的下载？
1.如果使用的是NSURLSessionDataTask方式下载,可以下面代理方法中写入数据的时候,可以建一个model,把下载长度,下载状态,都保存在本地,下次打开取出model,把下载长度传入请求头range里面,然后去下载
`- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data` 2.使用NSURLSessionDownloadTask下载方式 实现后台下载

创建NSURLSession使用 `backgroundSessionConfigurationWithIdentifier` 方法设置一个标识.

在应用被杀掉前，iOS系统保存应用下载sesson的信息，在重新启动应用，并且创建和之前相同identifier的session时（苹果通过identifier找到对应的session数据），iOS系统会对之前下载中的任务进行依次回调 `URLSession:task:didCompleteWithError:` 方法，之后可以使用上面提到的下载失败时的处理方法进行恢复下载

## 后台下载

	1. 创建NSURLSession时，需要创建后台模式NSURLSessionConfiguration。

```
//1.创建NSURLSession带标识的配置 NSURLSessionConfiguration* cfg = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"SessionIdentifier"];
//2.创建NSURLSession self.seesion = [NSURLSession sessionWithConfiguration:cfg delegate:self delegateQueue:[NSOperationQueue mainQueue]]; 复制代码
```

	1. 在AppDelegate中实现下面方法，并定义变量保存completionHandler代码块：

```
#pragma mark -- AppDelegate委托方法
//在应用处于后台，且后台任务下载完成时回调
-(void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler;
复制代码
```

* 3.在下载类中实现下面NSURLSessionDelegate协议方法，其实就是先执行完task的协议，保存数据、刷新界面之后再执行在AppDelegate中保存的代码块：

```
#pragma mark -- NSURLSession委托方法 // 在任务下载完成、下载失败或者是应用被杀掉后，重新启动应用并创建相关identifier的Session时调用
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error; /* 应用在后台，而且后台所有下载任务完成后， * 在所有其他NSURLSession和NSURLSessionDownloadTask委托方法执行完后回调， * 可以在该方法中做下载数据管理和UI刷新,执行在AppDelegate中保存的代码块 */
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session;
复制代码
```

[iOS文件下载,断点续传,后台下载.](https://juejin.cn/post/6916707043441115143#heading-8)