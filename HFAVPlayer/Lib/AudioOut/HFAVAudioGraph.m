//
//  HFAVAudioGraph.m
//  test
//
//  Created by pengfei28 on 2018/7/19.
//  Copyright © 2018年 bj-m-206066a. All rights reserved.
//

#import "HFAVAudioGraph.h"
#import <AVFoundation/AVFoundation.h>

@interface HFAVAudioGraph ()

{
    AUGraph _auGraph;
    AUNode _outNode;
    AudioUnit _outAudioUnit;
    
    UInt32 _readedSize;
    
    AudioBufferList _sampleBufferList;
    
}

@property (nonatomic, assign) AudioBufferList *bufferList;

@end

#define OUTPUT_BUS 0

@implementation HFAVAudioGraph

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self _audioSession];
        [self _setup];
    }
    return self;
}

- (void)_audioSession
{
    NSError *error = nil;
    AVAudioSession *audioSesstion = [AVAudioSession sharedInstance];
    [audioSesstion setCategory:AVAudioSessionCategoryPlayback error:&error];
    if (error) NSLog(@"初始化失败:%@",error);
}

#pragma mark - setup
- (void)_setup
{
    OSStatus status = noErr;
    
    status = [self _newAudioGraph];
    
    status = [self _addAudioGraphNode];
    
    status = [self _openAudioGraph];
    
    status = [self _getAudioGraphNodeInfo];
    
    status = [self _setAudioGraphProperty];
    
    [self _registerAudioGraphCallBack];
    
    CAShow(_auGraph);
    
    status = AUGraphInitialize(_auGraph);
}

#pragma mark - graph
- (OSStatus)_newAudioGraph
{
    return  NewAUGraph(&_auGraph);
}

- (OSStatus)_openAudioGraph
{
    return AUGraphOpen(_auGraph);
}

- (OSStatus)_addAudioGraphNode
{
    AudioComponentDescription inDes = [self __componentDescription];
    return AUGraphAddNode(_auGraph, &inDes, &_outNode);
}

- (OSStatus)_getAudioGraphNodeInfo
{
    return AUGraphNodeInfo(_auGraph, _outNode, NULL, &_outAudioUnit);
}

- (OSStatus)_setAudioGraphProperty
{
    UInt32 flag = 1;
    AudioUnitSetProperty(_outAudioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, OUTPUT_BUS, &flag, sizeof(flag));
    
    AudioStreamBasicDescription audioStreamDes = [self __streamDes];
    return AudioUnitSetProperty(_outAudioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, OUTPUT_BUS, &audioStreamDes, sizeof(audioStreamDes));
}

- (OSStatus)_registerAudioGraphCallBack
{
    AURenderCallbackStruct playCallBack;
    playCallBack.inputProc = PlayCallBack;
    playCallBack.inputProcRefCon = (__bridge void *)self;
    return AudioUnitSetProperty(_outAudioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, OUTPUT_BUS, &playCallBack, sizeof(playCallBack));
}

#pragma mark - Call Back
static OSStatus PlayCallBack(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData)
{
    HFAVAudioGraph *audioPlayer = (__bridge id)inRefCon;
    return [audioPlayer _processAudioRenderData:ioData flags:ioActionFlags timeStamp:inTimeStamp inBusNumber:inBusNumber inNumberFrames:inNumberFrames];
}

- (OSStatus)_processAudioRenderData:(AudioBufferList *)ioData flags:(AudioUnitRenderActionFlags *)flags timeStamp:(const AudioTimeStamp *)timeStamp inBusNumber:(UInt32)inBusNumber inNumberFrames:(UInt32)inNumberFrames
{
    @autoreleasepool
    {
        if (!_bufferList || _readedSize + ioData->mBuffers[0].mDataByteSize > _bufferList->mBuffers[0].mDataByteSize)
        {
            _bufferList = [self __getBufferList];
            _readedSize = 0;
        }
        
        if (!_bufferList || _bufferList->mNumberBuffers == 0)
        {
            DefineWeakInstance(self);
            dispatch_async(dispatch_get_main_queue(), ^{
                [WeakInstance stop];
            });
        }
        
        else
        {
            for (int i = 0; i < _bufferList->mNumberBuffers; i++)
            {
                HFDebugLog(@"audio tianchong");
                memcpy(ioData->mBuffers[i].mData, _bufferList->mBuffers[i].mData + _readedSize, ioData->mBuffers[i].mDataByteSize);
                _readedSize += ioData->mBuffers[i].mDataByteSize;
            }
        }
        return noErr;
    }
}

- (AudioBufferList *)__getBufferList
{
    if ([self.delegate respondsToSelector:@selector(audioRenderGetBufferList)])
    {
        return [self.delegate audioRenderGetBufferList];
    }
    else if ([self.delegate respondsToSelector:@selector(audioRenderGetSampleBuffer)])
    {
        return [self __audioBufferListWithSampleBuffer:[self.delegate audioRenderGetSampleBuffer]];
    }
    return nil;
}

- (AudioBufferList *)__audioBufferListWithSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    HFDebugLog(@"HF-AG-sampleBuffer %@",sampleBuffer);
    if (!sampleBuffer)
    {
        [self stop];
        return nil;
    }
    CMBlockBufferRef blockBufferOut = NULL;
//    size_t bufferListSizeNeededOut = 0;
//    OSStatus status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, &bufferListSizeNeededOut, &_sampleBufferList, sizeof(_sampleBufferList), kCFAllocatorSystemDefault, kCFAllocatorSystemDefault, kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment, &blockBufferOut);
        OSStatus status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, &_sampleBufferList, sizeof(_sampleBufferList), NULL, NULL, 0, &blockBufferOut);
    CFRelease(sampleBuffer);
    
    return &_sampleBufferList;
}

#pragma mark - common
- (AudioComponentDescription)__componentDescription
{
    AudioComponentDescription description;
    description.componentType = kAudioUnitType_Output;
    description.componentSubType = kAudioUnitSubType_RemoteIO;
    description.componentManufacturer = kAudioUnitManufacturer_Apple;
    description.componentFlags = 0;
    description.componentFlagsMask = 0;
    
    return description;
}

- (AudioStreamBasicDescription)__streamDes
{
    AudioStreamBasicDescription streamDes;
    memset(&streamDes, 0, sizeof(streamDes));
    streamDes.mSampleRate = 44100;
    streamDes.mFormatID = kAudioFormatLinearPCM;
    streamDes.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger;
    streamDes.mFramesPerPacket = 1;
    streamDes.mChannelsPerFrame = 1;
    streamDes.mBytesPerFrame = 2;
    streamDes.mBytesPerPacket = 2;
    streamDes.mBitsPerChannel = 16;
    
    return streamDes;
}

#pragma mark - getter


#pragma mark - public
- (void)start
{
    AUGraphStart(_auGraph);
}

- (void)stop
{
    AUGraphStop(_auGraph);
    HFDebugLog(@"audio stop");
}



@end
