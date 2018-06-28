//
//  ViewController.m
//  HFAVPlayer
//
//  Created by 程鹏飞 on 2018/6/23.
//  Copyright © 2018年 pengfei. All rights reserved.
//

#import "ViewController.h"

#import <libavformat/avformat.h>

#import "HFAVPlayerDecoder.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor grayColor];
    
//    [self decode];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"flv"];
    
    HFAVPlayerDecoder *decoder = [HFAVPlayerDecoder new];
    NSMutableArray *frames = [decoder _decodeFrameWithFileName:filePath];
    
    HFDebugLog(@"frame count:%ld",frames.count);
}

- (void)decode {
    
    //注册解码器
    av_register_all();
    avformat_network_init();
    
    //打开文件
    AVFormatContext *formatContext = avformat_alloc_context();
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"flv"];
    if (avformat_open_input(&formatContext, [filePath UTF8String], NULL, NULL) != 0) {
        HFTODODebugLog(@"打开失败");
        return;
    }
    HFDebugLog(@"打开成功");
    
    //从文件中提取流信息
    if (avformat_find_stream_info(formatContext, NULL) < 0)
    {
        HFTODODebugLog(@"没有找到流信息");
        return;
    }
    
    //穷举所有流，查找需要的流类型
    int videoIndex = -1;
    int audioIndex = -1;
    for (int i = 0; i < formatContext->nb_streams; i++)
    {
        enum AVMediaType mediaType = formatContext->streams[i]->codec->codec_type;
        if (mediaType == AVMEDIA_TYPE_VIDEO)
        {
            HFDebugLog(@"发现一路视频流");
            videoIndex = i;
            continue;
        }
        if (mediaType == AVMEDIA_TYPE_AUDIO)
        {
            HFDebugLog(@"发现一路音频流");
            audioIndex = i;//考虑有多路音频流
            continue;
        }
        HFDebugLog(@"发现一路其他流");
    }
    
    //查找指定类型流的解码器(视频流)
    AVCodecContext *codecContext = formatContext->streams[videoIndex]->codec;
    AVCodec *codec = avcodec_find_decoder(codecContext->codec_id);
    if (codec == NULL) {
        HFTODODebugLog(@"查找解码器失败");
        return;
    }
    HFDebugLog(@"查找解码器成功");
    
    //打开指定的解码器
    if (avcodec_open2(codecContext, codec, NULL) < 0) {
        HFTODODebugLog(@"打开解码器失败");
        return;
    }
    HFDebugLog(@"打开解码器成功");
    
    //为解码帧分配内存
    AVFrame *frame = av_frame_alloc();
    AVFrame *framYUV = av_frame_alloc();
    
    //不断的从码流中提取帧数据(子线程)
    AVPacket *packet = av_malloc(sizeof(AVPacket));
    if (av_read_frame(formatContext, packet) < 0) {
        HFTODODebugLog(@"帧数据读取失败 退出子线程");
        return;
    }
    
    //判断帧类型，调用对应类型解码器解码
    int gotPicture = -1;
    if (packet->stream_index == videoIndex) {
        HFDebugLog(@"视频流类型");
        if (avcodec_decode_video2(codecContext, frame, &gotPicture, packet) < 0) {
            HFTODODebugLog(@"解码错误");
            return;
        }
        HFDebugLog(@"解码成功");
    }
    
    //close
    av_frame_free(&frame);
    av_frame_free(&framYUV);
    
    //解码完成后 释放解码器
    avcodec_close(codecContext);
    
    //关闭输入文件
    avformat_close_input(&formatContext);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
