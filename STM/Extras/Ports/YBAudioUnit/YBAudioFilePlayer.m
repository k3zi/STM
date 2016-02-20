//
//  YBAudioFilePlayer.m
//  YBAudioUnit
//
//  Created by Martijn Thé on 3/21/12.
//  Copyright (c) 2012 Yobble. All rights reserved.
//

#import "YBAudioFilePlayer.h"
#import "YBAudioException.h"
#import "YBAudioUnitGraph.h"
#import "YBAudioUtils.h"

@interface YBAudioUnitNode (Internal)
- (instancetype)initWithAUNode:(AUNode)auNode audioUnit:(AudioUnit)auAudioUnit inGraph:(YBAudioUnitGraph *)graph;
@end

@implementation YBAudioFilePlayer {
    AudioFileID _audioFileID;
    ScheduledAudioFileRegion _region;
    Float64 _sampleRateRatio;
    NSURL *_fileURL;
    UInt64 _filePacketsCount;
}

@synthesize framesPlayed;

/**
    Overriden because kAudioUnitProperty_CurrentPlayTime is the playTime relative to the mStartFrame,
    while it often makes more sense to have the time from the beginning of the file.
    In case the player is stopped (currentPlayTime == -1.) the mStartFrame of the current region is
    reported back, which often makes sense as this is often used as the cue point at which the player is `paused`.
 */
- (AudioTimeStamp)currentPlayTime {
    AudioTimeStamp currentPlayTime;
    UInt32 dataSize = sizeof(currentPlayTime);
    YBAudioThrowIfErr(AudioUnitGetProperty(_auAudioUnit, kAudioUnitProperty_CurrentPlayTime, kAudioUnitScope_Global, 0, &currentPlayTime, &dataSize));
    if (currentPlayTime.mSampleTime == -1.) {
        currentPlayTime.mSampleTime = 0;
    }
    currentPlayTime.mFlags = kAudioTimeStampSampleTimeValid;
    currentPlayTime.mSampleTime += _sampleRateRatio * (Float64)_region.mStartFrame;
    return currentPlayTime;
}

- (AudioTimeStamp)timeStampForFrames:(Float64)frames {
    AudioTimeStamp currentPlayTime;
    UInt32 dataSize = sizeof(currentPlayTime);
    YBAudioThrowIfErr(AudioUnitGetProperty(_auAudioUnit, kAudioUnitProperty_CurrentPlayTime, kAudioUnitScope_Global, 0, &currentPlayTime, &dataSize));
    
    currentPlayTime.mFlags = kAudioTimeStampSampleTimeValid;
    currentPlayTime.mSampleTime = frames;
    return currentPlayTime;
}

- (BOOL)setFileURL:(NSURL *)fileURL {
    return [self setFileURL:fileURL typeHint:0];
}

- (BOOL)setFileURL:(NSURL *)fileURL typeHint:(AudioFileTypeID)typeHint {
    if (_fileURL) {
        // Release old file:
        AudioFileClose(_audioFileID);
    }else{
        hasPlayed = FALSE;
    }
    
    _fileURL = fileURL;
    
    if (_fileURL) {
        if(AudioFileOpenURL((__bridge CFURLRef)fileURL, kAudioFileReadPermission, typeHint, &_audioFileID)){
            return FALSE;
        }
        
        OSStatus err;
        
        err = AudioUnitSetProperty(_auAudioUnit, kAudioUnitProperty_ScheduledFileIDs, kAudioUnitScope_Global, 0, &_audioFileID, sizeof(AudioFileID));
        NSLog(@"%d", (int)err);
        if(err){
            return FALSE;
        }
        
        // Get number of audio packets in the file:
        UInt32 propsize = sizeof(_filePacketsCount);
        if(AudioFileGetProperty(_audioFileID, kAudioFilePropertyAudioDataPacketCount, &propsize, &_filePacketsCount)){
            return FALSE;
        }
        
        // Get file's asbd:
        propsize = sizeof(_fileASBD);
        if(AudioFileGetProperty(_audioFileID, kAudioFilePropertyDataFormat, &propsize, &_fileASBD)){
            return FALSE;
        }
        
        // Get unit's asbd:
        propsize = sizeof(_fileASBD);
        if(AudioUnitGetProperty(_auAudioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &_unitASBD, &propsize)){
            return FALSE;
        }
        
        if (_fileASBD.mSampleRate > 0 && _unitASBD.mSampleRate > 0) {
            _sampleRateRatio = _unitASBD.mSampleRate / _fileASBD.mSampleRate;
        } else {
            _sampleRateRatio = 1.;
        }
    }else{
        return FALSE;
    }
    
    return TRUE;
}

