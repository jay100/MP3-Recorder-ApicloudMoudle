package com.ezhiduo.mp3recorder;

import android.annotation.SuppressLint;
import android.media.MediaPlayer;
import android.os.Handler;
import android.os.Message;
import android.text.TextUtils;

import com.coolzhouy.lamedemo.mp3recorder.RecMicToMp3;
import com.uzmap.pkg.uzcore.UZWebView;
import com.uzmap.pkg.uzcore.uzmodule.UZModule;
import com.uzmap.pkg.uzcore.uzmodule.UZModuleContext;

import org.json.JSONObject;

import java.io.File;
import java.util.Date;

public class RecApi
        extends UZModule {

    RecMicToMp3 mRecMicToMp3;
    String mp3Url;
    String fsUrl;
    private UZModuleContext handleContext;


    public RecApi(UZWebView paramUZWebView) {
        super(paramUZWebView);
    }

    private void initUrl() {
        fsUrl = "fs://mp3recorder/" + new Date().getTime() + ".mp3";


        File f = new File(makeRealPath("fs://mp3recorder"));
        if(!f.exists()) {
            f.mkdir();
        }

        mp3Url = makeRealPath(fsUrl);
    }

    @SuppressLint("HandlerLeak")
    public void jsmethod_start(UZModuleContext paramUZModuleContext) {
        handleContext = paramUZModuleContext;
        initUrl();//初始化地址
        mRecMicToMp3 = new RecMicToMp3(mp3Url, 44100);
        mRecMicToMp3.setHandle(new Handler() {
            @Override
            public void handleMessage(Message msg) {
                try {
                    JSONObject json = new JSONObject();
                    switch (msg.what) {
                        case RecMicToMp3.MSG_REC_STARTED:
                            //录音中...
                            json.put("status", true);
                            json.put("message", "录音中...");
                            handleContext.success(json, true);
                            break;
                        case RecMicToMp3.MSG_REC_STOPPED:

                            MediaPlayer mediaPlayer = new MediaPlayer();
                            mediaPlayer.setDataSource(mp3Url);
                            mediaPlayer.prepare();
                            int duration = mediaPlayer.getDuration()/1000;

                            if(duration==0) {
                               File f = new File(mp3Url);
                               if(f.exists()) f.delete();
                               fsUrl = "";
                            }

                            json.put("status", true);
                            json.put("message", "完成了");
                            json.put("path", fsUrl);
                            json.put("duration", duration);
                            handleContext.success(json, true);

                            break;
                        case RecMicToMp3.MSG_ERROR_GET_MIN_BUFFERSIZE:

                            json.put("status", false);
                            json.put("message", "不支持录音");
                            handleContext.error(null,json, true);
                            break;
                        case RecMicToMp3.MSG_ERROR_CREATE_FILE:
                            json.put("status", false);
                            json.put("message", "无法生成文件");
                            handleContext.error(null,json, true);
                            break;
                        case RecMicToMp3.MSG_ERROR_REC_START:
                            json.put("status", false);
                            json.put("message", "请检查开启录音权限");
                            handleContext.error(null,json, true);
                            break;
                        case RecMicToMp3.MSG_ERROR_AUDIO_RECORD:
                            json.put("status", false);
                            json.put("message", "请检查开启录音权限");
                            handleContext.error(null,json, true);
                            break;
                        case RecMicToMp3.MSG_ERROR_AUDIO_ENCODE:
                            json.put("type", "error");
                            json.put("message", "编码失败");
                            handleContext.error(null,json, true);
                            break;
                        case RecMicToMp3.MSG_ERROR_WRITE_FILE:
                            json.put("status", false);
                            json.put("message", "文件写入失败");
                            handleContext.error(null,json, true);
                            break;
                        case RecMicToMp3.MSG_ERROR_CLOSE_FILE:
                            json.put("status", false);
                            json.put("message", "文件写入失败");
                            handleContext.error(null,json, true);
                            break;
                        default:
                            break;
                    }
                } catch (Exception e) {
                }
            }
        });

        mRecMicToMp3.start();
    }

    public void jsmethod_stop(UZModuleContext paramUZModuleContext) {
        handleContext = paramUZModuleContext;
        mRecMicToMp3.stop();
    }
}
