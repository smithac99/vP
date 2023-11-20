//
//  VPContentView.m
//  vP
//
//  Created by alan on 20/03/22.
//  Copyright © 2022 Alan C Smith. All rights reserved.
//

#import "VPContentView.h"

@implementation VPContentView

-(void)mouseMoved:(NSEvent *)event
{
	NSPoint coord = [self convertPoint:[event locationInWindow] fromView:nil];
	NSLog(@"%g %g",coord.x,coord.y);
}

@end
