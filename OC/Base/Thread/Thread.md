1. NSThread、GCD、NSOperation多线程
<details>
<summary> 参考 </summary>

1. NSThread

>NSThread是封装程度最小最轻量级的，使用更灵活，但要手动管理线程的生命周期、线程同步和线程加锁等，开销较大；

2. GCD

>GCD基于C语言封装的，遵循FIFO

3. NSOperation

>NSOperation基于GCD封装的，比GCD可控性更强;可以加入操作依赖（addDependency）、设置操作队列最大可并发执行的操作个数（setMaxConcurrentOperationCount）、取消操作（cancel）设置优先级等,需要使用两个它的实体子类：NSBlockOperation和NSInvocationOperation，或者继承NSOperation自定义子类;NSBlockOperation和NSInvocationOperation用法的主要区别是：前者执行指定的方法，后者执行代码块，相对来说后者更加灵活易用。NSOperation操作配置完成后便可调用start函数在当前线程执行，如果要异步执行避免阻塞当前线程则可以加入NSOperationQueue中异步执行


关系：①:先搞清两者的关系,NSOpertaionQueue用GCD构建封装的，是GCD的高级抽象!

②:GCD仅仅支持FIFO队列，而NSOperationQueue中的队列可以被重新设置优先级，从而实现不同操作的执行顺序调整。GCD不支持异步操作之间的依赖关系设置。如果某个操作的依赖另一个操作的数据（生产者-消费者模型是其中之一），使用NSOperationQueue能够按照正确的顺序执行操作。GCD则没有内建的依赖关系支持。

③:NSOperationQueue支持KVO，意味着我们可以观察任务的执行状态。

了解以上不同，我们可以从以下角度来回答

性能:①:GCD更接近底层，而NSOperationQueue则更高级抽象，所以GCD在追求性能的底层操作来说，是速度最快的。这取决于使用Instruments进行代码性能分析，如有必要的话

②:从异步操作之间的事务性，顺序行，依赖关系。GCD需要自己写更多的代码来实现，而NSOperationQueue已经内建了这些支持

③:如果异步操作的过程需要更多的被交互和UI呈现出来，NSOperationQueue会是一个更好的选择。底层代码中，任务之间不太互相依赖，而需要更高的并发能力，GCD则更有优势
</details>

2. 如何保证多线程中读写分离，加锁方案？

<details>
<summary> 参考 </summary>

[多线程](https://github.com/luckyvondoit/iOS/blob/master/Book/UnderlyingPrincipleOfOC/Multithreading.md)

</details>