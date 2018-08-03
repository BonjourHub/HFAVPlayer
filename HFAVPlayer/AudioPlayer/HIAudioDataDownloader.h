//
//  HIAudioDataDownloader.h
//  HFAVPlayer
//
//  Created by pengfei28 on 2018/8/3.
//  Copyright © 2018年 pengfei. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, HIAudioDataDownloaderHandleType) {
    HIAudioDataDownloaderHandleTypeFillContentData,
    HIAudioDataDownloaderHandleTypeHandleReciveData,
    HIAudioDataDownloaderHandleTypeResponseError,
//    HIAudioDataDownloaderHandleTypeResponseData,
};

typedef void(^HIAudioDataDownloaderHandel)(HIAudioDataDownloaderHandleType type, id data);

@interface HIAudioDataDownloader : NSObject

+ (instancetype)downloaderWithURL:(NSURL *)url RuqestRange:(NSRange)range completionHandle:(HIAudioDataDownloaderHandel)completion;

@end
