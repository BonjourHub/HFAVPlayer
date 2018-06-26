//
//  HFAVPlayerDecoder.m
//  HFAVPlayer
//
//  Created by pengfei28 on 2018/6/26.
//  Copyright © 2018年 pengfei. All rights reserved.
//

#import "HFAVPlayerDecoder.h"
#import "HFAVPlayerMessage.h"
#import "HFAVPlayerEnum.h"

#import <libavformat/avformat.h>
#import <libavcodec/avcodec.h>

typedef void(^HFAVPlayerDecoderCallBackMessage)(HFAVPlayerMessage *message);

@interface HFAVPlayerDecoder()
@property (nonatomic, copy) HFAVPlayerDecoderCallBackMessage messageCallBack;
@end

@implementation HFAVPlayerDecoder

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self _register];
    }
    return self;
}

- (void)_register
{
    // Register all formats and codecs.
    av_register_all();
    avformat_network_init();
}

#pragma mark - 打开文件
- (AVFormatContext *)_openVideoFileWithFileName:(NSString *)fileName
{
    AVFormatContext *formatContext = NULL;
    if (avformat_open_input(&formatContext, [fileName UTF8String], NULL, NULL) < 0)
    {
        id message = [self _messageWithType:HFAVPlayerMessageTypeError code:HFAVPlayerMessageDecoderCodeOpenInputFailed content:@"Couldn't open file."];
        if (_messageCallBack) _messageCallBack (message);
        HFDebugLog(@"HFAV-DE:Couldn't open file.");
        return nil;
    }
    HFDebugLog(@"HFAV-DE:Open file.");
    return formatContext;
}

#pragma mark - 获取解码器
- (BOOL)_retrieveStreamInfomationFormatCtx:(AVFormatContext *)formatCtx
{
    if (avformat_find_stream_info(formatCtx, NULL) < 0)
    {
        id message = [self _messageWithType:HFAVPlayerMessageTypeError code:HFAVPlayerMessageDecoderCodeOpenVideoStreamFailed content:@"Couldn't find stream information."];
        if (_messageCallBack) _messageCallBack(message);
        HFDebugLog(@"HFAV-DE:文件内没有流信息");
        return NO;
    }
    
    return YES;
}

- (AVCodecContext *)_getVideoStreamCodecContextWithFormatCtx:(AVFormatContext *)formatCtx
{
    if ([self _retrieveStreamInfomationFormatCtx:formatCtx] == NO) return NULL;
    
    NSInteger videoStreamIndex = -1;
    for (int i = 0; i < formatCtx->nb_streams; i++)
    {
        if (formatCtx->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO)
        {
            videoStreamIndex = i;
            break;
        }
    }
    
    if (videoStreamIndex == -1) {
        id message = [self _messageWithType:HFAVPlayerMessageTypeError code:HFAVPlayerMessageDecoderCodeOpenVideoStreamFailed content:@"Didn't find a video stream."];
        if (_messageCallBack) _messageCallBack(message);
        HFDebugLog(@"HFAV-DE:Didn't find a video stream.");
        return NULL;
    }

    AVCodecContext *codecCtx = formatCtx->streams[videoStreamIndex]->codec;
    return codecCtx;
}

- (AVCodecContext *)_getAudioStreamCodecContextWithFormatCtx:(AVFormatContext *)formatCtx {
    
    return NULL;
}

- (BOOL)_openVideoDecoderWithFormatCtx:(AVFormatContext *)formatCtx
{
    AVCodecContext *videoCodecCtx = [self _getVideoStreamCodecContextWithFormatCtx:formatCtx];
    if (videoCodecCtx == NULL) return NO;
    
    AVCodec *codec = avcodec_find_decoder(videoCodecCtx->codec_id);
    if (codec == NULL) {
        id message = [self _messageWithType:HFAVPlayerMessageTypeError code:HFAVPlayerMessageDecoderCodeNoCodec content:@"Unsupported codec!"];
        if (_messageCallBack) _messageCallBack(message);
        HFDebugLog(@"HFAV-DE:视频解码器不支持");
        return NO;
    }
    
    //copy context
    AVCodecContext *codecCtx = avcodec_alloc_context3(codec);
    if (avcodec_copy_context(codecCtx, videoCodecCtx) != 0) {
        HFDebugLog(@"HFAV-DE:视频解器上下文拷贝失败");
        return NO;
    }
    
    //open codec
    if (avcodec_open2(codecCtx, codec, NULL) < 0) {
        HFDebugLog(@"HFAV-DE:视频解码器打开失败");
        return NO;
    }
    
    return YES;
}

#pragma mark - helper
- (id)_messageWithType:(HFAVPlayerMessageType)type code:(HFAVPlayerMessageDecoderCode)code content:(NSString *)content
{
    return [HFAVPlayerMessage messageWithType:type code:code content:content];
}

#pragma mark - public
- (void)decodeVideoWithFileName:(NSString *)fileName
{
    AVFormatContext *formatCtx = [self _openVideoFileWithFileName:fileName];
    if (!formatCtx) return;
    
    //调试输出formatCtx中信息
//    av_dump_format(formatCtx, 0, NULL, NULL);
    
    BOOL openCodex = [self _openVideoDecoderWithFormatCtx:formatCtx];
    if (openCodex == NO) return;
}

@end
