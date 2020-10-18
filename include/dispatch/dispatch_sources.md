# Dispatch Sources - Beche - 博客园
**一、简介**

Dispatch Sources常用于处理跟系统有关的事件，协调处理指定的低级别的系统事件。在配置Dispatch Source时，需指定监控的事件类型、Dispatch Queues、Event Handle(blocks/functions)。当被监控的事件发生时，Dispatch Source提交Event Handle到指定的Dispatch Queues。

不同于手动提交到queue中的任务，dispatch sources给应用提供了持续的事件资源。dispatch source除了明确取消，否则会持续与dispatch queue相关联。不管什么时候指定的事件发生时，就会提交任务到关联着的dispatch queue中。例如，定时器事件周期性的发生，还有大多数只有在指定条件下才发生的事件。为此，dispatch sources持有关联的dispatch queue，避免事件仍然会发生而dispatch queue被释放了。

为了避免event handle被积压在某个dispatch queue中，dispatch sources实现事件合并方案。如果前一个任务已出列并在处理时，新的事件到来了，dispatch source合并新事件和旧事件的数据。合并规则取决于事件的类型，合并可能代替旧事件，或者更新旧事件的数据。例如，基于信号的dispatch source会提供最近相关的信息，但也报告自从上次事件处理发生以来总共发出了多少信号量。

Dispatch Sources包括这几类：Timer dispatch sources、Signal dispatch sources、Descriptor sources、Process dispatch sources、Mach port dispatch sources和Custom dispatch sources。

1、Timer dispatch sources周期性通知。2、Signal dispatch sources为unix信号发出时通知。3、Descriptor sources各种各样的file-和socket-操作通知。如从文件或者网络中读/写数据，或文件名被重命名，或文件被删、被移动、数据内容改动时。4、Process dispatch sources父子process退出时等等操作通知。5、Mach port dispatch sources

6、Custom dispatch sources

**二、创建Dispatch Sources**

dispatch_source_create函数返回的是出于暂停状态的dispatch source，在暂停状态时，dispatch source接收通知但并不执行event handle。

1、Event Handle

event handle用于处理dispatch source的通知，通过dispatch_source_set_event_handle函数，为dispatch source创建function/block类型的event handle。当事件到来时，dispatch source提交event handle到指定的dispatch queue。

event handle为处理即将到来的所有事件负责。假设上一个event handle已经在队列中等待被执行，又有新的event handle请求添加到queue中，dispatch source会合并两个事件。然而当event handel正在执行，dispatch source等待它执行结束后，再将event handle提交到queue中。

```
// 基于block的event handle没有参数也没有返回值。
void (^dispatch_block_t)(void) // 基于function的event handle包括上下文指针和dispatch source对象，无返回值。
void (*dispatch_function_t)(void *)
```

```
dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, myDescriptor, 0, myQueue);
dispatch_source_set_event_handler(source, ^{ // block从外部捕获到source变量 size_t estimated = dispatch_source_get_data(source); // Continue reading the descriptor...
});
dispatch_resume(source);
```

2、Cancellation Handle

Cancellation handle用于在dispatch source被释放前清理dispatch source。在大多数dispatch source类型中它是选择性被实现，除了descriptor/mach port dispatch source需通过cancellation handle去关闭descriptor和释放mach port。

```
dispatch_source_set_cancel_handler(mySource, ^{ close(fd); // Close a file descriptor opened earlier.
});
```

3、Target Queue

在创建dispatch source需要指定调度event handle/cancellation handle的dispatch queue。在指定之后，还可以通过dispatch_set_target_queue函数修改关联的dispatch queue。一般修改target queue是用于修改queue的优先级，该操作是异步操作。因此在做修改操作前，已在旧dispatch queue中的任务继续被调度执行。如果恰好在修改过程中，添加任务到queue，该queue可能是旧queue，也可能是新queue。

4、Custom Data

跟GCD一样，dispatch source可以通过dispatch_set_context关联自定义数据，原理是通过context pointer存储event handle中需要用到的数据。注意的是创建了context pointer，就必须通过cancellation handle最终释放那些存储的数据。

另一种方案是通过event handle用block实现，虽然也能捕获变量，但变量随时可能被释放。因此这种方案需要通过拷贝并持有数据防止变量被回收，最终再通过cancellation handle释放该变量。

5、Memory Management

满足内存管理原则，可以通过dispatch_retain/dispatch_release来控制。

**三、Dispatch Source案例**

1、Create a Timer

timer dispatch source是周期性的timers，类型为DISPATCH_SOURCE_TYPE_TIMER，leeway值是设置的容差值，如果leeway为0，系统也无法保证在指定周期执行任务。它常用于游戏等应用刷新频幕和动画。

当电脑进入休眠时，timer dispatch source也被暂停，电脑恢复时它恢复，暂停会影响timer下一次执行。如果通过dispatch_time创建的timer，时间为相对时间，它会使用系统闹钟，系统闹钟在电脑休眠时不会转动。但如果通过 dispatch_walltime创建的timer，时间为绝对时间，它使用wall闹钟，常用于大的时间间隔。

