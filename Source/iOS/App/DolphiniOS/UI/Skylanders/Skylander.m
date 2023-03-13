// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <Foundation/Foundation.h>

#import "Skylander.h"

@implementation Skylander

- (id) init
{
    return [self initWithValues:0 andId:0 andVar:0];
}

- (id) initWithValues: (int) inPortalSlot andId: (int) inSkyId andVar: (int) inSkyVar
{
    self = [super init];
    if(self) {
        _portalSlot = inPortalSlot;
        _skyId = inSkyId;
        _skyVar = inSkyVar;
    }
    return self;
}

@end
