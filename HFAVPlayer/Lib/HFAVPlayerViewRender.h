//
//  HFAVPlayerViewRender.h
//  HFAVPlayer
//
//  Created by pengfei28 on 2018/7/4.
//  Copyright © 2018年 pengfei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>
#import <AVFoundation/AVFoundation.h>

// Our platform independent renderer class
@interface HFAVPlayerViewRender : NSObject<MTKViewDelegate>

{
    id<MTLTexture> _videoTexture[2];
    CVMetalTextureCacheRef _videoTextureCache;
}

- (instancetype)initWithMetalKitView:(MTKView *)mtkView;
/**
  自定义绘制方法，解决解码渲染频率同步问题
 */
- (void)drawInRenderView;
@end
