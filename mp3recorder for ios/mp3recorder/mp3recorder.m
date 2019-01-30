//
//  mp3recorder.m
//  mp3recorder
//
//  Created by 黄信杰 on 2019/1/29.
//  Copyright © 2019年 黄信杰. All rights reserved.
//

#import "mp3recorder.h"
#import "NSDictionaryUtils.h"
#import "ConvertAudioFile.h"
#import <AVFoundation/AVFoundation.h>

#define isValidString(string)               (string && [string isEqualToString:@""] == NO)
#define ETRECORD_RATE 11025.0
//边录边转换
#define ENCODE_MP3    1

@interface mp3recorder()<AVAudioRecorderDelegate>

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) AVAudioRecorder *audioRecorder;

@end

@implementation mp3recorder{
    UZModuleMethodContext *handleContext;
    NSString *mp3Url;
    NSString *fsMp3Url;
    NSString *cafUrl;
    NSInteger time;
}


#pragma mark - Override
+ (void)onAppLaunch:(NSDictionary *)launchOptions {
    NSLog(@"onAppLaunch mp3recorder...");
    // 方法在应用启动时被调用
}

- (id)initWithUZWebView:(UZWebView *)webView {
    if (self = [super initWithUZWebView:webView]) {
        // 初始化方法
    }
    return self;
}

- (void)dispose {
    // 方法在模块销毁之前被调用
    //[thisClient removeMapContext:[self toHash]];
    NSLog(@"dispose mp3recorder");
}