- (void)setCurrentTime:(float)time{
    if(time < 0)time = 0;
    if((time * _fileASBD.mSampleRate) > (_filePacketsCount * _fileASBD.mFramesPerPacket)){
        time = (_filePacketsCount * _fileASBD.mFramesPerPacket) - 1000;
    }
    [self unschedule];
    [self scheduleEntireFilePrimeAndStartImmediatelyWithStartTime:(time * _fileASBD.mSampleRate)];
    [self setStartTimeStampImmediately];
}

- (float)currentTime{
    return [self currentPlayTime].mSampleTime / _fileASBD.mSampleRate;
}

- (float)duration{
    float fileDuration = (_filePacketsCount * _fileASBD.mFramesPerPacket) / _fileASBD.mSampleRate;
    return fileDuration;
}

- (void)scheduleEntireFilePrimeAndStartImmediately {
    [self setRegionEntireFile];
    [self primeBuffers];
    [self setStartTimeStampSampleTime:-1.];
}

- (void)scheduleEntireFilePrimeAndStartImmediatelyWithStartTime:(SInt64)startFrame {
    [self resetRegionToEntireFileWithStartFrame:startFrame];
    YBAudioThrowIfErr(AudioUnitSetProperty(_auAudioUnit, kAudioUnitProperty_ScheduledFileRegion, kAudioUnitScope_Global, 0, &_region, sizeof(_region)));
    [self primeBuffers];
    [self setStartTimeStampSampleTime:-1.];
}

- (void)resetRegionToEntireFileWithStartFrame:(SInt64)startFrame {
    _region.mTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
    _region.mTimeStamp.mSampleTime = 0; /* Relative to graph's time line */
    _region.mAudioFile = _audioFileID;
    _region.mLoopCount = 0;
    _region.mStartFrame = startFrame;
    _region.mFramesToPlay = (UInt32)(_filePacketsCount * _fileASBD.mFramesPerPacket) - (UInt32)startFrame;
}

- (void)rescheduleEntireFileBeginningAtPlaybackTime:(AudioTimeStamp)timestamp {
    if(!hasPlayed)return;
    [self unschedule];
    NSAssert((timestamp.mFlags & kAudioTimeStampSampleTimeValid), nil);
    [self resetRegionToEntireFileWithStartFrame:timestamp.mSampleTime / _sampleRateRatio];
    YBAudioThrowIfErr(AudioUnitSetProperty(_auAudioUnit, kAudioUnitProperty_ScheduledFileRegion, kAudioUnitScope_Global, 0, &_region, sizeof(_region)));
    [self primeBuffers];
}

- (void)rescheduleEntireFileBeginningAtCurrentPlaybackTime {
    [self rescheduleEntireFileBeginningAtPlaybackTime:self.currentPlayTime];
}

- (void)setRegionEntireFile {
    [self resetRegionToEntireFileWithStartFrame:0];
    YBAudioThrowIfErr(AudioUnitSetProperty(_auAudioUnit, kAudioUnitProperty_ScheduledFileRegion, kAudioUnitScope_Global, 0, &_region, sizeof(_region)));
}

- (void)setRegion:(ScheduledAudioFileRegion*)region {
    if (region != &_region) {
        memcpy(&_region, region, sizeof(_region));
    }
    YBAudioThrowIfErr(AudioUnitSetProperty(_auAudioUnit, kAudioUnitProperty_ScheduledFileRegion, kAudioUnitScope_Global, 0, &_region, sizeof(_region)));
}

- (ScheduledAudioFileRegion *)region {
    return &_region;
}

- (void)primeBuffers {
    UInt32 defaultVal = 0;
    YBAudioThrowIfErr(AudioUnitSetProperty(_auAudioUnit, kAudioUnitProperty_ScheduledFilePrime, kAudioUnitScope_Global, 0, &defaultVal, sizeof(defaultVal)));
}

- (void)primeBuffersWithFrames:(UInt32)numberOfFrames {
    YBAudioThrowIfErr(AudioUnitSetProperty(_auAudioUnit, kAudioUnitProperty_ScheduledFilePrime, kAudioUnitScope_Global, 0, &numberOfFrames, sizeof(numberOfFrames)));
}

- (instancetype)initWithAUNode:(AUNode)auNode audioUnit:(AudioUnit)auAudioUnit inGraph:(YBAudioUnitGraph *)graph {
    self = [super initWithAUNode:auNode audioUnit:auAudioUnit inGraph:graph];
    if (self) {
        _sampleRateRatio = 1.;
    }
    return self;
}

- (void)dealloc {
    [self setFileURL:nil typeHint:0];
}
@end
