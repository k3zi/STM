//
//  YBMultiChannelMixer.h
//  YBAudioUnit
//
//  Created by Martijn Thé on 3/22/12.
//  Copyright (c) 2012 Yobble. All rights reserved.
//

#import "YBAudioUnitNode.h"

@interface YBPresetEQNode : YBAudioUnitNode

@property (nonatomic, getter=iPodEQPresetsArray) CFArrayRef mEQPresetsArray;

/**
    Enables or disables (mutes) a mixer input bus.
    @see kMultiChannelMixerParam_Enable
 */
- (void)selectEQPreset:(NSInteger)value;

@end