-(NSURL*) getSavePath{
    NSString *dir = [self getPathWithUZSchemeURL:@"fs://mp3recoder"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    
    
    BOOL isDir = NO;
    
    BOOL existed = [fileManager fileExistsAtPath:dir isDirectory:&isDir];
    
    
    if ( !(isDir == YES && existed == YES) )
    {
        [fileManager createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }

    NSString *timeStamp = [NSString stringWithFormat:@"%ld",(long)([[NSDate date] timeIntervalSince1970]*1000)];
    
    mp3Url =    [NSString stringWithFormat:@"fs://mp3recoder/%@.mp3",timeStamp];
    cafUrl =    [NSString stringWithFormat:@"fs://mp3recoder/%@.caf",timeStamp];
    
    fsMp3Url = mp3Url;
    //获取真实路径
    mp3Url = [self getPathWithUZSchemeURL:mp3Url];
    cafUrl = [self getPathWithUZSchemeURL:cafUrl];
    NSURL *url=[NSURL fileURLWithPath:cafUrl];
    return url;
}

/**
 *  获得录音机对象
 *
 *  @return 录音机对象
 */
- (AVAudioRecorder *)audioRecorder{
    if (!_audioRecorder) {
        
        //7.0第一次运行会提示，是否允许使用麦克风
        AVAudioSession *session = [AVAudioSession sharedInstance];
        NSError *sessionError;
        //AVAudioSessionCategoryPlayAndRecord用于录音和播放
        [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
        if(session == nil)
            NSLog(@"Error creating session: %@", [sessionError description]);
        else
            [session setActive:YES error:nil];
        
        //创建录音文件保存路径
        NSURL *url= [self getSavePath];
        //创建录音格式设置
        NSDictionary *setting = [self getAudioSetting];
        //创建录音机
        NSError *error=nil;
        _audioRecorder = [[AVAudioRecorder alloc]initWithURL:url settings:setting error:&error];
        _audioRecorder.delegate=self;
        _audioRecorder.meteringEnabled=YES;//如果要监控声波则必须设置为YES
        [_audioRecorder prepareToRecord];
        if (error) {
            NSLog(@"创建录音机对象时发生错误，错误信息：%@",error.localizedDescription);
            return nil;
        }
    }
    return _audioRecorder;
}

/**
 *  取得录音文件设置
 *
 *  @return 录音设置
 */
- (NSDictionary *)getAudioSetting{
    NSMutableDictionary *dicM = [NSMutableDictionary dictionary];
    [dicM setObject:@(kAudioFormatLinearPCM) forKey:AVFormatIDKey];
    
    [dicM setObject:@(ETRECORD_RATE) forKey:AVSampleRateKey];
    [dicM setObject:@(2) forKey:AVNumberOfChannelsKey];
    [dicM setObject:@(16) forKey:AVLinearPCMBitDepthKey];
    [dicM setObject:[NSNumber numberWithInt:AVAudioQualityMin] forKey:AVEncoderAudioQualityKey];
    return dicM;
}


- (void)cleanCafFile {
    
    if (isValidString(cafUrl)) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDir = FALSE;
        BOOL isDirExist = [fileManager fileExistsAtPath:cafUrl isDirectory:&isDir];
        if (isDirExist) {
            [fileManager removeItemAtPath:cafUrl error:nil];
            NSLog(@"  xxx.caf  file   already delete");
        }
    }
}

- (void)cleanMp3File {
    
    if (isValidString(mp3Url)) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDir = FALSE;
        BOOL isDirExist = [fileManager fileExistsAtPath:mp3Url isDirectory:&isDir];
        if (isDirExist) {
            [fileManager removeItemAtPath:mp3Url error:nil];
            NSLog(@"  xxx.mp3  file   already delete");
        }
    }
}


- (void)convertMp3 {
    
    [[ConvertAudioFile sharedInstance] conventToMp3WithCafFilePath:cafUrl
                                                       mp3FilePath:mp3Url
                                                        sampleRate:ETRECORD_RATE callback:^(BOOL result)
     {
         NSLog(@"---- 转码完成  --- result %d  ---- ", result);
     }];;
    
    
}

- (void)startRecord {
    
    // 重置录音机
    if (_audioRecorder) {
       // [self cleanMp3File];
        [self cleanCafFile];
        _audioRecorder = nil;
        time = 0;
        [self destoryTimer];
    }

    if (![self.audioRecorder isRecording]) {
        AVAudioSession *session = [AVAudioSession sharedInstance];
        NSError *sessionError;
        //AVAudioSessionCategoryPlayAndRecord用于录音和播放
        [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
        if(session == nil)
            NSLog(@"Error creating session: %@", [sessionError description]);
        else
            [session setActive:YES error:nil];
        
        
        
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                      target:self
                                                    selector:@selector(record)
                                                    userInfo:nil
                                                     repeats:YES];
        [self.audioRecorder record];
        
        NSLog(@"录音开始");
        
#if ENCODE_MP3
        [[ConvertAudioFile sharedInstance] conventToMp3WithCafFilePath:cafUrl
                                                           mp3FilePath:mp3Url
                                                            sampleRate:ETRECORD_RATE
                                                              callback:^(BOOL result)
         {
             if (result) {
                 NSLog(@"mp3 file compression sucesss");
             }
         }];
#endif
    } else {
        NSLog(@"is  recording now  ....");
    }
    
}

- (void)record {
    time ++;
}


- (void)stopRecord {
    if ([self.audioRecorder isRecording]) {
        NSLog(@"完成");
        [self destoryTimer];
        [[ConvertAudioFile sharedInstance] sendEndRecord];
        [self.audioRecorder stop];
    }
}


- (void)destoryTimer {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
        NSLog(@"----- timer destory");
    }
}





#pragma mark - js method
JS_METHOD(start:(UZModuleMethodContext *)context) {
    handleContext = context;
    NSDictionary *ret = @{@"status": @YES,@"message":@"录音中..."};
    
    [self startRecord];
    
    [context callbackWithRet:ret err:nil delete:YES];
}
JS_METHOD(stop:(UZModuleMethodContext *)context) {

    [self stopRecord];
    
    AVURLAsset* audioAsset =[AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath: mp3Url] options:nil];
    CMTime audioDuration = audioAsset.duration;
    int audioDurationSeconds = CMTimeGetSeconds(audioDuration);
    
    if(audioDurationSeconds==0){
        [self cleanMp3File];
        fsMp3Url=@"";
    }
    
    NSString *d = [NSString stringWithFormat:@"%d",audioDurationSeconds];
    
    
    
    NSDictionary *ret = @{@"status": @YES,@"message":@"录音完毕！",@"path":fsMp3Url,@"duration":d};
    
    [context callbackWithRet:ret err:nil delete:YES];
}

@end
