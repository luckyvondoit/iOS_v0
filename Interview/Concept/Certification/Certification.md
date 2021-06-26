# iOS证书背后的原理

在日常的 iOS 开发中，无论是新手还是老鸟，总是会遇到各种与证书、签名有关的问题。当不了解其中的具体原理时，我们总是会被这些问题整得焦头烂额。对于我也是如此，为了彻底理清其中的原理，我花了一些时间进行了研究并整理出这篇文章以供后续进行参考。

# 基本概念

iOS 开发中各种证书的核心就是 **非对称加密技术**（即 **公钥/私钥加密技术**）。关于非对称加密的原理，本文不作介绍。

为了深入了解证书幕后的原理，我们需要了解两个关键的概念：

- **数字签名**
- **数字证书**

## 数字签名

**数字签名（Digital Signature）** 是一种相当于现实世界中的盖章、签字的功能在数字信息领域中的实现。数字签名可以识别篡改和伪装。

在数字签名技术中，有两种行为：

- **签名生成**
- **签名验证**

### 签名生成

签名生成由通信中的发起方进行，其过程如下所示。首先对通信内容进行哈希，然后使用发送放的私钥进行加密，最终得到签名。

[![img](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/sketch-images/signature-creation.png?x-oss-process=image/resize,w_800)](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/sketch-images/signature-creation.png?x-oss-process=image/resize,w_800)

### 签名验证

签名验证由通信中的接收方进行，其过程如下所示。一般而言，发送方会把 **消息**、**签名** 一起发送给接收方。接收方首先使用发送方的公钥对签名进行解密，计算得出一个摘要。然后使用消息进行哈希，计算得出另一个摘要。最后，判断两个摘要是否相等，如果相等则说明接收到的消息没有被第三方进行篡改。

[![img](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/sketch-images/signature-validation.png?x-oss-process=image/resize,w_800)](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/sketch-images/signature-validation.png?x-oss-process=image/resize,w_800)

那么接收方是如何获取到发送方的公钥的呢？接收方又是如何确定该公钥就是属于发送方的呢？这就是数字证书要做到事。

## 数字证书

**数字证书（Digital Certificate）** 是一种相当于现实世界中身份证的功能在数字信息领域中的实现。数字证书包含了个人或机构的 **身份信息** 及其 **公钥**，因此也称为 **公钥证书（Public-Key Certificate，PKC）**。

[![img](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/blog-images/my-certificate-example.png?x-oss-process=image/resize,w_800)](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/blog-images/my-certificate-example.png?x-oss-process=image/resize,w_800)

类似于身份证是由权威的公安局颁发，公钥证书也是由权威的 **认证机构（Certificate Authority，CA）** 颁发。认证机构向接收方提供发送方的证书，证书中包含了发送方的身份信息和公钥。为了防止证书在颁发过程中被篡改，认证机构会将身份信息和公钥作为消息，用 **CA 私钥** 进行签名，进而将 **身份信息**、**公钥**、**签名** 一起放入证书，如下图所示。

[![img](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/sketch-images/certificate.png?x-oss-process=image/resize,w_800)](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/sketch-images/certificate.png?x-oss-process=image/resize,w_800)

## 根证书

接收方得到发送方证书时，通过 CA 公钥对证书进行签名验证。

[![img](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/sketch-images/certificate-validation.png?x-oss-process=image/resize,w_800)](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/sketch-images/certificate-validation.png?x-oss-process=image/resize,w_800)

不过，需要注意的是，很多情况下，CA 公钥则又是由一个更加权威的机构颁发。

类似于地方公安局的证书是由市级公安局颁发，市级公安局的证书又是由省级公安局颁发。证书是具有信任链（Chain of Trust）的，**根证书（Root Certificate）** 是信任源，即信任链的起源。

根证书的颁发者被称为 **Root Certificate Authority（Root CA）**。某一认证领域内的根证书是 Root CA 自行颁发给自己的证书（Self-signed Certificate），安装证书意味着对这个 CA 认证中心的信任。

根据证书在信任链中所处的位置，可以将证书分为三种：

