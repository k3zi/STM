//
//  KZPlayerInner.m
//  EZAudio
//
//  Created by Syed Haris Ali on 12/2/13.
//  Copyright (c) 2013 Syed Haris Ali. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT FALSET LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND FALSENINFRINGEMENT. IN FALSE EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "KZPlayerInner.h"
#import "EZAudio.h"
#import "YBAudioUnit.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

#import "PRTween.h"

@interface KZPlayerInner() {
    YBAudioUnitGraph *graph;
    YBAudioUnitNode *ioNode;
    
    YBMultiChannelMixer *fileMixerNode;
    YBAudioUnitNode  *converter1;
    YBAudioUnitNode  *converter4;
    YBReverb *reverbNode;
    AudioStreamBasicDescription outputASBD;
    
    EZAudioFile *audioFile1;
    EZAudioFile *audioFile2;
}
@end

@implementation KZPlayerInner
@synthesize delegate = _delegate;

static KZPlayerInner *_sharedOutput = nil;
static YBNewTimePitch *timePitchNode;
static AudioBufferList *convertedEQBufferList;

static OSStatus RemoteIORenderCallback(void *inRefCon, AudioUnitRenderActionFlags  *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData) {
    
    KZPlayerInner *output = (__bridge KZPlayerInner *)inRefCon;
    //1. Call Mixer Audio Unit (Which calls the EQs Converter and stores in seperate convertedEQBufferList)
    //2. Take Eqs copy and put in ioData
    
    AudioBufferList *audioBufferList = (AudioBufferList *)malloc(sizeof(AudioBufferList));
    audioBufferList->mNumberBuffers = ioData->mNumberBuffers;
    audioBufferList->mBuffers[0].mNumberChannels = ioData->mBuffers[0].mNumberChannels;
    audioBufferList->mBuffers[0].mDataByteSize = ioData->mBuffers[0].mDataByteSize;
    audioBufferList->mBuffers[0].mData = (STMAudioUnitSampleType *)malloc(ioData->mBuffers[0].mDataByteSize);
    OSStatus status = AudioUnitRender(output.converter3.audioUnit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, audioBufferList);
    
    AudioStreamBasicDescription outputFormat = {0};
    [output.converter3 getStreamFormat:&outputFormat scope:kAudioUnitScope_Output bus:0];
    if(status == noErr)[output.delegate hasDataWithMic:audioBufferList numberOfFrames:inNumberFrames format:outputFormat];
    
    //audioBufferList = Buffer With Mic Input
    //convertedEQBufferList = Buffer Without Mic Input
    
    memcpy(ioData->mBuffers[0].mData, (char*)convertedEQBufferList->mBuffers[0].mData, convertedEQBufferList->mBuffers[0].mDataByteSize);
    memset(convertedEQBufferList->mBuffers[0].mData, 0, convertedEQBufferList->mBuffers[0].mDataByteSize);
    
    return noErr;
}

static OSStatus InputFileRenderCallback(void *inRefCon, AudioUnitRenderActionFlags  *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData) {
    /*if (ABReceiverPortIsConnected([[AppDelegate del] receiverPort])) {
        // Receive audio from Audiobus, if connected. Note that we also fetch the timestamp here, which is
        // useful for latency compensation, where appropriate.
        AudioTimeStamp timestamp = *inTimeStamp;
        ABReceiverPortReceive([[AppDelegate del] receiverPort], nil, ioData, inNumberFrames, &timestamp);
    }else{*/
        KZPlayerInner *output = (__bridge KZPlayerInner*)inRefCon;
        [output.delegate shouldFillAudio1BufferList:ioData frames:inNumberFrames];
    //}
    
    return noErr;
}

static OSStatus InputFile2RenderCallback(void *inRefCon, AudioUnitRenderActionFlags  *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData) {
   /* if (ABReceiverPortIsConnected([[AppDelegate del] receiverPort])) {
        // Receive audio from Audiobus, if connected. Note that we also fetch the timestamp here, which is
        // useful for latency compensation, where appropriate.
        AudioTimeStamp timestamp = *inTimeStamp;
        ABReceiverPortReceive([[AppDelegate del] receiverPort], nil, ioData, inNumberFrames, &timestamp);
    }else{*/
        KZPlayerInner *output = (__bridge KZPlayerInner*)inRefCon;
        [output.delegate shouldFillAudio2BufferList:ioData frames:inNumberFrames];
    //}
    
    return noErr;
}

