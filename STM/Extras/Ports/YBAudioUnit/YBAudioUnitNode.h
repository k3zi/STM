//
//  YBAudioUnitNode.h
//  YBAudioUnit
//
//  Created by Martijn Thé on 3/20/12.
//  Copyright (c) 2012 Yobble. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@class YBAudioUnitGraph;

/**
	YBAudioUnitNode represents a node in a graph and it's associated audio component instance.
    You can create new nodes by using -[YBAudioUnitGraph -addNodeWithType:] factory method.
    Do not use [[YBAudioUnitNode alloc] init] directly, this will cause an exception.
 
    YBAudioUnitNode provides a convenient interface to simplify tasks related to configuring
    the audio unit's properties and making and breaking connections between units in the graph.
 
    It wraps both a CoreAudio AUNode and its corresponding AudioUnit instance.
    These lower-level constructs are hidden deliberately, although are accessed by other objects
    in the framework through hidden category methods. See the .m file for more info.
 */

@interface YBAudioUnitNode : NSObject {
    @package
    AUNode _auNode;
    AudioUnit _auAudioUnit;
}

/**
	The graph instance to which the receiver belongs
 */
@property (nonatomic, readonly, weak) YBAudioUnitGraph *graph;

/**
	Convenience methods to make and break connections between busses of nodes
 */
- (void)connectInput:(AudioUnitElement)inBus toOutput:(AudioUnitElement)outBus ofNode:(YBAudioUnitNode*)outNode;
- (void)connectOutput:(AudioUnitElement)outBus toInput:(AudioUnitElement)inBus ofNode:(YBAudioUnitNode*)inNode;
- (void)disconnectInput:(AudioUnitElement)inBus;

- (void)reset;

/**
    Accessors for the MaximumFramesPerSlice property
    This property can only be set BEFORE the mixer's is connected / initialized.
	@see kAudioUnitProperty_MaximumFramesPerSlice
 */
@property (nonatomic, readwrite, assign) UInt32 maximumFramesPerSlice;

/**
	Accessor for the Bypass property, YES indicating the unit's processing should be bypassed
    @see kAudioUnitProperty_BypassEffect
 */
// TODO: turning bypass on/off seems to work only once...?
@property (nonatomic, readwrite, assign) UInt32 bypass;

/**
	Accessors for the StreamFormat property
    @see kAudioUnitProperty_StreamFormat
 */
- (void)setStreamFormat:(AudioStreamBasicDescription*)asbd scope:(AudioUnitScope)scope bus:(AudioUnitElement)bus;
- (void)getStreamFormat:(AudioStreamBasicDescription*)asbd scope:(AudioUnitScope)scope bus:(AudioUnitElement)bus; 

/**
	Accessors for the SampleRate property
    @see kAudioUnitProperty_SampleRate
 */
- (void)setSampleRate:(Float64)sampleRate scope:(AudioUnitScope)scope bus:(AudioUnitElement)bus;
- (Float64)sampleRateInScope:(AudioUnitScope)scope bus:(AudioUnitElement)bus;

/**
     Accessors for the Bus Count (ElementCount) property
     @see kAudioUnitProperty_ElementCount
 */
- (void)setBusCount:(UInt32)busCount scope:(AudioUnitScope)scope;
- (UInt32)busCountInScope:(AudioUnitScope)scope;

- (void)enableMeteringWithScope:(AudioUnitScope)scope bus:(AudioUnitElement)bus;
- (float)averagePowerWithScope:(AudioUnitScope)scope bus:(AudioUnitElement)bus;

- (void)enableMetering:(BOOL)enabled;
@property (NS_NONATOMIC_IOSONLY, readonly) float averagePower;
- (void)setCallback:(AURenderCallbackStruct)callbackStruct forScope:(int)scope bus:(int)bu;
- (void)setInputCallback:(AURenderCallbackStruct)callbackStruct forScope:(int)scope bus:(int)bus;
@end


@interface YBAudioUnitNode (LowerLevel)
@property (NS_NONATOMIC_IOSONLY, readonly) AUNode AUNode;
@property (NS_NONATOMIC_IOSONLY, readonly) AudioUnit audioUnit;
@end


@interface YBAudioUnitNode (DynamicParameterAccessorResolution)
typedef struct {
    SEL sel;
    AudioUnitParameterID paramID;
    AudioUnitScope scope;
    AudioUnitElement element;
    BOOL isSetter;
} YBParameterAccessorDescription;
+ (BOOL)resolveParameterAccessor:(YBParameterAccessorDescription)parameterAccessorDescription;
- (instancetype)initWithAUNode:(AUNode)auNode audioUnit:(AudioUnit)auAudioUnit inGraph:(YBAudioUnitGraph *)graph;
@end
