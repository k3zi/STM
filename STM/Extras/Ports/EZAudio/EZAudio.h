//
//  EZAudio.h
//  EZAudio
//
//  Created by Syed Haris Ali on 11/21/13.
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

#if !CA_PREFER_FIXED_POINT
 typedef Float32     STMAudioSampleType;
 typedef Float32     STMAudioUnitSampleType;
#else
 typedef SInt16      STMAudioSampleType;
 typedef SInt32      STMAudioUnitSampleType;
#define kAudioUnitSampleFractionBits 24
#endif

#pragma mark - 3rd Party Utilties
#import "AEFloatConverter.h"
#import "TPCircularBuffer.h"

#pragma mark - Core Components
#import "EZAudioFile.h"
#import "KZConverter.h"

@interface EZAudio : NSObject

+ (AudioBufferList *)audioBufferListWithNumberOfFrames:(UInt32)frames numberOfChannels:(UInt32)channels interleaved:(BOOL)interleaved;
+ (void)freeBufferList:(AudioBufferList *)bufferList;

+ (AudioStreamBasicDescription)M4AFormatWithNumberOfChannels:(UInt32)channels sampleRate:(float)sampleRate;
+ (AudioStreamBasicDescription)monoFloatFormatWithSampleRate:(float)sampleRate;
+ (AudioStreamBasicDescription)monoCanonicalFormatWithSampleRate:(float)sampleRate;
+ (AudioStreamBasicDescription)stereoCanonicalNonInterleavedFormatWithSampleRate:(float)sampleRate;

+ (AudioStreamBasicDescription)stereoFloatInterleavedFormatWithSampleRate:(float)sampleRate;
+ (AudioStreamBasicDescription)stereoFloatNonInterleavedFormatWithSampleRate:(float)sameRate;
+ (void)printASBD:(AudioStreamBasicDescription)asbd;
/**
 Maps a value from one coordinate system into another one. Takes in the current value to map, the minimum and maximum values of the first coordinate system, and the minimum and maximum values of the second coordinate system and calculates the mapped value in the second coordinate system's constraints.
 @param 	value 	The value expressed in the first coordinate system
 @param 	leftMin 	The minimum of the first coordinate system
 @param 	leftMax 	The maximum of the first coordinate system
 @param 	rightMin 	The minimum of the second coordindate system
 @param 	rightMax 	The maximum of the second coordinate system
 @return	The mapped value in terms of the second coordinate system
 */
+ (float)MAP:(float)value
    leftMin:(float)leftMin
    leftMax:(float)leftMax
   rightMin:(float)rightMin
   rightMax:(float)rightMax;

/**
 Calculates the root mean squared for a buffer.
 @param 	buffer 	A float buffer array of values whose root mean squared to calculate
 @param 	bufferSize 	The size of the float buffer
 @return	The root mean squared of the buffer
 */
+ (float)RMS:(float*)buffer
     length:(int)bufferSize;

/**
 Calculate the sign function sgn(x) =
 {  -1 , x < 0,
 {   0 , x = 0,
 {   1 , x > 0
 @param value The float value for which to use as x
 @return The float sign value
 */
+ (float)SGN:(float)value;

#pragma mark - OSStatus Utility
///-----------------------------------------------------------
/// @name OSStatus Utility
///-----------------------------------------------------------

/**
 Basic check result function useful for checking each step of the audio setup process
 @param result    The OSStatus representing the result of an operation
 @param operation A string (const char, not NSString) describing the operation taking place (will print if fails)
 */
+ (void)checkResult:(OSStatus)result
         operation:(const char*)operation;


@end
