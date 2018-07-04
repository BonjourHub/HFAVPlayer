//
//  HFAVPlayer.m
//  HFAVPlayer
//
//  Created by pengfei28 on 2018/7/4.
//  Copyright © 2018年 pengfei. All rights reserved.
//

#import "HFAVPlayer.h"
#import "HFAVPlayerView.h"

@interface HFAVPlayer()


@end

@implementation HFAVPlayer

#pragma mark - initInstance
- (instancetype)init
{
    self = [super init];
    if (self) {
        [self playerView];
    }
    return self;
}

+ (instancetype)playerWithURLString:(NSString *)urlString
{
    return [[HFAVPlayer alloc] init];
}

#pragma mark - getter
- (UIView *)playerView
{
    if (!_playerView) {
        _playerView = [HFAVPlayerView new];
    }
    return _playerView;
}


@end
