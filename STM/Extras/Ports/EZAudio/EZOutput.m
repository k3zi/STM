//
//  EZOutput.m
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

#import "EZOutput.h"
#import "EZAudio.h"
#import "YBAudioUnit.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

#import "PRTween.h"
#import "MeterTable.h"

#define kBLOCK_SIZE 4096

@interface EZOutput () {
    YBAudioUnitGraph *graph;
    YBAudioUnitNode *ioNode;
    double currentSampleRate;
    double callCount;
}
@end

@implementation EZOutput
@synthesize outputDataSource = _outputDataSource;
@synthesize mixerNode, fileMixerNode, descAACFormat, reverbNode, converter1, converter2, converter3, converter4;

static EZOutput *_sharedOutput = nil;
static AudioConverterRef _render_converter;
static float zero;
static YBNewTimePitch *timePitchNode;
static AudioBufferList *convertedEQBufferList;

static OSStatus RemoteIORenderCallback(void *inRefCon, AudioUnitRenderActionFlags  *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData) {

    EZOutput *output = (__bridge EZOutput*)inRefCon;
    AudioBufferList *audioBufferList = (AudioBufferList *)malloc(sizeof(AudioBufferList));
    audioBufferList->mNumberBuffers = ioData->mNumberBuffers;
    audioBufferList->mBuffers[0].mNumberChannels = ioData->mBuffers[0].mNumberChannels;
    audioBufferList->mBuffers[0].mDataByteSize = ioData->mBuffers[0].mDataByteSize;
    audioBufferList->mBuffers[0].mData = (STMAudioUnitSampleType *)malloc(ioData->mBuffers[0].mDataByteSize);

    if(output.inputMonitoring) {
        AudioUnitRender(output.converter3.audioUnit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData);
        memcpy(audioBufferList->mBuffers[0].mData, (char*)ioData->mBuffers[0].mData, ioData->mBuffers[0].mDataByteSize);
        [output convertToAAC:audioBufferList];
    } else {
        //1. Call Mixer Audio Unit (Which calls the EQs Converter and stores in seperate convertedEQBufferList)
        //2. Take Eqs copy and put in ioData
        AudioUnitRender(output.converter3.audioUnit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, audioBufferList);

        //TODO: Pass in the format for the sampleRate
        [output convertToAAC:audioBufferList];

        //audioBufferList = Buffer With Mic Input
        //convertedEQBufferList = Buffer Without Mic Input

        if(convertedEQBufferList){
            memcpy(ioData->mBuffers[0].mData, (char*)convertedEQBufferList->mBuffers[0].mData, convertedEQBufferList->mBuffers[0].mDataByteSize);
            memset(convertedEQBufferList->mBuffers[0].mData, 0, convertedEQBufferList->mBuffers[0].mDataByteSize);
        }
    }
    return noErr;
}

static OSStatus InputFileRenderCallback(void *inRefCon, AudioUnitRenderActionFlags  *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData) {
    EZOutput *output = (__bridge EZOutput*)inRefCon;
    [output.outputDataSource output:output shouldFillAudioBufferList:ioData withNumberOfFrames:inNumberFrames];

    return noErr;
}

static OSStatus InputFile2RenderCallback(void *inRefCon, AudioUnitRenderActionFlags  *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData) {
    EZOutput *output = (__bridge EZOutput*)inRefCon;
    [output.outputDataSource output:output shouldFillAudioBufferList2:ioData withNumberOfFrames:inNumberFrames];

    return noErr;
}

static OSStatus EQConverterRenderCallback(void *inRefCon, AudioUnitRenderActionFlags  *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData) {
    //Calls & stores in seperaye bundle)
    EZOutput *output = (__bridge EZOutput*)inRefCon;

    AudioUnitRender(output.converter2.audioUnit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData);
    if(!output.inputMonitoring) {
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
    }
    return noErr;
}

- (float)convertFloatToRate:(float)x{
    return ((4.5)*(x*x)) - (0.75*x) + 0.25;
}

