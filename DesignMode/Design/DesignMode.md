- [1.设计模式概述](#1设计模式概述)
  - [1.1 初始设计模式](#11-初始设计模式)
  - [1.2 设计模式的分类](#12-设计模式的分类)
  - [2.UML](#2uml)
  - [3.软件设计的7条原则](#3软件设计的7条原则)
    - [3.1 开闭原则（Open-Closed Principle, OCP）](#31-开闭原则open-closed-principle-ocp)
    - [3.2 里氏替换原则（Liskov Substitution Principle,LSP）](#32-里氏替换原则liskov-substitution-principlelsp)
    - [3.4 单一职责原则（Simple Responsibility Pinciple，SRP）](#34-单一职责原则simple-responsibility-pinciplesrp)
    - [3.4 接口隔离原则（Interface Segregation Principle, ISP）](#34-接口隔离原则interface-segregation-principle-isp)
    - [3.5 依赖倒置原则（Dependence Inversion Principle,DIP）](#35-依赖倒置原则dependence-inversion-principledip)
    - [3.6 迪米特原则](#36-迪米特原则)
    - [3.7 合成复用原则](#37-合成复用原则)
  - [4. 创建型设计模式](#4-创建型设计模式)
    - [4.1 单例设计模式](#41-单例设计模式)
  - [5.总结](#5总结)
    - [5.1 7种基本设计原则](#51-7种基本设计原则)
    - [5.2 23种经典设计模式](#52-23种经典设计模式)
      - [5.2.1 创建型设计模式](#521-创建型设计模式)
      - [5.2.2 结构型设计模式](#522-结构型设计模式)
      - [5.2.3 行为型设计模式](#523-行为型设计模式)
# 1.设计模式概述

## 1.1 初始设计模式

设计模式是一套被反复使用、多次总结、从代码设计经验中总结出的软件设计方法。其是软件工程师前辈对编码经验的总结，目的是提高代码的可重用性、可读性和可靠性。

下面列举使用设计模式所要达到的目标：

1. 使得代码的组织结构更加合理，逻辑更加清晰。
2. 提高代码的可重用性。
3. 提高代码的可读性。
4. 提高代码的可维护性。
5. 提高代码的扩展性和灵活性。
6. 使程序的设计更加标准化，代码的编写更加工程化，提高开发效率。

## 1.2 设计模式的分类

共介绍23总设计模式，从作用上可以分为3类：即**创建型模式**、**结构性模式**和**行为型模式**。

创建型模式用来描述怎样创建对象。其核心是将对象的创建与使用分离，包括**单例模式**、**原型模式**、**工厂方法模式**、**抽象工厂方法模式**、**建造者模式**。

结构型模式用来描述怎样组织类和对象，包括**代理模式**、**适配器模式**、**桥接模式**、**装饰模式**、**外观模式**、**享元模式**、**组件模式**。

行为模式用来描述类或对象的行为，包括**模板方法模式**、**策略模式**、**命令模式**、**职责链模式**、**状态模式**、**观察者模式**、**中介模式**、**迭代器模式**、**访问者模式**、**备忘录模式**、**解释器模式**。

## 2.UML

[UML](../UML/UML.md)

## 3.软件设计的7条原则

### 3.1 开闭原则（Open-Closed Principle, OCP）

勃兰特·梅耶在1988年的著作《面向对象软件设计》中提出：**软件实体应当对扩展开放，对修改关闭**。这成为开闭原则的经典定义。

使用开闭原则设计的软件有如下优势：

- 测试方便。
- 提高代码复用性。
- 提高软件的维护性和扩展性。

实现开闭原则可以通过**继承父类**与**实现接口**两种方式。在开闭原则中，一个类只因为错误而修改，新加入的功能都不应该修改原始代码。

继承的方式通过让子类继承父类来实现扩展。子类可以重写父类的方法来实现差异功能，也可以部分复用父类的代码，在此基础上添加新的逻辑功能。

以应用皮肤主题设计为例来理解开闭原则，首先使用Xcode开发工具新建一个命名为OpenClosePrinciple.playground的文件，在其中编码如下：

```swift
enum Color : String {
    case black = "black"
    case white = "white"
    case red   = "red"
    case blue  = "blue"
    case green = "green"
    case gray  = "gray"
    case yellow = "yellow"
    case purple = "purple"
}

//默认的主题风格
class Style {
    var backgroundColor = Color.black
    var textColor = Color.white
    
    init(){}
    
    func apply() {
        print("应用皮肤：背景颜色（\(self.backgroundColor.rawValue)）,文字颜色：（\(self.textColor.rawValue)）")
        
    }
}

let baseStyle = Style()
baseStyle.apply()

//print
//应用皮肤：背景颜色（black）,文字颜色：（white）
```

假设我们需要添加一个背景色为白色、文字颜色为黑色且按钮颜色为紫色的主题。根据开闭原则应该创建一个继承于Style的类，用来扩展新功能，而不是直接修改Style类。

```swift
class LightStyle : Style {
    var buttonColor = Color.purple
    
    override init() {
        super.init()
        self.backgroundColor = Color.white
        self.textColor = Color.black
    }
    
    override func apply() {
        print("应用皮肤：背景颜色（\(self.backgroundColor.rawValue)），文字颜色：（\(self.textColor.rawValue)），按钮颜色：（\(self.buttonColor)）")
    }
}

let lightStyle = LightStyle()
lightStyle.apply()

//print 
//应用皮肤：背景颜色（white），文字颜色：（black），按钮颜色：（purple）
```

从上面的代码可以看出，通过继承方式实现的开闭原则并不彻底。通过接口可以更好地实现开闭原则，改写如下：

```swift
protocol StyleInterface {
    var backgroundColor : Color { get }
    var textColor : Color { get }
    var buttonColor : Color { get }
    func apply() -> Void
}

class BaseStyle : StyleInterface {
    var backgroundColor: Color {
        get {
            return Color.white
        }
    }
    
    var textColor: Color {
        get {
            return Color.black
        }
    }
    
    var buttonColor: Color {
        get {
            return Color.red
        }
    }
    
    init() {}
    
    func apply() {
        print("应用皮肤：背景颜色（\(self.backgroundColor.rawValue)），文字颜色：（\(self.textColor.rawValue)），按钮颜色：（\(self.buttonColor)）")
    }
}

class DarkStyle : StyleInterface {
    var backgroundColor: Color {
        get {
            return Color.black
        }
    }
    
    var textColor: Color {
        get {
            return Color.white
        }
    }
    
    var buttonColor: Color {
        get {
            return Color.purple
        }
    }
    
    init() {}
    
    func apply() {
        print("应用皮肤：背景颜色（\(self.backgroundColor.rawValue)），文字颜色：（\(self.textColor.rawValue)），按钮颜色：（\(self.buttonColor)）")
    }
}

let baseStyle = BaseStyle()
baseStyle.apply()

let darkStyle = DarkStyle()
darkStyle.apply()

//pirnt
//应用皮肤：背景颜色（white），文字颜色：（black），按钮颜色：（red）
//应用皮肤：背景颜色（black），文字颜色：（white），按钮颜色：（purple）
```

如上代码所示，StyleInterface是一个协议，协议中定义了与主题相关的一些属性和方法，后面当我们需要扩展多个主题时，只需要对此接口进行不同的实现即可，不会影响到其他已经存在的主题类。

### 3.2 里氏替换原则（Liskov Substitution Principle,LSP）

里氏替换原则是里斯科夫在1987年的“面向对象技术高峰会议”上提出的，其核心观念是：**继承必须保证超类所拥有的性质在子类中依然成立**。遵循里氏替换原则，**在进行类的继承时，要保证子类不对父类的属性或方法进行重写，而只是扩展父类的功能**。

> 子类可以扩展父类的功能，但不能改变父类原有的功能

其实，里氏替换原则是对开闭原则一种更严厉的补充，除了有开闭原则带来的优势，也保证了继承中重写父类方法造成的可复用性变差与稳定性变差的问题。

里氏替换原则在实际编程中主要应用在类的组织结构上，对于继承的设计，子类不可以重写父类的方法，只能为父类添加方法。如果在设计时，发现子类不得不重写父类的方法，则表明类的组织结构又问题，需要重新设计类的继承关系。

例如,假设我们的程序中需要组织鸟类与鸵鸟类，我们可能很容易写出下面的代码：

```swift
class Bird {
    var name: String
    init(name: String) {
        self.name = name
    }
    
    func fly() {
        print("\(self.name)开始飞行")
    }
}

let bird = Bird(name: "鸟")
bird.fly()

class Ostrich : Bird {
    override func fly() {
        print("抱歉！不能飞行")
    }
    
    func run() {
        print("\(self.name)急速奔跑")
    }
}

let ostrich = Ostrich(name: "鸵鸟")
ostrich.run()

//print
//鸟开始飞行
//鸵鸟急速奔跑
```

在设计鸵鸟类时，我们让其继承自鸟类，并且扩展了一个奔跑的方法。因为鸵鸟不能飞，我们重写了`fly`方法。这样做虽然实现了需求，但是违反了里氏替换原则。在这种情况下，我们需要对类的继承关系进行重构。如下：

```swift
class Animal {
    var name: String
    
    init(name: String) {
        self.name = name
    }
}

class Bird : Animal {
    func fly() {
        print("\(self.name)开始飞行")
    }
}

let bird = Bird(name: "鸟")
bird.fly()

class Ostrich : Animal {
    func run() {
        print("\(self.name)急速奔跑")
    }
}

let ostrich = Ostrich(name: "鸵鸟")
ostrich.run()

//print
//鸟开始飞行
//鸵鸟急速奔跑
```

> **注：里氏替换原则和多态**
> 多态和里氏替换原则所关注的角度不同。
> 
> 多态是面向编程的一大特性，也是面向编程语言的一种语法，它是一种代码的实现思路。
> 
> 里氏替换原则是一种设计原则，是用来指导继承关系中子类该如何设计
>
> 将父类设计成抽象类或者通过接口继承，避免使用多态破坏里氏替换原则。

### 3.4 单一职责原则（Simple Responsibility Pinciple，SRP）

单一职责原则是由罗伯特·C.马丁最初在《敏捷软件开发：原则、模式和实践》一书中提出的一种软件设计原则。其核心是**一个类只应该承担一项责任**。

如果一个类或对象承担了太多的责任，则其中一个责任的变化可以带来对其他责任的影响，且不利于代码复用，容易造成代码的冗余和浪费。

遵守单一职责原则设计的程序有以下几个特点：

- 降低类的复杂度。
- 提高代码的可读性，可复用性。
- 增强代码的可维护性和可拓展性。
- 将变更带来的影响降到最低。

```swift
class UserInterface {
    var data: String?
    
    func loadBannerData() {
        self.bannerData = "横竖数据加载完成"
    }
    
    func loadListData() {
        self.listData = "列表数据加载完成"
    }
    
    func show() {
        self.loadData()
        print("展示界面：\(self.bannerData!),\(self.listData)")
    }
}


let ui = UserInterface()
ui.show()
```

UserInterface承担了两个责任，分别是加载数据和展示界面，违反了单一职责原则。如果对数据加载的逻辑进行修改必然需要修改展示逻辑。

```swift
class DataLoader {
    var bannerData: String?
    var listData: String?
    
    func loadBannerData() {
        self.bannerData = "横竖数据加载完成"
    }
    
    func loadListData() {
        self.listData = "列表数据加载完成"
    }
    
    func getData() -> String {
        self.loadBannerData()
        self.loadListData()
        return "\(self.bannerData!),\(self.listData)"
    }
}

class UserInterface {
    func show() {
        print("展示界面：\(DataLoader().getData())")
    }
}
```

### 3.4 接口隔离原则（Interface Segregation Principle, ISP）

接口隔离原则要求编程人员将庞大臃肿的接口拆分成更小和更具体的接口。

### 3.5 依赖倒置原则（Dependence Inversion Principle,DIP）

依赖倒置原则的定义：**高层模块不应该依赖底层模块，两者都应该依赖其抽象；抽象不应该依赖细节，细节应该依赖抽象**

有如下优势：
- 由于都对接口进行依赖，因此减少了类之间的耦合。
- 封闭了对类实现的修改，增强了程序的稳定性。
- 面向接口开发，减少了并行开发的依赖于风险。
- 提高代码的可读性和可维护性。

### 3.6 迪米特原则

又叫最少知道原则。比如，如果一个类需要使用多个类的功能，可以封装一个manager分别调用不同的功能，而不需要知道具体的实现细节。

### 3.7 合成复用原则

合成复用原则的核心为在设计类的复用时，要尽量先使用组合或聚合的方式设计，尽少的使用继承。

## 4. 创建型设计模式

### 4.1 单例设计模式

类只能有一个实例，这就是单例设计模式的核心定义。

## 5.总结

### 5.1 7种基本设计原则
- 1、开闭原则：软件设计的终极目标，对扩展开放，对修改关闭。
- 2、里氏替换原则：子类可以扩展父类的方法，但是不要修改父类原有方法的行为。
- 3、依赖倒置原则：面向协议编程，尽量依赖抽象。
- 4、单一职责原则：降低类的复杂度，一个类只负责一项职责。
- 5、接口隔离原则：精简接口，一个接口只负责一项职责。
- 6、迪米特原则：简化类之间的交互，使用中介统一处理。
- 7、合成复用原则：使用组合或聚合代替继承。

### 5.2 23种经典设计模式

#### 5.2.1 创建型设计模式

- 1、单例模式：全局共享数据的最佳实践。
- 2、原型模式：快速复制对象的便捷途径。
- 3、工厂方法模式：将对象的创建和使用进行隔离。
- 4、抽象工厂模式：提供一组接口创建不同类别的产品的实现方法。
- 5、建造者模式：拆分复杂对象为多个简单对象进行创建。

#### 5.2.2 结构型设计模式

- 6、代理模式：使用中介处理对象间的交互。
- 7、适配器模式：新旧接口不兼容时的安全处理方案。
- 8、桥接模式：使用组合代替继承，将抽象与实现分离。
- 9、装饰模式：不改变原始行为的前提下对类的功能进行扩展。
- 10、外观模式：使用统一的外观接口处理类之间一对多的交互逻辑。
- 11、享元模式：创建大量重复对象的优化方案。
- 12、组合模式：部分与整体提供统一的功能接口。

#### 5.2.3 行为型设计模式

- 13、模板方法模式：定义算法骨架的前提下允许对关键环节的算法实现做修改。
- 14、策略模式：定义一系列方便切换的算法实现。
- 15、命令模式：将操作封装为命令对象。
- 16、责任链模式：通过责任链对请求进行处理，隐藏处理请求的对象细节。
- 17、状态模式：将变化的属性封装为状态对象进行统一管理。
- 18、观察者设计模式：通过监听的方式处理对象间的交互逻辑
- 19、中介者模式：通过定义中介者来将网状结构的逻辑改为星型结构。
- 20、迭代器模式：提供一种访问对象内部集合数据的接口。
- 21、访问者模式：将数据的操作与数据本身分离。
- 22、备忘录设计模式：通过快照的方式存储对象的状态。
- 23、解释器设计模式：通过编写解释器对自定义的简单语言进行解析，从而实现逻辑。
- 