//
//  HFAudioPlayer.h
//  HFAVPlayer
//
//  Created by pengfei28 on 2018/7/31.
//  Copyright © 2018年 pengfei. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HFAudioPlayer : NSObject

+ (instancetype)shareInstance;
- (void)playWithURLString:(NSString *)urlString;

@end
