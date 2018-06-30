//
//  ViewController.m
//  HFAVPlayer
//
//  Created by 程鹏飞 on 2018/6/23.
//  Copyright © 2018年 pengfei. All rights reserved.
//

#import "ViewController.h"
#import <MetalKit/MTKView.h>
#import "HFMetalRender.h"

@interface ViewController ()

{
    HFMetalRender *_render;
}
@property (nonatomic, strong) MTKView *mtkView;

@end

/**
 MTKView 默认通过60FPS帧率调用代理函数drawInMTKView 获取数据使用GPU进行渲染。
 MTKDevice 是GPU的抽象类，用于获取GPU信息，管理CommandQueue等可以和GPU直接交互的对象。
 MTLCommandQueue 负责产生和管理commandBuffer执行顺序。
 MTLCommandBuffer 指令Buffer,负责包装GPU执行的指令数据
 MTLEncoder GPU有多种类型，负责各种任务，所以CommandBuffer需要转码后交给GPU执行
 */
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor grayColor];
    
    [self.view addSubview:self.mtkView];
    
    if (_mtkView.device == nil) {
        NSLog(@"当前设备不支持metal.");
        return;
    }
    
    _render = [[HFMetalRender alloc] initMetalRenderWithMetalKitView:_mtkView];
    _mtkView.delegate = _render;
    _mtkView.preferredFramesPerSecond = 60;
    
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
}

#pragma mark - getter
- (MTKView *)mtkView
{
    if (!_mtkView) {
        _mtkView = [[MTKView alloc] init];
        _mtkView.device = MTLCreateSystemDefaultDevice();
        _mtkView.frame = self.view.bounds;
    }
    return _mtkView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
