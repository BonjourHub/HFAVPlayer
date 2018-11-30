//
//  HIAudioPlayer.m
//  test
//
//  Created by pengfei28 on 2018/3/19.
//  Copyright © 2018年 bj-m-206066a. All rights reserved.
//

#import "HIAudioPlayer.h"
#import "HIAudioDataManager.h"
#import <AVFoundation/AVFoundation.h>

@interface HIAudioPlayer ()
@property (nonatomic, strong)AVPlayer *audioPlayer;
@property (nonatomic, strong) HIAudioDataManager *dataManager;
@end

@implementation HIAudioPlayer

#pragma mark - getter
- (AVPlayer *)audioPlayer
{
    if (!_audioPlayer)
    {
        _audioPlayer = [[AVPlayer alloc] init];
        if (@available(iOS 10.0, *)) _audioPlayer.automaticallyWaitsToMinimizeStalling = NO;
        
        [_audioPlayer addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        __weak typeof(self) weakSelf = self;
        [_audioPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:nil usingBlock:^(CMTime time) {
            [weakSelf periodicTimeObserverWithTime:time];
        }];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_playerItemDidPlayToEndTimeNotification:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    }
    return _audioPlayer;
}

- (HIAudioDataManager *)dataManager
{
    if (!_dataManager)
    {
        _dataManager = [HIAudioDataManager new];
    }
    return _dataManager;
}

#pragma mark - Observer
- (void)periodicTimeObserverWithTime:(CMTime)time
{
    CMTime duration = self.audioPlayer.currentItem.duration;
    CGFloat total = CMTimeGetSeconds(duration);
    
    HFDebugLog(@"progress:%.2lld total:%f",time.value/time.timescale,total);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"status"])
    {
        if ([object isKindOfClass:[AVPlayer class]])
            [self _playerStatusChangeWithStatus:[(AVPlayer *)object status]];
    }
    
    if ([keyPath isEqualToString:@"loadedTimeRanges"])
    {
        if ([object isKindOfClass:[AVPlayerItem class]])
            [self _bufferProgressWithItem:(AVPlayerItem *)object];
    }
}

- (void)_playerStatusChangeWithStatus:(AVPlayerStatus)status
{
    switch (status) {
        case AVPlayerStatusReadyToPlay:
        {
            HFDebugLog(@"Ready To Play");
            [self _play];
        }
            break;
        case AVPlayerStatusFailed:
        {
            HFDebugLog(@"Ready To Failed");
        }
            break;
        case AVPlayerStatusUnknown:
        {
            HFDebugLog(@"Ready To Unknown");
        }
            break;
            
        default:
            break;
    }
}

- (void)_bufferProgressWithItem:(AVPlayerItem *)item
{
    CMTimeRange timeRange = [item.loadedTimeRanges.firstObject CMTimeRangeValue];
    NSTimeInterval totalBuffer = CMTimeGetSeconds(timeRange.start) + CMTimeGetSeconds(timeRange.duration);
    HFDebugLog(@"共缓冲：%.2f",totalBuffer);
}

#pragma mark - notification
- (void)_playerItemDidPlayToEndTimeNotification:(NSNotification *)notification
{
    if ([notification.name isEqualToString:AVPlayerItemDidPlayToEndTimeNotification]) {
        [self _removeItemObserve];
    }
}

#pragma mark - remove
- (void)removeAllObserve
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.audioPlayer removeObserver:self forKeyPath:@"status"];
    [self _removeItemObserve];
}

- (void)_removeItemObserve
{
    [self.audioPlayer.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
}

#pragma mark - Control
- (void)_play
{
    [self.audioPlayer.currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    [self.audioPlayer play];
}

- (void)_pause
{
    [self.audioPlayer pause];
}

- (void)_stop
{
    
}

- (void)seekToProgress:(float)progress
{
    float time = progress * CMTimeGetSeconds(self.audioPlayer.currentItem.duration);
    HFDebugLog(@"drag progress:%.2f",time);
    
    [self.audioPlayer seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];
//    [self.audioPlayer seekToTime:CMTimeMake(time, self.audioPlayer.currentItem.currentTime.timescale) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
//    [self.audioPlayer seekToTime:CMTimeMake(time, NSEC_PER_SEC) completionHandler:^(BOOL finished) {
//        [self.audioPlayer play];
//    }];
}

#pragma mark - Public
+ (instancetype)shareInstance
{
    static HIAudioPlayer *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [HIAudioPlayer new];
    });
    
    return instance;
}

- (void)playWithURLString:(NSString *)urlString
{
    AVPlayerItem *item = [self.dataManager playerItemWithURLString:urlString];
    [self.audioPlayer replaceCurrentItemWithPlayerItem:item];
    [self _play];
}

//- (AVPlayerItem *)playerItemWithURLString:(NSString *)urlString
//{
//    if (!urlString.length)
//    {
//        return nil;
//    }
//
//    AVURLAsset *urlAsset = [AVURLAsset assetWithURL:[NSURL URLWithString:urlString]];
//    return [AVPlayerItem playerItemWithAsset:urlAsset];
//}

- (void)play
{
    [self _play];
}

- (void)pause
{
    [self _pause];
}

- (void)stop
{
    [self _stop];
}





@end