- **根证书（Root Certificate）**
- **中间证书（Intermediate Certificate）**
- **叶子证书（Leaf Certificate）**

这里就有一个根本性的问题：**如何保证根证书是可信的？**

事实上，根证书都是随软件一起安装的，如：操作系统安装时会内置一份可信的根证书列表。

# iOS 证书

在介绍了数字签名（包括：签名生成、签名验证）和数字证书（根证书）的基本概念之后，我们现在来介绍 iOS 开发中的相关证书。

首先，我们来看一下 MacOS 系统中关于 iOS 开发证书的信任链示例（通过“钥匙串”查看）：

- Apple Root Certificate Authority

  ：根证书

  - Apple Worldwide Developer Relations Certification Authority

    ：中间证书

    - **iPhone Developer: 楚权 包(XXXXXXX)**：叶子证书
    - **iPhone Distribution: Apple Tech**：叶子证书
    - **Apple Development: baocq@apple.com**：叶子证书

[![img](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/blog-images/keychain-trust-of-chain.jpeg?x-oss-process=image/resize,w_1000)](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/blog-images/keychain-trust-of-chain.jpeg?x-oss-process=image/resize,w_1000)

根证书 `Apple Root Certificate Authority` 是在 MacOS 操作系统安装时内置的，是 Apple Root CA 自行颁发的。

中间证书 `Apple World Developer Relations Certificate Authority` （实际文件为 `AppleWWDRCA.cer`）是在Xcode 安装时内置的，是 Apple Root CA 颁发的。虽然 `AppleWWDRCA.cer` 是中间证书，但是对于 iOS 开发分类来说，它就是 **开发根证书**。

我们开发所使用的证书都是叶子证书，是 Apple Worldwide Developer Relations Certification Authority 颁发的。

那么，我们开发所示用的证书是如何生成的呢？下面我们来介绍一下如何申请开发证书。

## 申请原理

下图所示，是证书申请的基本原理，可分为以下几个步骤：

- 开发者在本地生成密钥对，并提供开发者的身份信息。
- 将密钥对中的公钥、身份信息发送给 CA。
- CA 使用 CA 私钥对开发者的公钥、身份信息进行签名。
- CA 将开发者的公钥、身份信息、签名组装成证书以供下载。

[![img](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/sketch-images/certificate-creation.png?x-oss-process=image/resize,w_800)](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/sketch-images/certificate-creation.png?x-oss-process=image/resize,w_800)

## 申请方法

上述介绍 iOS 开发证书的申请原理。在 iOS 开发中，一般由两种申请方法：

- **CertificateSigningRequest**
- **Xcode 自动申请**

下面我们依次进行介绍。

### CertificateSigningRequest

首先，通过 “钥匙串” 菜单栏选择 【从证书颁发机构请求证书…】。

[![img](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/blog-images/certificate-creation02.png?x-oss-process=image/resize,w_800)](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/blog-images/certificate-creation02.png?x-oss-process=image/resize,w_800)

其次，填写用户的身份信息（电子邮箱），并勾选【存储到磁盘】。点击【继续】后将会保存一个 `CSR` 文件（`CertificateSigningRequest.certSigningRequest`）至本地。

注意，这个过程期间会生成一对非对称密钥对，`CertificateSigningRequest.certSigningRequest` 本质上包含了 **开发者信息**和 **公钥**。**私钥** 则始终保存在开发者的 Mac 中。

[![img](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/blog-images/certificate-creation03.png?x-oss-process=image/resize,w_800)](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/blog-images/certificate-creation03.png?x-oss-process=image/resize,w_800)

然后，在开发者网站（扮演了 AppleWDRCA 的角色）上传 `CSR` 文件，由 CA 进行签名并生成开发者证书。开发者证书始终保留在开发者网站上，开发者可以删除（Revoke）已注册的证书。

[![img](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/blog-images/certificate-creation04.png?x-oss-process=image/resize,w_800)](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/blog-images/certificate-creation04.png?x-oss-process=image/resize,w_800)

最后，从开发者网站上下载开发者证书至 Mac，双击后即可安装。

