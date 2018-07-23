//
//  HFAVPlayerView.m
//  HFAVPlayer
//
//  Created by pengfei28 on 2018/7/4.
//  Copyright © 2018年 pengfei. All rights reserved.
//

#import "HFAVPlayerView.h"
#import "HFAVPlayerViewRender.h"
#import "HFAVDecoder.h"
#import "HFAVPlayerVideoRender.h"

@import MetalKit;
@import Metal;

@interface HFAVPlayerView()<HFAVPlayerVideoRenderDataSource>

@property (nonatomic, strong) HFAVDecoder *decoder;
@property (nonatomic, strong) HFAVPlayerVideoRender *videoRender;

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
    [self addSubview:self.videoRender];
    
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _videoRender.frame = self.bounds;
}

#pragma mark - getter
- (HFAVPlayerVideoRender *)videoRender
{
    if (!_videoRender)
    {
        _videoRender = [HFAVPlayerVideoRender new];
        _videoRender.dataSource = self;
    }
    return _videoRender;
}

- (HFAVDecoder *)decoder
{
    if (!_decoder)
    {
        _decoder = [HFAVDecoder new];
    }
    return _decoder;
}

#pragma mark - Public
- (void)playWithURL:(NSURL *)url
{
    [self.decoder decodecWithURL:url completion:nil];
}

#pragma mark - DataSource
- (CMSampleBufferRef)playerRenderView:(HFAVPlayerVideoRender *)render mtkView:(MTKView *)mtkView
{
    return [self.decoder videoSampleBufferRef];
}

@end
