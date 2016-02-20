//
//  YBNewTimePitch.h
//  Stream To Me
//
//  Created by Kesi Maduka on 5/10/15.
//  Copyright (c) 2015 Storm Edge Apps LLC. All rights reserved.
//

#import "YBAudioUnitNode.h"

@interface YBNewTimePitch : YBAudioUnitNode

- (void)setRate:(float)rate;
- (void)setPitch:(float)pitch;

@end
