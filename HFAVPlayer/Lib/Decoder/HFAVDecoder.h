//
//  HFAVDecoder.h
//  HFAVPlayer
//
//  Created by pengfei28 on 2018/7/5.
//  Copyright © 2018年 pengfei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef void(^HFAVDecoderCallBack)(CVPixelBufferRef pixelBuffer, NSError *error);

@interface HFAVDecoder : NSObject

- (void)decodecWithURL:(NSURL *)url completion:(HFAVDecoderCallBack)completion;

@end
