<!-- <span id=""></span>

<details>
<summary> 参考 </summary>

</details> -->

1. [内存布局](#1)


---

1. <span id="1">内存布局</span>

<details>
<summary> 参考 </summary>

![](./imgs/1782258-c982ebeacd0a42dc.png)

- 栈(stack):方法调用，局部变量等，是连续的，高地址往低地址扩展
- 堆(heap):通过alloc等分配的对象，是离散的，低地址往高地址扩展，需要我们手动控制
- 未初始化数据(bss):未初始化的全局变量等
- 已初始化数据(data):已初始化的全局变量等
- 代码段(text):程序代码

</details>