static OSStatus EQConverterRenderCallback(void *inRefCon, AudioUnitRenderActionFlags  *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData) {
    //Calls & stores in seperaye bundle)
    KZPlayerInner *output = (__bridge KZPlayerInner*)inRefCon;
    
    AudioUnitRender(output.converter2.audioUnit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData);
    if(!convertedEQBufferList) {
        convertedEQBufferList = (AudioBufferList *)malloc(sizeof(AudioBufferList));
    }
    convertedEQBufferList->mNumberBuffers = ioData->mNumberBuffers;
    convertedEQBufferList->mBuffers[0].mNumberChannels = ioData->mBuffers[0].mNumberChannels;
    if(convertedEQBufferList->mBuffers[0].mDataByteSize != ioData->mBuffers[0].mDataByteSize) {
        convertedEQBufferList->mBuffers[0].mDataByteSize = ioData->mBuffers[0].mDataByteSize;
        convertedEQBufferList->mBuffers[0].mData = (STMAudioUnitSampleType *)malloc(ioData->mBuffers[0].mDataByteSize);
    }
    
    memcpy(convertedEQBufferList->mBuffers[0].mData, (char*)ioData->mBuffers[0].mData, ioData->mBuffers[0].mDataByteSize);
    return noErr;
}

- (float)convertFloatToRate:(float)x{
    return ((4.5)*(x*x)) - (0.75*x) + 0.25;
}

#pragma mark - Initialization
- (id)init {
    self = [super init];
    if(self) {
        [self _configureOutput];
    }
    return self;
}

- (instancetype)initWithDelegate:(id<KZPlayerInnerDelegate>)delegate {
    self = [super init];
    if(self) {
        self.delegate = delegate;
        [self _configureOutput];
    }
    return self;
}

#pragma mark - Configure The Output Unit

