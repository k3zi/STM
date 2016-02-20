//
//  YBDistortionFilter.h
//  YBAudioUnit
//
//  Created by Martijn Thé on 3/22/12.
//  Copyright (c) 2012 Yobble. All rights reserved.
//

#import "YBAudioUnitNode.h"

@interface YBDelay : YBAudioUnitNode

/** Delay in Milliseconds, 0 -> 2, 0  */
@property (nonatomic, readwrite, assign) AudioUnitParameterValue delay;

@end
