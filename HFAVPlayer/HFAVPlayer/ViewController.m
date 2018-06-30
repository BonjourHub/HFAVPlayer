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
