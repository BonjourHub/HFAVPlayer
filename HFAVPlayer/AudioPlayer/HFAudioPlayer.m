//
//  HFAudioPlayer.m
//  HFAVPlayer
//
//  Created by pengfei28 on 2018/7/31.
//  Copyright © 2018年 pengfei. All rights reserved.
//

#import "HFAudioPlayer.h"
#import <AVFoundation/AVFoundation.h>

@interface HFAudioPlayer()

@property (nonatomic, strong) AVPlayer *audioPlayer;

@end

@implementation HFAudioPlayer

#pragma mark - getter
- (AVPlayer *)audioPlayer
{
    if (!_audioPlayer)
    {
        _audioPlayer = [AVPlayer new];
    }
    return _audioPlayer;
}

#pragma mark - public
+ (instancetype)shareInstance
{
    static HFAudioPlayer *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [HFAudioPlayer new];
    });
    
    return instance;
}

- (void)playWithURLString:(NSString *)urlString
{
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:urlString]];
    [self.audioPlayer replaceCurrentItemWithPlayerItem:item];
    [self.audioPlayer play];
}

@end
