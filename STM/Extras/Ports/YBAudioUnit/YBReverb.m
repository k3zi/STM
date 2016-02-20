//
//  YBReverb.m
//  Stream To Me
//
//  Created by Kesi Maduka on 5/10/15.
//  Copyright (c) 2015 Storm Edge Apps LLC. All rights reserved.
//

#import "YBReverb.h"
#import "YBAudioException.h"

@implementation YBReverb

- (void)setDryWet:(float)val{
    YBAudioThrowIfErr(AudioUnitSetParameter(self.audioUnit, kReverb2Param_DryWetMix, kAudioUnitScope_Global, 0, (val * 100), 0));
}

- (void)setDecay:(float)val{
    YBAudioThrowIfErr(AudioUnitSetParameter(self.audioUnit, kReverb2Param_DecayTimeAt0Hz, kAudioUnitScope_Global, 0, val, 0));
}

@end
