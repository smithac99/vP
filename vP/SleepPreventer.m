//
//  SleepPreventer.m
//  vP
//
//  Created by Alan Smith on 31/08/2025.
//  Copyright © 2025 Alan C Smith. All rights reserved.
//

#import "SleepPreventer.h"

#import <IOKit/pwr_mgt/IOPMLib.h>

@interface SleepPreventer ()
@property (nonatomic, assign) IOPMAssertionID assertionID;
@property (nonatomic, assign) BOOL active;
@end

@implementation SleepPreventer

- (instancetype)init
{
    if ((self = [super init]))
    {
        _assertionID = kIOPMNullAssertionID;
        _active = NO;
    }
    return self;
}

- (void)beginPreventingSleep
{
    if (self.active)
        return;

    IOPMAssertionID assertionID = kIOPMNullAssertionID;
    IOReturn result = IOPMAssertionCreateWithName(
        kIOPMAssertionTypePreventUserIdleDisplaySleep,
        kIOPMAssertionLevelOn,
        CFSTR("Video playback"),
        &assertionID
    );

    if (result == kIOReturnSuccess)
    {
        self.assertionID = assertionID;
        self.active = YES;
    }
    else
    {
        NSLog(@"SleepPreventer: failed to create assertion (%d)", result);
    }
}

- (void)endPreventingSleep
{
    if (!self.active)
        return;

    IOReturn result = IOPMAssertionRelease(self.assertionID);
    if (result != kIOReturnSuccess)
    {
        NSLog(@"SleepPreventer: failed to release assertion (%d)", result);
    }
    self.assertionID = kIOPMNullAssertionID;
    self.active = NO;
}

- (void)dealloc
{
    [self endPreventingSleep];
}

@end
