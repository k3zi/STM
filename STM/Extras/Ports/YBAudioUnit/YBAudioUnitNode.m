//
//  YBAudioUnitNode.m
//  YBAudioUnit
//
//  Created by Martijn Thé on 3/20/12.
//  Copyright (c) 2012 Yobble. All rights reserved.
//

#import "YBAudioUnitNode.h"
#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "YBAudioUnitGraph.h"
#import "YBAudioException.h"
#import "YBAudioUtils.h"
#import <objc/runtime.h>
#import "EZAudio.h"

@interface YBAudioUnitNode (Internal)
- (instancetype)initWithAUNode:(AUNode)auNode audioUnit:(AudioUnit)auAudioUnit inGraph:(YBAudioUnitGraph *)graph;
@end

@implementation YBAudioUnitNode {
    __weak YBAudioUnitGraph *_graph; // nodes are retained by its _graph, hence __weak
}

- (instancetype)init {
    [NSException raise:@"YBAudioUnitNode" format:@"Please use -[YBAudioUnitGraph -addNodeWithType:] to create new nodes!"];
    return nil;
}

- (instancetype)initWithAUNode:(AUNode)auNode audioUnit:(AudioUnit)auAudioUnit inGraph:(YBAudioUnitGraph *)graph {
    self = [super init];
    if (self) {
        _auNode = auNode;
        _graph = graph;
        _auAudioUnit = auAudioUnit;
        
        AudioStreamBasicDescription outFormat;
        YBSetStreamFormatAUCanonical(&outFormat, 1, 44100, false);
        
        //AudioUnitSetProperty(_auAudioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &outFormat, sizeof(outFormat));
        //-AudioUnitSetProperty(_auAudioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &outFormat, sizeof(outFormat));
    }
    return self;
}

- (AUNode)AUNode {
    return _auNode;
}

- (AudioUnit)audioUnit {
    return _auAudioUnit;
}

- (void)setCallback:(AURenderCallbackStruct)callbackStruct forScope:(int)scope bus:(int)bus  {

    [EZAudio checkResult:AudioUnitSetProperty(_auAudioUnit,
                         kAudioUnitProperty_SetRenderCallback,
                         scope,
                         bus,
                         &callbackStruct,
                         sizeof(callbackStruct)) operation:"Setting callback"];
}

- (void)setInputCallback:(AURenderCallbackStruct)callbackStruct forScope:(int)scope bus:(int)bus  {
    
    [EZAudio checkResult:AudioUnitSetProperty(_auAudioUnit,
                                              kAudioOutputUnitProperty_SetInputCallback,
                                              scope,
                                              bus,
                                              &callbackStruct,
                                              sizeof(callbackStruct)) operation:"Setting callback"];
}

+ (BOOL)resolveParameterAccessor:(YBParameterAccessorDescription)parameterAccessorDescription {
    char *types;
    IMP imp;
    AudioUnitParameterID paramID = parameterAccessorDescription.paramID;
    AudioUnitScope scope = parameterAccessorDescription.scope;
    AudioUnitElement element = parameterAccessorDescription.element;
    if (parameterAccessorDescription.isSetter) {
        types = "v@:f";
        imp = imp_implementationWithBlock((__bridge id)((__bridge void*)(^(id _self, AudioUnitParameterValue value){
            YBAudioThrowIfErr(AudioUnitSetParameter([_self audioUnit], paramID, scope, element, value, 0));
        })));
    } else {
        types = "f@:";
        imp = imp_implementationWithBlock((__bridge id)((__bridge void*)(^(id _self, ...){
            AudioUnitParameterValue value;
            YBAudioThrowIfErr(AudioUnitGetParameter([_self audioUnit], paramID, scope, element, &value));
            return value;
        })));
    }
    class_addMethod([self class], parameterAccessorDescription.sel, imp, types);
    return YES;
}

- (void)connectInput:(AudioUnitElement)inBus toOutput:(AudioUnitElement)outBus ofNode:(YBAudioUnitNode*)outNode {
    [_graph connectInput:inBus ofNode:self toOutput:outBus ofNode:outNode];
}

- (void)connectOutput:(AudioUnitElement)outBus toInput:(AudioUnitElement)inBus ofNode:(YBAudioUnitNode*)inNode {
    [_graph connectOutput:outBus ofNode:self toInput:inBus ofNode:inNode];
}

- (void)disconnectInput:(AudioUnitElement)inBus {
    [_graph disconnectInput:inBus ofNode:self];
}

- (void)reset {
    YBAudioThrowIfErr(AudioUnitReset(_auAudioUnit, kAudioUnitScope_Global, 0));
}

#pragma mark - Property accessors:

