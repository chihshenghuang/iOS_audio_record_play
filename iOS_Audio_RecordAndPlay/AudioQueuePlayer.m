//
//  AudioQueuePlayer.m
//  iOS_Audio_RecordAndPlay
//
//  Created by pedoe on 2016/1/29.
//  Copyright © 2016年 NTU. All rights reserved.
//

#import "AudioQueuePlayer.h"

#pragma mark player call back
// Declare C callback functions for reuse the AudioQueueBufferRef. When all the data which pass AudioQueueEnqueueBuffer flow out, the callback functions will inform the Audio Queue Service
void AudioPlayCallback(void                  *aqData,
                       AudioQueueRef         inAQ,
                       AudioQueueBufferRef   inBuffer);


@implementation AudioQueuePlayer

@synthesize playState;

- (id)init {
    
    self = [super init];
    if(self) {
        
        NSLog(@"AudioQueuePlayer init");
        [self initVariables];
    }
    return self;
}

- (void)initVariables
{
    // Get audio file page
    char path[256];
    [self getFilename:path maxLenth:sizeof path];
    fileURL = CFURLCreateFromFileSystemRepresentation(NULL, (UInt8*)path, strlen(path), false);
    
    // Init state variables
    playState.mIsPlaying = false;
}

// Fills an empty buffer with data and sends it to the speaker
void AudioPlayCallback(void * aqData,
                       AudioQueueRef inAQ,
                       AudioQueueBufferRef inBuffer)
{
    PlayState* pAqData = (PlayState *)aqData;
    if(!pAqData->mIsPlaying)
    {
        printf("Not playing, returning\n");
        return;
    }
    
    printf("Queuing buffer %lld for playback\n", pAqData->mCurrentPacket);
    
    UInt32 bytesRead;
    UInt32 numPackets = pAqData->mNumPacketsToRead;
    OSStatus status;
    status = AudioFileReadPackets(pAqData->mAudioFile,
                                  false,
                                  &bytesRead,
                                  pAqData->mPacketDescs,
                                  pAqData->mCurrentPacket,
                                  &numPackets,
                                  inBuffer->mAudioData);
    
    if (status) {
        NSLog(@"AudioFileReadPackets failed: %d", (int)status);
    }
    
    if (numPackets){
        inBuffer->mAudioDataByteSize = bytesRead;
        status = AudioQueueEnqueueBuffer(pAqData->mQueue,
                                         inBuffer,
                                         (pAqData->mPacketDescs ? numPackets : 0),
                                         pAqData->mPacketDescs);
        
        pAqData->mCurrentPacket += numPackets;
    }
    else{
        AudioQueueStop(pAqData->mQueue, false);
        //AudioFileClose(pAqData->mAudioFile);
        pAqData->mIsPlaying = false;

        //AudioQueueFreeBuffer(pAqData->mQueue, inBuffer);
    }
    
}

- (void)setupAudioFormat:(AudioStreamBasicDescription*)format
{
    format->mSampleRate = 48000;
    format->mFormatID = kAudioFormatLinearPCM;
    format->mFramesPerPacket = 1;
    format->mChannelsPerFrame = 2;
    format->mBitsPerChannel = 16;
    format->mBytesPerFrame = (format->mBitsPerChannel/8) * format->mChannelsPerFrame;
    format->mBytesPerPacket = format->mBytesPerFrame;
    format->mReserved = 0;
    format->mFormatFlags = kAudioFormatFlagIsBigEndian |  //According to the PCM file description to choose big endian or little endian
    kAudioFormatFlagIsSignedInteger |
    kAudioFormatFlagIsPacked;
}

- (void)startPlayback
{
    playState.mCurrentPacket = 0;
    playState.mNumPacketsToRead = 8000;
    [self setupAudioFormat:&playState.mDataFormat];

    OSStatus status;
    status = AudioFileOpenURL(fileURL, kAudioFileReadPermission, kAudioFileAIFFType, &playState.mAudioFile);
    NSLog(@"fileURL = %@", fileURL);
    NSLog(@"%d",(int)status);
    if (status == 0)
    {
       
        status = AudioQueueNewOutput(&playState.mDataFormat,
                                     AudioPlayCallback,
                                     &playState,
                                     CFRunLoopGetCurrent(),
                                     kCFRunLoopCommonModes,
                                     0,
                                     &playState.mQueue);
        
        if (status == 0)
        {
            // Allocate and prime playback buffers
            playState.mIsPlaying = true;
            for (int i = 0; i < NUMBER_AUDIOQUEUE_BUFFERS && playState.mIsPlaying; i++)
            {
                AudioQueueAllocateBuffer(playState.mQueue, MIN_SIZE_PER_FRAME, &playState.mBuffers[i]);
                AudioPlayCallback(&playState, playState.mQueue, playState.mBuffers[i]);
            }
            
            Float32 gain = 2.0;
            AudioQueueSetParameter(playState.mQueue, kAudioQueueParam_Volume, gain);
            
            status = AudioQueueStart(playState.mQueue, NULL);
            do{
                CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.25, false);
            }while (playState.mIsPlaying);
            
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1, false);
            
            if (status == 0)
            {
                NSLog(@"Playing");
            }
        }
    }
    
    if (status != 0)
    {
        [self stopPlayback];
        NSLog(@"Play failed");
    }
}

- (void)stopPlayback
{
    playState.mIsPlaying = false;
    
    for(int i = 0; i < NUMBER_AUDIOQUEUE_BUFFERS; i++)
    {
        AudioQueueFreeBuffer(playState.mQueue, playState.mBuffers[i]);
    }
    
    AudioQueueDispose(playState.mQueue, true);
    AudioFileClose(playState.mAudioFile);
}

- (void)dealloc
{
    CFRelease(fileURL);
    
}


- (BOOL)getFilename:(char*)buffer maxLenth:(int)maxBufferLength
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString* docDir = [paths objectAtIndex:0];
    
    NSString* file = [docDir stringByAppendingString:@"/recording.pcm"];
    return [file getCString:buffer maxLength:maxBufferLength encoding:NSUTF8StringEncoding];
}
/*
- (BOOL)getFilename:(char*)buffer maxLenth:(int)maxBufferLength
{
    //NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
    //                                                     NSUserDomainMask, YES);
    //NSString* docDir = [paths objectAtIndex:0];
    
    //NSString* file = [docDir stringByAppendingString:@"/iOS_Audio.pcm"];
    
    NSString *filepath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/recording.pcm"];
    NSLog(@"filepath = %@",filepath);
    NSFileManager *manager = [NSFileManager defaultManager];
    NSLog(@"file exist = %d",[manager fileExistsAtPath:filepath]);
    NSLog(@"file size = %lld",[[manager attributesOfItemAtPath:filepath error:nil] fileSize]) ;
    //return [file getCString:buffer maxLength:maxBufferLength encoding:NSUTF8StringEncoding];
    return [filepath getCString:buffer maxLength:maxBufferLength encoding:NSUTF8StringEncoding];
}
*/
@end
