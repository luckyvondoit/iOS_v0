# iOS包体积优化实战-无脑瘦身篇

## 前情提要

**团队现在正在维护更新一款之前团队遗留下来的App，后来我们接手之后，又是一顿新功能添加，再加上之前老代码是用OC写的，我们接手之后用的是Swift，所以现在的包体积可想而知啊。。。简直惨不忍睹。**

![](./imgs/1.jpg)

**哈哈，323MB，包体积越大，我们的可优化幅度就越大。**

**之前因为赶新功能的业务代码，所以一直没得空去优化包体积。上周打包给测试，又看到这300多MB的安装包，实在是不能忍了，赶紧着手优化了一波。**

## 方案选取

**我们本身的代码优化方面的肯定是自身最清楚的，比如哪些功能是已经不用了，哪些代码是无效代码，哪些图片是无用图片，那这些肯定就是我们优化的第一步。**

**优化之前也顺便翻了一下业界的优化方案，汲取了一些好的优化思路，pick了一些好用的软件、好用的脚本。下面罗列一些业界的优化方案。虽然，我目前还只是在删除一些无用图片和无用代码，但效果已然显著。**

* 无用图片删除
* 无用代码删除
* 图片压缩（无损、有损 两种方案，未实践，效果未知）
* 图片放到云端（自己的云服务器、Apple的On-Demand Resources 两种方案，未实践，效果未知）
* 代码优化（重复方法合并，工作量大）
* Bitcode（似乎只在Appstore有效）

**我目前还只是在无用资源的删除阶段，且还未完全完成，但目前看下来效果还是很显著的，先放一张半优化后的包体积截图。优化了接近62MB，当然这跟我们之前没有优化过有关，且我们代码中确实有很多无用功能，现在不用了么，当然就可以删了。**

![](./imgs/2.jpg)

## 进入实战

### 第一步 删除无用图片

