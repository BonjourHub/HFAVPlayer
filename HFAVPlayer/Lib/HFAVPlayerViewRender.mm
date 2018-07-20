//
//  HFAVPlayerViewRender.m
//  HFAVPlayer
//
//  Created by pengfei28 on 2018/7/4.
//  Copyright © 2018年 pengfei. All rights reserved.
//

// 添加纹理

#import "HFAVPlayerViewRender.h"
#import "HFAVPlayerViewRenderMakeTexture.h"
#import <Metal/Metal.h>
#import "HFAVPlayerViewRender+VideoData.h"

#import <simd/simd.h>

static const long kInFlightCommandBuffers = 3;

struct HFAVRenderColorParameters
{
    simd::float3x3 yuvToRGB;
};

//16:9
static const float quad[] =
{
    -1, 9/32.0, 0,  0, 0,
    1, -9/32.0, 0,  1, 1,
    1,  9/32.0, 0,  1, 0,
    
    -1,  9/32.0, 0,  0, 0,
    1, -9/32.0, 0,  1, 1,
    -1, -9/32.0, 0,  0, 1,
};

@interface HFAVPlayerViewRender()

{
    id <MTLCommandQueue> _commandQueue;
    id <MTLLibrary> _defaultLibrary;
    id <MTLRenderPipelineState> _pipelineState;
    id <MTLSamplerState> _samplerState;
    
    id <MTLBuffer> _parametersBuffer;
    id <MTLBuffer> _vertextBuffer;
    
    // 封面图
    HFAVPlayerViewRenderMakeTexture * _quadTex;
    
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
        _inflight_semaphore = dispatch_semaphore_create(kInFlightCommandBuffers);
        _mtkView = mtkView;
        BOOL config = [self _configWithMetalView:_mtkView];
        if (!config) return self;
        
        [self _setVideoTexture];
        
        //TEST
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"test" withExtension:@"mp4"];
        [self generateVideoDataWithURLString:[url absoluteString]];
        
    }
    return self;
}

#pragma mark - 配置渲染环境
- (BOOL)_configWithMetalView:(MTKView *)mtkView
{
    _device = _mtkView.device;
    
    mtkView.depthStencilPixelFormat = MTLPixelFormatInvalid;
    mtkView.depthStencilPixelFormat = MTLPixelFormatInvalid;
    mtkView.sampleCount = 1;
    
    _commandQueue = [_device newCommandQueue];
    _defaultLibrary = [_device newDefaultLibrary];
    if (!_defaultLibrary) {
        HFDebugLog(@"[Render]:TOTO:>> Error:Couldn't create a default shader library");
        return NO;
    }
    
    // 渲染管线
    if ([self _preparePipelineState:mtkView] == NO) {
        HFDebugLog(@"[Render]:TODO:>> Error:count't create a valid pipeline state");
        return NO;
    }
    
    // Allocate a buffer to store vertex position data (we'll quad buffer this one)
    _vertextBuffer = [_device newBufferWithBytes:quad length:sizeof(quad) options:MTLResourceCPUCacheModeDefaultCache];
    _vertextBuffer.label = @"Vertices";
    
    // 封面图（没有视频数据用）
    HFDebugLog(@"[Render]:TODO:>> 封面图可配置");
    _quadTex = [[HFAVPlayerViewRenderMakeTexture alloc] initWithResourceName:@"lena" extension:@"png"];
    BOOL load = [_quadTex loadIntoTextureWithDevice:_device];
    if (load == NO) {
        HFDebugLog(@"[Render]:Faild to load png texture.");
    }
    
    return YES;
}

#pragma mark 管线
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
    
    _parametersBuffer = [_device newBufferWithLength:sizeof(HFAVRenderColorParameters)*2 options:MTLResourceOptionCPUCacheModeDefault];
    HFAVRenderColorParameters matrix;
    simd::float3 A;
    simd::float3 B;
    simd::float3 C;
    
    A.x = 1.164;
    A.y = 1.164;
    A.z = 1.164;
    
    B.x = 0;
    B.y = -0.231;
    B.z = 2.112;
    
    C.x = 1.793;
    C.y = -0.533;
    C.z = 0;
    
    matrix.yuvToRGB = simd::float3x3{A, B, C};
    
    memcpy(_parametersBuffer.contents, &matrix, sizeof(HFAVRenderColorParameters));
    
    return YES;
}

#pragma mark - 设置视频纹理
- (void)_setVideoTexture
{
    CVMetalTextureCacheFlush(_videoTextureCache, 0);
    CVReturn error = CVMetalTextureCacheCreate(kCFAllocatorDefault, NULL, _device, NULL, &_videoTextureCache);
    if (error) {
        HFDebugLog(@"[Render]:>> ERROR: Could not create a texture cach");
        assert(0);
    }
}

#pragma mark - getter

#pragma mark - delegate
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size
{
    HFDebugLog(@"[Render]:drawable size will change");
}
- (void)drawInMTKView:(MTKView *)view
{}
#pragma mark 自定义绘制方法调用

/**
 解决解码渲染频率同步问题
 */
- (void)drawInRenderView
{
    MTKView *view = self.mtkView;
    //TEST Color
    view.clearColor = MTLClearColorMake(0.9, 0.5, 0.7, 0.8);
    
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
    
    [renderEncoder setRenderPipelineState:_pipelineState];
    
    [renderEncoder setVertexBuffer:_vertextBuffer offset:0 atIndex:0];
    
    [renderEncoder setFragmentBuffer:_parametersBuffer offset:0 atIndex:0];
    
    [renderEncoder setFragmentSamplerState:_samplerState atIndex:0];
    
    if (!_videoTexture[0])
    {
        [renderEncoder setFragmentTexture:_quadTex.texture atIndex:0];
        [renderEncoder setFragmentTexture:_quadTex.texture atIndex:1];
    }
    else
    {
        [renderEncoder setFragmentTexture:_videoTexture[0] atIndex:0];
        [renderEncoder setFragmentTexture:_videoTexture[1] atIndex:1];
    }
    
    // tell the render context we want to draw our primitives
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6 instanceCount:2];
    
    [renderEncoder popDebugGroup];
}


@end
