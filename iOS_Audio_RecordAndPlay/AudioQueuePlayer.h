//
//  AudioQueuePlayer.h
//  iOS_Audio_RecordAndPlay
//
//  Created by pedoe on 2016/1/29.
//  Copyright © 2016年 NTU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#define NUMBER_AUDIOQUEUE_BUFFERS 3 //Number of Audio Queue Service buffers and the number must be larger than 3 for high performance
#define MIN_SIZE_PER_FRAME 48000 //Minimum buffer size for allocating Audio Queue Buffer in each frame

typedef struct
{
    AudioStreamBasicDescription  mDataFormat;
    AudioQueueRef                mQueue;
    AudioQueueBufferRef          mBuffers[NUMBER_AUDIOQUEUE_BUFFERS];
    AudioFileID                  mAudioFile;
    UInt32                       bufferByteSize;
    SInt64                       mCurrentPacket;
    UInt32                       mNumPacketsToRead;
    AudioStreamPacketDescription *mPacketDescs;
    bool                         mIsPlaying;
} PlayState;


@interface AudioQueuePlayer : NSObject
{
    PlayState playState;
    CFURLRef fileURL;
}

@property PlayState playState;

- (BOOL)getFilename:(char*)buffer maxLenth:(int)maxBufferLength;
- (void)setupAudioFormat:(AudioStreamBasicDescription*)format;

- (void)startPlayback;
- (void)stopPlayback;

@end
