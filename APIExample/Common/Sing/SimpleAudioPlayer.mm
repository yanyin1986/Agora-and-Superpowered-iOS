//
//  SimpleAudioPlayer.m
//  APIExample
//
//  Created by yin.yan on 2023/05/10.
//  Copyright © 2023 Agora Corp. All rights reserved.
//

#import "SimpleAudioPlayer.h"
#if TARGET_OS_IPHONE
#import <AgoraRtcKit/AgoraRtcEngineKit.h>
#import <AgoraRtcKit/IAgoraRtcEngine.h>
#import <AgoraRtcKit/IAgoraMediaEngine.h>
#else
#import <AgoraRtcKit/AgoraRtcEngineKit.h>
#import <AgoraRtcKit/IAgoraRtcEngine.h>
#import <AgoraRtcKit/IAgoraMediaEngine.h>
#endif
#import "Superpowered.h"
#import "SuperpoweredIOSAudioIO.h"
#import "SuperpoweredAdvancedAudioPlayer.h"
#import "SuperpoweredMixer.h"
#import "SuperpoweredSimple.h"

@interface SimpleAudioPlayer() <SuperpoweredIOSAudioIODelegate> {
    Superpowered::AdvancedAudioPlayer *player;
    Superpowered::StereoMixer *mixer;
    float *playbuffer;
    short int *myBuffer;
}
@property (nonatomic, strong) SuperpoweredIOSAudioIO* internalIO;
@property (nonatomic, strong) AgoraRtcEngineKit *agoraKit;
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation SimpleAudioPlayer

+ (void)load {
    Superpowered::Initialize("ExampleLicenseKey-WillExpire-OnNextUpdate");
}

- (void)dealloc {
    [self stop];
    _internalIO = NULL;

    delete player;
    delete mixer;
}

static BOOL audioProcessing(void *clientdata,
                            float *input,
                            float *output,
                            unsigned int numberOfFrames,
                            unsigned int samplerate,
                            uint64_t hostTime) {
    __unsafe_unretained SimpleAudioPlayer *self = (__bridge SimpleAudioPlayer *)clientdata;
    return [self audioProcessing:input output:output numFrames:numberOfFrames samplerate:samplerate];
}

- (BOOL)audioProcessing:(float *)input
                 output:(float *)output
              numFrames:(unsigned int)numberOfFrames
             samplerate:(unsigned int)samplerate {
    player->outputSamplerate = samplerate;
    bool notSilence = player->processStereo(output, false, numberOfFrames);
    mixer->process(input, output, NULL, NULL, output, numberOfFrames);

    Superpowered::FloatToShortInt(output, myBuffer, numberOfFrames);
    [self.agoraKit pushExternalAudioFrameRawData:myBuffer samples:numberOfFrames timestamp:0];

    return notSilence;
}

- (void)stop {
    [_internalIO stop];
}

- (BOOL)start {
    return [_internalIO start];
}

- (void)setupExternalAudioWithAgoraKit:(AgoraRtcEngineKit *)agoraKit
                            sampleRate:(uint)sampleRate
                              channels:(uint)channels {
//    AVAudioSessionCategory category = [AVAudioSession sharedInstance].category;
    _internalIO = [SuperpoweredIOSAudioIO.alloc initWithDelegate:self
                                             preferredBufferSize:12
                                             preferredSamplerate:sampleRate
                                            audioSessionCategory:AVAudioSessionCategoryPlayAndRecord
                                                        channels:channels
                                         audioProcessingCallback:audioProcessing
                                                      clientdata:(__bridge void *)self];

//    // Agora Engine of C++
//    agora::rtc::IRtcEngine* rtc_engine = (agora::rtc::IRtcEngine*)agoraKit.getNativeHandle;
//    agora::util::AutoPtr<agora::media::IMediaEngine> mediaEngine;
//    mediaEngine.queryInterface(rtc_engine, agora::AGORA_IID_MEDIA_ENGINE);
//
//    if (mediaEngine) {
//        s_audioFrameObserver = new ExternalAudioFrameObserver();
//        s_audioFrameObserver -> sampleRate = sampleRate;
//        s_audioFrameObserver -> sampleRate_play = channels;
//        mediaEngine->registerAudioFrameObserver(s_audioFrameObserver);
//    }
    _playable = NO;

    player = new Superpowered::AdvancedAudioPlayer(sampleRate, 0);
    player->playbackRate = 1;
    player->pitchShiftCents = 0;

    playbuffer = (float *) malloc(sizeof(float) * 2 * 960);
    myBuffer = (short int *) malloc(sizeof(short int) * 2 * 960);

    mixer = new Superpowered::StereoMixer();

    _agoraKit = agoraKit;
}

- (void)setPlayable:(BOOL)playable {
    if (_playable != playable) {
        _playable = playable;

        [self.delegate player:self isPlayableChanged:_playable];
    }
}

- (void)loadSongURL:(NSURL *)url {
    self.playable = NO;

    if (player == NULL) {
        return;
    }
    // open bgm file
    if (url.isFileURL) {
        player->open(url.fileSystemRepresentation);
    } else {
        player->open(url.path.UTF8String);
    }

    _timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(checkPlayerEvent:) userInfo:nil repeats:YES];
}

- (void)checkPlayerEvent:(NSTimer *)timer {
    if (player == NULL) {
        return;
    }

    switch (player->getLatestEvent()) {
        case Superpowered::AdvancedAudioPlayer::PlayerEvent_Opening:
            NSLog(@"opening");
            break;

        case Superpowered::AdvancedAudioPlayer::PlayerEvent_Opened:
            NSLog(@"opened");
            self.playable = YES;
            [_timer invalidate];
            _timer = NULL;
            [self play];

            break;
        case Superpowered::AdvancedAudioPlayer::PlayerEvent_ConnectionLost:
            NSLog(@"PlayerEvent_ConnectionLost");
            break;

        case Superpowered::AdvancedAudioPlayer::PlayerEvent_OpenFailed:
            NSLog(@"Open error %i: %s", player->getOpenErrorCode(), Superpowered::AdvancedAudioPlayer::statusCodeToString(player->getOpenErrorCode()));
            [_timer invalidate];
            _timer = NULL;

            break;
        case Superpowered::AdvancedAudioPlayer::PlayerEvent_ProgressiveDownloadFinished:
            NSLog(@"PlayerEvent_ProgressiveDownloadFinished");
            break;
        default:
            break;
    }
}

- (BOOL)isPlaying {
    if (player) {
        return player->isPlaying();
    }
    return NO;
}

- (void)play {
    if (player && !player->isPlaying()) {
        player->play();
    }
}

- (void)pause {
    if (player && player->isPlaying()) {
        player->pause();
    }
}

@end

