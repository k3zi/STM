//
//  YBDistortionFilter.m
//  YBAudioUnit
//
//  Created by Martijn Thé on 3/22/12.
//  Copyright (c) 2012 Yobble. All rights reserved.
//

#import "YBDelay.h"
#import "YBAudioUtils.h"

@implementation YBDelay

@dynamic delay;

+ (BOOL)resolveInstanceMethod:(SEL)aSEL {
    YBAudioUnitResolveAccessorPair(delay, Delay, kDelayParam_DelayTime, kAudioUnitScope_Global, 0);
    return [super resolveInstanceMethod:aSEL];
}

@end

