//
//  HFAVPlayerMessage.h
//  HFAVPlayer
//
//  Created by pengfei28 on 2018/6/26.
//  Copyright © 2018年 pengfei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HFAVPlayerEnum.h"

typedef NS_ENUM(NSUInteger, HFAVPlayerMessageType) {
    HFAVPlayerMessageTypeCorrect,
    HFAVPlayerMessageTypeError,
};

@interface HFAVPlayerMessage : NSObject

@property (nonatomic, assign, readonly) HFAVPlayerMessageType type;
@property (nonatomic, assign, readonly) NSUInteger code;
@property (nonatomic, copy, readonly) NSString *content;

+ (instancetype)messageWithType:(HFAVPlayerMessageType)type code:(NSUInteger)code content:(NSString *)content;

@end
