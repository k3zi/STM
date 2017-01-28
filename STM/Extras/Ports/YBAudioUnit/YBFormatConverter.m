//
//  YBMultiChannelMixer.m
//  YBAudioUnit
//
//  Created by Martijn Thé on 3/22/12.
//  Copyright (c) 2012 Yobble. All rights reserved.
//

#import "YBFormatConverter.h"
#import "YBAudioException.h"

@implementation YBFormatConverter

- (instancetype)initWithAUNode:(AUNode)auNode audioUnit:(AudioUnit)auAudioUnit inGraph:(YBAudioUnitGraph *)graph{
    self = [super initWithAUNode:auNode audioUnit:auAudioUnit inGraph:graph];
    return self;
}

@end
