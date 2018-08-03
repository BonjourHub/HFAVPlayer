//
//  HIAudioDataManager.h
//  HFAVPlayer
//
//  Created by pengfei28 on 2018/8/3.
//  Copyright © 2018年 pengfei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface HIAudioDataManager : NSObject

- (AVPlayerItem *)playerItemWithURLString:(NSString *)urlString;

@end
