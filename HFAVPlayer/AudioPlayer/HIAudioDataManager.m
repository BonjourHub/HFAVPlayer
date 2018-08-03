//
//  HIAudioDataManager.m
//  HFAVPlayer
//
//  Created by pengfei28 on 2018/8/3.
//  Copyright © 2018年 pengfei. All rights reserved.
//

#import "HIAudioDataManager.h"
#import "HIAudioDataDownloader.h"
#import <MobileCoreServices/MobileCoreServices.h>

NSString *const localScheme = @"audioAsset";

@interface HIAudioDataManager ()<AVAssetResourceLoaderDelegate>
{
    NSString *_originScheme;
}
@property (nonatomic, strong) HIAudioDataDownloader *downloader;

@end

@implementation HIAudioDataManager

#pragma mark - helper
- (NSURL *)_replaceScheme:(NSString *)urlString
{
    if (!urlString) return nil;
    NSURL *url = [NSURL URLWithString:urlString];
    _originScheme = url.scheme;
    urlString = [urlString stringByReplacingOccurrencesOfString:url.scheme withString:localScheme];
    
    return [NSURL URLWithString:urlString];
}

#pragma mark - public
- (AVPlayerItem *)playerItemWithURLString:(NSString *)urlString
{
    AVURLAsset *asset = [AVURLAsset assetWithURL:[self _replaceScheme:urlString]];
    [asset.resourceLoader setDelegate:self queue:dispatch_get_main_queue()];//使用子线程
    
    return [AVPlayerItem playerItemWithAsset:asset];
}

#pragma mark - AVAssetResourceLoaderDelegate
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest
{
    [self _handleLoadingRequest:loadingRequest];
    return YES;
}

#pragma mark handle
- (void)_handleLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    if (loadingRequest.dataRequest.requestsAllDataToEndOfResource)
    {
        HFDebugLog(@"HIAu-新请求");
    }

    NSUInteger requestOffset = loadingRequest.dataRequest.requestedOffset;
    NSUInteger requestLength = loadingRequest.dataRequest.requestedLength;
    NSRange requestRange = NSMakeRange(requestOffset, requestLength);
    
    NSURLComponents *componentURL = [NSURLComponents componentsWithURL:[loadingRequest.request URL] resolvingAgainstBaseURL:NO];
    componentURL.scheme = _originScheme;
    
    DefineWeakInstance(self);
    self.downloader = [HIAudioDataDownloader downloaderWithURL:[componentURL URL] RuqestRange:requestRange completionHandle:^(HIAudioDataDownloaderHandleType type, id data)
    {
        switch (type) {
            case HIAudioDataDownloaderHandleTypeFillContentData:
                [WeakInstance _fillContentInfo:data loadingRequest:loadingRequest];
                break;
            case HIAudioDataDownloaderHandleTypeHandleReciveData:
                [loadingRequest.dataRequest respondWithData:data];
                [loadingRequest finishLoading];
                break;
            case HIAudioDataDownloaderHandleTypeResponseError:
                break;
            default:
                break;
        }
    }];
}

#pragma mark - 逻辑处理
- (void)_fillContentInfo:(NSURLResponse *)response loadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    
    AVAssetResourceLoadingContentInformationRequest *contentInfoRequest = loadingRequest.contentInformationRequest;
    if (contentInfoRequest) {
        if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        //服务器端是否支持分段传输
        BOOL byteRangeAccessSupported = [httpResponse.allHeaderFields[@"Accept-Ranges"] isEqualToString:@"bytes"];
        
        //获取返回文件的长度
        long long contentLength = [[[httpResponse.allHeaderFields[@"Content-Range"] componentsSeparatedByString:@"/"] lastObject] longLongValue];
//        self.dataManager.contentLength = (NSUInteger)contentLength;
        //获取返回文件的类型
        NSString *mimeType = httpResponse.MIMEType;
        CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)mimeType, NULL);//此处需要引入<MobileCoreServices/MobileCoreServices.h>头文件
        NSString *contentTypeStr = CFBridgingRelease(contentType);
        
        contentInfoRequest.byteRangeAccessSupported = byteRangeAccessSupported;
        contentInfoRequest.contentLength = contentLength;
        contentInfoRequest.contentType = contentTypeStr;
    }
    
}

@end
