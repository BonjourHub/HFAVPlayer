//
//  HFMetalRender.h
//  HFAVPlayer
//
//  Created by 程鹏飞 on 2018/6/30.
//  Copyright © 2018年 pengfei. All rights reserved.
//

#import <Foundation/Foundation.h>
@import MetalKit;

@interface HFMetalRender : NSObject<MTKViewDelegate>

- (instancetype)initMetalRenderWithMetalKitView:(MTKView *)mtkView;

@end
