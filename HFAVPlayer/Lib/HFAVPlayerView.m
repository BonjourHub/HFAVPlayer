//
//  HFAVPlayerView.m
//  HFAVPlayer
//
//  Created by pengfei28 on 2018/7/4.
//  Copyright © 2018年 pengfei. All rights reserved.
//

#import "HFAVPlayerView.h"
#import "HFAVPlayerViewRender.h"

@import MetalKit;
@import Metal;

@interface HFAVPlayerView()

@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) HFAVPlayerViewRender *render;

@end

@implementation HFAVPlayerView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self _addSubviews];
    }
    return self;
}

- (void)_addSubviews
{
    [self addSubview:self.mtkView];
    
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _mtkView.frame = self.bounds;
}

#pragma mark - getter
- (MTKView *)mtkView
{
    if (!_mtkView) {
        _mtkView = [MTKView new];
        _mtkView.device = MTLCreateSystemDefaultDevice();
        if (!_mtkView.device) HFDebugLog(@"TODO:Metal is not supported on this device");
        _mtkView.delegate = self.render;
    }
    return _mtkView;
}

- (HFAVPlayerViewRender *)render
{
    if (!_render) {
        _render = [[HFAVPlayerViewRender alloc] initWithMetalKitView:self.mtkView];
    }
    return _render;
}

@end