- (void)convertToAAC:(AudioBufferList *)audioBufferList {
    if(currentSampleRate != [AVAudioSession sharedInstance].sampleRate) {
        currentSampleRate = [AVAudioSession sharedInstance].sampleRate;
        descAACFormat = [EZAudio M4AFormatWithNumberOfChannels:2 sampleRate:currentSampleRate];
        _outputASBD = [EZAudio stereoCanonicalNonInterleavedFormatWithSampleRate:currentSampleRate];
        // see the question as for setting up pcmASBD and arc ASBD
        AudioClassDescription *description = [self getAudioClassDescriptionWithType:kAudioFormatMPEG4AAC fromManufacturer:kAppleSoftwareAudioCodecManufacturer];
        if (!description) {
            NSLog(@"description  fail!");
        }


        OSStatus st = AudioConverterNewSpecific(&_outputASBD, &descAACFormat, 2, description, &_render_converter);
        if(st) {
            NSLog(@"error creating audio converter: %d",(int)st);
        }
    }

    if ((CACurrentMediaTime() - callCount) > 0.1) {
        @autoreleasepool {
            NSData *data = [NSData dataWithBytes:audioBufferList->mBuffers[0].mData length:audioBufferList->mBuffers[0].mDataByteSize];
            [self playedDataPCM:data frames:(int)data.length];
            data = nil;
        }

        callCount = CACurrentMediaTime();
    }

    if(!self.aacEncode) {
        NSData *data = [NSData dataWithBytes:audioBufferList->mBuffers[0].mData length:audioBufferList->mBuffers[0].mDataByteSize];
        [self.outputDataSource playedData:data frames:(int)data.length];
        data = nil;
        free(audioBufferList->mBuffers[0].mData);
        free(audioBufferList);
    }else{
        @autoreleasepool{
            NSMutableData *data = [NSMutableData data];

            int times = ceilf((float)audioBufferList->mBuffers[0].mDataByteSize / (float)kBLOCK_SIZE);

            for (int i = 0; i < times; i++) {
                AudioBufferList *pcmBufferList = AllocateABL(2, kBLOCK_SIZE, TRUE, 1);
                AudioBufferList *aacBufferList = AllocateABL(2, kBLOCK_SIZE, TRUE, 1);
                AudioStreamPacketDescription resultDesc;

                if((i*kBLOCK_SIZE + kBLOCK_SIZE) > audioBufferList->mBuffers[0].mDataByteSize) {
                    memcpy(pcmBufferList->mBuffers[0].mData, (char*)audioBufferList->mBuffers[0].mData + (i*kBLOCK_SIZE), audioBufferList->mBuffers[0].mDataByteSize - (i*kBLOCK_SIZE));
                }else{
                    memcpy(pcmBufferList->mBuffers[0].mData, (char*)audioBufferList->mBuffers[0].mData + (i*kBLOCK_SIZE), kBLOCK_SIZE);
                }

                UInt32 ouputPacketsCount = 1;
                if (0 == AudioConverterFillComplexBuffer(_render_converter, encoderDataProc, &pcmBufferList, &ouputPacketsCount, aacBufferList,&resultDesc)) {
                    [data appendData:[self adtsDataForPacketLength:aacBufferList->mBuffers[0].mDataByteSize sampleRate:currentSampleRate]];
                    [data appendBytes:aacBufferList->mBuffers[0].mData length:aacBufferList->mBuffers[0].mDataByteSize];

                }
                free(aacBufferList->mBuffers[0].mData);
                free(aacBufferList);
                free(pcmBufferList->mBuffers[0].mData);
                free(pcmBufferList);
            }
            [self.outputDataSource playedData:data frames:(int)data.length];
            data = nil;
            free(audioBufferList->mBuffers[0].mData);
            free(audioBufferList);
        }
    }
}

