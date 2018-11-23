//
//  HIURLSeesionDownloader.h
//  HFAVPlayer
//
//  Created by pengfei28 on 2018/11/16.
//  Copyright © 2018 pengfei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HIAVAssetResposeResourceLoader.h"

NS_ASSUME_NONNULL_BEGIN

@interface HIURLSeesionDownloader : NSObject<HIAVAssetResourceDownloader>

- (void)requestWithURLString:(NSString *)urlString;

@end

NS_ASSUME_NONNULL_END
