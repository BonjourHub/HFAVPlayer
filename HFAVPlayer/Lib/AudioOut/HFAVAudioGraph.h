//
//  HFAVAudioGraph.h
//  test
//
//  Created by pengfei28 on 2018/7/19.
//  Copyright © 2018年 bj-m-206066a. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@protocol HFAVAudioGraphRenderDelegate <NSObject>

- (AudioBufferList *)audioRenderGetBufferList;
- (CMSampleBufferRef)audioRenderGetSampleBuffer;

@end

@interface HFAVAudioGraph : NSObject

@property (nonatomic, weak) id<HFAVAudioGraphRenderDelegate>delegate;

- (void)start;

@end
