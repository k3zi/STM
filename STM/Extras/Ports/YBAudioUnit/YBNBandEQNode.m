//
//  YBMultiChannelMixer.m
//  YBAudioUnit
//
//  Created by Martijn Thé on 3/22/12.
//  Copyright (c) 2012 Yobble. All rights reserved.
//

#import "YBNBandEQNode.h"
#import "YBAudioException.h"

@implementation YBNBandEQNode

- (instancetype)initWithAUNode:(AUNode)auNode audioUnit:(AudioUnit)auAudioUnit inGraph:(YBAudioUnitGraph *)graph{
    self = [super initWithAUNode:auNode audioUnit:auAudioUnit inGraph:graph];
    
    // Frequency bands
    NSArray *eqFrequencies = @[ @80, @1000, @21000];
    
    // By default the equalizer isn't enabled! You need to set bypass
    // to zero so the equalizer actually does something
    NSArray *eqBypass = @[@0, @0, @0];
    
    UInt32 noBands = (UInt32)[eqFrequencies count];
    // Set the number of bands first
    YBAudioThrowIfErr(AudioUnitSetProperty(_auAudioUnit,
                                           kAUNBandEQProperty_NumberOfBands,
                                           kAudioUnitScope_Global,
                                           0,
                                           &noBands,
                                           sizeof(noBands)));
    // Set the frequencies
    for (int i=0; i<eqFrequencies.count; i++) {
        YBAudioThrowIfErr(AudioUnitSetParameter(_auAudioUnit,
                                                kAUNBandEQParam_Frequency+i,
                                                kAudioUnitScope_Global,
                                                0,
                                                (AudioUnitParameterValue)[eqFrequencies[i] floatValue],
                                                0));
    }
    // Set the bypass
    for (int i=0; i<eqBypass.count; i++) {
        YBAudioThrowIfErr(AudioUnitSetParameter(_auAudioUnit,
                                                kAUNBandEQParam_BypassBand+i,
                                                kAudioUnitScope_Global,
                                                0,
                                                (AudioUnitParameterValue)[eqBypass[i] intValue],
                                                0));
        if(i == 3){//high
            YBAudioThrowIfErr(AudioUnitSetParameter(_auAudioUnit,
                                                    kAUNBandEQParam_Bandwidth+i,
                                                    kAudioUnitScope_Global,
                                                    0,
                                                    0.1,//of octive
                                                    0));
        }else if(i == 2){//mid
            YBAudioThrowIfErr(AudioUnitSetParameter(_auAudioUnit,
                                                kAUNBandEQParam_Bandwidth+i,
                                                kAudioUnitScope_Global,
                                                0,
                                                0.05,//of octive
                                                0));
        }else{//low
            YBAudioThrowIfErr(AudioUnitSetParameter(_auAudioUnit,
                                                    kAUNBandEQParam_Bandwidth+i,
                                                    kAudioUnitScope_Global,
                                                    0,
                                                    0.5,//of octive
                                                    0));
        }
    }
    
    /*NSArray *eqFrequencies = @[ @32, @64, @125, @250, @500, @1000, @2000, @4000, @8000, @16000 ];
    self.numBands = eqFrequencies.count;
    self.bands = eqFrequencies;*/
    
    return self;
}

- (void)setGain:(NSInteger)gain forBand:(int)value{
    gain = gain - 96;//0 = -96, 120 = 24
    
    AudioUnitParameterID parameterID = kAUNBandEQParam_Gain + value;
    YBAudioThrowIfErr(AudioUnitSetParameter(_auAudioUnit, parameterID, kAudioUnitScope_Global, 0, gain, 0));
}

- (UInt32)maxNumberOfBands{
    UInt32 maxNumBands = 0;
    UInt32 propSize = sizeof(maxNumBands);
    YBAudioThrowIfErr(AudioUnitGetProperty(_auAudioUnit,
                                        kAUNBandEQProperty_MaxNumberOfBands,
                                        kAudioUnitScope_Global,
                                        0,
                                        &maxNumBands,
                                        &propSize));
    
    return maxNumBands;
}


- (UInt32)numBands{
    UInt32 numBands;
    UInt32 propSize = sizeof(numBands);
    YBAudioThrowIfErr(AudioUnitGetProperty(_auAudioUnit,
                                        kAUNBandEQProperty_NumberOfBands,
                                        kAudioUnitScope_Global,
                                        0,
                                        &numBands,
                                        &propSize));
    
    return numBands;
}

- (void)setNumBands:(UInt32)numBands
{
    YBAudioThrowIfErr(AudioUnitSetProperty(_auAudioUnit,
                                        kAUNBandEQProperty_NumberOfBands,
                                        kAudioUnitScope_Global,
                                        0,
                                        &numBands,
                                        sizeof(numBands)));
}


- (void)setBands:(NSArray *)bands{
    _bands = bands;
    
    for (AudioUnitParameterID i=0; i<bands.count; i++) {
        YBAudioThrowIfErr(AudioUnitSetParameter(_auAudioUnit,
                                             kAUNBandEQParam_Frequency+i,
                                             kAudioUnitScope_Global,
                                             0,
                                             (AudioUnitParameterValue)[bands[i] floatValue],
                                             0));
    }
}


- (AudioUnitParameterValue)gainForBandAtPosition:(AudioUnitParameterID)bandPosition{
    AudioUnitParameterValue gain;
    AudioUnitParameterID parameterID = kAUNBandEQParam_Gain + bandPosition;
    
    YBAudioThrowIfErr(AudioUnitGetParameter(_auAudioUnit,
                                         parameterID,
                                         kAudioUnitScope_Global,
                                         0,
                                         &gain));
    
    return gain;
}


- (void)setGain:(AudioUnitParameterValue)gain forBandAtPosition:(AudioUnitParameterID)bandPosition{
    AudioUnitParameterID parameterID = kAUNBandEQParam_Gain + bandPosition;
    
    YBAudioThrowIfErr(AudioUnitSetParameter(_auAudioUnit,
                                         parameterID,
                                         kAudioUnitScope_Global,
                                         0,
                                         gain,
                                         0));
}

@end
