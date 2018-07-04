//
//  HFAVPlayerViewRender.h
//  HFAVPlayer
//
//  Created by pengfei28 on 2018/7/4.
//  Copyright © 2018年 pengfei. All rights reserved.
//

#import <Foundation/Foundation.h>
@import MetalKit;

//#import <simd/simd.h>
//
//struct HFAVRenderColorParameters
//{
////    simd::float3x3 yuvToRGB;
//};

// Our platform independent renderer class
@interface HFAVPlayerViewRender : NSObject<MTKViewDelegate>

- (instancetype)initWithMetalKitView:(MTKView *)mtkView;

@end