- (void)playedDataPCM:(NSData *)buffer frames:(int)frames {
    if([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        size_t length = frames;
        NSInteger sampleTally = 0;
        NSInteger samplesPerPixel = floor((length / [EZOutput sharedOutput].outputASBD.mBytesPerFrame)/41);
        NSMutableData *fullSongData = [NSMutableData data];
        SInt16 maxValue = 0;
        float power = [[EZOutput sharedOutput].mixerNode averagePower];
        float level = [[MeterTable sharedTable] ValueAt:power];

        if([[EZOutput sharedOutput].mixerNode volumeForBus:1] > 0.0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.outputDataSource updateMicLevel:level];
            });
        }

        @autoreleasepool {
            NSMutableData *data = [NSMutableData dataWithLength:length];
            memcpy(data.mutableBytes, buffer.bytes, frames);

            SInt16 *samples = (SInt16 *) data.mutableBytes;
            int sampleCount = (int)length / (int)[EZOutput sharedOutput].outputASBD.mBytesPerFrame;

            for (int i = 0; i < sampleCount; i++) {
                SInt16 left = *samples++;

                SInt16 right = 0;

                if ([EZOutput sharedOutput].outputASBD.mChannelsPerFrame == 2) {
                    right = *samples++;
                }

                sampleTally++;

                if (sampleTally > samplesPerPixel) {
                    left = (left / sampleTally);

                    if ([EZOutput sharedOutput].outputASBD.mChannelsPerFrame == 2) {
                        right = (right / sampleTally);
                    }

                    SInt16 val = right ? ((right + left) / 2) : left;

                    [fullSongData appendBytes:&val length:sizeof(val)];

                    sampleTally = 0;
                }
            }
        }

        NSMutableData *adjustedSongData = [[NSMutableData alloc] init];

        int sampleCount = (int)fullSongData.length / 2;

        int adjustFactor = ceilf((float)sampleCount / (self.outputDataSource.view.frame.size.width / (TRUE ? 2.0 : 1.0)));

        SInt16* samples = (SInt16 *)fullSongData.mutableBytes;

        int i = 0;

        while (i < sampleCount) {
            SInt16 val = 0;

            for (int j = 0; j < adjustFactor; j++) {
                val += samples[i + j];
            }
            val /= adjustFactor;

            if (ABS(val) > maxValue) {
                maxValue = ABS(val);
            }
            [adjustedSongData appendBytes:&val length:sizeof(val)];
            i += adjustFactor;
        }

        sampleCount = (int)adjustedSongData.length / 2;

        CGSize imageSize = CGSizeMake(sampleCount * (TRUE ? 2 : 0), self.outputDataSource.heightForVisualizer);
        float sampleAdjustmentFactor = imageSize.height / (float)maxValue;

        for (int i = 0; i < sampleCount; i++) {
            float val = *samples++;
            val = fabsf(val * sampleAdjustmentFactor) * level;
            if ((int)val == 0)
                val = 1.0;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.outputDataSource setBarHeight:i height:val];
            });
        }
    }
}


AudioBufferList * AllocateABL(UInt32 channelsPerFrame, UInt32 bytesPerFrame, bool interleaved, UInt32 capacityFrames) {
    AudioBufferList *bufferList = NULL;

    UInt32 numBuffers = interleaved ? 1 : channelsPerFrame;
    UInt32 channelsPerBuffer = interleaved ? channelsPerFrame : 1;

    bufferList = (AudioBufferList *)(calloc(1, offsetof(AudioBufferList, mBuffers) + (sizeof(AudioBuffer) * numBuffers)));

    bufferList->mNumberBuffers = numBuffers;

    for(UInt32 bufferIndex = 0; bufferIndex < bufferList->mNumberBuffers; ++bufferIndex) {
        bufferList->mBuffers[bufferIndex].mData = (void *)(calloc(capacityFrames, bytesPerFrame));
        bufferList->mBuffers[bufferIndex].mDataByteSize = capacityFrames * bytesPerFrame;
        bufferList->mBuffers[bufferIndex].mNumberChannels = channelsPerBuffer;
    }

    return bufferList;
}


OSStatus encoderDataProc(AudioConverterRef inAudioConverter, UInt32* ioNumberDataPackets, AudioBufferList* ioData, AudioStreamPacketDescription** outDataPacketDescription, void* inUserData) {

    AudioBufferList *pcmList = *(AudioBufferList**)inUserData;
    ioData->mBuffers[0].mData = pcmList->mBuffers[0].mData;
    ioData->mBuffers[0].mDataByteSize = pcmList->mBuffers[0].mDataByteSize;
    ioData->mBuffers[0].mNumberChannels = 2;
    *ioNumberDataPackets = ioData->mBuffers[0].mDataByteSize / [[EZOutput sharedOutput] outputASBD].mBytesPerPacket;

    return noErr;
}




