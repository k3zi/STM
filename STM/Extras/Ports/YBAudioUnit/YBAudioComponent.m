//
//  YBAudioComponent.m
//  YBAudioUnit
//
//  Created by Martijn Thé on 3/20/12.
//  Copyright (c) 2012 Yobble. All rights reserved.
//

#import "YBAudioUnit.h"
#import <AudioUnit/AudioUnit.h>

const OSType kAudioUnitManufacturer_Yobble = 'ybbl';

@interface YBAudioComponent (Internal)
+ (void)fillOutComponentDescription:(AudioComponentDescription*)description withType:(YBAudioComponentType)type;
+ (Class)wrapperClassForComponentType:(YBAudioComponentType)type;
@end

@implementation YBAudioComponent

+ (void)fillOutComponentDescription:(AudioComponentDescription*)description withType:(YBAudioComponentType)type {
    if (description == NULL) {
        return;
    }
    
    memset(description, 0, sizeof(AudioComponentDescription));
    description->componentManufacturer = kAudioUnitManufacturer_Apple;
    
    switch (type) {
            
        /** Converters */
        case YBAudioComponentTypeConverter     : { description->componentType = kAudioUnitType_FormatConverter; description->componentSubType = kAudioUnitSubType_AUConverter; return; }
        case YBAudioComponentTypeVariSpeed     : { description->componentType = kAudioUnitType_FormatConverter; description->componentSubType = kAudioUnitSubType_Varispeed; return; }
        case YBAudioComponentTypeiPodTime      : { description->componentType = kAudioUnitType_FormatConverter; description->componentSubType = kAudioUnitSubType_AUiPodTime; return; }
        case YBAudioComponentTypeNewTimePitch : { description->componentType = kAudioUnitType_FormatConverter; description->componentSubType = kAudioUnitSubType_NewTimePitch; return; }
        /** Effects */
        case YBAudioComponentTypePeakLimiter       : { description->componentType = kAudioUnitType_Effect; description->componentSubType = kAudioUnitSubType_PeakLimiter; return; }
        case YBAudioComponentTypeDelay       : { description->componentType = kAudioUnitType_Effect; description->componentSubType = kAudioUnitSubType_Delay; return; }
        case YBAudioComponentTypeDynamicsProcessor : { description->componentType = kAudioUnitType_Effect; description->componentSubType = kAudioUnitSubType_DynamicsProcessor; return; }
        case YBAudioComponentTypeReverb2           : { description->componentType = kAudioUnitType_Effect; description->componentSubType = kAudioUnitSubType_Reverb2; return; }
        case YBAudioComponentTypeLowPassFilter     : { description->componentType = kAudioUnitType_Effect; description->componentSubType = kAudioUnitSubType_LowPassFilter; return; }
        case YBAudioComponentTypeHighPassFilter    : { description->componentType = kAudioUnitType_Effect; description->componentSubType = kAudioUnitSubType_HighPassFilter; return; }
        case YBAudioComponentTypeBandPassFilter    : { description->componentType = kAudioUnitType_Effect; description->componentSubType = kAudioUnitSubType_BandPassFilter; return; }
        case YBAudioComponentTypeHighShelfFilter   : { description->componentType = kAudioUnitType_Effect; description->componentSubType = kAudioUnitSubType_HighShelfFilter; return; }
        case YBAudioComponentTypeLowShelfFilter    : { description->componentType = kAudioUnitType_Effect; description->componentSubType = kAudioUnitSubType_LowShelfFilter; return; }
        case YBAudioComponentTypeParametricEQ      : { description->componentType = kAudioUnitType_Effect; description->componentSubType = kAudioUnitSubType_ParametricEQ; return; }
        case YBAudioComponentTypeDistortion        : { description->componentType = kAudioUnitType_Effect; description->componentSubType = kAudioUnitSubType_Distortion; return; }
        case YBAudioComponentTypeiPodEQ            : { description->componentType = kAudioUnitType_Effect; description->componentSubType = kAudioUnitSubType_AUiPodEQ; return; }
        case YBAudioComponentTypeNBandEQ           : { description->componentType = kAudioUnitType_Effect; description->componentSubType = kAudioUnitSubType_NBandEQ; return; }
        
        case YBAudioComponentTypeTremolo           : { description->componentManufacturer = kAudioUnitManufacturer_Yobble; description->componentType = kAudioUnitType_Effect; description->componentSubType = kAudioUnitSubType_Tremolo; return; }
            
        /** Mixers */
        case YBAudioComponentTypeMultiChannelMixer : { description->componentType = kAudioUnitType_Mixer; description->componentSubType = kAudioUnitSubType_MultiChannelMixer; return; }
        case YBAudioComponentType3DMixerEmbedded   : { description->componentType = kAudioUnitType_Mixer; description->componentSubType = kAudioUnitSubType_SpatialMixer; return; }
        
        /** Generators */
        case YBAudioComponentTypeScheduledSoundPlayer : { description->componentType = kAudioUnitType_Generator; description->componentSubType = kAudioUnitSubType_ScheduledSoundPlayer; return; }
        case YBAudioComponentTypeAudioFilePlayer      : { description->componentType = kAudioUnitType_Generator; description->componentSubType = kAudioUnitSubType_AudioFilePlayer; return; }
        
        /** Music Instruments */
        case YBAudioComponentTypeSampler : { description->componentType = kAudioUnitType_MusicDevice; description->componentSubType = kAudioUnitSubType_Sampler; return; }
        
        /** Input/Output */
        case YBAudioComponentTypeGenericOutput     : { description->componentType = kAudioUnitType_Output; description->componentSubType = kAudioUnitSubType_GenericOutput; return; }
        case YBAudioComponentTypeRemoteIO          : { description->componentType = kAudioUnitType_Output; description->componentSubType = kAudioUnitSubType_RemoteIO; return; }
        case YBAudioComponentTypeVoiceProcessingIO : { description->componentType = kAudioUnitType_Output; description->componentSubType = kAudioUnitSubType_VoiceProcessingIO; return; }
    }
}

+ (Class)wrapperClassForComponentType:(YBAudioComponentType)type {
    switch (type) {
        /** Effects */
        case YBAudioComponentTypeDistortion: return [YBDistortionFilter class];
        case YBAudioComponentTypeiPodEQ: return [YBPresetEQNode class];
        case YBAudioComponentTypeNBandEQ: return [YBNBandEQNode class];
        case YBAudioComponentTypeReverb2: return [YBReverb class];
        case YBAudioComponentTypeDelay: return [YBDelay class];
            
        /** Mixers */
        case YBAudioComponentTypeMultiChannelMixer: return [YBMultiChannelMixer class];
            
        /** Generators */
        case YBAudioComponentTypeScheduledSoundPlayer: return [YBScheduledSoundPlayer class];
        case YBAudioComponentTypeAudioFilePlayer: return [YBAudioFilePlayer class];
        
        case YBAudioComponentTypeVariSpeed: return [YBVarispeedConverter class];
        case YBAudioComponentTypeNewTimePitch: return [YBNewTimePitch class];
        default: return [YBAudioUnitNode class];
    }
}

@end
