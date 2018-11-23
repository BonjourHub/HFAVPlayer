//
//  HIAVAssetResposeResourceLoader.m
//  HFAVPlayer
//
//  Created by pengfei28 on 2018/11/21.
//  Copyright © 2018 pengfei. All rights reserved.
//

#ifdef DEBUG
#define NSLog(...) NSLog(__VA_ARGS__)
#endif

#import "HIAVAssetResposeResourceLoader.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface HIAVAssetResposeResourceLoader (networking)
- (void)_networkTaskWithRequest:(AVAssetResourceLoadingRequest *)loadingRequest shouldCache:(BOOL)shouldCache;
@end

@interface HIAVAssetResposeResourceLoader (FillData)
- (void)_processFillData;
@end

@interface HIAVAssetResposeResourceLoader ()
{
    NSError *_error;
    NSHTTPURLResponse *_response;
    
    BOOL _flag;
}
@property (nonatomic, strong) NSMutableArray *pendingRequests;
@property (nonatomic, strong) NSMutableData *data;
@end

@implementation HIAVAssetResposeResourceLoader

- (instancetype)initWithOriginURLScheme:(NSString *)urlScheme
{
    self = [super init];
    if (self) {
        _originURLScheme = urlScheme;
    }
    return self;
}

#pragma mark - getter
- (NSMutableArray *)pendingRequests
{
    if (!_pendingRequests) {
        _pendingRequests = [NSMutableArray arrayWithCapacity:1];
    }
    return _pendingRequests;
}

#pragma mark - AVAssetResourceLoaderDelegate
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest
{
    NSLog(@"Loader Assistanter. shouldWaitForLoadingOfRequestedResource <requestedOffset:%lld, currentOffset:%lld, requestedLength:%ld>",loadingRequest.dataRequest.requestedOffset, loadingRequest.dataRequest.currentOffset, loadingRequest.dataRequest.requestedLength);
    
    /**
     * 这里是播放器获取数据，至少两次调用，第一次获取头部信息；
     * 之后为数据段获取，需要进行数据回填，网络请求只需发起一次，不能每次播放器获取都发起网络请求
     * 但是Seek动作需要重新发起网络请求，因为Seek需要从新的位置开始加载数据，等于一次新的链接请求
     */
//    if (loadingRequest.dataRequest.requestsAllDataToEndOfResource == NO) {
    if (!_flag) {
        NSLog(@"第一次到达 请求开始 获取头部信息");//注意：seek动作的区别 可能需要重新请求
        [self _resetRecourceLoader];
        [self.pendingRequests addObject:loadingRequest];
        
        [self _networkTaskWithRequest:loadingRequest shouldCache:_shouldCache];
        _flag = YES;
    }
    else
    {
        NSLog(@"获取所有剩余数据");
//        if (loadingRequest.dataRequest.requestsAllDataToEndOfResource == NO)
            [self.pendingRequests addObject:loadingRequest];
        
        // TODO 数据存在 响应数据
        [self _processFillData];
        
    }
    
    return YES;
}

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForRenewalOfRequestedResource:(AVAssetResourceRenewalRequest *)renewalRequest
{
    // 猜测 此处当发生一个新的请求的时候调用
    NSAssert(1, @"这里被调用了");
    return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    NSLog(@"Loader Assistanter. DidCancelLoadingRequest <requestedOffset:%lld, currentOffset:%lld, requestedLength:%ld>",loadingRequest.dataRequest.requestedOffset, loadingRequest.dataRequest.currentOffset, loadingRequest.dataRequest.requestedLength);
    
    [self _resetRecourceLoader];
}

#pragma mark - 复位操作
- (void)_resetRecourceLoader
{
    [self.pendingRequests removeAllObjects];
    _response = nil;
    _error = nil;
    
    _flag = NO;
}


@end


#pragma mark - 网络加载
@implementation HIAVAssetResposeResourceLoader (networking)

- (void)_networkTaskWithRequest:(AVAssetResourceLoadingRequest *)loadingRequest shouldCache:(BOOL)shouldCache
{
    if ([self.resourceDownloader respondsToSelector:@selector(downloadWithLoadingRequest:reciveDataCompletion:)])
    {
        self.data = [NSMutableData data];
        NSMutableURLRequest *reuquest = [self _loadingURLRequest:loadingRequest];
        __weak typeof(self) weakSelf = self;
        [self.resourceDownloader downloadWithLoadingRequest:reuquest reciveDataCompletion:^(NSHTTPURLResponse * _Nonnull response, NSData * _Nonnull data, NSError * _Nonnull error)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                _error = error;
                if (response) _response = response;
                if (data) [weakSelf.data appendData:data];
                
                // TODO 数据存在 响应数据
                if (weakSelf.data.length > 0)
                    [self _processFillData];
                
                // TODO 写缓存文件
            });
        }];
    }
}

