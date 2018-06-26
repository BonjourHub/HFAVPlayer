//
//  HFAVPlayerMessage.m
//  HFAVPlayer
//
//  Created by pengfei28 on 2018/6/26.
//  Copyright © 2018年 pengfei. All rights reserved.
//

#import "HFAVPlayerMessage.h"

@interface HFAVPlayerMessage ()
@property (nonatomic, assign, readwrite) HFAVPlayerMessageType type;
@property (nonatomic, assign, readwrite) NSUInteger code;
@property (nonatomic, copy, readwrite) NSString *content;
@end

@implementation HFAVPlayerMessage

+ (instancetype)messageWithType:(HFAVPlayerMessageType)type code:(NSUInteger)code content:(NSString *)content
{
    HFAVPlayerMessage *message = [HFAVPlayerMessage new];
    message.type = type;
    message.code = code;
    message.content = content;
    
    return message;
}

@end
