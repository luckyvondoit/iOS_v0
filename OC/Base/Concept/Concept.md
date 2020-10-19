1. NSNotificationCenter通知中心的实现原理？

<details>
<summary> 参考 </summary>

[通知原理](https://github.com/luckyvondoit/iOS/blob/master/Foundation/NSNotification/NSNotification.md)

</details>

2. 苹果推送如何实现的？

<details>
<summary> 参考 </summary>

1. 由App向iOS设备发送一个注册通知，用户需要同意系统发送推送。
2. iOS应用向APNS远程推送服务器发送App的Bundle Id和设备的UDID。
3. APNS根据设备的UDID和App的Bundle Id生成deviceToken再发回给App。
4. App再将deviceToken发送给远程推送服务器(自己的服务器), 由服务器保存在数据库中。
5. 当自己的服务器想发送推送时, 在远程推送服务器中输入要发送的消息并选择发给哪些用户的deviceToken，由远程推送服务器发送给APNS。
6. APNS根据deviceToken发送给对应的用户。

</details>

3. 响应者链

<details>
<summary> 参考 </summary>

[响应者链]()

</details>