### Xcode 自动申请

通过，Xcode 菜单【Preference…】->【Account】->【Apple IDs】->【＋】，登录开发者账号。

[![img](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/blog-images/certificate-creation05.png?x-oss-process=image/resize,w_800)](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/blog-images/certificate-creation05.png?x-oss-process=image/resize,w_800)

登录成功后，“钥匙串”会自动导入一份证书（包含一份密钥对）。开发者网站也会注册一份证书。

[![img](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/blog-images/certificate-creation07.png?x-oss-process=image/resize,w_800)](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/blog-images/certificate-creation07.png?x-oss-process=image/resize,w_800)

[![img](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/blog-images/certificate-creation06.png?x-oss-process=image/resize,w_800)](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/blog-images/certificate-creation06.png?x-oss-process=image/resize,w_800)

Xcode 自动申请是一种一键式的申请方式，推荐开发者使用。

## 使用

iOS 证书包含开发者的信息以及开发者的公钥。Xcode 导入证书后，对 App 打包时 Xcode 会根据证书从 Keychain 中找到与之匹配的私钥，并使用私钥对 App 进行签名。

[![img](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/sketch-images/certificate-usage.png?x-oss-process=image/resize,w_800)](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/sketch-images/certificate-usage.png?x-oss-process=image/resize,w_800)

当 App 安装到真机时，真机使用开发者公钥（App 中包含开发者公钥）对 App 进行签名验证，从而确保来源可信。App 安装时具体的验证过程我们后文再说。

## 分类

iOS 证书可以分为两种：

- **Development**：开发证书，用来开发和调试 App。一般证书名是 `iPhone Developer: xxx`。如果是多人协作的开发者账号，任意成员都可以申请自己的 Development 证书。
- **Distribution**：发布证书，用来发布 App。一般证书名是 `iPhone Distribution: xxx`。只有管理员以上身份的开发者账号才可以申请，因此可以控制提交权限的范围。

下文主要针对 iOS App 开发调试过程中的开发证书进行介绍。

# 授权文件（Entitlements）

**沙盒（Sandbox）** 技术是 iOS 安全体系中非常重要的一项技术，其目的是 **限制 App 的行为**，如：可读写的路径、允许访问的硬件、允许使用的服务等等。因此，如果代码出现漏洞，也不会影响沙盒外的系统。

[![img](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/sketch-images/sandbox.png?x-oss-process=image/resize,w_800)](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/sketch-images/sandbox.png?x-oss-process=image/resize,w_800)

沙盒使用 **授权文件（Entitlements）** 声明 App 的权限。如果 App 中使用到了某项沙盒限制的功能，但是没有声明对应的权限，运行到相关代码时会直接 Crash。

新建的工程是没有 Entitlements 文件的，如果在 【Capabilities】中开启所需权限后，Xcode 会自动生成 Entitlements 文件，并将对应的权限声明添加到该文件中。

[![img](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/blog-images/entitlements02.png?x-oss-process=image/resize,w_800)](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/blog-images/entitlements02.png?x-oss-process=image/resize,w_800)

[![img](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/blog-images/entitlements01.png?x-oss-process=image/resize,w_800)](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/blog-images/entitlements01.png?x-oss-process=image/resize,w_800)

Entitlements 文件是一个 `xml` 格式的 `plist` 文件，在项目中一般以 `.entitlements` 为后缀，其内容如下：

```
 <?xml version="1.0" encoding="UTF-8"?>
 <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>aps-environment</key>
    <string>production</string>
    <key>com.apple.developer.associated-domains</key>
    <array>
        <string>applinks:xxxx.companyname.com</string>
    </array>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.companyname</string>
    </array>
</dict>
</plist>
```



事实上，Entitlements 文件的内容并不是全部的授权声明。因为缺省状态下，App 默认会包含与 TeamID 及 App ID 相关的权限声明，如下：

```
<dict>
    <key>keychain-access-groups</key>
    <array>
        <string>xxxxxxxxxx.*</string>
    </array>
    <key>get-task-allow</key>
    <true/>
    <key>application-identifier</key>
    <string>xxxxxxxxxx.test.CodeSign</string>
    <key>com.apple.developer.team-identifier</key>
    <string>xxxxxxxxxx</string>
</dict>
```



