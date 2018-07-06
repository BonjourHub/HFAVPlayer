//
//  HFAVPlayerPrefixHeader.h
//  HFAVPlayer
//
//  Created by pengfei28 on 2018/7/4.
//  Copyright © 2018年 pengfei. All rights reserved.
//

#ifndef HFAVPlayerPrefixHeader_h
#define HFAVPlayerPrefixHeader_h

#define DefineWeakInstance(instance)  __weak typeof(instance) weakInstance = instance
#define WeakInstance weakInstance

#ifdef DEBUG
#define HFDebugLog(format,...) NSLog(@"%s Log:%@",__func__,[NSString stringWithFormat:format, ##__VA_ARGS__])
#define HFTODODebugLog(format,...) NSLog(@"%s 🔵Todo:%@",__func__,[NSString stringWithFormat:format, ##__VA_ARGS__])
#else
#define HFDebugLog(...) do { \
} while(0)
#define HFTODODebugLog(...) do { \
} while(0)
#endif

#endif /* HFAVPlayerPrefixHeader_h */