- (NSMutableURLRequest *)_loadingURLRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    NSURL *originURL = [self _originURL:loadingRequest.request.URL];
    
    NSTimeInterval timeoutInterval = loadingRequest.request.timeoutInterval;
    if (_timeoutInterval > 0)
        timeoutInterval = _timeoutInterval;
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:originURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:timeoutInterval];
    
    // is seek
    if (loadingRequest.dataRequest.requestedOffset > 0)
        [request addValue:[NSString stringWithFormat:@"bytes=%lld-%ld",loadingRequest.dataRequest.requestedOffset, loadingRequest.dataRequest.requestedLength] forHTTPHeaderField:@"Range"];
    
    return request;
}

- (NSURL *)_originURL:(NSURL *)url
{
    NSURLComponents *URLComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    if (_originURLScheme)
        URLComponents.scheme = _originURLScheme;
    
    return [URLComponents URL];
}


@end


#pragma mark - 数据填充
@implementation HIAVAssetResposeResourceLoader (FillData)

- (void)_processFillData
{
    NSLog(@"Loader Assistander. Will Fill Data <pendingCount:%ld>", self.pendingRequests.count);
    NSMutableArray *finishFillRequests = [NSMutableArray array];
    for (AVAssetResourceLoadingRequest *loadingRequest in self.pendingRequests) {
        if ([self _finishFillDataWithLoadingRequest:loadingRequest])
            [finishFillRequests addObject:loadingRequest];
    }
    
    [self.pendingRequests removeObjectsInArray:finishFillRequests];
}

// 是否完全响应了该段数据
- (BOOL)_finishFillDataWithLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    NSLog(@"Loader Assistanter. Will Fill Data <requestedOffset:%lld, currentOffset:%lld, requestedLength:%ld>",loadingRequest.dataRequest.requestedOffset, loadingRequest.dataRequest.currentOffset, loadingRequest.dataRequest.requestedLength);
    
    loadingRequest = [self _fillContentInfomationRequest:loadingRequest];
    if (!loadingRequest) return NO;
    
    // 数据不够
    if (self.data.length <= loadingRequest.dataRequest.requestedOffset) return NO;
    
    /**
     * 两种情况：
     * 1.self.data 请求慢，数据不够，只能响应需要的一部分数据，则响应已有的部分
     * 2.self.data 请求快，数据超过本次需要响应的长度，则响应requestedLength长度
     */
    NSUInteger canReadLength = self.data.length - loadingRequest.dataRequest.requestedOffset;
    NSUInteger responseLength = MIN(canReadLength, loadingRequest.dataRequest.requestedLength);
    NSData *readData = [self.data subdataWithRange:NSMakeRange(loadingRequest.dataRequest.requestedOffset, responseLength)];
    NSLog(@"Loader Assistanter. canReadLength:%ld responseLength:%ld",canReadLength, responseLength);
    /**
     * respondWithData 响应数据必须和对应的loadingRequest请求需要的数据匹配
     * 即：响应数据必须是需要数据段数据 或者 是需要数据段的一部分子集合数据
     */
    [loadingRequest.dataRequest respondWithData:readData];
    
    NSLog(@"Loader Assistanter. Did Fill Data <requestedOffset:%lld, currentOffset:%lld, requestedLength:%ld>",loadingRequest.dataRequest.requestedOffset, loadingRequest.dataRequest.currentOffset, loadingRequest.dataRequest.requestedLength);
    
    // 通知当前LoadingRequest 你要的数据已经全部响应完毕
    if (loadingRequest.dataRequest.currentOffset >= (loadingRequest.dataRequest.requestedOffset + loadingRequest.dataRequest.requestedLength)) {
        [loadingRequest finishLoading];
        NSLog(@"Finish Loading");
        return YES;
    }
    
    return NO;
}

- (AVAssetResourceLoadingRequest *)_fillContentInfomationRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    NSHTTPURLResponse *httpResponse = _response;
    if (!httpResponse || ![httpResponse isKindOfClass:[NSHTTPURLResponse class]]) {
        return nil;
    }
    //服务器端是否支持分段传输
    BOOL byteRangeAccessSupported = [httpResponse.allHeaderFields[@"Accept-Ranges"] isEqualToString:@"bytes"];
    
    //获取返回文件的长度
//    long long contentLength = [[[httpResponse.allHeaderFields[@"Content-Length"] componentsSeparatedByString:@"/"] lastObject] longLongValue];
    long long contentLength = [[[httpResponse allHeaderFields] objectForKey:@"Content-Length"] longLongValue];
    
    //获取返回文件的类型
    NSString *mimeType = httpResponse.MIMEType;
    CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)mimeType, NULL);//此处需要引入<MobileCoreServices/MobileCoreServices.h>头文件
    NSString *contentTypeStr = CFBridgingRelease(contentType);
    
    loadingRequest.contentInformationRequest.byteRangeAccessSupported = byteRangeAccessSupported;
    loadingRequest.contentInformationRequest.contentLength = contentLength;
    loadingRequest.contentInformationRequest.contentType = contentTypeStr;
    
    return loadingRequest;
}

@end
