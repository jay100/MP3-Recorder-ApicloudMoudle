# MP3-Recorder-ApicloudMoudle
apicloud 模块 - mp3录音


<div class="outline">

[start](#a1)

[stop](#a2)



<!--[listenerMiniLanuchApp](#listenerMiniLanuchApp)-->
</div>

# **概述**

本模块基于<a href="http://lame.sourceforge.net/" target="_blank">lame</a>开源框架 
封装了 Android与ios  mp3录音原生SDK 基础功能 

参考以下 GitHub 开源项目
- <a href="https://github.com/rpplusplus/iOSMp3Recorder" target="_blank">iOSMp3Recorder</a>
- <a href="https://github.com/begin1209/LameDemo" target="_blank">LameDemo（android）</a>

## **模块接口**
    
<div id="a1"></div>

# **start**
开始录音

open(callback(ret, err))

## callback(ret, err)

ret：

- 类型：JSON 对象
- 内部字段：

```js
{
    status: true      //打开成功
    message: "打开成功" // 
}
```
err：

- 类型：JSON 对象
- 内部字段：

```js
{
    status: false     //打开失败；
    message:"提示信息"      
}
```
## 示例代码

```js
var recMp3 = api.require('recMp3');
recMp3.start(function(ret, err) {
    if (ret) {
        alert(ret.message);
    } else {
        alert(err.message);
    }
});
```

<div id="a2"></div>

# **stop**

停止录音

stop(callback(ret,err))

## callback(ret,err)

ret：

- 类型：JSON 对象
- 内部字段：

```js
{
     
    status:true      
    message: ""    //字符串;
    duration:"3"   //时长（秒）
    path:'fs://xxx.mp3'  //文件路径
}
```

## 示例代码

```js
var recMp3 = api.require('recMp3');
recMp3.stop( function(ret,err) {
      if(ret){
          var duration = ret.duration;
          var path = ret.path;
          toast(ret.message+", 时长："+duration+",路径："+path);
      }
});
```

#可用性

iOS系统，Android系统