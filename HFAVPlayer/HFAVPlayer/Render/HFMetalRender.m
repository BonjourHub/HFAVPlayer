//
//  HFMetalRender.m
//  HFAVPlayer
//
//  Created by 程鹏飞 on 2018/6/30.
//  Copyright © 2018年 pengfei. All rights reserved.
//

#import "HFMetalRender.h"

@interface HFMetalRender()

{
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;
}

@end

typedef struct {
    float red;
    float green;
    float blue;
    float alpha;
}Color;

@implementation HFMetalRender

- (instancetype)initMetalRenderWithMetalKitView:(MTKView *)mtkView
{
    self = [super init];
    if (self) {
        _device = mtkView.device;
        _commandQueue = [_device newCommandQueue];
    }
    return self;
}

//随机生成梦幻色
- (Color)makeFancyColor
{
    static BOOL       growing = YES;
    static NSUInteger primaryChannel = 0;
    static float      colorChannels[] = {1.0, 0.0, 0.0, 1.0};
    
    const float DynamicColorRate = 0.015;
    
    if(growing)
    {
        NSUInteger dynamicChannelIndex = (primaryChannel+1)%3;
        colorChannels[dynamicChannelIndex] += DynamicColorRate;
        if(colorChannels[dynamicChannelIndex] >= 1.0)
        {
            growing = NO;
            primaryChannel = dynamicChannelIndex;
        }
    }
    else
    {
        NSUInteger dynamicChannelIndex = (primaryChannel+2)%3;
        colorChannels[dynamicChannelIndex] -= DynamicColorRate;
        if(colorChannels[dynamicChannelIndex] <= 0.0)
        {
            growing = YES;
        }
    }
    
    Color color;
    
    color.red   = colorChannels[0];
    color.green = colorChannels[1];
    color.blue  = colorChannels[2];
    color.alpha = colorChannels[3];
    
    return color;
}

#pragma mark - delegate
- (void)drawInMTKView:(MTKView *)view
{
    Color color = [self makeFancyColor];
    view.clearColor = MTLClearColorMake(color.red, color.green, color.blue, color.alpha);
    
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"myBuffer";
    
    MTLRenderPassDescriptor *descriptor = view.currentRenderPassDescriptor;
    if (descriptor != nil) {
        id<MTLCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:descriptor];
        [encoder endEncoding];
        
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    
    [commandBuffer commit];
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size
{
    NSLog(@"size will change");
}

@end
