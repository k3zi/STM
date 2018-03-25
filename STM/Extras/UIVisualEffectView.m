//
//  UIVisualEffectView.m
//  STM
//
//  Created by KZ on 2018/03/24.
//  Copyright © 2018年 Storm Edge Apps LLC. All rights reserved.
//

#import "STM-Swift.h"

@implementation UIVisualEffectView (private)
    + (void)initialize {
        [self swizzle_setBounds];
    }
@end
