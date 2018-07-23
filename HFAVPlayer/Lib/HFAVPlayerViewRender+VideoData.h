//
//  HFAVPlayerViewRender+VideoData.h
//  HFAVPlayer
//
//  Created by pengfei28 on 2018/7/4.
//  Copyright © 2018年 pengfei. All rights reserved.
//

#import "HFAVPlayerViewRender.h"

@interface HFAVPlayerViewRender (VideoData)

- (void)generateVideoDataWithURLString:(NSString *)urlString;

-  (void)_display:(CVPixelBufferRef)overlay;

@end