- (void)_configureOutput {
    outputASBD = [EZAudio stereoCanonicalNonInterleavedFormatWithSampleRate:48000];
    graph = [[YBAudioUnitGraph alloc] init];
    
    //SETUP File/EQs
    reverbNode = [graph addNodeWithType:YBAudioComponentTypeReverb2];
    timePitchNode = [graph addNodeWithType:YBAudioComponentTypeNewTimePitch];
    converter1 = [graph addNodeWithType:YBAudioComponentTypeConverter];
    self.converter2 = [graph addNodeWithType:YBAudioComponentTypeConverter];
    [reverbNode setMaximumFramesPerSlice:4096];
    [timePitchNode setMaximumFramesPerSlice:4096];
    [converter1 setMaximumFramesPerSlice:4096];
    [self.converter2 setMaximumFramesPerSlice:4096];
    
    AudioStreamBasicDescription eqFormat = {0};
    [reverbNode getStreamFormat:&eqFormat scope:kAudioUnitScope_Input bus:0];
    [converter1 setStreamFormat:&outputASBD scope:kAudioUnitScope_Input bus:0];
    [converter1 setStreamFormat:&eqFormat scope:kAudioUnitScope_Output bus:0];
    [self.converter2 setStreamFormat:&eqFormat scope:kAudioUnitScope_Input bus:0];
    [self.converter2 setStreamFormat:&outputASBD scope:kAudioUnitScope_Output bus:0];
    
    
    //SETUP Mixer
    self.mixerNode = [graph addNodeWithType:YBAudioComponentTypeMultiChannelMixer];
    [self.mixerNode setBusCount:2 scope:kAudioUnitScope_Input];
    [self.mixerNode setMaximumFramesPerSlice:4096];
    [self.mixerNode enableMetering:TRUE];
    [self.mixerNode setStreamFormat:&outputASBD scope:kAudioUnitScope_Input bus:0];
    [self.mixerNode setStreamFormat:&outputASBD scope:kAudioUnitScope_Input bus:1];
    
    AudioStreamBasicDescription mixerOutputFormat = {0};
    self.converter3 = [graph addNodeWithType:YBAudioComponentTypeConverter];
    [self.converter3 setMaximumFramesPerSlice:4096];
    [self.mixerNode getStreamFormat:&mixerOutputFormat scope:kAudioUnitScope_Output bus:0];
    [self.converter3 setStreamFormat:&mixerOutputFormat scope:kAudioUnitScope_Input bus:0];
    [self.converter3 setStreamFormat:&outputASBD scope:kAudioUnitScope_Output bus:0];
    
    //SETUP File Mixer
    fileMixerNode = [graph addNodeWithType:YBAudioComponentTypeMultiChannelMixer];
    [fileMixerNode setBusCount:2 scope:kAudioUnitScope_Input];
    [fileMixerNode setMaximumFramesPerSlice:4096];
    [fileMixerNode setStreamFormat:&outputASBD scope:kAudioUnitScope_Input bus:0];
    [fileMixerNode setStreamFormat:&outputASBD scope:kAudioUnitScope_Input bus:1];
    
    converter4 = [graph addNodeWithType:YBAudioComponentTypeConverter];
    [converter4 setMaximumFramesPerSlice:4096];
    [converter4 setStreamFormat:&mixerOutputFormat scope:kAudioUnitScope_Input bus:0];
    [converter4 setStreamFormat:&eqFormat scope:kAudioUnitScope_Output bus:0];
    
    //SETUP RemoteIO
    ioNode = [graph addNodeWithType:YBAudioComponentTypeRemoteIO]; //(_outputASBD->_outputASBD)
    [ioNode setMaximumFramesPerSlice:4096];
    UInt32 flag = 1;
    [EZAudio checkResult: AudioUnitSetProperty(ioNode.audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &flag, sizeof(flag)) operation:"Enable Recording"];
    [ioNode setStreamFormat:&outputASBD scope:kAudioUnitScope_Output bus:1];
    [ioNode setStreamFormat:&outputASBD scope:kAudioUnitScope_Input bus:0];
    
    
    //SETUP Connections (audio->converter1->eqs->converter2->mixer->converter3->io)
    [fileMixerNode connectOutput:0 toInput:0 ofNode:converter4];
    [converter4 connectOutput:0 toInput:0 ofNode:reverbNode];
    [reverbNode connectOutput:0 toInput:0 ofNode:timePitchNode];
    [timePitchNode connectOutput:0 toInput:0 ofNode:self.converter2];
    [self.converter2 connectOutput:0 toInput:0 ofNode:self.mixerNode];
    [self.mixerNode connectOutput:0 toInput:0 ofNode:self.converter3];
    [self.converter3 connectOutput:0 toInput:0 ofNode:ioNode];
    
    [ioNode connectOutput:1 toInput:1 ofNode:self.mixerNode];
    
    AURenderCallbackStruct callbackStruct1;
    callbackStruct1.inputProc = InputFileRenderCallback;
    callbackStruct1.inputProcRefCon = (__bridge void *)(self);
    [fileMixerNode setCallback:callbackStruct1 forScope:kAudioUnitScope_Input bus:0];
    
    AURenderCallbackStruct callbackStruct2;
    callbackStruct2.inputProc = InputFile2RenderCallback;
    callbackStruct2.inputProcRefCon = (__bridge void *)(self);
    [fileMixerNode setCallback:callbackStruct2 forScope:kAudioUnitScope_Input bus:1];
    
    AURenderCallbackStruct callbackStruct3;
    callbackStruct3.inputProc = EQConverterRenderCallback;
    callbackStruct3.inputProcRefCon = (__bridge void *)(self);
    [self.mixerNode setCallback:callbackStruct3 forScope:kAudioUnitScope_Input bus:0];
    
    AURenderCallbackStruct callbackStruct4;
    callbackStruct4.inputProc = RemoteIORenderCallback;
    callbackStruct4.inputProcRefCon = (__bridge void *)(self);
    [ioNode setCallback:callbackStruct4 forScope:kAudioUnitScope_Input bus:0];
    
    [graph updateSynchronous];
    [self setVolume:0.0 forPlayer:1];
    [self setVolume:0.0 forPlayer:0];
}

- (void)setReverbValue:(float)val{
    [reverbNode setDryWet:val];
}

- (void)setPitchValue:(float)value{
    [timePitchNode setPitch:value];
}

- (void)setRateValue:(float)value{
    [timePitchNode setRate:[self convertFloatToRate:value]];
}

- (void)setVolume:(float)volume forPlayer:(int)player{
    [fileMixerNode setVolume:volume forBus:player-1];
}

- (float)volumeForPlayer:(int)player{
    return [fileMixerNode volumeForBus:player-1];
}

#pragma mark - Events

- (BOOL)isPlaying{
    return graph.running;
}

- (void)startPlayback {
    if(![self isPlaying]) {
        [graph start];
    }
}

- (void)stopPlayback {
    if([self isPlaying]) {
        [graph stop];
    }
}

#pragma mark - Getters
- (AudioStreamBasicDescription)audioStreamBasicDescription {
    return outputASBD;
}

- (void)dealloc {
    [graph stop];
}

@end
