//
//  HFAVPlayerDecoder.h
//  HFAVPlayer
//
//  Created by pengfei28 on 2018/6/26.
//  Copyright © 2018年 pengfei. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HFAVPlayerDecoder : NSObject

- (NSMutableArray *)_decodeFrameWithFileName:(NSString *)fileName;

@end
