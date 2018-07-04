//
//  HFAVPlayerViewRender.m
//  HFAVPlayer
//
//  Created by pengfei28 on 2018/7/4.
//  Copyright © 2018年 pengfei. All rights reserved.
//

// 添加纹理

#import "HFAVPlayerViewRender.h"
@import Metal;

@interface HFAVPlayerViewRender()

{
    id <MTLCommandQueue> _commandQueue;
    id <MTLLibrary> _defaultLibrary;
    id <MTLRenderPipelineState> _pipelineState;
    id <MTLSamplerState> _samplerState;
    id <MTLBuffer> _parametersBuffer;
    
    //控制资源访问
    dispatch_semaphore_t _inflight_semaphore;
}

@property (nonatomic, weak) MTKView *mtkView;
@property (nonatomic, weak) id <MTLDevice> device;

@end

@implementation HFAVPlayerViewRender

- (instancetype)initWithMetalKitView:(MTKView *)mtkView
{
    self = [super init];
    if (self)
    {
        _mtkView = mtkView;
        [self _configWithMetalView:_mtkView];
    }
    return self;
}

- (void)_configWithMetalView:(MTKView *)mtkView
{
    _device = _mtkView.device;
    
    mtkView.depthStencilPixelFormat = MTLPixelFormatInvalid;
    mtkView.depthStencilPixelFormat = MTLPixelFormatInvalid;
    mtkView.sampleCount = 1;
    
    _commandQueue = [_device newCommandQueue];
    _defaultLibrary = [_device newDefaultLibrary];
    if (!_defaultLibrary) {
        HFDebugLog(@"TOTO:>> Error:Couldn't create a default shader library");
        return;
    }
    
    //渲染管线
    if ([self _preparePipelineState:mtkView] == NO) {
        HFDebugLog(@"TODO:>> Error:count't create a valid pipeline state");
        return;
    }
    
}

- (BOOL)_preparePipelineState:(MTKView *)mtkView
{
    ///加载定点函数/片段函数
    id <MTLFunction> vertexProgram = [_defaultLibrary newFunctionWithName:@"texture_vertex"];
    id <MTLFunction> fragmentProgram = [_defaultLibrary newFunctionWithName:@"yuv_rgb"];
    
    ///创建可重用的渲染管线
    //管线描述符（配置）
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineStateDescriptor.label = @"MyPipeline";
    //存储颜色数据附件
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipelineStateDescriptor.vertexFunction = vertexProgram;
    pipelineStateDescriptor.fragmentFunction = fragmentProgram;
    
    //渲染管线
    NSError *error = nil;
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    if (!_pipelineState) {
        HFDebugLog(@"[Render]:Error >> Failed Aquiring pipline state: %@",error);
        return NO;
    }
    
    ///采样器设置
    MTLSamplerDescriptor *samplerDescriptor = [MTLSamplerDescriptor new];
    samplerDescriptor.minFilter = MTLSamplerMinMagFilterNearest;
    samplerDescriptor.magFilter = MTLSamplerMinMagFilterLinear;
    _samplerState = [_device newSamplerStateWithDescriptor:samplerDescriptor];
    
//    _parametersBuffer = [_device newBufferWithLength:sizeof()*2 options:MTLResourceOptionCPUCacheModeDefault];
    
    return NO;
}

#pragma mark - delegate
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size
{
    HFDebugLog(@"[Render]:drawable size will change");
}

- (void)drawInMTKView:(MTKView *)view
{
    //TEST Color
    view.clearColor = MTLClearColorMake(0.3, 0.3, 0.3, 1);
    
    //检测当前信号量访问资源数，如果semaphore的value值为0的时候，线程将被阻塞，否则，semaphore的value值将--
    dispatch_semaphore_wait(_inflight_semaphore, DISPATCH_TIME_FOREVER);
    
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"MyCommandBuffer";
    
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    if (renderPassDescriptor != nil) {
        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        
        [self _renderTriangle:renderEncoder view:view name:@"Quad"];
        
        [renderEncoder endEncoding];
        
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    
    __block dispatch_semaphore_t block_sema = _inflight_semaphore;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
        
        // GPU has completed rendering the frame and is done using the contents of any buffers previously encoded on the CPU for that frame.
        // Signal the semaphore and allow the CPU to proceed and construct the next frame.
        // 发送消息给semaphore,收到消息后，semaphore的value值会++。如果此时线程处于休眠状态，线程会被唤醒，继续处理任务。
        dispatch_semaphore_signal(block_sema);
    }];
    
    [commandBuffer commit];
}

#pragma mark - 设置RenderEcoder
- (void)_renderTriangle:(id <MTLRenderCommandEncoder>)renderEncoder view:(MTKView *)view name:(NSString *)name
{
    [renderEncoder pushDebugGroup:name];
    
//    [renderEncoder setRenderPipelineState:<#(nonnull id<MTLRenderPipelineState>)#>];
    
    [renderEncoder popDebugGroup];
}

@end
