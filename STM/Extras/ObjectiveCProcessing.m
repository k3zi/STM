//
//  ObjectiveCProcessing.m
//  STM
//
//  Created by Kesi Maduka on 3/2/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

#import "ObjectiveCProcessing.h"

@implementation ObjectiveCProcessing : NSObject

+ (void)proccessVisualizerBufferData:(void *)bytes audioLevel:(float)level frames:(UInt32)frames bytesPerFrame:(UInt32)bytesPerFrame channelsPerFrame:(UInt32)channelsPerFrame size:(CGSize)size update:(void (^)(int barIndex, CGFloat height))updateBlock {
    @autoreleasepool {
        NSMutableData *data = [NSMutableData dataWithBytes:bytes length:bytesPerFrame*frames];
        [self processVisualizerData:data audioLevel:level frames:frames bytesPerFrame:bytesPerFrame channelsPerFrame:channelsPerFrame size:size update:updateBlock];
        data = nil;
    }
}

+ (void)processVisualizerData:(NSMutableData *)data audioLevel:(float)level frames:(UInt32)frames bytesPerFrame:(UInt32)bytesPerFrame channelsPerFrame:(UInt32)channelsPerFrame size:(CGSize)size update:(void (^)(int barIndex, CGFloat height))updateBlock {
    NSMutableData *fullSongData = [NSMutableData data];
    SInt16 maxValue = 0;
    size_t length = frames;

    @autoreleasepool {
        NSInteger samplesPerPixel = floor((length / bytesPerFrame)/50);
        NSInteger sampleTally = 0;

        SInt16 *samples = (SInt16 *)data.mutableBytes;
        int sampleCount = (int)length / bytesPerFrame;

        for (int i = 0; i < sampleCount; i++) {
            SInt16 left = *samples++;
            SInt16 right = 0;

            if (channelsPerFrame == 2){
                right = *samples++;
            }

            sampleTally++;

            if (sampleTally > samplesPerPixel) {
                left = (left / sampleTally);

                if (channelsPerFrame == 2) {
                    right = (right / sampleTally);
                }

                SInt16 val = right ? ((right + left) / 2) : left;

                [fullSongData appendBytes:&val length:sizeof(val)];

                sampleTally = 0;
            }
        }
    }

    NSMutableData *adjustedSongData = [[NSMutableData alloc] init];

    int sampleCount = (int)fullSongData.length / 2; // sizeof(SInt16)
    int adjustFactor = ceilf((float)sampleCount / (size.width / 2.0));

    SInt16 *samples = (SInt16 *)fullSongData.mutableBytes;

    int i = 0;

    while (i < sampleCount) {
        SInt16 val = 0;

        for (int j = 0; j < adjustFactor; j++) {
            val += samples[i + j];
        }

        val /= adjustFactor;

        if (ABS(val) > maxValue){
            maxValue = ABS(val);
        }

        [adjustedSongData appendBytes:&val length:sizeof(val)];

        i += adjustFactor;
    }

    sampleCount = (int)adjustedSongData.length / 2;

    CGSize imageSize = CGSizeMake(sampleCount * 2, size.height);
    float sampleAdjustmentFactor = imageSize.height / (float)maxValue;

    for (int i = 0; i < sampleCount; i++) {
        float val = *samples++;
        val = fabsf(val * sampleAdjustmentFactor) * level;
        if ((int)val == 0)
            val = 1.0;
        dispatch_async(dispatch_get_main_queue(), ^{
            updateBlock(i, val);
        });
    }
}

@end
