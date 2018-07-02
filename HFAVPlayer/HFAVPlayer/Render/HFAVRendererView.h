//
//  HFAVRendererView.h
//  HFAVPlayer
//
//  Created by pengfei28 on 2018/6/28.
//  Copyright © 2018年 pengfei. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

@interface HFAVRendererView : UIView

{
    CAEAGLLayer *_eaglLayer;
    EAGLContext *_context;
    GLuint _colorRenderBuffer;
    GLuint _frameBuffer;
}


@end
