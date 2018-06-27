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
#import <libavutil/imgutils.h>
#import <libswscale/swscale.h>

typedef void(^HFAVPlayerDecoderCallBackMessage)(HFAVPlayerMessage *message);

@interface HFAVPlayerDecoder()

{
    NSInteger _videoStreamIndex;
}

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
    
    _videoStreamIndex = -1;
    for (int i = 0; i < formatCtx->nb_streams; i++)
    {
        if (formatCtx->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO)
        {
            _videoStreamIndex = i;
            break;
        }
    }
    
    if (_videoStreamIndex == -1) {
        id message = [self _messageWithType:HFAVPlayerMessageTypeError code:HFAVPlayerMessageDecoderCodeOpenVideoStreamFailed content:@"Didn't find a video stream."];
        if (_messageCallBack) _messageCallBack(message);
        HFDebugLog(@"HFAV-DE:Didn't find a video stream.");
        return NULL;
    }

    AVCodecContext *codecCtx = formatCtx->streams[_videoStreamIndex]->codec;
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

#pragma mark - 存储数据
- (void)_covertFrameFormatToRGBWithCodecCtx:(AVCodecContext *)codecCtx formatCtx:(AVFormatContext *)formatCtx
{
    AVFrame *frameRGB = av_frame_alloc();
    if (frameRGB == NULL)
    {
        HFDebugLog(@"HFAV-DE:frameRGB alloc error.");
    }
    
    //视频帧原始数据
    int numByte = av_image_get_buffer_size(AV_PIX_FMT_RGB24, codecCtx->width, codecCtx->height, 1);
    uint8_t *buffer = av_malloc(numByte * sizeof(uint8_t));
    av_image_fill_arrays(frameRGB->data, frameRGB->linesize, buffer, AV_PIX_FMT_RGB24, codecCtx->width, codecCtx->height, 1);
    
    //读取数据
    // Initialize SWS context for software scaling.
    struct SwsContext *swsCtx = sws_getContext(codecCtx->width, codecCtx->height, codecCtx->pix_fmt, codecCtx->width, codecCtx->height, AV_PIX_FMT_RGB24, SWS_BILINEAR, NULL, NULL, NULL);
    // Read frames and save first five frames to disk.
    AVFrame *frame = av_frame_alloc();
    AVPacket packet;
    int frameFinishedPtr;
    int i = 0;
    while (av_read_frame(formatCtx, &packet) >= 0)
    {
        // Is this a packet from the video stream?
        if (packet.stream_index == _videoStreamIndex)
        {
            //Decode video frame
            avcodec_decode_video2(codecCtx, frame, &frameFinishedPtr, &packet);
            
            //Did we get a video frame?
            if (frameFinishedPtr)
            {
                //Convert the image from its native format to RGB.
                sws_scale(swsCtx, (uint8_t const * const *)frame->data, frame->linesize, 0, codecCtx->height, frameRGB->data, frameRGB->linesize);
                
                //Save the frame to disk
                if (++i <= 5)
                {
                    
                }
            }
        }
    }
    
    free(buffer);
    av_frame_free(&frameRGB);
    av_frame_free(&frame);
}

void SaveFrame(AVFrame *frame, int width, int height, int iFrame)
{
    FILE *file;
    char szFilename[32];
    int y;
    
    // open file
    sprintf(szFilename, "frame%d.ppm",iFrame);
    file = fopen(szFilename, "wb");
    if (file == NULL) return;
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