其中 `get-task-allow` 代表是否允许被调试，它在开发阶段是必需的一项权限，而在进行Archive打包用于上架时会被去掉。

**注意：代码签名时，会将 Entitlements 文件（如有）与上述缺省内容进行合并，得到最终的授权文件，并嵌入二进制代码中，作为被签名内容的一部分，由代码签名保证其不可篡改性。**

# App ID

**App ID** 即 Product ID，用于标识一个或一组 App。

App ID 字符串通常以 **反域名（reverse-domain-name）** 格式的 Company Identifier（Company ID）作为前缀（Prefix/Seed），一般不超过 255 个 ASCII 字符。

App ID 全名会被追加 Application Identifier Prefix（一般为 TeamID）。App ID 可以分为两种：

- **Explicit App ID**：唯一的 App ID，用于标识一个应用程序。如：`com.apple.garageband` 用于标识 Bundle Identifier 为 `com.apple.garageband` 的 App。
- **Wildcard App ID**：含有通配符的 App ID，用于标识一组应用程序。如：`com.apple.*` 用于标识 Bundle Identifier 以 `com.apple.` 开头（苹果公司）的所有应用程序。

开发者可在 Developer Member Center 网站上注册（Register）或删除（Delete）已注册的 App IDs。

在 Xcode 中，配置项 `Xcode Target -> Info -> Bunlde Identifier` 必须与 App ID 是一致的（Explicit）或匹配的（Wildcard）。

**注意：注册 App ID 时，允许开发者在【Capabilities】中勾选所需的权限。这与上述的授权文件 Entitlements 相匹配。**

[![img](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/blog-images/appid01.png?x-oss-process=image/resize,w_800)](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/blog-images/appid01.png?x-oss-process=image/resize,w_800)

# 设备

**设备（Device）** 即用于开发调试的 iOS 设备。每台 Apple 设备使用 **UUID（Unique Device Identifier）** 来唯一标识，即设备 ID。

Apple Member Center 网站个人账号下的 **Device** 中包含注册过的所有可用于开发和测试的设备，普通个人开发账号每年累计最多注册 100 个设备。

开发者可在网站上注册或启用/禁用（Enable/Disable）已注册的 Device。

本文的 Device 是指连接到 macOS/Xcode 被授权用于开发测试的 iOS 设备（iPhone/iPad）。

# 供应配置文件（Provisioning Profile）

## 创建

**供应配置文件（Provisioning Profile，简称 pp）** 包含了上述所有内容：

- **App ID**（App ID 在注册时可声明所需沙盒权限，所以包含了 Entitlements）
- **证书**
- **设备 ID**

[![img](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/sketch-images/provisioning-profile.png?x-oss-process=image/resize,w_800)](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/sketch-images/provisioning-profile.png?x-oss-process=image/resize,w_800)

一个 Provisioning Profile 对应一个 Explicit ID 或 Wildcard ID。在网站上手动创建一个 Provisioning Profile 时，需依次指定上述三项内容：

- App ID：单选（沙盒权限，可多选）
- 证书：Certificates，可多选，对应多个开发者
- 设备：Devices，可多选，对应更多个开发设备

开发者可以下载 Provisioning Profile 文件，即一个 `.mobileprovision` 文件。开发者也可以删除（Delete）已注册的 Provisioning Profile。

Provisioning Profile 会配置到 `Xcode -> Target -> Signing & Capabilities -> Provisioning Profile` 中。

Provisioning Profile 默认保存在本地的 `~/Library/MobileDevice/Provisioning Profiles` 目录下。

## 构成

`.mobileprovision` 包含以下这些字段及内容：

- `Name`：即 `mobileprovision` 文件。

- `UUID`：即 `mobileprivision` 文件的真实文件名，是一个唯一标识。

- `TeamName`：即 Apple ID 账号名。

- `TeamIdentifier`：即 Team Identity。

