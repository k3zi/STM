//
//  Ports.h
//  STM
//
//  Created by Kesi Maduka on 1/30/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "EZAudio.h"

@protocol KZConverterDelegate <NSObject>

- (void)receiveConvertedData:(NSData *)data;

@end

@interface KZConverter : NSObject

@property id<KZConverterDelegate> delegate;

- (void)pipeData:(AudioBufferList *)audioBufferList format:(AudioStreamBasicDescription)format;

@end

AudioBufferList * AllocateABLX(UInt32 channelsPerFrame, UInt32 bytesPerFrame, bool interleaved, UInt32 capacityFrames);
