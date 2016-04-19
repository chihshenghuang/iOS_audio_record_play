//
//  ViewController.m
//  iOS_Audio_RecordAndPlay
//
//  Created by pedoe on 2016/1/29.
//  Copyright © 2016年 NTU. All rights reserved.
//

#import "ViewController.h"


@interface ViewController ()

@end

@implementation ViewController
{
    AudioQueuePlayer *audioPlayer;
    AudioQueueRecorder *audioRecorder;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    audioPlayer = [[AudioQueuePlayer alloc]init];
    audioRecorder = [[AudioQueueRecorder alloc]init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)actionPlay:(id)sender {

    if (!audioPlayer.playState.mIsPlaying)
    {
        printf("Starting playback\n");
        [audioPlayer startPlayback];
    }
    
    else
    {
        printf("Stopping playback\n");
        [audioPlayer stopPlayback];
    }
     
}

- (IBAction)actionRecord:(id)sender {
    
    if (!audioRecorder.recordState.mIsRecording)
    {
        printf("Starting recording\n");
        [audioRecorder startRecording];
    }
    
    else
    {
        printf("Stopping recording\n");
        [audioRecorder stopRecording];
    }
}

@end
