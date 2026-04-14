//
//  VPContentView.m
//  vP
//
//  Created by alan on 20/03/22.
//  Copyright © 2022 Alan C Smith. All rights reserved.
//

#import "VPContentView.h"

@interface VPContentView ()
@property (nonatomic, strong) NSTimer *cursorTimer;
@property (nonatomic, assign) BOOL cursorHidden;
@end

@implementation VPContentView

- (void)resetCursorTimer
{
    [self.cursorTimer invalidate];
    
    if (self.cursorHidden)
    {
        [NSCursor unhide];
        self.cursorHidden = NO;
    }

    self.cursorTimer = [NSTimer scheduledTimerWithTimeInterval:8.0
                                                        target:self
                                                      selector:@selector(hideCursor)
                                                     userInfo:nil
                                                      repeats:NO];
}

- (void)hideCursor
{
    [NSCursor hide];
    self.cursorHidden = YES;
}

-(void)mouseMoved
{
    [self resetCursorTimer];
}

- (void)mouseMoved:(NSEvent *)event
{
    //NSPoint coord = [self convertPoint:[event locationInWindow] fromView:nil];
    //NSLog(@"view %g %g",coord.x,coord.y);
    [self mouseMoved];
}

- (void)playbackDidStart
{
    [self resetCursorTimer];
}

- (void)playbackDidStop
{
    [self.cursorTimer invalidate];
    self.cursorTimer = nil;
    if (self.cursorHidden) {
        [NSCursor unhide];
        self.cursorHidden = NO;
    }
}
@end