- (AudioClassDescription *)getAudioClassDescriptionWithType:(UInt32)type fromManufacturer:(UInt32)manufacturer {
    static AudioClassDescription desc;

    UInt32 encoderSpecifier = type;
    OSStatus st;

    UInt32 size;
    st = AudioFormatGetPropertyInfo(kAudioFormatProperty_Encoders, sizeof(encoderSpecifier), &encoderSpecifier, &size);
    if (st) {
        NSLog(@"error getting audio format propery info: %d", (int)st);
        return nil;
    }

    unsigned int count = size / sizeof(AudioClassDescription);
    AudioClassDescription descriptions[count];
    st = AudioFormatGetProperty(kAudioFormatProperty_Encoders, sizeof(encoderSpecifier), &encoderSpecifier, &size, descriptions);
    if (st) {
        NSLog(@"error getting audio format propery: %d", (int)st);
        return nil;
    }

    for (unsigned int i = 0; i < count; i++) {
        if ((type == descriptions[i].mSubType) &&
            (manufacturer == descriptions[i].mManufacturer)) {
            memcpy(&desc, &(descriptions[i]), sizeof(desc));
            return &desc;
        }
    }

    return nil;
}

- (void)deinterleave:(float *)data left:(float *)left right:(float *)right length:(vDSP_Length)length {
    vDSP_vsadd(data, 2, &zero, left, 1, length);
    vDSP_vsadd(data+1, 2, &zero, right, 1, length);
}

- (void)interleave:(float *)data left:(float *)left right:(float *)right length:(vDSP_Length)length {
    vDSP_vsadd(left, 1, &zero, data, 2, length);
    vDSP_vsadd(right, 1, &zero, data+1, 2, length);
}

#pragma mark - Initialization
- (id)init {
    self = [super init];
    if(self) {
        [self _configureOutput];
    }
    return self;
}

#pragma mark - Singleton

+ (BOOL)isStarted{
    return (BOOL)(_sharedOutput);
}

+ (EZOutput*)sharedOutput {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedOutput = [[EZOutput alloc] init];
    });
    return _sharedOutput;
}

#pragma mark - Audio Component Initialization
- (AudioComponentDescription)_getOutputAudioComponentDescription {
    // Create an output component description for default output device
    AudioComponentDescription outputComponentDescription;
    outputComponentDescription.componentFlags        = 0;
    outputComponentDescription.componentFlagsMask    = 0;
    outputComponentDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
#if TARGET_OS_IPHONE
    outputComponentDescription.componentSubType      = kAudioUnitSubType_RemoteIO;
#elif TARGET_OS_MAC
    outputComponentDescription.componentSubType      = kAudioUnitSubType_DefaultOutput;
#endif
    outputComponentDescription.componentType         = kAudioUnitType_Output;
    return outputComponentDescription;
}

- (AudioComponent)_getOutputComponentWithAudioComponentDescription:(AudioComponentDescription)outputComponentDescription {
    // Try and find the component
    AudioComponent outputComponent = AudioComponentFindNext( NULL , &outputComponentDescription );
    NSAssert(outputComponent,@"Couldn't get input component unit!");
    return outputComponent;
}

#pragma mark - Configure The Output Unit