**我们删除无用图片，用[LSUnusedResources](https://github.com/tinymind/LSUnusedResources) ，筛选条件可以直接用默认的，填入自己的工程路径就可以用了，很方便。**

![](./imgs/3.png)

### 第二步 删除无用代码

**删除无用代码，这是一个循序渐进的过程，我们首先要确保的是工程可运行，不能根据我们的经验，知道这部分代码不用了，就直接删了，那样，报错信息会让你奔溃的。**

**其实，我们首先要删的是根本没有import的文件，推荐一个工具，[fui](https://github.com/dblock/fui) ，它可以帮助我们找到并且删除没有import的文件，用命令行工具操作，常用的命令行有两个。我们通过ignore-path来忽略搜索目标路径，一般忽略Pods和我们直接引进来的三方库路径.**

```
fui -x --path=/Users/zsy/LaiPlus  --ignore-path=Pods --ignore-path=LaiApp_Swift/AliyunApiClient find
fui -x --path=/Users/zsy/LaiPlus  --ignore-path=Pods --ignore-path=LaiApp_Swift/AliyunApiClient delete --perform --prompt
复制代码
```

**这两个命令，一个是寻找，一个是删除，当然删除的时候最好加上--perform --prompt，这样会有确认提示。就像下图这样，我们通过输入 Y or N 来确认是否删除。**

![](./imgs/4.png)

**删除这一步，我们需要反复执行，因为某些文件删除之后，又会出现一些新的没有import的文件。**

**Tips1：这里的删除操作，xib文件不会删除，所以xib文件还需要我们自己手动去删除。** **Tips2：storyboard有引用的话，库会认为有引用，所以storyboard需要手动删除。**

### 第三步 删除Project文件

**无用代码删除后，我们删的是finder里面的真实文件，但Xcode里面的Project文件还有虚色或者红色文件，直接运行是会报错的。所以我们还要把project的文件也要一并删掉，这里如果手动去删，还是蛮麻烦的，所以我去群里请教了一下，果不其然，真有大佬现场撸了一个简易版本的Ruby脚本，但是需要安装Cocoapods的[Xcodeproj](https://github.com/CocoaPods/Xcodeproj) ，这个简易脚本一开始有点坑到我了，哈哈，也怪我拿来主义，初期脚本长这样。**

```
require 'xcodeproj'

project_path = '/Users/zsy/LaiPlus/LaiApp_OC.xcodeproj'

def remove_reference_from_project(reference, project)
  project.targets.each do |target|
    target.remove_reference(reference)
  end
end

project = Xcodeproj::Project.open(project_path)

project.files.each do |file|
  file_path = (file.real_path)

  unless File.exists?(file_path)
      file.remove_from_project
  end
end

project.save
复制代码
```

**结果把我的Framework都删了，还有之前工程引用的一些tbd文件，当然还有.app文件，误删之后会出现build成功，但不会run程序，虽然可以在executable那里直接指定，但不会自动run了，当时我就预感我把project误删了，重新审视了一遍脚本，project修改回退，自己手动打印了一下，证实了我的猜测，所以修改后的脚本长这样。**

```
require 'xcodeproj'

project_path = '/Users/zsy/LaiPlus/LaiApp_OC.xcodeproj'

def remove_reference_from_project(reference, project)
  project.targets.each do |target|
    target.remove_reference(reference)
  end
end

project = Xcodeproj::Project.open(project_path)

project.files.each do |file|
  file_path = (file.real_path)

  unless File.exists?(file_path)
    suffix_path = File.basename(file_path)

    unless suffix_path.include?(".framework") | suffix_path.include?(".app") | suffix_path.include?(".tbd")
      file.remove_from_project
    end
  end
end

project.save
复制代码
```

**把我们不需要删的文件后缀判断一下，完美删除。**

### 第四步 删除有引用的代码

**前面删除完之后，你肯定发现，还是有一些无用代码没删掉，因为互相import了，导致库认为我们有使用，所以我们需要帮库找到最顶层的import的代码，把它删掉，比如：A引用了B,B引用了C，C引用了A，这种初期设计的时候不合理导致的强耦合性，我们必须要自己打破循环，当然接下来就还是fui库来帮我们做之后的删除操作。**

### 反复核对、删除

**其实上面的删除操作都是需要反复操作，核对的，无用代码删除之后，应该又会产生一些无用图片，所以回过头来还要再把那些无用图片删掉。第四步的打破循环也是一个体力活，但因为我们的老代码都在一个目录下，所以这个过程也可以接受，主要是可操作。**

## 总结

**目前的优化还在继续，且还未进行到图片压缩过程，目测无用代码和无用图片还能优化几十MB，应该能优化到200MB左右，具体能优化到多少，后面还会出文章分享。总结一句，删除无用代码的过程切勿操之过急，Git提交频繁一些没关系，但要确保每一次提交的代码都是可运行的，一点点删，别怕慢，因为有时候一把删的过多，就回不了头了。。。哈哈，别问我为什么，问了我也不说。**


# iOS包体积优化-图片压缩

## 前言

**上一篇[iOS包体积优化实战-无脑瘦身篇](https://juejin.im/post/6861976679586201614) 实践下来，确实优化效果显著，后来又删了一些无用代码和无用图片，到最后打出来的dev包大概240M左右。那接下来就是参考业界图片压缩方案了。本篇从实践角度来给大家做一下前车之鉴😂😂😂**

## 一、分析图片占用大小

**优化之前，肯定要先分析一下我们的包那么大，那到底图片占了多大，对吧？要是图片只占了一点点，那就算全删了也没优化多少。**

**解压ipa包，查看包内容，找到Assets.car，可以看到，确实很大。**

![](./imgs/5.png)

**但这里有一个奇怪的点，也是问了好多同学，也没有完全解答清楚。** 

![](./imgs/6.png)

**可以看到，我们把Assets.car解压之后，其实文件大小总共就只有50Mb左右，为什么苹果经过处理之后，变成Assets.car的包变成了200Mb，接近4倍，**

**[developer.apple.com/forums/thre…](https://developer.apple.com/forums/thread/108799)有人似乎也有这种疑问，但Apple认为这是预期的行为。他们针对特定操作系统版本进行了优化。当最终应用程序被精简后，将仅显示必需的内容。简单来讲就是，App Store下载后，包应该是精简过的。** 

![](./imgs/7.png)

**但我们的dev测试包没办法精简啊😳😳😳。。。尴尬**

## 二、Assets文件夹分析

**看一下我们解压后的Assets文件夹里面的文件，可以看到都是1x、2x图，3x图呢？我也不知道。。。应该跟我打得是dev包有关，猜想到appstore的话，应该会根据机型下发不同分辨率的图，这应该就是前面所说的，Assets帮我们做的事情。** 

![](./imgs/8.png)

**分析过程中发现了一些问题，比如说jpg放在Asset里面，apple会帮我们转换成png，当jpg本身很大的时候，转出来的png会更大，之前美图的文章是说59k的jpg转出来就是185k的png了（但其实不是说跟大小有关，后续会用数据说明），其实png也一样，先看下图，同一张png图片，Assets之后，变大了好多好多。**

![](./imgs/9.png)

![](./imgs/10.png)

**但也有不会变大的，上图就显示没有变大。之前业界的结论是说，Assets里面最好不要放超过100kb的图，加载的时候会有缓存，不禁怀疑那难道图片过大，苹果的压缩算法还会导致图片变大？立马搜索看有没有大图没有变大的情况，被我找到了🤣🤣🤣。。。想来苹果的算法也不会那么菜啊，哈哈。**

![](./imgs/11.png)

**那就应该是跟图片本身有关了，但图片大小涉及到的因素有很多，我们又不是专门研究这个的，所以无从分析啊。那不管怎么说，我们还没尝试图片压缩方案呢，作为实践派，先试上一试。**

## 三、ImageOptim压缩

**[ImageOptim](https://github.com/ImageOptim/ImageOptim) 是一款开源的图片压缩工具，压缩比例可以自己调，我用的无损压缩。**

**我先用ImageOptim压缩那张会变大的图片，确实效果不明显，但不会像苹果的压缩算法那样直接变大，所以两种做法应该还是有区别的，苹果不单单是做了压缩，应该还做了其他处理，主要是为了商店下载版本的包优化。**

![](./imgs/12.png)

**那接下来就是尝试全部压缩一遍，然后打包上传，可以看到最终结果还是很喜人的，节省了12.8MB。**

![](./imgs/13.png)

**当美滋滋开始打包，喝杯茶，准备深藏功与名的时候，现实给了我一记狠狠的闷棍。包的大小并没有改变，还是跟原来一样大小，我很痛苦但又不得不承认的验证了之前[头条](https://www.jianshu.com/p/a3151dfebc9c) 的结论。头条说自己用ImageOptim压缩后再用苹果的Assets，没有效果，很有可能反而会使包增大。** 

![](./imgs/14.png)

**虽然[美图的文章](https://juejin.im/entry/6844903709860691976) 是持相反态度的，但基于什么原因，文章也没有详说。目前我验证下来的结果确实是，用ImageOptim压缩Assets是没有效果的。**

**那至于还有想压缩Assets的想法的话，大家可以把头条的那篇文章读完，人家本着no zuo no die的精神踩了很多坑，最终压缩这条路已经无路可走，最后从tint color这个角度入手，开始实施精简图片，可以想见，这个工程并不小，但确实是一个具体的优化方向。**

**当然还有一个方法是图片放云端，可以是自己的云端，也可以是苹果的云端，如果放在苹果的云端，我们只能TestFlight测试了，目前看下来有风险且不易测试，如果业务场景适合放云端的话，这也是一种优化策略。**

## 四、总结

**那目前实践下来，苹果对Assets压缩的过程做了自己独特的处理，想要人为的改变这一过程，是不被苹果允许的，有时候可能还会出现反效果，那我们能做的是什么呢？**

* 项目开发前，需要制定规则，图片大小尽量不能大于某一临界值，这样UI设计师也会保持敏感度
* 项目开发过程中，开发人员也要对UI提供的切图大小保持敏感，怕麻烦的可以编写一个脚本，定一个临界值，当大于这个临界值的时候告警
* 项目开发结束，肯定会出现一些无用图片资源，尽快删除
* 当项目涉及到白天黑夜模式切换，尽量采用头条的方案，用改变tint color的方式实现切换效果
* 方案设计之初，哪些图片可以放云端需要充分讨论，这比我们后期哼哧哼哧的去做优化可简单太多了(当然你们要是用这个做绩效，当我没说😂😂😂 )


## Reference

* [iOS包体积优化实战-无脑瘦身篇](https://juejin.im/post/6861976679586201614)
* [iOS包体积优化-图片压缩](https://juejin.im/post/6877000471932829704)