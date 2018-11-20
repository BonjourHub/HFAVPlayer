//
//  HIURLSeesionDownloader.m
//  HFAVPlayer
//
//  Created by pengfei28 on 2018/11/16.
//  Copyright © 2018 pengfei. All rights reserved.
//

#ifdef DEBUG
#define NSLog(...) NSLog(__VA_ARGS__)
#endif

#import "HIURLSeesionDownloader.h"

@interface HIURLSeesionDownloader (SessionDelegate)<NSURLSessionDownloadDelegate>

@end

@interface HIURLSeesionDownloader ()

@property (nonatomic, strong) NSURLSession *urlSession;
@property (nonatomic, strong) NSURLSessionConfiguration *sessionConfiguration;

@end

@implementation HIURLSeesionDownloader

#pragma mark - getter
- (NSURLSession *)urlSession
{
    if (!_urlSession) {
        _urlSession = [NSURLSession sessionWithConfiguration:self.sessionConfiguration delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
    }
    return _urlSession;
}

- (NSURLSessionConfiguration *)sessionConfiguration
{
    if (!_sessionConfiguration) {
        _sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        _sessionConfiguration.allowsCellularAccess = YES;//允许使用蜂窝移动网络
//        [_sessionConfiguration setHTTPAdditionalHeaders:@{@"Accept": @"application/json"}];//设置请求只接受json类型数据
    }
    return _sessionConfiguration;
}

- (void)requestWithURLString:(NSString *)urlString
{
    
    NSURLSessionDownloadTask *downloadTask = [self.urlSession downloadTaskWithURL:[NSURL URLWithString:urlString]];
    [downloadTask resume];
    
}

@end

@implementation HIURLSeesionDownloader (SessionDelegate)

//下载过程中
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    NSLog(@"下载进度:%lf", 1.0 *totalBytesWritten/totalBytesExpectedToWrite);
}

//恢复下载
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
    NSLog(@"恢复下载");
}

//写入数据到本地
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    NSLog(@"下载完成 写入数据到：%@", [location absoluteString]);
    NSLog(@"TODO: 移动数据到指定目录");
    NSString *toPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingString:downloadTask.response.suggestedFilename];
    [[NSFileManager defaultManager] moveItemAtURL:location
                                            toURL:[NSURL fileURLWithPath:toPath]
                                            error:nil];
    NSLog(@"存储路径:%@",toPath);
}

//请求完成 发生错误
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    NSLog(@"完成 发生错误：%@",error.description);
}

@end
