//
//  KZPlayerInner.h
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
#import <Accelerate/Accelerate.h>
#import "YBAudioUnit.h"
#import "TPCircularBuffer.h"

@protocol KZPlayerInnerDelegate <NSObject>

- (void)hasDataWithMic:(AudioBufferList *)audioBufferList numberOfFrames:(UInt32)frames format:(AudioStreamBasicDescription)format;
- (void)shouldFillAudio1BufferList:(AudioBufferList *)audioBufferList frames:(UInt32)frames;
- (void)shouldFillAudio2BufferList:(AudioBufferList *)audioBufferList frames:(UInt32)frames;

@end


@interface KZPlayerInner : NSObject

@property (nonatomic,assign) id<KZPlayerInnerDelegate>delegate;

@property YBMultiChannelMixer *mixerNode;
@property YBAudioUnitNode  *converter2;
@property YBAudioUnitNode  *converter3;

- (instancetype)initWithDelegate:(id<KZPlayerInnerDelegate>)delegate;

- (void)startPlayback;
- (void)stopPlayback;

- (AudioStreamBasicDescription)audioStreamBasicDescription;

- (BOOL)isPlaying;

- (void)setPitchValue:(float)value;
- (void)setReverbValue:(float)val;
- (void)setRateValue:(float)value;

- (void)setVolume:(float)volume forPlayer:(int)player;
- (float)volumeForPlayer:(int)player;

@end
