//
//  ViewController.m
//  ReadAudio_AVAssetReader
//
//  Created by D.K. Willardson on 11/7/17.
//  Copyright © 2017 Hitting Tech. All rights reserved.
//

#import "ViewController.h"

float videoDurationSeconds;
//int zcounter;

@interface ViewController ()

@property (nonatomic, strong) NSNumber *amplitude;
@property (nonatomic, strong) NSMutableArray *soundArray;

@property (nonatomic, strong) NSMutableArray *frameBuffer;
@property (nonatomic, strong) NSMutableArray *imageFrame;
@property (nonatomic,strong)NSMutableArray *saveImages;
@property(nonatomic,strong) UIImage *myImage;

@property(nonatomic,strong) NSString *outputPath;
@property(nonatomic,strong) NSURL *outputURL;

@end

int hitFrame;

@implementation ViewController

- (void) viewDidLoad {
    [super viewDidLoad];
 
    //Extract Audio From Video
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    AVAsset *movieAsset = [AVAsset assetWithURL:[[NSBundle mainBundle] URLForResource:@"output8" withExtension:@"mp4"]]; //CHANGE THIS FILE TO TEST
    
    AVAssetTrack * videoAssetTrack = [movieAsset tracksWithMediaType: AVMediaTypeVideo].firstObject;
//    capture_frames_per_second = videoAssetTrack.nominalFrameRate;
//    video_frame_/Users/dkwillardson/Desktop/untitled folder/output3.mp4time = 1 / capture_frames_per_second;
    NSLog(@"FPS is  : %f ", videoAssetTrack.nominalFrameRate);
    
    
    //Extract Audio From Video
    
    NSString *audioPath = [documentsDirectory stringByAppendingPathComponent:@"soundOneNew.m4a"];
   //  NSString *audioPath = [documentsDirectory stringByAppendingPathComponent:@"soundOneNew2.caf"];
    //  NSString *audioPath = [documentsDirectory stringByAppendingPathComponent:@"soundOneNew2.aif"];
    
    
    CMTime videoDuration = movieAsset.duration;
    float videoDurationSeconds = CMTimeGetSeconds(videoDuration);
    NSLog(@"video duration: %f", videoDurationSeconds);
    
    float startTime = (videoDurationSeconds - .1);//.1); // About 24 Frames
    float endTime = videoDurationSeconds;
    
    AVAssetExportSession *exportSession=[AVAssetExportSession exportSessionWithAsset:movieAsset presetName:AVAssetExportPresetAppleM4A];
   // AVAssetExportSession *exportSession=[AVAssetExportSession exportSessionWithAsset:movieAsset presetName:AVAssetExportPresetPassthrough];
    
    
    exportSession.outputURL=[NSURL fileURLWithPath:audioPath];
    exportSession.outputFileType=AVFileTypeAppleM4A;
   // exportSession.outputFileType=AVFileTypeAIFF;
   // exportSession.outputFileType=AVFileTypeCoreAudioFormat;
    
    CMTime vocalStartMarker = CMTimeMake((int)(floor(startTime * 100)), 100);
    CMTime vocalEndMarker = CMTimeMake((int)(ceil(endTime * 100)), 100);
    
    CMTimeRange exportTimeRange = CMTimeRangeFromTimeToTime(vocalStartMarker, vocalEndMarker);
    exportSession.timeRange= exportTimeRange;
    if ([[NSFileManager defaultManager] fileExistsAtPath:audioPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:audioPath error:nil];
    }
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        if (exportSession.status==AVAssetExportSessionStatusFailed) {
            NSLog(@"failed");
        }
        else {
            NSLog(@"AudioLocation : %@",audioPath);
            
            
            // NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:@"output" ofType:@"mp4"];
            // NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:@"ClapSound" ofType:@"m4a"];
            // NSURL *fileURL = [NSURL fileURLWithPath:soundFilePath];
            
            
            NSURL *fileURL = [NSURL fileURLWithPath:audioPath];
            
            AVURLAsset *soundAsset = [[AVURLAsset alloc] initWithURL:fileURL options:nil];
            
            [self soundLevelFromFile:soundAsset];
        }
    }];
    
    _saveImages = [[NSMutableArray alloc]init];
    AVAssetImageGenerator *generate = [[AVAssetImageGenerator alloc] initWithAsset:movieAsset];
    generate.appliesPreferredTrackTransform = YES;
    
    // CMTime videoDuration = movieAsset.duration;
    //  float videoDurationSeconds = CMTimeGetSeconds(videoDuration);
    int totalFrames=(int)videoDurationSeconds*CAPTURE_FRAMES_PER_SECOND;
    // float lastFrameTime = CMTimeGetSeconds(movieAsset.duration)*60.0;
    
    generate.requestedTimeToleranceBefore = kCMTimeZero;
    generate.requestedTimeToleranceAfter = kCMTimeZero;
    
    NSMutableArray *timesm=[[NSMutableArray alloc]init];
    for (int i=(totalFrames-CAPTURE_FRAMES); i<totalFrames; i++) {
        CMTime time = CMTimeMakeWithSeconds(videoDurationSeconds *i/(float)totalFrames, totalFrames);
        // CMTime time = CMTimeMake(videoDurationSeconds *i/(float)frames, frames);
        
        [timesm addObject:[NSValue valueWithCMTime:time]];
    }
    
    [generate generateCGImagesAsynchronouslyForTimes:timesm
                                   completionHandler:^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
                                       
                                       UIImage* myImage = [[UIImage alloc] initWithCGImage:image];
                                       
                                       [self.saveImages addObject:myImage];
                                       
                                          if(_saveImages.count == CAPTURE_FRAMES)
                                         {
                                              [self sendFrames];
                                          }
                                       
                                       
                                   }];
}


