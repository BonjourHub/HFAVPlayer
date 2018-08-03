//
//  HIAudioPlayer.h
//  test
//
//  Created by pengfei28 on 2018/3/19.
//  Copyright © 2018年 bj-m-206066a. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HIAudioPlayer : NSObject

+ (instancetype)shareInstance;
- (void)playWithURLString:(NSString *)urlString;

- (void)play;
- (void)pause;

@end
