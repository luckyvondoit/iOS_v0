# iOS-离屏渲染详解
![](Off-ScreenRendering/1315383-77c50d6b97205e4b.png)
> 引言: 一款优秀的app,流畅很关键,用户使用60的fps的app,跟使用30的fps的app感受是完全不一样的.类似于 **半糖** 这种优秀的应用肯定花了大把精力去优化界面.网上关于优化的界面的文章一搜一大把.本文并不是讲界面优化的,优化的话推荐下面几篇文章;  

[YYKit作者: "iOS 保持界面流畅的技巧"](http://blog.ibireme.com/2015/11/12/smooth_user_interfaces_for_ios/) (我相信认真看一定有收获!)

[离屏渲染的优化](https://www.jianshu.com/p/ca51c9d3575b) (这篇文章很强)

[jim: 浅谈iOS中的视图优化](http://kuailejim.com/2016/04/22/%E6%B5%85%E8%B0%88iOS%E4%B8%AD%E7%9A%84%E8%A7%86%E5%9B%BE%E4%BC%98%E5%8C%96/)

有些东西研究起来挺费劲的.但是想要更多的收获,还真就必须得研究.知识零零散散,时间久了再次用起来难免会生疏,又得重新找资料,看文章.很麻烦.索性就整理个比较全面的知识点供以后复习.

1. On-Screen Rendering (当前屏幕渲染)

1. 指的是GPU的渲染操作是在当前用于显示的屏幕缓冲区进行.

2. Off-Screen Rendering (离屏渲染)

2. 指的是在GPU在当前屏幕缓冲区以外开辟一个缓冲区进行渲染操作.

> 几个名词 "GPU" " 缓冲区" .  

不知道GPU的就自行百度吧 (- - 宝宝说不清). 说下缓冲区.要明白缓冲区,首先就得要知道图像显示出来的原理,本文的第一篇博客里面介绍的很详细. 显示器 显示出来的图像是经过 CRT电子枪一行一行的扫描.(可以是横向的也可以是纵向 ,具体CRT电子枪又是什么,百度文库介绍的很详细.),扫描出来就呈现了一帧画面,随后电子枪又会回到初始位置循环扫描,为了让显示器的显示跟视频控制器同步,当电子枪新扫描一行的时候.准备扫描的时候,会发送一个 水平同步信号(HSync信号),而当一帧画面绘制完成后,电子枪回复到原位，准备画下一帧前，显示器会发出一个垂直同步信号（vertical synchronization简称 VSync），显示器一般是固定刷新频率的,这个刷新的频率其实就是VSync信号产生的频率. 然后CPU计算好frame等属性,就将计算好的内容提交给GPU去渲染,GPU渲染完成之后就会放入帧缓冲区,然后视频控制器会按照VSync信号逐行读取帧缓冲区的数据,经过可能的数模转换传递给显示器.就显示出来了.

原理图就不放了,过一遍概念.

离屏渲染的代价很高,想要进行离屏渲染,首选要创建一个新的缓冲区,屏幕渲染会有一个上下文环境的一个概念,离屏渲染的整个过程需要切换上下文环境,先从 当前屏幕切换到离屏,等结束后,又要将上下文环境切换回来.这也是为什么会消耗性能的原因了.
。由于垂直同步的机制，如果在一个 VSync 时间内，CPU 或者 GPU 没有完成内容提交，则那一帧就会被丢弃，等待下一次机会再显示，而这时显示屏会保留之前的内容不变。这就是界面卡顿的原因。

> 那有个问题: 为什么离屏渲染这么耗性能,为什么有这套机制呢?  

当使用圆角，阴影，遮罩的时候，图层属性的混合体被指定为在未预合成之前(下一个VSync信号开始前)不能直接在屏幕中绘制，所以就需要屏幕外渲染。 你可以这么理解. 老板叫我短时间间内做一个 app.我一个人能做,但是时间太短,所以我得让我朋友一起来帮着我做.(性能消耗: 也就是耗 你跟你朋友之间沟通的这些成本,多浪费啊).但是没办法 谁让你做不完呢.
这么一讲会不会比较明白点.

官方公开的的资料里关于离屏渲染的信息最早是在 2011年的 WWDC， 在多个 session 里都提到了尽量避免会触发离屏渲染的效果，包括：mask, shadow, group opacity, edge antialiasing。

* shouldRasterize（光栅化）

* masks（遮罩）

* shadows（阴影）

* edge antialiasing（抗锯齿）

* group opacity（不透明）

* 复杂形状设置圆角等

* 渐变

* Text（UILabel, CATextLayer, Core Text, etc）...

> **介绍一些属性.**  

* shouldRasterize（光栅化）: 将图转化为一个个栅格组成的图象。 光栅化特点：每个元素对应帧缓冲区中的一像素。
>   

`shouldRasterize = YES` 在其它属性触发离屏渲染的同时,会将光栅化后的内容缓存起来,如果对应的 `layer` 或者 `sublayers` 没有发生改变,在下一帧的时候可以直接复用,从而减少渲染的频率.
当使用光栅化是, 可以开启 "Color Hits Green and Misses Red"来检查该场景下是否适合选择光栅化,绿色表示缓存被复用,红色表示缓存在被重复创建.对于经常变动的内容,不要开启,否则会造成性能的浪费.

如果cell里面的内容不断变化(cell的复用),如果设置了 `cell.layer.shouldRaseterize = YES` 则会降低图形性能,造成离屏渲染.

mask是layer的一个属性.

```
/ A layer whose alpha channel is used as a mask to select between the
 * layer's background and the result of compositing the layer's
 * contents with its filtered background. Defaults to nil. When used as
 * a mask the layer's `compositingFilter' and `backgroundFilters'
 * properties are ignored. When setting the mask to a new layer, the
 * new layer must have a nil superlayer, otherwise the behavior is
 * undefined. Nested masks (mask layers with their own masks) are
 * unsupported. */

@property(nullable, strong) CALayer *mask;
```

大概的意思. 当透明度改变的时候,这个 mask 就是覆盖上去的那个阴影.该层的layer的alpha决定了多少层背景跟内容通过并显示,完全,或者部分不透明的像素允许潜在的内容 通过并显示. 默认是nil,当配置一个 遮罩的时候,记得设置 遮罩的大小,位置.已确保跟盖图层对齐.(这是官方文档说的 如果不对齐会怎样.you can try. 我试过是只能显示对齐的那一部分.)

如果你想给这个属性赋值,前提是必须没有 superLayer,如果有superLayer,这个行为则是无效的.(你也可以尝试一下反的.)

> tip:用mask可以做一些转场动画.这里就不介绍了.  

那说了这么多,他就是生来会触发离屏渲染的.所以要谨慎 设置透明度. 提到透明度,另外补充一个概念.)

Color Blended Layers
用jim的话来介绍它就是

> 屏幕上的每个像素点的颜色是由当前像素点上的多层layer(如果存在)共同决定的，GPU会进行计算出混合颜色的RGB值，最终显示在屏幕上。而这需要让GPU计算，所以我们要尽量避免设置alpha，这样GPU会忽略下面所有的layer，节约计算量。再提一下opaque这个属性，网上普遍认为view.opaque = YES，GPU就不会进行图层混合计算了。而这个结论是错误的，其实view.opaque事实上并没什么卵用。  
> 如果你真的想达到这个效果，可以用layer.opaque,这个才是正确的做法  

* shadows(阴影.)
* 略过.... (自己可以随便尝试一下)
>   

再介绍一下edge antialiasing（抗锯齿) 这个吧. 因为之前自己也没接触过,很多人估计也是没接触过吧.

177286BA-E7BE-4CFE-B992-AF18B30FE1DE.png

翻译:

是否允许执行反锯齿边缘。
默认的值是 NO.(不使用抗锯齿,也有人叫反锯齿),当 Value 为YES的时候, 在layer的 edgeAntialiasingMask属性layer依照这个值允许抗锯齿边缘,(参照这个值) 可以在info.plist里面开启这个属性.

0068582C-92E8-4A80-AAD8-C89E22668964.png

放一个 plist 常见的key值表 [info.plist配置表](http://blog.csdn.net/jeffasd/article/details/50800728) (楼主真的好...)

说了这么多. 那抗锯齿又是啥????

[抗锯齿的概念](http://baike.baidu.com/link?url=5Upxs3_02CY_6aZKArxN2jOFDhGhq-vUfYHs0q8VOCKGHd0nAWxdnYRsip0FbnOJr7fNqpS-gIh1fe_78oFuda) (随便看看.)
在我们iOS中表现 [参考这里](http://www.cocoachina.com/ios/20150901/13300.html)

```
CALayer *layer = [CALayer layer]; 
    layer.position = CGPointMake(100, 100);
    layer.bounds = CGRectMake(0,0, 100, 100);
    layer.backgroundColor = [UIColor redColor].CGColor;
    //layer.allowsEdgeAntialiasing = YES;
    [self.view.layer addSublayer:layer];
```

正常添加layer 在view上是这样的.

模拟器不旋转.png

下一步.

```
CGFloat angle = M_PI / 30.0;
[layer setTransform:CATransform3DRotate(layer.transform, angle, 0.0, 0.0, 1.0)];
```

在模拟器表现是这样的.

模拟器NO.png

如果 layer.allowsEdgeAntialiasing = YES;

--- 在模拟器上是

模拟器YES.png

--- 在真机上.

真机YES.png

可见真机效果跟模拟器还是有差距的,(模拟器边缘比真机模糊,)官方文档也有提到这点

> Use antialiasing when drawing a layer that is not aligned to pixel boundaries. This option allows for more sophisticated rendering in the simulator but can have a noticeable impact on performance.  

这是UIView的抗锯齿,在模拟器上还是有性能的消耗的.

看看效果就行,具体的不研究太多了,知道怎么避免就行.

组不透明.png

大概的意思就是 这个属性决定了Core Animation框架下 子layers从他们Superlayer.继承过来的不透明度. iOS 6之前是默认NO,iOS7以后就默认 是YES. 文档也是说可以在模拟器上呈现.但是对性能有明显的影响.

这里我就不测试了.这个属性过一遍,重点是下一个属性.

我们在开发中经常会对一些图片或者按钮进行圆角处理,需求还是特别多的,设置圆角有多种方法,我列一下常见的方式.

1. 设置layer层的圆角大小.经常我们还会设置masksToBounds,

```
//按正方形来算.长的一半就是半径.按照这个去设置就是圆角了,长方形的话则按短的那一边
_imageView.layer.cornerRadius = iamgeView.width/2;
_imageView.layer.masksToBounds = YES;
```

这样做对于少量的图片，这个没有什么问题，但是数量比较多的时候,UITableView滑动可能不是那么流畅，屏幕的帧数下降，影响用户体验。

1. 使用layer的mask遮罩和CAShapLayer
1. 创建圆形的CAShapeLaer对象,设置为View的mask属性,这样也可以达到圆角的效果,但是前面提到过了,使用mask属性会离屏渲染,不仅这样,还曾加了一个 CAShapLayer对象.着实不可以取.

2. 使用带圆形的透明图片.(求个切图大师 - - ).

3. CoreGraphics自定义绘制圆角.

提到CoreGraphics,还有一种 特殊的"离屏渲染"方式 不得不提,那就是drawRect方法.触发的方式:
如果我们重写了 drawRect方法,并且使用CoreGraphics技术去绘制.就设计到了CPU渲染,整个渲染,由CPU在app内同步完成,渲染之后再交给GPU显示.(这种方式对性能的影响不是很高)

> tip：CoreGraphic通常是线程安全的，所以可以进行异步绘制，然后在主线程上更新.  

```
- (void)display {
   dispatch_async(backgroundQueue, ^{
       CGContextRef ctx = CGBitmapContextCreate(...);
       CGImageRef img = CGBitmapContextCreateImage(ctx);
       CFRelease(ctx);
       dispatch_async(mainQueue, ^{
           layer.contents = img;
       });
   });
}
```

* 之前看了一些文章说在intruments里面的 CoreAnimation里面有工具.检测.(没找着.求补充)

打开的正确方式:
模拟器的 debug -> 选取 color Offscreen-Rendered.

BB55F33F-97CC-4C28-B3F1-22456A2A7BD8.png

开启后会把那些需要离屏渲染的图层高亮成黄色，这就意味着黄色图层可能存在性能问题。

正常:是这样的

正常渲染.png

有问题的图层:

调试.png

可以看见我设置了圆角的imageView有问题.

### 项目开发中怎么去处理?

> 抛出一个问题: 需求就是有很多圆角那我们项目中应该怎么去处理圆角呢?  

1. 使用 [YYWebImage去处理](https://www.jianshu.com/p/60cd5f8bb4cb)
2. [iOS中圆角图片的处理](https://www.jianshu.com/p/82e68984711f)

相信看完两篇文章,多少都会能收获一点!

> 有些人说:  

iOS 9.0 之后UIButton设置圆角会触发离屏渲染，而UIImageView里png图片设置圆角不会触发离屏渲染了，如果设置其他阴影效果之类的还是会触发离屏渲染的(这句话不知道谁说的.自己有没有去尝试呢???)

结论: 经过测试

70915C7C-7523-4008-9A88-B5682407926D.png

大家可以看到,
UIButton 的 masksToBounds = YES下发生离屏渲染与 背景图存不存在有关系, 如果没有给按钮设置 `btn.image = [UIImage imageName:@"xxxxx"];` 是不会产生离屏渲染的 .

关于 UIImageView,现在测试发现(现版本: iOS10),在性能的范围之内,给UIImageView设置圆角是不会触发离屏渲染的,但是同时给UIImageView设置背景色则肯定会触发.触发离屏渲染跟 png.jpg格式并无关联(可能采取的压缩格式不同,这里不做探讨,这里我给出结果是没有关系)

* 对于网上一些文章得出的结论,我觉得大家得理性分析,并不是每个人都是对的,只有经过自己实践才能得出较好的定论.本文也是,我希望哪里有理解错或者其它什么错误请提出(认真脸.),人无完人,我希望在学习的道路上能碰见更多一起进步的人!

[iOS-离屏渲染详解](https://www.jianshu.com/p/57e2ec17585b)