- `AppIDName`：即 explicit/wildcard Apple ID name（ApplicationIdentifierPrefix）。

- `ApplicationIdentifierPrefix`：即完整 App ID 的前缀。

- `ProvisionedDevices`：该 `.mobileprovision` 授权的所有开发设备的 UUID。

- `DeveloperCertificates`：该 `.mobileprovision` 允许对应用程序进行签名的所用证书，不同证书对应不同的开发者。如果使用不在这个列表中的证书进行签名，会出现 `code signing failed` 相关报错。

- ```
  Entitlements
  ```

  ：包含了一组键值对。

  ```
  <key>
  ```

  、

  ```
  <dict>
  ```

  。

  - `keychain-access-groups`：`$(AppIdentifierPrefix)`
  - `application-identifier`：带前缀的全名。如：`$(AppIdentifierPrefix)com.apple.garageband`
  - `com.apple.security.application-groups`：App Group ID。
  - `com.apple.developer.team-identifier`：同 Team Identifier。

## 签名 & 打包

首先，Xcode 会检查 Signing（entitlement、certificate）配置是否与 Provisioning Profile 相匹配，否则编译会报错。

[![img](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/blog-images/signing01.png?x-oss-process=image/resize,w_800)](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/blog-images/signing01.png?x-oss-process=image/resize,w_800)

其次，Xcode 会检查 Signing & Capabilities 配置的证书是否在本机 Keychain Access 中存在对应的 Public/Private Key Pair，否则编译会报错。

然后，Xcode 证书在本机 Keychain Access 匹配的 Key Pair 的私钥对应用程序 **内容（Executable Code，resources such as images and nib files are not signed）** 进行签名（CodeSign）。**注意：Entitlements 文件也会被嵌入到内容中进行签名。**

最终，签名、Provisioning Profile、应用程序都会被打包到 `.ipa` 中

[![img](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/sketch-images/provisioning-profile-signing.png?x-oss-process=image/resize,w_800)](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/sketch-images/provisioning-profile-signing.png?x-oss-process=image/resize,w_800)

### `.ipa` 文件

我们可以用 `file` 命令来查看 `.ipa` 文件，从输出结果可以看出它是一个压缩文件。对 `.ipa` 文件解压后会得到一个 `Payload` 文件，里面包含了 `.app` 目录。

```
$ file Solar_200319-1858_r372ce72fe.ipa
Solar_200319-1858_r372ce72fe.ipa: Zip archive data, at least v1.0 to extract
```

#### `.app` 文件

以 `Solar.app` 为例，`.app` 目录下主要有以下这些类型的文件：

- **可执行文件**：以项目名称命名的可执行文件。如：`Solar`。
- **`xxx.bundle`**：资源文件，对应不同的 SDK 和 Pod。
- **`xxx.lproj`**：多语言本地化资源文件。每种语言单独定义其资源，包含：图片、文本、Storyboard、Xib 等。
- **`Frameworks`**：包含了 app 使用的第三方静态库、Swift 动态库。
- **`Info.plist`**：app 的相关配置，包括：Bundle Identifier、可执行文件名等。
- **`embedded.mobileprovision`**：供应配置文件（Provisioning Profile）。
- **`_CodeSignature/CodeResources`**：一个 `plist` 文件，保存签名时每个文件的哈希值（摘要），这些哈希值并不需要都进行加密，因为非对称加密的性能是比较差的，全部都加密只会拖慢签名和校验的速度。

## 验证 & 运行

在真机上运行测试包和正式包时，系统对两者的验证有所不同。简而言之，测试包在设备上进行了完整的签名验证；正式包则把验证过程交给了 App Store，App Store 验证通过后重新进行一次签名，设备下载正式包后进行的验证过程则简化很多。

下面我们首先介绍一下测试包的验证过程。

### 测试包

当在设备上安装运行时，会对 App 进行验证。

首先，设备系统会对 App 中的 bundle ID、entitlements、certificate 与 Provisioning Profile 中的 App ID、entitlements、certificates 进行匹配验证，否则无法启动 App。

