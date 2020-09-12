### 第1条：了解Objective-C起源

该语言使用“消息结构”（message structure）而非“函数调用”（founction calling）
```
//message structure
Object *obj = [Object new];
[obj performWith:p1 and:p2];

//founction calling
Object *obj = [Object new];
obj->perform(p1, p2);
```

**关键区别在于**：使用消息结构体的语言，其运行时所执行的代码由运行环境决定；而使用函数调用的语言，则由编译器决定。

**要点**

- Objective-C为C语言添加了面向对象特性，是其超集。OC使用动态绑定的消息结构，也就是说，在运行时才会检查对象类型。接受一条消息之后，究竟应执行何种代码，由运行环境而非编译器决定。
- 理解C语言的核心概念有助于写好OC程序。尤其要掌握内存模型和指针。

### 第2条：在类的头文件中尽量少引入其他头文件

创建好一个类之后，其代码看上去如下所示：

```
//IFXPerson.h

#import <Foundation/Foundation.h>

@interface IFXPerson : NSObject

@property (nonatomic, assign) NSString *firstName;
@property (nonatomic, assign) NSString *lastName;

@end

//IFXPerson.m
#import "IFXPerson.h"

@implementation IFXPerson

@end
```

过段时间，你可能又创建了一个名为IFXEmployer的新类，然后可能觉得每个IFXPerson实例都应该有一个IFXE门票loyer。于是，直接为其添加一项属性：

```IFXPerson.h
#import <Foundation/Foundation.h>
#import "IFXEmployer.h"

@interface IFXPerson : NSObject

@property (nonatomic, assign) NSString *firstName;
@property (nonatomic, assign) NSString *lastName;
@property (nonatomic, strong) IFXEmployer *employer;

@end
```

这种办法可行但不够优雅。改为：
```
#import <Foundation/Foundation.h>
@class IFXEmployer;//改变

@interface IFXPerson : NSObject

@property (nonatomic, assign) NSString *firstName;
@property (nonatomic, assign) NSString *lastName;
@property (nonatomic, strong) IFXEmployer *employer;

@end

//IFXPerson.m
#import "IFXPerson.h"
#import "IFXEmployer.h"

@implementation IFXPerson

@end
```

向前声明也可解决两个类相互引用的问题。

如果写的类继承自某个超类，则必须引入定义那个超类的头文件。同理，如果要声明你写的类遵从某个协议（protocol），那么该协议必须有完整的定义，且不能使用向前引用。向前声明只能告诉编译器有某个协议，而此时编译器却要知道该协议中定义的方法。

**要点**
- 除非确有必要，否则不要引入头文件。一般来说，应在某个类的头文件中使用向前声明来提及别的类，并在实现文件中引入那些类的头文件。这样做可以劲量降低类之间的耦合。
- 有时无法使用向前声明，比如要声明某个类遵循一项协议。这种情况下，劲量把“该类遵循某协议”的这条声明移至“class-continuation"中。如果不行的话，就把协议单独放在一个头文件中，然后引入。

### 第3条：多用字面量语法，少用与之等价的方法

**要点**
- 应该使用字面量语法来创建字符串、数值、数组、字典。与创建此类对象的常规方法相比，这么做更加简明扼要。
- 应该通过取下标操作来访问数组下标或字典中的键所对应的元素。
- 用字面量语法创建数组或字典时，若值中有nil，这会抛出异常。因此，务必确保值里不含nil

### 第4条：多用类型常量，少用#define预处理指令

```
#define ANIMATION_DURATION 0.3
```
这样定义出来的常量没有类型信息。

```
static const NSTimeInterval kAnimationDuration = 0.3;
```
用次方法定义的常量包含类型信息。变量一定要同时用`static`和`const`来声明。如果试图修改由`const`修饰符所声明的变量，那么编译器会报错。而`static`修饰符则意味着变量仅在定义此变量的编译单元可见。

实际上，如果一个变量既声明为`static`，又声明为`const`，那么编译器根本不会创建符号，而是会像`#define`预处理指令一样，把所有遇到的变量都替换为常值。

若不打算公开某个常量，则应该将其定义在使用该常量的实现文件里。

有时候需要对我公开某个常量。此常量需放在“全局符号表”（global symbol table）中，以便可以在定义该常量的编译单元之外使用。应该这样定义：
```
// in the header file
extern NSString *const IFXStringConstant;

// in the implementation file
NSString *const IFXStringConstant = @"value";
```

注意常量的名字。为避免名称冲突，最好是用与之相关的类名做前缀。

**要点**

- 不要用预处理指令定义常量。这样定义出来的常量不含类型信息，编译器只是会在编译前据此执行查找与替换操作。即使有人重新定义常量值，编译器也不会产生警告信息，这将导致应用程序中的常量值不一致。
- 在实现文件中使用`static const`来定义“只在编译单元内可见的常量”。由于此类常量不在全局符号表中，所以无需为其添加前缀。
- 在头文件中使用`extern`来声明全局常量，并在相关实现文件中定义其值。这种常量要出现在全局符号表中，所以其名称应加以区分，通常用与之相关的类名左前缀。

