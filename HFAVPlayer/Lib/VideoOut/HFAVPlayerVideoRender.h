//
//  HFAVPlayerVideoRender.h
//  HFAVPlayer
//
//  Created by pengfei28 on 2018/7/23.
//  Copyright © 2018年 pengfei. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class HFAVPlayerVideoRender;
@class MTKView;
@protocol HFAVPlayerVideoRenderDataSource<NSObject>

- (CMSampleBufferRef)playerRenderView:(HFAVPlayerVideoRender *)render mtkView:(MTKView *)mtkView;

@end

@interface HFAVPlayerVideoRender : UIView

@property (nonatomic, weak) id<HFAVPlayerVideoRenderDataSource> dataSource;

@end

@interface HFAVPlayerVideoRender (Texture)
-  (void)_display:(CVPixelBufferRef)overlay;
@end

@interface HFAVPlayerVideoRender (Draw)
- (void)drawInRenderView;
@end


