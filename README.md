## meizu-music-down

**下载魅族音乐APP分享出来的专辑**
`github:`https://github.com/youqingkui/down-meizu-music


### 安装

    sudo npm i meizu-music-down -g

### 使用

1. 点击分享，然后可以把获取到分享出来的地址：
>分享专辑：世界 演唱者：逃跑计划 http://music.meizu.com/share/distribute.do?style=2&id=2318991&type=2&source=2&token=3a3322513c2750ad80c5149adb3795d6 
来自 MEIZU MX
![Alt text](http://youqingkui.me/images/af666c1ba5d18508a6bfae679b13e13b.png)

2. 然后运行代码：`music-mz url(分享处理的url地址)`
会在运行命令的目录下面自动创建专辑的文件夹，里面会包含下载的音乐和专辑图片
![Alt text](http://youqingkui.me/images/098646324d58dfccebb7e30e82ca709e.png)



> 魅族音乐分享出来的音乐的格式都是.M4A的格式，文件很小，音质我似乎没有听出来和无损音乐的差别。
> 已经增加对分享出来的单曲URL的下载