### 第5条：用枚举表示状态、选项、状态码

```
typedef NS_ENUM(NSUInteger, IFXState) {
    IFXStateDisConnected,
    IFXStateConnecting,
    IFXStateConnected
}

typedef NS_OPTIONS(NSUInteger, IFXDirection) {
    IFXDirectionUp     = 1 << 0,
    IFXDirectionDown   = 1 << 1,
    IFXDirectionLeft   = 1 << 2,
    IFXDirectionRight  = 1 << 3
}

```

使用： 

```
IFXState state  = IFXStateDisConnected;
if (state == IFXStateDisConnected) {
    NSLog(@"DisConnected");
} else if ((state == IFXStateConnecting) {
    NSLog(@"Connecting");
} else {
    NSLog(@"Connected");
}
```

```
IFXDirection direction  = IFXDirectionUp | IFXDirectionDown;
if (direction & IFXDirectionUp) {
    NSLog(@"include IFXDirectionUp");
}

if (direction & IFXDirectionDown) {
    NSLog(@"include IFXDirectionDown");
}

if (direction & IFXDirectionLeft) {
    NSLog(@"include IFXDirectionLeft");
}

if (direction & IFXDirectionRight) {
    NSLog(@"include IFXDirectionRight");
}

```

**要点**

- 应该用枚举来表示状态机的状态、传递给方法的选项以及状态码等值，给这些起个易懂的名字。
- 如果把传递给某个方法的选项表示为枚举类型，而多个选项又可同时使用，那么就将各选项值定义为2的幂，以便通过通过按位或操作将其组合起来。
- 用NS_ENUM与NS_OPTIONS宏定义枚举类型，并指明其底层数据类型。这样做可以确保枚举是用开发者所选的底层数据类型实现出来的，而不会采用编译器所选的类型。
- 在处理枚举类型的switch语句中不要实现default分支。这样的话，加入新枚举之后，编译器就会提示开发者，switch语句并未处理所有枚举。

### 第6条：理解“属性”这一概念

