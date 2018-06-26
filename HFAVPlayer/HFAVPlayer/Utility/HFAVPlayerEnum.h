//
//  HFAVPlayerEnum.h
//  HFAVPlayer
//
//  Created by pengfei28 on 2018/6/26.
//  Copyright © 2018年 pengfei. All rights reserved.
//

#ifndef HFAVPlayerEnum_h
#define HFAVPlayerEnum_h

typedef NS_ENUM(NSUInteger, HFAVPlayerMessageDecoderCode) {
    HFAVPlayerMessageDecoderCodeOpenInputFailed = 10000,//打开文件失败
    HFAVPlayerMessageDecoderCodeOpenVideoStreamFailed,//Didn't find a video stream.
    HFAVPlayerMessageDecoderCodeNoCodec,//解码器不支持
    
};

typedef NS_ENUM(NSUInteger, HFAVPlayerMediaType) {
    HFAVPlayerMediaTypeVideo,
    HFAVPlayerMediaTypeAudio,
    HFAVPlayerMediaTypeUnknow,
};

#endif /* HFAVPlayerEnum_h */
