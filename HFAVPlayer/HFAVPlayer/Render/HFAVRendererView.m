//
//  HFAVRendererView.m
//  HFAVPlayer
//
//  Created by pengfei28 on 2018/6/28.
//  Copyright © 2018年 pengfei. All rights reserved.
//

#import "HFAVRendererView.h"

@implementation HFAVRendererView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
//        self.backgroundColor = [UIColor blackColor];
    }
    return self;
}

- (void)layoutSubviews
{
//    [super layoutSubviews];
    
    [self setupLayer];
    [self setupContext];
    
    [self destoryRenderAnderFrameBuffer];
    
    [self setupRenderBuffer];
    [self setupFrameBuffer];
    
    [self render];
}

#pragma mark 修改默认layer类型
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

#pragma mark 配置layer
- (void)setupLayer
{
    _eaglLayer = (CAEAGLLayer *)self.layer;
    _eaglLayer.opaque = YES;
    // 不维持渲染内容 颜色格式RGBA8
    _eaglLayer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking:[NSNumber numberWithBool:NO],kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGBA8};
}

#pragma makr 配置上下文
- (void)setupContext
{
    EAGLRenderingAPI api2 = kEAGLRenderingAPIOpenGLES2;
    _context = [[EAGLContext alloc] initWithAPI:api2];
    if (!_context)
    {
        HFDebugLog(@"HFVR: 创建 OpenGLES 2.0 失败.");
        exit(1);
    }
    
    //设置为当前上下文
    if (![EAGLContext setCurrentContext:_context])
    {
        HFDebugLog(@"HFVR: 设置当前 OpenGL context 失败.");
        exit(1);
    }
}

#pragma mark 创建RenderBuffer
- (void)setupRenderBuffer
{
    glGenBuffers(1, &_colorRenderBuffer);
    glBindBuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    
    //为 color renderbuffer 分配存储空间
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
}

#pragma mark 创建 framebuffer object
- (void)setupFrameBuffer
{
    glGenFramebuffers(1, &_frameBuffer);
    // 设置为当前的 framebuffer
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    // 将_colorRenderBuffer 装配到 GL_COLOR_ATTACHMENT0 这个装配点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
}

#pragma mark 销毁生成的buffer
- (void)destoryRenderAnderFrameBuffer
{
    glDeleteBuffers(1, &_colorRenderBuffer);
    _colorRenderBuffer = 0;
    glDeleteBuffers(1, &_frameBuffer);
    _frameBuffer = 0;
}

#pragma mark 渲染
- (void)render
{
    glClearColor(0, 0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    BOOL presnt = [_context presentRenderbuffer:GL_RENDERBUFFER];
}

@end