[property](https://github.com/luckyvondoit/OC_Document/blob/master/Interview/Property.md)

**要点**

- 可以用@property语法来定义对象中所封装的数据。
- 通过“特质”来指定存储数据所需的正确语义。
- 在设置属性所对应的实例变量时，一定要遵从该属性所声明的语义。
- 开发iOS程序时应该使用nonatomic属性，因为atomic属性会严重影响性能。

### 第7条：在对象内部劲量直接访问实例变量

[self](https://github.com/luckyvondoit/OC_Document/blob/master/Interview/Self.md)

**要点**

- 在对象内部读取数据时，应该直接通过实例变量来读，而写入数据时，则应该通过属性来写。
- 在初始化方法和dealloc方法中，总是应该直接通过实例变量来读写数据。
- 有时会使用懒加载技术配置某份数据，这种情况下，需要通过属性来读取数据。

### 第8条：理解“对象等同性”这一感念

```
NSString *foo = @"badger 123";
NSString *bar = [NSString stringWithFormat:@"badger %i"m, 123];
BOOL equalA = (foo == bar); //equalA = NO
BOOL equalB = [foo isEqual:bar];//equalB = YES
BOOL equalC = [foo isEqualToString:bar];//equalC = YES
```
可以看出 == 与等同性判断的区别。

NSString自定义方法`isEqualToString:`。传递给该方法的对象必须是NSString，否则结果未定义。调用该方法比`isEqual:`方法快，后者还要执行额外的步骤，因为它不知道受测对象的类型。

NSObject协议中有两个用于判断等同性的关键方法：

```
- (BOOL)isEqual:(id)objdet;
- (NSUinteger)hash;
```

如果`isEqual:`方法判断两个对象相等，那么其`hash`方法也必须返回同一个值。但是，如果两个对象的`hash`方法放回同一个值，那么`isEqual:`方法未必会认为两者相等。

**要点**

- 若想监测对象的同等性，请提供“isEqual:"与hash方法。
- 相同的对象必须具有相同的哈希值，但是哈希值相同的对象却未必相同。
- 不要盲目地逐个监测每条属性，而是应该依照具体需求来制定检测方案。
- 编写hash方法时，应该使用计算速度快而且哈希码碰撞几率低的算法。

### 第9条：以“类族模式”隐藏实现细节

现在举例演示如何创建类簇。假设有一个处理雇员的类，每个雇员都有“名字”和“薪水”这两个属性，管理者可以命令其执行日常工作。但是，各种雇员的工作内容却不相同。经理在带领雇员做项目时，无需关心每个人如何完成其任务，仅需指示其开工即可。

相关代码实现：

[ClassCluster](https://github.com/luckyvondoit/OC_Foundation/tree/master/Classes/ClassCluster)

**要点**

- 类族模式可以把实现细节隐藏在一套简单的公共接口后面。
- 系统框架中经常使用类簇。
- 从类簇的公共抽象基类中继承子类时要当心，若有开发文档，则应首先阅读。

### 第10条：在既有的类中使用关联对象存放自定义数据

### 第11条：理解objc_msgSend的作用

### 第12条：理解消息转发机制

### 第13条：用“方法调配技术”调试“黑盒方法”（method swizzling）

### 第14条：理解“类对象”的用意

### 第15条：用前缀避免命名空间冲突

**要点**

- 选择与你的公司、应用程序或二者皆有关联之名称作为类名的前缀，并在所有代码中均使用这一前缀。
- 若自己所开发的诚信库中用到了第三方库，则应为其中的名称加上前缀。

### 第16条：提供“全能初始化方法”

**要点**

- 在类中提供一个全能初始化方法，并于文档里指明。其他初始化方法均应调用此方法。
- 若全能初始化方法与超类不同，则需要覆写超类中的对应方法。
- 如果超类的初始化方法不适用于子类，那么应该覆写这个超类方法，并在其中抛出异常。

### 第17条：实现description方法

**要点**

- 实现description方法返回一个有意义的字符串，用以描述实例。
- 若想在调试时打印出更详尽的对象描述信息，则应实现debugDescription方法。

### 第18条：尽量使用不可变对象

**要点**

- 尽量创建不可变对象
- 若某属性仅可于对象内部修改，则在”class-continuation分类”中将其由readonly属性扩展为readwrite属性
- 不要把可变的collection作为属性公开，而应提供相关方法，以此修改对象中的可变collection。

### 第19条：使用清晰而协调的命名方式

**要点**

- 起名时应遵从标准的Objective-C命名规范，这样创建出来的接口更容易为开发者所理解。
- 方法名要言简意赅，从左至右读起来要像个日常用语中的句子才好。
- 方法名里不要使用缩略后的类型名称。
- 给方法起名时的第一要务就就是确保其风格与你自己的代码或所要集成的框架相符。

### 第20条：为私有方法名加前缀

**要点**

- 给私有方法的名称加上前缀，这样可以很容易地将其同公共方法区分开。
- 不要单用一个下划线做私有方法的前缀，因为这样做法是预留给苹果公司用的。

### 第21条：理解OC错误模型

**要点**

- 只有发生了可使整个应用程序崩溃的严重错误时，才应使用异常。
- 在错误不那么严重的情况下，可以指派“委托方法”（delegate method）来处理错误，也可以把错误信息放在NSError对象里，经由“输出参数”返回给调用者。

### 第22条：理解NSCopying协议

**要点**

- 若想令自己所写的对象具有拷贝功能，则需实现NSCopying协议。
- 如果自定义的对象分为可变版本与不可变版本，那么就要同时实现NSCopying与NSMutableCopying协议。
- 复制对象时需决定采用浅拷贝还是深拷贝，一般情况下应该尽量执行浅拷贝。
- 如果你所写的对象需要深拷贝，那么可考虑新增一个专门执行深拷贝的方法。

### 第23条：通过委托与数据源协议进行对象间通信

**要点**

- 委托模式为对象提供了一套接口，使其可由此将相关事件告知其他对象。
- 将委托对象应该支持的接口定义成协议，在协议中把可能需要处理的事件定义成方法。
- 当某个对象需要从另一个对象中获取数据时，可以使用委托模式。这种情况下，该模式亦称“数据源协议”（data source protocal）
- 若有必要，可实现含有位段的结构体，将委托对象是否能响应相关协议方法这一信息缓存至其中。

### 第24条：将类的实现代码飞散到便于管理的数个分类中。

**要点**

- 使用分类机制把类的实现代码划分成易于管理的小块。
- 将应该视为“私有”的方法归入名叫Private的分类中，以影藏实现细节。

### 第25条：总是为第三方类的分类名称添加前缀

**要点**

- 向第三方类中添加分类时，总应给其名称加上你专用的前缀。
- 向第三方类中添加分类时，总应给其中的方法名加上你专用的前缀。

### 第26条：勿在分类中声明属性

**要点**

- 把封装数据所用的全部属性都定义在主接口里
- 在“class-continuation分类”之外的其他分类中，可以定义存取方法，但尽量不要定义属性。

### 第27条：使用“class-continuation分类”影藏实现细节

**要点**

- 通过“class-continuation分类”向类中新增实例变量。
- 如果某属性在主接口中声明为“只读”，而类的内部又要用设置方法修改此属性，那么就在“class-continuation分类”中将其扩展为“可读写”。
- 把私有方法的原型声明在“class-continuation分类”里面。
- 若想使类遵循的协议不为人所知，则可于“class-continuation分类”中声明。

### 第28条：通过协议提供匿名对象

