//
//  YBMultiChannelMixer.m
//  YBAudioUnit
//
//  Created by Martijn Thé on 3/22/12.
//  Copyright (c) 2012 Yobble. All rights reserved.
//

#import "YBPresetEQNode.h"
#import "YBAudioException.h"

@implementation YBPresetEQNode

@synthesize mEQPresetsArray;

- (id)initWithAUNode:(AUNode)auNode audioUnit:(AudioUnit)auAudioUnit inGraph:(YBAudioUnitGraph *)graph{
    self = [super initWithAUNode:auNode audioUnit:auAudioUnit inGraph:graph];
    UInt32 size = sizeof(mEQPresetsArray);
    YBAudioThrowIfErr(AudioUnitGetProperty(_auAudioUnit, kAudioUnitProperty_FactoryPresets, kAudioUnitScope_Global, 0, &mEQPresetsArray, &size));
    
     UInt8 count = CFArrayGetCount(mEQPresetsArray);
     for (int i = 0; i < count; ++i) {
         AUPreset *aPreset = (AUPreset*)CFArrayGetValueAtIndex(mEQPresetsArray, i);
         CFShow(aPreset->presetName);
     }
    return self;
}

- (void)setInputEnabled:(BOOL)enabled forBus:(AudioUnitElement)bus {
    AudioUnitParameterValue isOn = (AudioUnitParameterValue)enabled;
    YBAudioThrowIfErr(AudioUnitSetParameter(_auAudioUnit, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, bus, isOn, 0));
}

- (void)selectEQPreset:(NSInteger)value{
    AUPreset *aPreset = (AUPreset*)CFArrayGetValueAtIndex(mEQPresetsArray, value);
    AudioUnitSetProperty(_auAudioUnit, kAudioUnitProperty_PresentPreset, kAudioUnitScope_Global, 0, aPreset, sizeof(AUPreset));
    CFShow(aPreset->presetName);
}

@end
