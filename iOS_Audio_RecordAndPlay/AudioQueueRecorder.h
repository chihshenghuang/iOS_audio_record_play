//
//  AudioQueueRecorder.h
//  iOS_Audio_RecordAndPlay
//
//  Created by pedoe on 2016/1/29.
//  Copyright © 2016年 NTU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#define NUM_BUFFERS 3
#define MIN_SIZE_PER_FRAME 48000

// Struct defining recording state
typedef struct
{
    AudioStreamBasicDescription  mDataFormat;
    AudioQueueRef                mQueue;
    AudioQueueBufferRef          mBuffers[NUM_BUFFERS];
    AudioFileID                  mAudioFile;
    UInt32                       bufferByteSize;
    SInt64                       mCurrentPacket;
    bool                         mIsRecording;
} RecordState;

@interface AudioQueueRecorder : NSObject
{
    RecordState recordState;
    CFURLRef fileURL;
}

@property RecordState recordState;

- (void)startRecording;
- (void)stopRecording;

@end
