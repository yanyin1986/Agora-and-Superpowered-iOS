//
//  SimpleAudioPlayer.h
//  APIExample
//
//  Created by yin.yan on 2023/05/10.
//  Copyright © 2023 Agora Corp. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AgoraRtcEngineKit;
@class SimpleAudioPlayer;
@protocol SimpleAudioPlayerDelegate

- (void)player:(SimpleAudioPlayer *)player isPlayableChanged:(BOOL)isPlayable;

@end

@interface SimpleAudioPlayer : NSObject

@property (nonatomic, assign, getter=isPlayable) BOOL playable;
@property (nonatomic, weak) id<SimpleAudioPlayerDelegate> delegate;

- (void)stop;
- (void)setupExternalAudioWithAgoraKit:(AgoraRtcEngineKit *)agoraKit
                            sampleRate:(uint)sampleRate
                              channels:(uint)channels;// audioCRMode:(AudioCRMode)audioCRMode IOType:(IOUnitType)ioType;
- (BOOL)start;

- (void)loadSongURL:(NSURL *)url;

- (BOOL)isPlaying;
- (void)play;
- (void)pause;

@end

NS_ASSUME_NONNULL_END
