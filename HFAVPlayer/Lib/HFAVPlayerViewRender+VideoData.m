//
//  HFAVPlayerViewRender+VideoData.m
//  HFAVPlayer
//
//  Created by pengfei28 on 2018/7/4.
//  Copyright © 2018年 pengfei. All rights reserved.
//

#import "HFAVPlayerViewRender+VideoData.h"
#import "HFAVDecoder.h"

@interface HFAVPlayerViewRender()

@end

@implementation HFAVPlayerViewRender (VideoData)

- (void)generateVideoDataWithURLString:(NSString *)urlString
{
    static HFAVDecoder *decoder = nil;
    decoder = [[HFAVDecoder alloc] init];
    DefineWeakInstance(self);
    [decoder decodecWithURL:[NSURL URLWithString:urlString] completion:^(CVPixelBufferRef pixelBuffer, NSError *error)
     {
        HFDebugLog(@"[Decodec] : pix");
        if (pixelBuffer) [WeakInstance _display:pixelBuffer];
         [WeakInstance drawInRenderView];
    }];
}

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
