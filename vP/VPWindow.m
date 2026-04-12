//
//  VPWindow.m
//  vP
//
//  Created by alan on 20/03/22.
//  Copyright © 2022 Alan C Smith. All rights reserved.
//

#import "VPWindow.h"

@implementation VPWindow

-(void)mouseMoved:(NSEvent *)event
{
    NSPoint coord = [event locationInWindow];
    NSLog(@"window %g %g",coord.x,coord.y);
    [_playView mouseMoved];
	[super mouseMoved:event];
	
}
@end
