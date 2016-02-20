//
//  YBAudioComponent.h
//  YBAudioUnit
//
//  Created by Martijn Thé on 3/20/12.
//  Copyright (c) 2012 Yobble. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, YBAudioComponentType) {
    
    /** Converters */
    YBAudioComponentTypeConverter,
    YBAudioComponentTypeVariSpeed,
    YBAudioComponentTypeiPodTime,
    YBAudioComponentTypeNewTimePitch,
    
    /** Effects */
    YBAudioComponentTypePeakLimiter,
    YBAudioComponentTypeDynamicsProcessor,
    YBAudioComponentTypeReverb2,
    YBAudioComponentTypeLowPassFilter,
    YBAudioComponentTypeHighPassFilter,
    YBAudioComponentTypeBandPassFilter,
    YBAudioComponentTypeHighShelfFilter,
    YBAudioComponentTypeLowShelfFilter,
    YBAudioComponentTypeParametricEQ,
    YBAudioComponentTypeDelay,
    YBAudioComponentTypeDistortion,
    YBAudioComponentTypeiPodEQ,
    YBAudioComponentTypeNBandEQ,
    
    YBAudioComponentTypeTremolo,
    
    /** Mixers */
    YBAudioComponentTypeMultiChannelMixer,
    YBAudioComponentType3DMixerEmbedded,
    
    /** Generators */
    YBAudioComponentTypeScheduledSoundPlayer,
    YBAudioComponentTypeAudioFilePlayer,
    
    /** Music Instruments */
    YBAudioComponentTypeSampler,
    
    /** Input/Output */
    YBAudioComponentTypeGenericOutput,
    YBAudioComponentTypeRemoteIO,
    YBAudioComponentTypeVoiceProcessingIO
    
} ;

extern const OSType kAudioUnitManufacturer_Yobble;

@interface YBAudioComponent : NSObject @end
