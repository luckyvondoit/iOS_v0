<!-- <span id=""></span> -->

<!-- <details>
<summary> 参考 </summary>
</details> -->

1. [指针常量和常量指针](#1)
2. [C和 OC 如何混编](#2)

---

1. <span id="1">指针常量和常量指针</span>

<details>
<summary> 参考 </summary>

>char* sp = "We are happy." 无法修改字符串内容，因为这个字符串存放在内存的常量区
>char str[] = "We are happy."可以修改字符串内容，因为这个字符串是存放在栈中的

1. **常量指针**：指向常量的指针，表示指针所指向的地址的内容是不可修改的，但指针自身可变。基本定义形式如下：

```c
const char *test = "hello world"; //const位于*的左边,const 修饰的是*test
```

```c
void test() {
    char *s1 = "hello";
    char *s2 = "world";
    
    const char *s = s1;
    s = s2;
    
    printf("%s \n",s);
}
```

打印

```c
world
Program ended with exit code: 0
```

```c
void test() {
    char *s1 = "hello";
    char *s2 = "world";
    //c语言char *c只能表示字符串，不能表示字符指针。
    const char *s = s1;
    *s = s2;
    
    printf("%c \n",s);
}
```

报错

```c
Read-only variable is not assignable
```

2. 指针常量：指针自身是一个常量，表示指针自身不可变，但其指向的地址的内容是可以被修改的。基本定义形式如下：

```c
char* const test = "hello world"; //const位于*的右边,const 修饰的是test
```

```c
void test() {
    
    char s1[] = "hello";
    char s2[] = "world";

    char * const s = s1;
    s1[0] = 'n';
    
    printf("%c \n",*s);
}
```

打印

```
n 
Program ended with exit code: 0
```

```c
void test() {
    
    char s1 = "hello";
    char s2 = "world";

    char * const s = s1;
    s = s2;
    
    printf("%c \n",*s);
}
```

报错

```
Cannot assign to variable 's' with const-qualified type 'char *const'
```

</details>

2. <span id="2">C和 OC 如何混编</span>

<details>
<summary> 参考 </summary>

xcode可以识别一下几种扩展名文件:

- .m文件,可以编写 OC语言 和 C 语言代码
- .cpp: 只能识别C++ 或者C语言(C++兼容C)
- .mm: 主要用于混编 C++和OC代码,可以同时识别OC,C,C++代码

</details>