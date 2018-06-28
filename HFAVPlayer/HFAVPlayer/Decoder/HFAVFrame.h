//
//  HFAVFrame.h
//  HFAVPlayer
//
//  Created by pengfei28 on 2018/6/27.
//  Copyright © 2018年 pengfei. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HFAVFrame : NSObject

@property (nonatomic, assign) NSUInteger width;
@property (nonatomic, assign) NSUInteger height;
@property (nonatomic, assign) NSUInteger linesize;
@property (nonatomic, strong) NSData *luma;
@property (nonatomic, strong) NSData *chromaB;
@property (nonatomic, strong) NSData *ChromaR;
@property (nonatomic, strong) id imageBuffer;

@end
