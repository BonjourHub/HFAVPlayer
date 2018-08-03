//
//  HFAVPlayerVideoRender.m
//  HFAVPlayer
//
//  Created by pengfei28 on 2018/7/23.
//  Copyright © 2018年 pengfei. All rights reserved.
//

#import "HFAVPlayerVideoRender.h"
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import "HFAVPlayerViewRenderMakeTexture.h"

static const long kInFlightCommandBuffers = 3;//每次访问三个

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

//static const float quad[] =
//{
//    -1, 1, 0,  0, 0,
//    1, -1, 0,  1, 1,
//    1,  1, 0,  1, 0,
//
//    -1,  1, 0,  0, 0,
//    1, -1, 0,  1, 1,
//    -1, -1, 0,  0, 1,
//};

struct HFAVRenderColorParameters
{
    simd::float3x3 yuvToRGB;
};

@interface HFAVPlayerVideoRender()<MTKViewDelegate>
{
    //控制资源访问
    dispatch_semaphore_t _inflight_semaphore;
    
    id <MTLCommandQueue> _commandQueue;
    id <MTLLibrary> _defaultLibrary;
    id <MTLRenderPipelineState> _pipelineState;
    id <MTLSamplerState> _samplerState;
    
    id <MTLBuffer> _parametersBuffer;
    id <MTLBuffer> _vertextBuffer;
    
    // 封面图
    HFAVPlayerViewRenderMakeTexture * _quadTex;
    
    id<MTLTexture> _videoTexture[2];
    CVMetalTextureCacheRef _videoTextureCache;
}
@property (nonatomic, strong) MTKView *mtkView;

@end

@implementation HFAVPlayerVideoRender

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self _addSubviews];
        
        _inflight_semaphore = dispatch_semaphore_create(kInFlightCommandBuffers);
        BOOL config = [self _configWithMetalView:self.mtkView];
        if (!config) return self;
        
        [self _setVideoTexture];
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
        _mtkView.delegate = self;
//        [self _preferredFramesPerSecond:60];
        
//         TEST 等解码完成 再渲染
        _mtkView.paused = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            _mtkView.paused = NO;
        });
    }
    return _mtkView;
}

#pragma mark - Config
#pragma mark 配置渲染环境
- (BOOL)_configWithMetalView:(MTKView *)mtkView
{
    id<MTLDevice> device = _mtkView.device;
    
    mtkView.depthStencilPixelFormat = MTLPixelFormatInvalid;
    mtkView.depthStencilPixelFormat = MTLPixelFormatInvalid;
    mtkView.sampleCount = 1;
    
    _commandQueue = [device newCommandQueue];
    _defaultLibrary = [device newDefaultLibrary];
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
    _vertextBuffer = [device newBufferWithBytes:quad length:sizeof(quad) options:MTLResourceCPUCacheModeDefaultCache];
    _vertextBuffer.label = @"Vertices";
    
    // 封面图（没有视频数据用）
    HFDebugLog(@"[Render]:TODO:>> 封面图可配置");
    _quadTex = [[HFAVPlayerViewRenderMakeTexture alloc] initWithResourceName:@"lena" extension:@"png"];
    BOOL load = [_quadTex loadIntoTextureWithDevice:mtkView.device];
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
    _pipelineState = [mtkView.device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    if (!_pipelineState) {
        HFDebugLog(@"[Render]:Error >> Failed Aquiring pipline state: %@",error);
        return NO;
    }
    
    ///采样器设置
    MTLSamplerDescriptor *samplerDescriptor = [MTLSamplerDescriptor new];
    samplerDescriptor.minFilter = MTLSamplerMinMagFilterNearest;
    samplerDescriptor.magFilter = MTLSamplerMinMagFilterLinear;
    _samplerState = [mtkView.device newSamplerStateWithDescriptor:samplerDescriptor];
    
    _parametersBuffer = [mtkView.device newBufferWithLength:sizeof(HFAVRenderColorParameters)*2 options:MTLResourceOptionCPUCacheModeDefault];
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
    CVReturn error = CVMetalTextureCacheCreate(kCFAllocatorDefault, NULL, _mtkView.device, NULL, &_videoTextureCache);
    if (error) {
        HFDebugLog(@"[Render]:>> ERROR: Could not create a texture cach");
        assert(0);
    }
}

#pragma mark - MTKViewDelegate
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size
{}
- (void)drawInMTKView:(MTKView *)view
{
    if ([self.dataSource respondsToSelector:@selector(playerRenderView:mtkView:)])
    {
        CMSampleBufferRef sampleBuffer = [self.dataSource playerRenderView:self mtkView:view];
        CVPixelBufferRef pixBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        if (pixBuffer)
        {
            [self _display:pixBuffer];
            [self drawInRenderView];
            CFRelease(pixBuffer);
        }
    }
}

@end


@implementation HFAVPlayerVideoRender (Texture)
#pragma mark - 数据填充
-  (void)_display:(CVPixelBufferRef)overlay {
    if (!overlay) {
        return;
    }
    
    if (!_videoTextureCache) {
        NSLog(@"No video texture cache");
        return;
    }
    
    [self _makeYUVTexture:overlay];
}

- (void)_makeYUVTexture:(CVPixelBufferRef)pixelBuffer {
    CVMetalTextureRef y_texture ;
    float y_width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0);
    float y_height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);
    CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _videoTextureCache, pixelBuffer, nil, MTLPixelFormatR8Unorm, y_width, y_height, 0, &y_texture);
    
    CVMetalTextureRef uv_texture;
    float uv_width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 1);
    float uv_height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1);
    CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _videoTextureCache, pixelBuffer, nil, MTLPixelFormatRG8Unorm, uv_width, uv_height, 1, &uv_texture);
    
    id<MTLTexture> luma = CVMetalTextureGetTexture(y_texture);
    id<MTLTexture> chroma = CVMetalTextureGetTexture(uv_texture);
    
    _videoTexture[0] = luma;
    _videoTexture[1] = chroma;
    
    CVBufferRelease(y_texture);
    CVBufferRelease(uv_texture);
}
@end

//#import "HFAVPlayerVideoRender+Draw.h"
@implementation HFAVPlayerVideoRender (Draw)

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

