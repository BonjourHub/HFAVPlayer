//
//  ViewController.m
//  HFAVPlayer
//
//  Created by 程鹏飞 on 2018/6/23.
//  Copyright © 2018年 pengfei. All rights reserved.
//

#import "ViewController.h"
#import "HFAVPlayer.h"
#import "HFAVDecoder.h"

@interface ViewController ()
{
    HFAVPlayer *_player;
    HFAVDecoder *_decoder;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
//    self.view.backgroundColor = [UIColor colorWithRed:0.9 green:0.8 blue:0.4 alpha:0.8];
    self.view.backgroundColor = [UIColor grayColor];
    
//    NSURL *url = [[NSBundle mainBundle] URLForResource:@"test" withExtension:@"mp4"];
//    _decoder = [HFAVDecoder new];
//    [_decoder decodecWithURL:url completion:^(CVPixelBufferRef pixelBuffer, NSError *error) {
//
//    }];
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"test1" withExtension:@"mp4"];
    _player = [HFAVPlayer playerWithURLString:[url absoluteString]];
    _player.playerView.frame = self.view.bounds;
    [self.view addSubview:_player.playerView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    _player.playerView.frame = self.view.bounds;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
