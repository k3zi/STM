//
//  YBMultiChannelMixer.h
//  YBAudioUnit
//
//  Created by Martijn Thé on 3/22/12.
//  Copyright (c) 2012 Yobble. All rights reserved.
//

#import "YBAudioUnitNode.h"

@interface YBNBandEQNode : YBAudioUnitNode

@property (readonly, nonatomic) UInt32 maxNumberOfBands;
@property (readwrite, nonatomic) UInt32 numBands;
@property (readwrite, nonatomic) NSArray *bands;
- (AudioUnitParameterValue)gainForBandAtPosition:(AudioUnitParameterID)bandPosition;
- (void)setGain:(AudioUnitParameterValue)gain forBandAtPosition:(AudioUnitParameterID)bandPosition;
- (void)setGain:(NSInteger)gain forBand:(int)value;
@end

