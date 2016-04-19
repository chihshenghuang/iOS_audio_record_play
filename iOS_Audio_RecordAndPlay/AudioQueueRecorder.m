//
//  AudioQueueRecorder.m
//  iOS_Audio_RecordAndPlay
//
//  Created by pedoe on 2016/1/29.
//  Copyright © 2016年 NTU. All rights reserved.
//

#import "AudioQueueRecorder.h"

void AudioRecordCallback(void * aqData,  // Custom audio metadata
                        AudioQueueRef inAQ,
                        AudioQueueBufferRef inBuffer,
                        const AudioTimeStamp * inStartTime,
                        UInt32 inNumPackets,
                        const AudioStreamPacketDescription * inPacketDescs);

@implementation AudioQueueRecorder

@synthesize recordState;

- (id)init {
    
    self = [super init];
    if(self) {
        
        NSLog(@"AudioQueueRecorder init");
        [self initVariables];
    }
    return self;
}

- (void)initVariables
{
    char path[256];
    [self getFilename:path maxLenth:sizeof path];
    fileURL = CFURLCreateFromFileSystemRepresentation(NULL, (UInt8*)path, strlen(path), false);
    
    // Init state variables
    recordState.mIsRecording = false;
}


// Takes a filled buffer and writes it to disk, "emptying" the buffer
void AudioRecordCallback(void * aqData,
                        AudioQueueRef inAQ,
                        AudioQueueBufferRef inBuffer,
                        const AudioTimeStamp * inStartTime,
                        UInt32 inNumPackets,
                        const AudioStreamPacketDescription * inPacketDescs)
{
    RecordState * recordState = (RecordState*)aqData;
    if (!recordState->mIsRecording)
    {
        printf("Not recording, returning\n");
    }
    
     if (inNumPackets == 0 && recordState->mDataFormat.mBytesPerPacket != 0)
     {
         inNumPackets = inBuffer->mAudioDataByteSize / recordState->mDataFormat.mBytesPerPacket;
     }
    
    
    OSStatus status = AudioFileWritePackets(recordState->mAudioFile,
                                            false,
                                            inBuffer->mAudioDataByteSize,
                                            inPacketDescs,
                                            recordState->mCurrentPacket,
                                            &inNumPackets,
                                            inBuffer->mAudioData);
    
    if (status == 0){
        recordState->mCurrentPacket += inNumPackets;
        NSLog(@"Writing buffer %lld\n", recordState->mCurrentPacket);
    }
    else{
        NSLog(@"error!");
    }
    
    AudioQueueEnqueueBuffer(recordState->mQueue, inBuffer, 0, NULL);
}


- (void)setupAudioFormat:(AudioStreamBasicDescription*)format
{
    format->mSampleRate = 48000;
    format->mFormatID = kAudioFormatLinearPCM;
    format->mFramesPerPacket = 1;
    format->mChannelsPerFrame = 2;
    format->mBitsPerChannel = 16;
    format->mBytesPerFrame = (format->mBitsPerChannel/8) * format->mChannelsPerFrame;//2;
    format->mBytesPerPacket = format->mBytesPerFrame;//2;
    format->mReserved = 0;
    format->mFormatFlags = kAudioFormatFlagIsBigEndian |
    kAudioFormatFlagIsSignedInteger |
    kAudioFormatFlagIsPacked;
}

- (void)startRecording
{
    [self setupAudioFormat:&recordState.mDataFormat];
    
    recordState.mCurrentPacket = 0;
    
    OSStatus status;
    status = AudioQueueNewInput(&recordState.mDataFormat,
                                AudioRecordCallback,
                                &recordState,
                                CFRunLoopGetCurrent(),
                                kCFRunLoopCommonModes,
                                0,
                                &recordState.mQueue);
    
    if (status == 0)
    {
        // Prime recording buffers with empty data
        for (int i = 0; i < NUM_BUFFERS; i++)
        {
            AudioQueueAllocateBuffer(recordState.mQueue, MIN_SIZE_PER_FRAME, &recordState.mBuffers[i]);
            AudioQueueEnqueueBuffer(recordState.mQueue, recordState.mBuffers[i], 0, NULL);
        }
 
        status = AudioFileCreateWithURL(fileURL,
                                        kAudioFileAIFFType,
                                        &recordState.mDataFormat,
                                        kAudioFileFlags_EraseFile,
                                        &recordState.mAudioFile);
        
        if (status == 0)
        {
            recordState.mIsRecording = true;
            status = AudioQueueStart(recordState.mQueue, NULL);
            if (status == 0)
            {
                NSLog(@"Recording");
            }
        }
    }
    
    if (status != 0)
    {
        [self stopRecording];
        NSLog(@"Record Failed");
    }
}

- (void)stopRecording
{
    recordState.mIsRecording = false;
    
    AudioQueueStop(recordState.mQueue, true);
    
    for(int i = 0; i < NUM_BUFFERS; i++)
    {
        AudioQueueFreeBuffer(recordState.mQueue, recordState.mBuffers[i]);
    }
    
    AudioQueueDispose(recordState.mQueue, true);
    AudioFileClose(recordState.mAudioFile);
}

- (BOOL)getFilename:(char*)buffer maxLenth:(int)maxBufferLength
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString* docDir = [paths objectAtIndex:0];
    
    NSString* file = [docDir stringByAppendingString:@"/recording.pcm"];
    return [file getCString:buffer maxLength:maxBufferLength encoding:NSUTF8StringEncoding];
}

@end
