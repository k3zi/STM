//
//  YBReverb.h
//  Stream To Me
//
//  Created by Kesi Maduka on 5/10/15.
//  Copyright (c) 2015 Storm Edge Apps LLC. All rights reserved.
//

#import "YBAudioUnitNode.h"

@interface YBReverb : YBAudioUnitNode

- (void)setDryWet:(float)val;
- (void)setDecay:(float)val;

@end
