//
//  HFAVDecoder.m
//  HFAVPlayer
//
//  Created by pengfei28 on 2018/7/5.
//  Copyright © 2018年 pengfei. All rights reserved.
//

#import "HFAVDecoder.h"
#import <QuartzCore/QuartzCore.h>
#import <AudioToolbox/AudioToolbox.h>

@interface HFAVDecoder ()

{
    AVURLAsset * _inputAsset;
}

@property (nonatomic, strong) AVAssetReader *inputAssetReader;
@property (nonatomic, strong) AVAssetReaderTrackOutput *videoRenderTrackOutput;
@property (nonatomic, strong) AVAssetReaderTrackOutput *audioRenderTrackOutput;

@property (nonatomic, copy) HFAVDecoderCallBack decoderCallBack;

@end

@implementation HFAVDecoder


#pragma mark - getter

- (AVAssetReaderTrackOutput *)videoRenderTrackOutput
{
    if (!_videoRenderTrackOutput)
    {
        AVAssetTrack *inputAssetTrack = [[_inputAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        NSDictionary *outputSettingDic = @{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)};
        _videoRenderTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:inputAssetTrack outputSettings:outputSettingDic];
        _videoRenderTrackOutput.alwaysCopiesSampleData = NO;
    }
    return _videoRenderTrackOutput;
}

- (AVAssetReaderTrackOutput *)audioRenderTrackOutput
{
    if (!_audioRenderTrackOutput)
    {
        AVAssetTrack *inputAssetTrack = [[_inputAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
        NSMutableDictionary *outputSettings = [NSMutableDictionary dictionaryWithCapacity:7];
        [outputSettings setObject:@(kAudioFormatLinearPCM) forKey:AVFormatIDKey];
        [outputSettings setObject:@(16) forKey:AVLinearPCMBitDepthKey];
        [outputSettings setObject:@(NO) forKey:AVLinearPCMIsBigEndianKey];
        [outputSettings setObject:@(NO) forKey:AVLinearPCMIsFloatKey];
        [outputSettings setObject:@(YES) forKey:AVLinearPCMIsNonInterleaved];
        [outputSettings setObject:@(44100.0) forKey:AVSampleRateKey];
        [outputSettings setObject:@(1) forKey:AVNumberOfChannelsKey];
        
        _audioRenderTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:inputAssetTrack outputSettings:outputSettings];
        _audioRenderTrackOutput.alwaysCopiesSampleData = NO;
    }
    return _audioRenderTrackOutput;
}

- (AVAssetReader *)inputAssetReader
{
    if (!_inputAssetReader)
    {
        NSError *error = nil;
        _inputAssetReader = [AVAssetReader assetReaderWithAsset:_inputAsset error:&error];
        [_inputAssetReader addOutput:self.videoRenderTrackOutput];
        [_inputAssetReader addOutput:self.audioRenderTrackOutput];
        if (error) HFDebugLog(@"[Decodec] : Reader create error : %@",error);
    }
    return _inputAssetReader;
}

#pragma mark - action
#pragma mark video data
- (CMSampleBufferRef)videoSampleBufferRef
{
    if (_videoRenderTrackOutput)
        return [_videoRenderTrackOutput copyNextSampleBuffer];
    return nil;
}

#pragma mark audio data
- (CMSampleBufferRef)audioSampleBufferRef
{
   return [_audioRenderTrackOutput copyNextSampleBuffer];
}

#pragma mark - Public
//- (void)pauseDecode
//{
//    [_decoderDisplayLink setPaused:YES];
//}
//
//- (void)resumDecode
//{
//    [self.decoderDisplayLink setPaused:NO];
//}

#pragma mark - Decode
- (void)decodecWithURL:(NSURL *)url completion:(HFAVDecoderCallBack)completion
{
    _decoderCallBack = completion;
//    NSDictionary *inputOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    _inputAsset = [[AVURLAsset alloc] initWithURL:url options:nil];
    DefineWeakInstance(self);
    [self _loadAssetValus:_inputAsset completion:^(bool loaded)
    {
        if (loaded == YES) [WeakInstance _processInputAsset];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [WeakInstance resumDecode];
//        });
    }];
}

#pragma mark Load Asseet Valus
- (void)_loadAssetValus:(AVURLAsset *)inputAsset completion:(void(^)(bool loaded))completion
{
    [_inputAsset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
        NSError *error = nil;
        AVKeyValueStatus tracksStatus = [_inputAsset statusOfValueForKey:@"tracks" error:&error];
        switch (tracksStatus) {
            case AVKeyValueStatusLoaded:
            {
                HFDebugLog(@"[Decodec] : Status Loaded.");
                if (completion) completion(YES);
            }
                break;
            case AVKeyValueStatusLoading:
            {
                HFDebugLog(@"[Decodec] : Status Loading.");
            }
                break;
            case AVKeyValueStatusFailed:
            {
                HFDebugLog(@"[Decodec] : Status Failed. error:%@",error);
            }
                break;
            case AVKeyValueStatusCancelled:
            {
                HFDebugLog(@"[Decodec] : Status Cancelled.");
            }
                break;
            case AVKeyValueStatusUnknown:
            {
                HFDebugLog(@"[Decodec] : Status Unknown. error:%@",error);
            }
                break;
            default:
                break;
        }
    }];
}

- (void)_processInputAsset
{
    BOOL read = [self.inputAssetReader startReading];
    if (read == NO)
    {
        HFDebugLog(@"[Decodec] : Error reading from file at URL: %@. Error:%@", _inputAsset, _inputAssetReader.error);
        return;
    }
    HFDebugLog(@"[Decodec] : Start reading success.");
}

@end