// Get Sound Levels from file


- (void) soundLevelFromFile:(AVURLAsset *)soundAsset {
    
    CMTime audioDuration = soundAsset.duration;
    
    float audioDurationSeconds = CMTimeGetSeconds(audioDuration);
    NSLog(@"sound duration: %f", audioDurationSeconds);
    
    NSError * error = nil;
    AVAssetReader * reader = [[AVAssetReader alloc] initWithAsset:soundAsset error:&error];
    AVAssetTrack * soundTrack = [soundAsset.tracks objectAtIndex:0];
    
    AudioChannelLayout channelLayout;
    memset(&channelLayout, 0, sizeof(AudioChannelLayout));
    channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
    
//    NSDictionary *outputSettingsDict = [NSDictionary dictionaryWithObjectsAndKeys:
//                                        [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
//                                        [NSNumber numberWithFloat:44100.0], AVSampleRateKey,
//                                        [NSNumber numberWithInt:2], AVNumberOfChannelsKey,
//                                        [NSData dataWithBytes:&channelLayout length:sizeof(AudioChannelLayout)],
//                                        AVChannelLayoutKey,
//                                        [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
//                                        [NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
//                                        [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
//                                        [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
//                                        nil];

    
    
    NSDictionary* outputSettingsDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                        [NSNumber numberWithInt:kAudioFormatLinearPCM],AVFormatIDKey,

                                       // [NSNumber numberWithInt:44100.0],AVSampleRateKey, //Not Supported
                                       // [NSNumber numberWithInt: 2],AVNumberOfChannelsKey,    //Not Supported
                                        [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,
                                        [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,
                                        [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                                        [NSNumber numberWithBool:NO],AVLinearPCMIsNonInterleaved,
                                        nil];
    
    AVAssetReaderTrackOutput* output = [[AVAssetReaderTrackOutput alloc] initWithTrack:soundTrack outputSettings:outputSettingsDict];
    
    [reader addOutput:output];
    
    UInt32 sampleRate = 0,channelCount = 0;
    
    NSArray* formatDesc = soundTrack.formatDescriptions;
    for(unsigned int i = 0; i < [formatDesc count]; ++i) {
        CMAudioFormatDescriptionRef item = (__bridge CMAudioFormatDescriptionRef)[formatDesc objectAtIndex:i];
        const AudioStreamBasicDescription* fmtDesc = CMAudioFormatDescriptionGetStreamBasicDescription (item);
        if(fmtDesc ) {
            
            sampleRate = fmtDesc->mSampleRate;
            channelCount = fmtDesc->mChannelsPerFrame;
            
            NSLog(@"channels:%u, bytes/packet: %u, sampleRate %f",fmtDesc->mChannelsPerFrame, fmtDesc->mBytesPerPacket,fmtDesc->mSampleRate);
        }
    }
    
    UInt32 bytesPerSample = 2 * channelCount;
    
    [reader startReading];
    
    UInt64          totalBytes = 0;
    UInt32          maxValue = 0;
    UInt32          runningSampleCount = 0;
    UInt32          index = 0;
    UInt32          maxIndex = 0;
    UInt32          amplitudeInt = 0;
    
    
    
    // float sampleTime = 1.0f / sampleRate;
    
    while (reader.status == AVAssetReaderStatusReading){
        
        AVAssetReaderTrackOutput * trackOutput = (AVAssetReaderTrackOutput *)[reader.outputs objectAtIndex:0];
        CMSampleBufferRef sampleBufferRef = [trackOutput copyNextSampleBuffer];
        
        if (sampleBufferRef){
            CMBlockBufferRef blockBufferRef = CMSampleBufferGetDataBuffer(sampleBufferRef);
            
            size_t length = CMBlockBufferGetDataLength(blockBufferRef);
            totalBytes += length;
            
            NSMutableData * data = [NSMutableData dataWithLength:length];
            CMBlockBufferCopyDataBytes(blockBufferRef, 0, length, data.mutableBytes);
            
            SInt16 *samples = (SInt16 *) data.mutableBytes;
            int sampleCount = (int)length / bytesPerSample;
            
            
            for (int i = 0; i < sampleCount ; i ++) {
                
                amplitudeInt = abs(samples[i]);
                
//                if (amplitudeInt < 1){
//                zeroCounter++;
//                }
//                NSNumber *amplitude = [NSNumber numberWithInt:amplitudeInt];
      
                if (amplitudeInt > 6500 ) { //or use max value
              //  if (amplitudeInt > maxValue){
                    maxValue = amplitudeInt;
                    maxIndex = i;
                    break;
                    
                }
                index = i + runningSampleCount;
                
               // NSLog(@"amplitude %u", (unsigned int)amplitudeInt);
                
            }
            runningSampleCount += sampleCount;
            
            
            if (reader.status == AVAssetReaderStatusFailed || reader.status == AVAssetReaderStatusUnknown){
                // Something went wrong. return nil
                
                //  return nil;
            }
        }
   
    }
    
        
        float hitTimeFTE,videoFramesFTE,hitFrameNumber;
        
        
       // zerosAdjustment = (float)zeroCounter/(float)sampleRate;
        hitTimeFTE = audioDurationSeconds - (maxIndex/(double)sampleRate);// - zerosAdjustment;
        videoFramesFTE = (hitTimeFTE / VIDEO_FRAME_TIME);
        hitFrameNumber = CAPTURE_FRAMES - videoFramesFTE;
        hitFrame = (int)hitFrameNumber-2;
        
        
        NSLog(@"AudioSegment (sec) %f", (double)index/(double)sampleRate);
        NSLog(@"Max Value %d", maxValue);
        NSLog(@"Max Index %d", maxIndex);
        NSLog(@"hitFrame %d", hitFrame);
        NSLog(@"Total Samples %d", runningSampleCount);
      //  NSLog(@"Hit TimeFTE %f VideoFramesFTE %f", hitTimeFTE, videoFramesFTE);
      //  NSLog(@"ZeroCount %d", zeroCounter);
      //  NSLog(@"ZeroAmplitudeCount %d", zeroAmplitudeCounter);
       // NSLog(@"ZerosAdjustment %f", zerosAdjustment);
    
        
       // [self sendFrames];
        
    
}

-(void)sendFrames{
    
    if ((hitFrame > 1) && (hitFrame < CAPTURE_FRAMES-1)){
        
        UIImage *image1 = [_saveImages objectAtIndex:hitFrame - 2];
        UIImage *image2 = [_saveImages objectAtIndex:hitFrame];
        UIImage *image3 = [_saveImages objectAtIndex:hitFrame + 1];
        
       
       //RESULTS (Using arbitrary -2 frames on this line of code -> hitFrame = (int)hitFrameNumber-2; Also, using Sound Threshold of 6,500.
        
                         //Expected Hit Frame            //Actual Hit Frame        //Diff
        //output -               7                              5                    +2
        //output1 -              6                              3                    +3
        //output2 -              8                              8                     0
        //output3 -              7                              8                    -1
        //output4 -              8                              4                    +4
        //output5 -              7                              4                    +3
        //output6 -              8                              4                    +4
        //output7 -              8                              6                    +2
        //output8 -              8                              8                    +3
        //output9 -              4                              5                    -1
        
        
        
        //NOTE - Small part of the issue may be actual FPS is not always 240. All of the above were 240FPS actual except "output1" which was 239.98
        
        
        
    }

}

@end



