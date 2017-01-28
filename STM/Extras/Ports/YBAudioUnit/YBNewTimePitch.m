//
//  YBNewTimePitch.m
//  Stream To Me
//
//  Created by Kesi Maduka on 5/10/15.
//  Copyright (c) 2015 Storm Edge Apps LLC. All rights reserved.
//

#import "YBNewTimePitch.h"
#import "YBAudioException.h"

@implementation YBNewTimePitch

- (void)setRate:(float)rate{
    YBAudioThrowIfErr(AudioUnitSetParameter(self.audioUnit, kNewTimePitchParam_Rate, kAudioUnitScope_Global, 0, rate, 0));
}

- (void)setPitch:(float)pitch{
    YBAudioThrowIfErr(AudioUnitSetParameter(self.audioUnit, kNewTimePitchParam_Pitch, kAudioUnitScope_Global, 0, pitch, 0));
}

@end
