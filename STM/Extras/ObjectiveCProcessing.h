//
//  ObjectiveC Processing.h
//  STM
//
//  Created by Kesi Maduka on 3/2/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ObjectiveCProcessing : NSObject

+ (void)proccessVisualizerBufferData:(void *)bytes audioLevel:(float)level frames:(UInt32)frames bytesPerFrame:(UInt32)bytesPerFrame channelsPerFrame:(UInt32)channelsPerFrame size:(CGSize)size update:(void (^)(int barIndex, CGFloat height))updateBlock;

+ (void)processVisualizerData:(NSData *)data audioLevel:(float)level frames:(UInt32)frames bytesPerFrame:(UInt32)bytesPerFrame channelsPerFrame:(UInt32)channelsPerFrame size:(CGSize)size update:(void (^)(int barIndex, CGFloat height))updateBlock;

@end
