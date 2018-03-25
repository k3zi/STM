//
//  EZOutput.h
//  EZAudio
//
//  Created by Syed Haris Ali on 12/2/13.
//  Copyright (c) 2013 Syed Haris Ali. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT FALSET LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND FALSENINFRINGEMENT. IN FALSE EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#if TARGET_OS_IPHONE
#elif TARGET_OS_MAC
#import <AudioUnit/AudioUnit.h>
#endif
#import "YBAudioUnit.h"
#import <Accelerate/Accelerate.h>
#import <UIKit/UIKit.h>
@class EZOutput;

@protocol EZOutputDataSource <NSObject>

@optional
- (void)output:(EZOutput *)output shouldFillAudioBufferList:(AudioBufferList*)audioBufferList withNumberOfFrames:(UInt32)frames;
- (void)output:(EZOutput *)output shouldFillAudioBufferList2:(AudioBufferList *)audioBufferList withNumberOfFrames:(UInt32)frames;
- (void)output2:(EZOutput *)output shouldFillAudioBufferList:(AudioBufferList*)audioBufferList withNumberOfFrames:(UInt32)frames;
- (void)playedData:(NSData *)buffer frames:(int)frames;
- (void)updateMicLevel:(float)level;
- (void)setBarHeight:(int)barIndex height:(CGFloat)height;
- (CGFloat)heightForVisualizer;
- (int)numChannels;
- (void)finishedCrossfade;
@end

@interface EZOutput : NSObject

@property (nonatomic, assign) UIViewController<EZOutputDataSource>*outputDataSource;
@property (nonatomic, retain) YBMultiChannelMixer *mixerNode;
@property (nonatomic, retain) YBMultiChannelMixer *fileMixerNode;
@property (nonatomic, retain) YBAudioUnitNode  *converter1;
@property (nonatomic, retain) YBAudioUnitNode  *converter2;
@property (nonatomic, retain) YBAudioUnitNode  *converter3;
@property (nonatomic, retain) YBAudioUnitNode  *converter4;
@property float pitch;
@property YBReverb *reverbNode;
@property (nonatomic, assign) BOOL aacEncode;
@property BOOL inputMonitoring;
@property (nonatomic, assign) AudioStreamBasicDescription outputASBD;
@property (nonatomic) AudioStreamBasicDescription descAACFormat;
@property (nonatomic) int activePlayer;
@property int currentCrossfade;

+ (EZOutput*)sharedOutput;
- (YBAudioUnitNode *)remoteIONode;
- (AudioComponentDescription)component;
- (void)deinterleave:(float *)data left:(float *) left right: (float *) right length:(vDSP_Length) length;
- (void)interleave:(float *)data left:(float *) left right: (float *) right length:(vDSP_Length) length;
- (void)setPitchValue:(float)value;
- (void)setReverbValue:(float)val;
- (void)setRateValue:(float)value;
- (void)setVolume:(float) volume forPlayer:(int) player;
- (void)setActivePlayer:(int) activePlayer withCrossfadeDuration:(float) duration;
+ (BOOL)isStarted;
- (BOOL)isPlaying;
- (void)startPlayback;
- (void)stopPlayback;

- (AudioClassDescription *)getAudioClassDescriptionWithType:(UInt32)type fromManufacturer:(UInt32)manufacturer;
- (AudioStreamBasicDescription)audioStreamBasicDescription;

@end
