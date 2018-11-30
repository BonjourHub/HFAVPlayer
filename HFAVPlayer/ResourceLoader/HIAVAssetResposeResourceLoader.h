//
//  HIAVAssetResposeResourceLoader.h
//  HFAVPlayer
//
//  Created by pengfei28 on 2018/11/21.
//  Copyright © 2018 pengfei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HIAVAssetResourceDownloader <NSObject>


/**
 发起网络请求，获取数据资源

 @param URLRequest 网络请求对象
 @param completion 数据回调,data-数据片段连续回调
 */
- (void)downloadWithLoadingRequest:(NSMutableURLRequest *)URLRequest reciveDataCompletion:(void(^)(NSHTTPURLResponse *response, NSData *data, NSError *error))completion;

// 任务挂起 暂停等

@end

@interface HIAVAssetResposeResourceLoader : NSObject<AVAssetResourceLoaderDelegate>

- (instancetype)initWithOriginURLScheme:(NSString *)urlScheme;

/**
 下载代理，可设置代理，遵守协议自行实现下载功能
 */
@property (nonatomic, weak) id<HIAVAssetResourceDownloader> resourceDownloader;

/**
 是否进行缓存，默认不缓存
 */
@property (nonatomic, assign) BOOL shouldCache;

@property (nonatomic, assign) NSTimeInterval timeoutInterval;

@property (nonatomic, copy) NSString *originURLScheme;





@end

NS_ASSUME_NONNULL_END