- (void)_configureOutput {
    zero = 0.0f;
    self.pitch = 1.0;
    currentSampleRate = [AVAudioSession sharedInstance].sampleRate;
    descAACFormat = [EZAudio M4AFormatWithNumberOfChannels:2 sampleRate:currentSampleRate];
    _outputASBD = [EZAudio stereoCanonicalNonInterleavedFormatWithSampleRate:currentSampleRate];
    graph = [[YBAudioUnitGraph alloc] init];

    //SETUP File/EQs
    reverbNode = [graph addNodeWithType:YBAudioComponentTypeReverb2];
    timePitchNode = [graph addNodeWithType:YBAudioComponentTypeNewTimePitch];
    converter1 = [graph addNodeWithType:YBAudioComponentTypeConverter];
    converter2 = [graph addNodeWithType:YBAudioComponentTypeConverter];
    [reverbNode setMaximumFramesPerSlice:4096];
    [timePitchNode setMaximumFramesPerSlice:4096];
    [converter1 setMaximumFramesPerSlice:4096];
    [converter2 setMaximumFramesPerSlice:4096];

    AudioStreamBasicDescription eqFormat = {0};
    [reverbNode getStreamFormat:&eqFormat scope:kAudioUnitScope_Input bus:0];
    [converter1 setStreamFormat:&_outputASBD scope:kAudioUnitScope_Input bus:0];
    [converter1 setStreamFormat:&eqFormat scope:kAudioUnitScope_Output bus:0];
    [converter2 setStreamFormat:&eqFormat scope:kAudioUnitScope_Input bus:0];
    [converter2 setStreamFormat:&_outputASBD scope:kAudioUnitScope_Output bus:0];


    //SETUP Mixer
    mixerNode = [graph addNodeWithType:YBAudioComponentTypeMultiChannelMixer];
    [mixerNode setBusCount:2 scope:kAudioUnitScope_Input];
    [mixerNode setMaximumFramesPerSlice:4096];
    [mixerNode enableMetering:TRUE];
    [mixerNode setStreamFormat:&_outputASBD scope:kAudioUnitScope_Input bus:0];
    [mixerNode setStreamFormat:&_outputASBD scope:kAudioUnitScope_Input bus:1];

    AudioStreamBasicDescription mixerOutputFormat = {0};
    converter3 = [graph addNodeWithType:YBAudioComponentTypeConverter];
    [converter3 setMaximumFramesPerSlice:4096];
    [mixerNode getStreamFormat:&mixerOutputFormat scope:kAudioUnitScope_Output bus:0];
    [converter3 setStreamFormat:&mixerOutputFormat scope:kAudioUnitScope_Input bus:0];
    [converter3 setStreamFormat:&_outputASBD scope:kAudioUnitScope_Output bus:0];

    //SETUP File Mixer
    fileMixerNode = [graph addNodeWithType:YBAudioComponentTypeMultiChannelMixer];
    [fileMixerNode setBusCount:2 scope:kAudioUnitScope_Input];
    [fileMixerNode setMaximumFramesPerSlice:4096];
    [fileMixerNode setStreamFormat:&_outputASBD scope:kAudioUnitScope_Input bus:0];
    [fileMixerNode setStreamFormat:&_outputASBD scope:kAudioUnitScope_Input bus:1];

    converter4 = [graph addNodeWithType:YBAudioComponentTypeConverter];
    [converter4 setMaximumFramesPerSlice:4096];
    [converter4 setStreamFormat:&mixerOutputFormat scope:kAudioUnitScope_Input bus:0];
    [converter4 setStreamFormat:&eqFormat scope:kAudioUnitScope_Output bus:0];

    //SETUP RemoteIO
    ioNode = [graph addNodeWithType:YBAudioComponentTypeRemoteIO]; //(_outputASBD->_outputASBD)
    [ioNode setMaximumFramesPerSlice:4096];
    UInt32 flag = 1;
    [EZAudio checkResult: AudioUnitSetProperty(ioNode.audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &flag, sizeof(flag)) operation:"Enable Recording"];
    [ioNode setStreamFormat:&_outputASBD scope:kAudioUnitScope_Output bus:1];
    [ioNode setStreamFormat:&_outputASBD scope:kAudioUnitScope_Input bus:0];


    //SETUP Connections (audio->converter1->eqs->converter2->mixer->converter3->io)
    [fileMixerNode connectOutput:0 toInput:0 ofNode:converter4];
    [converter4 connectOutput:0 toInput:0 ofNode:reverbNode];
    [reverbNode connectOutput:0 toInput:0 ofNode:timePitchNode];
    [timePitchNode connectOutput:0 toInput:0 ofNode:converter2];
    [converter2 connectOutput:0 toInput:0 ofNode:mixerNode];
    [mixerNode connectOutput:0 toInput:0 ofNode:converter3];
    [converter3 connectOutput:0 toInput:0 ofNode:ioNode];

    [ioNode connectOutput:1 toInput:1 ofNode:mixerNode];

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
    [mixerNode setCallback:callbackStruct3 forScope:kAudioUnitScope_Input bus:0];

    AURenderCallbackStruct callbackStruct4;
    callbackStruct4.inputProc = RemoteIORenderCallback;
    callbackStruct4.inputProcRefCon = (__bridge void *)(self);
    [ioNode setCallback:callbackStruct4 forScope:kAudioUnitScope_Input bus:0];





    [reverbNode setDryWet:0.0];
    [reverbNode setDecay:1.0];

    // see the question as for setting up pcmASBD and arc ASBD
    AudioClassDescription *description = [self getAudioClassDescriptionWithType:kAudioFormatMPEG4AAC fromManufacturer:kAppleSoftwareAudioCodecManufacturer];
    if (!description) {
        NSLog(@"description  fail!");
    }


    OSStatus st = AudioConverterNewSpecific(&_outputASBD, &descAACFormat, 2, description, &_render_converter);
    if(st) {
        NSLog(@"error creating audio converter: %d",(int)st);
    }

    [graph updateSynchronous];
    [self setVolume:0.0 forPlayer:1];
    [self setVolume:0.0 forPlayer:0];
    _activePlayer = -1;
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
    [fileMixerNode setVolume:volume forBus:player];
}

