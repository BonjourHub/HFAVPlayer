//
//  HFAVPlayer.h
//  HFAVPlayer
//
//  Created by pengfei28 on 2018/7/4.
//  Copyright © 2018年 pengfei. All rights reserved.
//

#import <Foundation/Foundation.h>
@import UIKit;

@interface HFAVPlayer : NSObject

@property (nonatomic, strong) UIView *playerView;

+ (instancetype)playerWithURLString:(NSString *)urlString;

@end
