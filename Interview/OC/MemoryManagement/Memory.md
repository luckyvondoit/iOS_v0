
- [1.weak修饰的释放则自动被置为nil的实现原理](#1weak修饰的释放则自动被置为nil的实现原理)
- [2.Autorelease的原理](#2autorelease的原理)

## 1.weak修饰的释放则自动被置为nil的实现原理

<details>
<summary> 参考 <summary>

- Runtime维护着一个Weak表（sidetable），用于存储指向某个对象的所有Weak指针
- Weak表是Hash表，Key是所指对象的地址，Value是Weak指针地址的数组
- 在对象被回收的时候，经过层层调用，会最终触发下面的方法将所有Weak指针的值设为nil。
- runtime源码，objc-weak.m 的 arr_clear_deallocating 函数
- weak指针的使用涉及到Hash表的增删改查，有一定的性能开销.

</details>

## 2.Autorelease的原理

<details>
<summary> 参考 <summary>

占位

</details>