其次，设备系统使用本地内置的 CA 公钥对 Provisioning Profile 中匹配的 certificate 进行签名验证，从而确认匹配到的证书的合法性。

然后，设备系统使用 Provisioning Profile 中的匹配的，且经过 CA 验证过的 certificate（即打包应用程序的开发者的证书）中取出公钥，对 App 进行签名验证，否则无法启动 App。

最后，设备系统会将设备的 Device ID 与 Provisioning Profile 中的 Devices 的 Device ID 进行匹配，否则无法启动 App。

[![img](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/sketch-images/provisioning-profile-validation.png?x-oss-process=image/resize,w_800)](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/sketch-images/provisioning-profile-validation.png?x-oss-process=image/resize,w_800)

### 正式包

假如你有一台越狱的设备，查看任意一个从 App Store 上下载的 App，你会发现里面没有 `embedded.mobileprovision` 文件，因为 App Store 已经完成了对 App 的验证（**类似于上述测试包的验证过程**）。当 App 通过验证后，Apple Store 会对 App 进行重新签名，如下图所示。重新签名的内容将不再包含 Provisioning Profile，最终的 ipa 文件也不包含它。

[![img](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/sketch-images/app-store-resigning.png?x-oss-process=image/resize,w_800)](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/sketch-images/app-store-resigning.png?x-oss-process=image/resize,w_800)

当设备从 App Store 下载 App 时，会直接使用设备上的 CA 公钥对 ipa 进行签名验证，如下图所示。与上述测试包的签名验证相比，正式包的签名验证简化了很多，因为有一部分验证工作已经由 App Store 完成了。

[![img](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/sketch-images/app-store-validation.png?x-oss-process=image/resize,w_800)](https://chuquan-public-r-001.oss-cn-shanghai.aliyuncs.com/sketch-images/app-store-validation.png?x-oss-process=image/resize,w_800)

# 总结

有上述可知，非对称加密贯穿于 iOS 开发之中。当我们在开发中遇到签名、证书相关的问题时，我们只要结合证书幕后的原理，很容易就能找到解决办法。

# 参考

1. 《图解密码技术》
2. [iOS Provisioning Profile(Certificate)与Code Signing详解](https://blog.csdn.net/phunxm/article/details/42685597)
3. [iOS 掉签的概念和原理](https://www.jianshu.com/p/178104408615)
4. [iOS 浅谈 APP ipa包的结构](https://www.jianshu.com/p/e33412176310)
5. [ipa 目录结构及构建过程](https://www.jianshu.com/p/c33db8e95e6d)
6. [Library vs Framework in iOS](https://juejin.im/entry/5bb831b4f265da0aa52921ca)
7. [iOS语言国际化/本地化-实践总结](https://juejin.im/post/5b90ea53e51d450ea131ef81)
8. [iOS 应用重签名](https://www.jianshu.com/p/5d9955bf4c55)
9. [细说iOS代码签名(一)](http://xelz.info/blog/2019/01/11/ios-code-signature-1/)
10. [细说iOS代码签名(二)](http://xelz.info/blog/2019/01/11/ios-code-signature-2/)
11. [细说iOS代码签名(三)](http://xelz.info/blog/2019/01/11/ios-code-signature-3/)
12. [细说iOS代码签名(四)](http://xelz.info/blog/2019/01/11/ios-code-signature-4/)
13. [搜题 Configurations 的说明](https://confluence.zhenguanyu.com/pages/viewpage.action?pageId=30677779)
14. [iOS 开发者中的公司账号与个人账号之间有什么区别？](https://www.zhihu.com/question/20308474)
15. [逆向（七）重签名](https://wenghengcong.com/posts/3c332106/)

欣赏此文？求鼓励，求支持！

赏

[# iOS 开发证书](http://chuquan.me/tags/iOS-开发证书/) [# Provisioning Profile](http://chuquan.me/tags/Provisioning-Profile/)

[Swift 性能优化(2)——协议与泛型的实现](http://chuquan.me/2020/02/19/swift-performance-protocol-type-generic-type/)



[猿辅导招聘](http://chuquan.me/2020/04/01/yuanfudao-zhaopin/)	
