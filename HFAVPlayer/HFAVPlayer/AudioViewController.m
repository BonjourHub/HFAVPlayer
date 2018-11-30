//
//  AudioViewController.m
//  HFAVPlayer
//
//  Created by pengfei28 on 2018/7/31.
//  Copyright © 2018年 pengfei. All rights reserved.
//

#import "AudioViewController.h"
#import "HIAudioPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import "HIURLSeesionDownloader.h"

@interface AudioViewController ()

{
    UIButton * _playButton;
    HIAudioPlayer *_audioPlayer;
    
    AVPlayer *_player;
    
    HIURLSeesionDownloader *_sessionDownloader;
    
    UISlider *_slider;
}

@end

@implementation AudioViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor colorWithRed:0.2 green:0.4 blue:0.6 alpha:0.8];
    
    _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _playButton.backgroundColor = [UIColor colorWithRed:0.8 green:0.2 blue:0.2 alpha:0.2];
    [_playButton addTarget:self action:@selector(actionWithButton:) forControlEvents:UIControlEventTouchUpInside];
    [_playButton setTitle:@"播放" forState:UIControlStateNormal];
    _playButton.tag = 1001;
    [self.view addSubview:_playButton];
    
    _slider = [[UISlider alloc] init];
    _slider.backgroundColor = [UIColor grayColor];
    _slider.minimumValue = 0;
    _slider.maximumValue = 100;
    [_slider addTarget:self action:@selector(_sliderAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_slider];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    _playButton.frame = CGRectMake(20, 100, 40, 30);
    
    _slider.frame = CGRectMake(20, 500, 300, 30);
}

#pragma mark - action
- (void)actionWithButton:(UIButton *)button
{
    switch (button.tag)
    {
        case 1001:
        {
//            [[HIAudioPlayer shareInstance] play];
//            NSString *urlString = @"http://download.lingyongqian.cn/music/AdagioSostenuto.mp3";
//            NSString *urlString = @"http://download.lingyongqian.cn/music/ForElise.mp3";
            NSString *urlString = @"http://www.170mv.com/kw/other.web.rh01.sycdn.kuwo.cn/resource/n3/21/19/3413654131.mp3";
//            NSString *urlString = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"mp3"];
            [[HIAudioPlayer shareInstance] playWithURLString:urlString];
            
//            _sessionDownloader = [HIURLSeesionDownloader new];
//            [_sessionDownloader requestWithURLString:urlString];
            
//            _player = [AVPlayer playerWithURL:[NSURL URLWithString:urlString]];
//            [_player play];
        }
            break;
            
        default:
            break;
    }
}

- (void)_sliderAction:(UISlider *)slider
{
    HFDebugLog(@"slider:%.2f %.2f %.2f",slider.value, slider.minimumValue, slider.maximumValue);
    
    [[HIAudioPlayer shareInstance] seekToProgress:slider.value/slider.maximumValue];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
