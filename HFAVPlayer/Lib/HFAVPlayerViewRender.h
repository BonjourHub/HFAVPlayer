//
//  HFAVPlayerViewRender.h
//  HFAVPlayer
//
//  Created by pengfei28 on 2018/7/4.
//  Copyright © 2018年 pengfei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>

// Our platform independent renderer class
@interface HFAVPlayerViewRender : NSObject<MTKViewDelegate>

- (instancetype)initWithMetalKitView:(MTKView *)mtkView;

@end