- (float)volumeForPlayer:(int)player{
    return [fileMixerNode volumeForBus:player];
}

- (void)crossToPlayer:(int)player withDuration:(float)duration{
    self.currentCrossfade +=  1;
    __block int crossfade = self.currentCrossfade;
    PRTweenPeriod *period1 = [PRTweenPeriod periodWithStartValue:[self volumeForPlayer:0] endValue:(player == 0) duration:duration];
    PRTweenPeriod *period2 = [PRTweenPeriod periodWithStartValue:[self volumeForPlayer:1] endValue:(player == 1) duration:duration];

    PRTweenOperation *operation1 = [PRTweenOperation new];
    operation1.period = period1;
    operation1.target = self;
    operation1.timingFunction = &PRTweenTimingFunctionLinear;
    operation1.updateBlock = ^(PRTweenPeriod *period) {
        [self setVolume:period.tweenedValue forPlayer:0];
    };
    operation1.completeBlock = ^(BOOL finished) {
        if(crossfade == self.currentCrossfade)
            [self.outputDataSource finishedCrossfade];
    };

    PRTweenOperation *operation2 = [PRTweenOperation new];
    operation2.period = period2;
    operation2.target = self;
    operation2.timingFunction = &PRTweenTimingFunctionLinear;
    operation2.updateBlock = ^(PRTweenPeriod *period) {
        [self setVolume:period.tweenedValue forPlayer:1];
    };


    [[PRTween sharedInstance] addTweenOperation:operation1];
    [[PRTween sharedInstance] addTweenOperation:operation2];
}

- (void)setActivePlayer:(int)activePlayer{
    [self crossToPlayer:activePlayer withDuration:0];
    _activePlayer = activePlayer;
}

- (void)setActivePlayer:(int)activePlayer withCrossfadeDuration:(float)duration{
    [self crossToPlayer:activePlayer withDuration:duration];
    _activePlayer = activePlayer;
}

- (NSData *)adtsDataForPacketLength:(NSUInteger)packetLength sampleRate:(float)sampleRate {
    int adtsLength = 7;
    char *packet = (char*)(malloc(sizeof(char) * adtsLength));
    // Variables Recycled by addADTStoPacket
    int profile = 2;  //AAC LC
    //39=MediaCodecInfo.CodecProfileLevel.AACObjectELD;
    int freqIdx = [self packetIDForSampleRate:sampleRate];
    int chanCfg = 2;  //MPEG-4 Audio Channel Configuration. 1 Channel front-center
    NSUInteger fullLength = adtsLength + packetLength;
    // fill in ADTS data
    packet[0] = (char)0xFF;	// 11111111  	= syncword
    packet[1] = (char)0xF9;	// 1111 1 00 1  = syncword MPEG-2 Layer CRC
    packet[2] = (char)(((profile-1)<<6) + (freqIdx<<2) + (chanCfg>>2));
    packet[3] = (char)(((chanCfg&3)<<6) + (fullLength>>11));
    packet[4] = (char)((fullLength&0x7FF) >> 3);
    packet[5] = (char)(((fullLength&7)<<5) + 0x1F);
    packet[6] = (char)0xFC;
    NSData *data = [NSData dataWithBytesNoCopy:packet length:adtsLength freeWhenDone:YES];
    return data;
}

- (int)packetIDForSampleRate:(float)sampleRate {
    switch ((int)sampleRate) {
        case 96000: return 0;
        case 88200: return 1;
        case 64000: return 2;
        case 48000: return 3; //Studio Quality
        case 44100: return 4; //CD Quality
        case 32000: return 5;
        case 24000: return 6;
        case 22050: return 7;
        case 16000: return 8;
        case 12000: return 9;
        case 11025: return 10;
        case 8000: return 11; //Phone Qulity
        case 7350: return 12;

        default:
            return 4;
    }
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
    return _outputASBD;
}

- (YBAudioUnitNode *)remoteIONode {
    return ioNode;
}

- (AudioComponentDescription)component {
    return (AudioComponentDescription) {
        .componentType = kAudioUnitType_RemoteGenerator,
        .componentSubType = '1270', // Note single quotes
        .componentManufacturer = 'stma' };
}

- (void)dealloc {
    [graph stop];
}

@end
