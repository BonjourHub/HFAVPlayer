//
//  HIAudioDataDownloader.m
//  HFAVPlayer
//
//  Created by pengfei28 on 2018/8/3.
//  Copyright © 2018年 pengfei. All rights reserved.
//

#import "HIAudioDataDownloader.h"

@interface HIAudioDataDownloader()<NSURLSessionDelegate>

{
    float _totalLength;
    float _totalRecivedLength;
}

@property (nonatomic, copy) HIAudioDataDownloaderHandel completion;

@property (nonatomic, strong) NSURLSession *urlSession;
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;

@property (nonatomic, strong) NSMutableData *data;

@end

@implementation HIAudioDataDownloader


#pragma mark - public
+ (instancetype)downloaderWithURL:(NSURL *)url RuqestRange:(NSRange)range completionHandle:(HIAudioDataDownloaderHandel)completion
{
    HIAudioDataDownloader *downloader = [HIAudioDataDownloader new];
    downloader.completion = completion;
    [downloader _downloadWithURL:url requestRange:range];
    return downloader;
}

#pragma mark -
- (void)_downloadWithURL:(NSURL *)url requestRange:(NSRange)range
{
//    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:10];
//    NSString *rangeString = [NSString stringWithFormat:@"bytes=%lu-%lu",range.location,(range.length - range.location - 1)];
//    [request setValue:rangeString forHTTPHeaderField:@"Range"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    self.dataTask = [self.urlSession dataTaskWithRequest:request];
    [self.dataTask resume];
}

- (void)cancel
{
    [self.dataTask cancel];
    [self.urlSession invalidateAndCancel];
}

#pragma mark - getter
- (NSURLSession *)urlSession
{
    if (!_urlSession)
    {
        _urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
    }
    
    return _urlSession;
}

#pragma mark - NSURLSessionDataDelegate
//首次请求调用
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSHTTPURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
//    HFDebugLog(@"HI-Downloader response:%@",response);
    HFDebugLog(@"开始下载");
//    if (_completion) _completion(HIAudioDataDownloaderHandleTypeFillContentData, response);
    completionHandler(NSURLSessionResponseAllow);
    
    _totalLength = [response.allHeaderFields[@"Content-Length"] floatValue];
    self.data = [NSMutableData data];
}

//不断接收服务器返回数据
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
//    HFDebugLog(@"HI-Downloader receive data");
    [self.data appendData:data];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_completion) _completion(HIAudioDataDownloaderHandleTypeHandleReciveData,data);
    });
    
    
    _totalRecivedLength = self.data.length;
    HFDebugLog(@"下载进度:%.5f",1.0 * _totalRecivedLength/_totalLength);
}

//请求出错
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error
{
    HFDebugLog(@"完成 error:%@",error.description);
//    if (error && _completion) _completion(HIAudioDataDownloaderHandleTypeResponseError, nil);
//    if (!error && _completion) _completion(HIAudioDataDownloaderHandleTypeFinishLoading, nil);
}

@end





