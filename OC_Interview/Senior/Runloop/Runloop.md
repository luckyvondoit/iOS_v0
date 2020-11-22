<!-- <span id=""></span> -->

<!-- <details>
<summary> 参考 </summary>
</details> -->


1. [什么是RunLoop](#1)
2. [Runloop 和线程的关系？](#2)
3. [RunLoop的运行模式](#3)
4. [autoreleasePool 在何时被释放？](#4)
5. [子线程中的自动释放池是什么时候释放的？](#5)
6. [GCD 在Runloop中的使用？](#6)
7. [PerformSelector 的实现原理？](#7)
8. [PerformSelector:afterDelay:这个方法在子线程中是否起作用？](#8)
9. [事件响应的过程？](#9)
10. [手势识别的过程？](#10)
11. [CADispalyTimer和Timer哪个更精确？](#11)


---

1. <span id="1">什么是RunLoop</span>

<details>
<summary> 参考 </summary>

RunLoop 就是一个事件处理的循环，用来不停的调度工作以及处理输入事件。使用 RunLoop 的目的是让你的线程在有工作的时候忙于工作,而没工作的时候处于休眠状态。 runloop 的设计是为了减少 cpu 无谓的空转。

作用就是：
1. 使程序持续运行
2. 有任务就运行，无任务就休眠，节约CPU资源，提高程序性能
3. 处理各种事件(触摸、定时器、performSelectord等等)

</details>

2. <span id="2">Runloop 和线程的关系？</span>

<details>
<summary> 参考 </summary>

- 一个线程对应一个 Runloop。
- 主线程的默认开启Runloop。
- 子线程的 Runloop 以懒加载的形式创建。
- Runloop 存储在一个全局的可变字典里，线程是 key ，Runloop 是 value。

</details>

3. <span id="3">RunLoop的运行模式</span>

<details>
<summary> 参考 </summary>

RunLoop的运行模式共有5种，RunLoop只会运行在一个模式下，要切换模式，就要暂停当前模式，重写启动一个运行模式。

- kCFRunLoopDefaultMode, App的默认运行模式，通常主线程是在这个运行模式下运行
- UITrackingRunLoopMode, 跟踪用户交互事件（用于 ScrollView 追踪触摸滑动，保证界面滑动时不受其他Mode影响）
- kCFRunLoopCommonModes, 伪模式，不是一种真正的运行模式
- UIInitializationRunLoopMode：在刚启动App时第进入的第一个Mode，启动完成后就不再使用
- GSEventReceiveRunLoopMode：接受系统内部事件，通常用不到

</details>



4. <span id="4">autoreleasePool 在何时被释放？</span>

<details>
<summary> 参考 </summary>

- App启动后，苹果在主线程 RunLoop 里注册了两个 Observer，其回调都是 _wrapRunLoopWithAutoreleasePoolHandler()。
- 第一个 Observer 监视的事件是 Entry(即将进入Loop)，其回调内会调用 _objc_autoreleasePoolPush() 创建自动释放池。其 order 是 -2147483647，优先级最高，保证创建释放池发生在其他所有回调之前。
- 第二个 Observer 监视了两个事件： BeforeWaiting(准备进入休眠) 时调用_objc_autoreleasePoolPop() 和 _objc_autoreleasePoolPush() 释放旧的池并创建新池；Exit(即将退出Loop) 时调用 _objc_autoreleasePoolPop() 来释放自动释放池。这个 Observer 的 order 是 2147483647，优先级最低，保证其释放池子发生在其他所有回调之后。
- 在主线程执行的代码，通常是写在诸如事件回调、Timer回调内的。这些回调会被 RunLoop 创建好的 AutoreleasePool 环绕着，所以不会出现内存泄漏，开发者也不必显示创建 Pool 了。

</details>


5. <span id="5">子线程中的自动释放池是什么时候释放的？</span>

<details>
<summary> 参考 </summary>

主线程的runloop默认主动开启。但是子线程中的runloop默认是关闭的，所以子线程中默认没有autoreleasepool。

运行循环结束前会释放自动释放池，还有就是池子满了，也会销毁。

</details>

6. <span id="6">GCD 在Runloop中的使用？</span>

<details>
<summary> 参考 </summary>

GCD由 子线程 返回到 主线程,只有在这种情况下才会触发 RunLoop。会触发 RunLoop 的 Source 1 事件。

</details>

7. <span id="7">PerformSelector 的实现原理？</span>

<details>
<summary> 参考 </summary>

- 当调用 NSObject 的 performSelecter:afterDelay: 后，实际上其内部会创建一个 Timer 并添加到当前线程的 RunLoop 中。所以如果当前线程没有 RunLoop，则这个方法会失效。

- 当调用 performSelector:onThread: 时，实际上其会创建一个 Timer 加到对应的线程去，同样的，如果对应线程没有 RunLoop 该方法也会失效。

</details>

8. <span id="8">PerformSelector:afterDelay:这个方法在子线程中是否起作用？</span>

<details>
<summary> 参考 </summary>

不起作用，子线程默认没有 Runloop，也就没有 Timer。可以使用 GCD的dispatch_after来实现

</details>

9. <span id="9">事件响应的过程？</span>

<details>
<summary> 参考 </summary>

- 苹果注册了一个 Source1 (基于 mach port 的) 用来接收系统事件，其回调函数为 __IOHIDEventSystemClientQueueCallback()。

- 当一个硬件事件(触摸/锁屏/摇晃等)发生后，首先由 IOKit.framework 生成一个 IOHIDEvent 事件并由 SpringBoard 接收。这个过程的详细情况可以参考这里。SpringBoard 只接收按键(锁屏/静音等)，触摸，加速，接近传感器等几种 Event，随后用 mach port 转发给需要的 App 进程。随后苹果注册的那个 Source1 就会触发回调，并调用 _UIApplicationHandleEventQueue() 进行应用内部的分发。

- _UIApplicationHandleEventQueue() 会把 IOHIDEvent 处理并包装成 UIEvent 进行处理或分发，其中包括识别 UIGesture/处理屏幕旋转/发送给 UIWindow 等。通常事件比如 UIButton 点击、touchesBegin/Move/End/Cancel 事件都是在这个回调中完成的。

</details>

10. <span id="10">手势识别的过程？</span>

<details>
<summary> 参考 </summary>

- 当 _UIApplicationHandleEventQueue() 识别了一个手势时，其首先会调用 Cancel 将当前的 touchesBegin/Move/End 系列回调打断。随后系统将对应的 UIGestureRecognizer 标记为待处理。

- 苹果注册了一个 Observer 监测 BeforeWaiting (Loop即将进入休眠) 事件，这个 Observer 的回调函数是 _UIGestureRecognizerUpdateObserver()，其内部会获取所有刚被标记为待处理的 GestureRecognizer，并执行GestureRecognizer 的回调。

- 当有 UIGestureRecognizer 的变化(创建/销毁/状态改变)时，这个回调都会进行相应处理。

</details>


11. <span id="11">CADispalyTimer和Timer哪个更精确？</span>

<details>
<summary> 参考 </summary>

CADisplayLink 更精确

- iOS设备的屏幕刷新频率是固定的，CADisplayLink在正常情况下会在每次刷新结束都被调用，精确度相当高。

- NSTimer的精确度就显得低了点，比如NSTimer的触发时间到的时候，runloop如果在阻塞状态，触发时间就会推迟到下一个runloop周期。并且 NSTimer新增了tolerance属性，让用户可以设置可以容忍的触发的时间的延迟范围。

- CADisplayLink使用场合相对专一，适合做UI的不停重绘，比如自定义动画引擎或者视频播放的渲染。NSTimer的使用范围要广泛的多，各种需要单次或者循环定时处理的任务都可以使用。在UI相关的动画或者显示内容使用 CADisplayLink比起用NSTimer的好处就是我们不需要在格外关心屏幕的刷新频率了，因为它本身就是跟屏幕刷新同步的。

</details>
