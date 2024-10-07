# Dol-Auto-Script：Dol自动脚本

<br>

   - 为了方便模组和美化包的便捷制作
   - 这只是为了我能够在手机上更加方便的使用
   - 这以后想起来再写，不会写东西(
   ~~因为北极星的py脚本还要单独装python太麻烦还需要单独启动的原因~~

<br>

## shell版功能

### 低效率，可直接mt管理器运行，缺点不能压缩成zip文件

 - [x] 自定义名称，版本，ModLoader版本，游戏版本。
 - [x] 读取img文件夹
 - [x] 创建boot.json，并写进读取内容(已经基本可以进行美化包打包了)
 - [ ] 打包成压缩文件(由于mt管理器没有zip压缩文件相关功能无法添加悲)

> ##### 没有解决办法了嵌入zip工具虽然能在没有装zip的设备上用但是在mt管理器上还是没办法使用 

 - [ ] 尝试模组/美化功能和一进行选择模式
 - [ ] 测试脚本内实现zip压缩中(QWQ配合gpt中这真的不会也好多问题哭

## 使用环境
  - 需要在能够执行sh脚本的环境下使用。
    
  - 如termux，mt管理器的侧边栏终端。

## Python版

### 高效率，可直接压缩成zip文件，缺点手机不可直接运行。
### 需要使用一个终端(如termux)安装Python才能运行，或者是具有Python环境可运行脚本的软件。
 - 修改文件扫描添加css，js，twee文件的扫描
 - 添加选择模式
 - 模式1.图片模式扫描文件(png，gif)
 - 模式2.扫描文件(png，gif，css，js，twee)添加进json文件中
 

<br>

## 使用教程

>* 演示所使用的为mt管理器终端，方便快捷移动文件。
使用shell版本(低效率)

# 1.找到脚本下载位置
![img](https://github.com/hotianbexuanto/Dol-sh-Auto-Script/blob/90443e783f839b3e7c1e7fd230a8c5b4b85ba483/picture/1.jpg)
# 2.在另一边找到模组/美化文件的位置
![img](https://github.com/hotianbexuanto/Dol-sh-Auto-Script/blob/90443e783f839b3e7c1e7fd230a8c5b4b85ba483/picture/2.jpg)
# 3.移动脚本到模组/美化的文件内
![img](https://github.com/hotianbexuanto/Dol-sh-Auto-Script/blob/90443e783f839b3e7c1e7fd230a8c5b4b85ba483/picture/3.jpg)
# 并打开mt管理器的右上角3个点，打开终端。
![img](https://github.com/hotianbexuanto/Dol-sh-Auto-Script/blob/90443e783f839b3e7c1e7fd230a8c5b4b85ba483/picture/4.jpg)
# 打开终端后会提示按照扩展包点击确定，安装完成后退出终端重新打开。
![img](https://github.com/hotianbexuanto/Dol-sh-Auto-Script/blob/90443e783f839b3e7c1e7fd230a8c5b4b85ba483/picture/5.jpg)
# 打开终端后点击下面的cd xxx/xxx/xxx来进入储存模组文件和脚本的文件夹。
## 如果提示消失，请重新退出终端重新进入会再次提示。
![img](https://github.com/hotianbexuanto/Dol-sh-Auto-Script/blob/90443e783f839b3e7c1e7fd230a8c5b4b85ba483/picture/6.jpg)
# 打开后输入ls，会显示当前打开的文件夹下的文件和目录，来确认你打开的文件夹是正确的。
![img](https://github.com/hotianbexuanto/Dol-sh-Auto-Script/blob/90443e783f839b3e7c1e7fd230a8c5b4b85ba483/picture/7.jpg)
# 输入sh 脚本的名字.sh 回车后则开始运行脚本，根据脚本提示完成相应填写
![img](https://github.com/hotianbexuanto/Dol-sh-Auto-Script/blob/90443e783f839b3e7c1e7fd230a8c5b4b85ba483/picture/8.jpg)
![img](https://github.com/hotianbexuanto/Dol-sh-Auto-Script/blob/90443e783f839b3e7c1e7fd230a8c5b4b85ba483/picture/9.jpg)
~~恼 这东西终于写出来了，看不看的懂我不保证~~