```
dispatch_source_t CreateDispatchTimer(uint64_t interval, uint64_t leeway, dispatch_queue_t queue, dispatch_block_t block)
{ dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue); if (timer){ dispatch_source_set_timer(timer, dispatch_walltime(NULL, 0), interval, leeway); // 时间间隔够长，所以用dispatch_walltime()函数
 dispatch_source_set_event_handler(timer, block); dispatch_resume(timer); } return timer;
} void MyCreateTimer()
{ // 每30秒执行一次，容差1秒，event handle中具体实现为MyPeriodicTask() dispatch_source_t aTimer = CreateDispatchTimer(30ull * NSEC_PER_SEC, 1ull * NSEC_PER_SEC, dispatch_get_main_queue(), ^{ MyPeriodicTask(); }); // Store it somewhere for later use. if (aTimer){ MyStoreTimer(aTimer); }
}
```

除了timer dispatch source定期处理系统事件，还有dispatch_after在指定时间之后执行一次某事件，dispatch_after就像指定了时间的dispatch_async函数。

2、Reading Data from a Descriptor

```
dispatch_source_t ProcessContentsOfFile(const char* filename)
{ // Prepare the file for reading. int fd = open(filename, O_RDONLY); if (fd == -1) return NULL; fcntl(fd, F_SETFL, O_NONBLOCK); // 避免阻塞读数据进程
 dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0); dispatch_source_t readSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, fd, 0, queue); if (!readSource){ close(fd); return NULL; } // Event Handler dispatch_source_set_event_handler(readSource, ^{　　　　size_t estimated = dispatch_source_get_data(readSource) + 1; // 读取数据至buffer char* buffer = (char*)malloc(estimated); if (buffer){ ssize_t actual = read(fd, buffer, (estimated)); Boolean done = MyProcessFileData(buffer, actual); // 处理数据
 free(buffer); // 读取完毕，取消该source。 if (done) dispatch_source_cancel(readSource); } }); // Cancellation Handler dispatch_source_set_cancel_handler(readSource, ^{close(fd);}); // 开始读文件
 dispatch_resume(readSource); return readSource;
}
```

3、Writing Data to a Descriptor

```
dispatch_source_t WriteDataToFile(const char* filename)
{ int fd = open(filename, O_WRONLY | O_CREAT | O_TRUNC, (S_IRUSR | S_IWUSR | S_ISUID | S_ISGID)); if (fd == -1) return NULL; fcntl(fd, F_SETFL); // Block during the write.
 dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0); dispatch_source_t writeSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_WRITE, fd, 0, queue); if (!writeSource){ close(fd); return NULL; } dispatch_source_set_event_handler(writeSource, ^{ size_t bufferSize = MyGetDataSize(); void* buffer = malloc(bufferSize); size_t actual = MyGetData(buffer, bufferSize); write(fd, buffer, actual); free(buffer); // Cancel and release the dispatch source when done.
 dispatch_source_cancel(writeSource); }); dispatch_source_set_cancel_handler(writeSource, ^{close(fd);}); dispatch_resume(writeSource); return (writeSource);
}
```

4、Monitoring a File-System Object

```
dispatch_source_t MonitorNameChangesToFile(const char* filename)
{ int fd = open(filename, O_EVTONLY); if (fd == -1) return NULL; dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0); dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, fd, DISPATCH_VNODE_RENAME, queue); if (source){ // Copy the filename for later use. int length = strlen(filename); char* newString = (char*)malloc(length + 1); newString = strcpy(newString, filename); dispatch_set_context(source, newString); // Install the event handler to process the name change dispatch_source_set_event_handler(source, ^{ const char* oldFilename = (char*)dispatch_get_context(source); MyUpdateFileName(oldFilename, fd); }); // Install a cancellation handler to free the descriptor // and the stored string. dispatch_source_set_cancel_handler(source, ^{ char* fileStr = (char*)dispatch_get_context(source); free(fileStr); close(fd); }); // Start processing events.
 dispatch_resume(source); } else close(fd); return source;
}
```

5、Monitoring Signals

```
void InstallSignalHandler()
{ // Make sure the signal does not terminate the application.
 signal(SIGHUP, SIG_IGN); dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0); dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_SIGNAL, SIGHUP, 0, queue); if (source){ dispatch_source_set_event_handler(source, ^{ MyProcessSIGHUP(); }); // Start processing signals
 dispatch_resume(source); }
}
```

6、Monitoring a Process

```
void MonitorParentProcess()
{ pid_t parentPID = getppid(); dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0); dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_PROC, parentPID, DISPATCH_PROC_EXIT, queue); if (source){ dispatch_source_set_event_handler(source, ^{ MySetAppExitFlag(); dispatch_source_cancel(source); dispatch_release(source); }); dispatch_resume(source); }
}
```

**四、取消Dispatch Source**

```
void RemoveDispatchSource(dispatch_source_t mySource)
{ dispatch_source_cancel(mySource); dispatch_release(mySource);
}
```

**五、暂停和恢复Dispatch Source**

[Dispatch Sources - Beche - 博客园](https://www.cnblogs.com/zhouyi-ios/p/6973348.html)
