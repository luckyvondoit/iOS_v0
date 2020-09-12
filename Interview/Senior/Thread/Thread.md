### 谈下iOS开发中知道的哪些锁?

>哪个性能最差?SD和AFN使用的哪个?  
>一般开发中你最常用哪个?   
>哪个锁apple存在问题又是什么问题?  

<details>
<summary> 参考 </summary>

- 我们在使用多线程的时候多个线程可能会访问同一块资源，这样就很容易引发数据错乱和数据安全等问题，这时候就需要我们保证每次只有一个线程访问这一块资源，锁 应运而生

- `@synchronized` 性能最差,SD和AFN等框架使用这个.

- NSRecursiveLock 和NSLock ：建议使用前者，避免循环调用出现**死锁**

- OSSpinLock 自旋锁 ,存在的问题是, 优先级反转问题,破坏了spinlock

- dispatch_semaphore 信号量 : 保持线程同步为线程加锁

- [多线程](https://github.com/luckyvondoit/OC_Document/blob/master/Interview/Book/UnderlyingPrincipleOfOC/Multithreading.md)
</details>

### 解决网络请求和界面刷新顺序问题

<details>
<summary> 参考 </summary>
* [解决网络请求和界面刷新顺序问题](https://blog.csdn.net/u012709932/article/details/77924019)
</details>