- (void)setMaximumFramesPerSlice:(UInt32)maximumFramesPerSlice {
    NSParameterAssert(maximumFramesPerSlice != 0);
    YBAudioThrowIfErr(AudioUnitSetProperty(_auAudioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maximumFramesPerSlice, sizeof(UInt32)));
}
 
- (UInt32)maximumFramesPerSlice {
    UInt32 maximumFramesPerSlice = 0;
    UInt32 dataSize = sizeof(UInt32);
    YBAudioThrowIfErr(AudioUnitGetProperty(_auAudioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maximumFramesPerSlice, &dataSize));
    return maximumFramesPerSlice;
}

- (void)setBypass:(UInt32)bypass {
    UInt32 bypassInt = bypass ? 1 : 0;
    YBAudioThrowIfErr(AudioUnitSetProperty(_auAudioUnit, kAudioUnitProperty_BypassEffect, kAudioUnitScope_Global, 0, &bypassInt, sizeof(UInt32)));
}

- (UInt32)bypass {
    UInt32 bypassInt;
    UInt32 dataSize = sizeof(UInt32);
    YBAudioThrowIfErr(AudioUnitGetProperty(_auAudioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &bypassInt, &dataSize));
    return bypassInt;
}

- (void)setStreamFormat:(AudioStreamBasicDescription*)asbd scope:(AudioUnitScope)scope bus:(AudioUnitElement)bus {
    YBAudioThrowIfErr(AudioUnitSetProperty(_auAudioUnit, kAudioUnitProperty_StreamFormat, scope, bus, asbd, sizeof(AudioStreamBasicDescription)));
}

- (void)getStreamFormat:(AudioStreamBasicDescription*)asbd scope:(AudioUnitScope)scope bus:(AudioUnitElement)bus {
    NSParameterAssert(asbd != NULL);
    UInt32 datasize = sizeof(AudioStreamBasicDescription);
    memset(asbd, 0, datasize);
    YBAudioThrowIfErr(AudioUnitGetProperty(_auAudioUnit, kAudioUnitProperty_StreamFormat, scope, bus, asbd, &datasize));
}

- (void)setSampleRate:(Float64)sampleRate scope:(AudioUnitScope)scope bus:(AudioUnitElement)bus {
    YBAudioThrowIfErr(AudioUnitSetProperty(_auAudioUnit, kAudioUnitProperty_SampleRate, scope, bus, &sampleRate, sizeof(Float64)));
}

- (Float64)sampleRateInScope:(AudioUnitScope)scope bus:(AudioUnitElement)bus {
    Float64 sampleRate = 0;
    UInt32 datasize = sizeof(Float64);
    YBAudioThrowIfErr(AudioUnitGetProperty(_auAudioUnit, kAudioUnitProperty_StreamFormat, scope, bus, &sampleRate, &datasize));
    return sampleRate;
}

- (void)setBusCount:(UInt32)busCount scope:(AudioUnitScope)scope {
    YBAudioThrowIfErr(AudioUnitSetProperty(_auAudioUnit, kAudioUnitProperty_ElementCount, scope, 0, &busCount, sizeof(UInt32)));
}

- (UInt32)busCountInScope:(AudioUnitScope)scope {
    UInt32 busCount;
    UInt32 datasize = sizeof(UInt32);
    YBAudioThrowIfErr(AudioUnitGetProperty(_auAudioUnit, kAudioUnitProperty_ElementCount, scope, 0, &busCount, &datasize));
    return busCount;
}

- (void)enableMetering:(BOOL)enabled{
    [self enableMeteringWithScope:kAudioUnitScope_Output bus:0];
}

- (float)averagePower{
    return [self averagePowerWithScope:kAudioUnitScope_Output bus:0];
}

- (void)enableMeteringWithScope:(AudioUnitScope)scope bus:(AudioUnitElement)bus{
    UInt32 allowMetering = TRUE;
    AudioUnitSetProperty(_auAudioUnit,
                                           kAudioUnitProperty_MeteringMode,
                                           scope,
                                           bus,
                                           &allowMetering,
                                           sizeof(allowMetering));
    
}

- (float)averagePowerWithScope:(AudioUnitScope)scope bus:(AudioUnitElement)bus{
    Float32 value = -120.0;
    AudioUnitGetParameter(_auAudioUnit,
                                            kMultiChannelMixerParam_PostAveragePower,
                                            scope,
                                            bus,
                                            &value);
    return value;
}

- (NSString*)description {
    NSString *unitDescription = YBCoreAudioObjectToString(_auAudioUnit);
    return [NSString stringWithFormat:@"<%@ %p> ---> <%@ %p>\n%@", [self class], self, [_graph class], _graph, unitDescription];
}

@synthesize graph = _graph;
@end
