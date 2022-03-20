//
//  ControlsView.m
//  vP
//
//  Created by alan on 20/03/22.
//  Copyright © 2022 Alan C Smith. All rights reserved.
//

#import "ControlsView.h"

@interface ControlsView()
{
	NSTrackingRectTag trackingTag;
}
@end

@implementation ControlsView

-(void)viewDidMoveToWindow
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundsChanged:)
		name:NSViewFrameDidChangeNotification object:self];
	[self setPostsFrameChangedNotifications:YES];
	[[self window]setAcceptsMouseMovedEvents:YES];
	[self resetSizes];
}

-(void)resetSizes
{
	if (trackingTag != 0)
		[self removeTrackingRect:trackingTag];
	
	trackingTag = [self addTrackingRect:[self bounds] owner:self userData:NULL assumeInside:NO];
}

-(void)boundsChanged:(NSNotification*)notif
{
	[self resetSizes];
}

-(void)show:(BOOL)sh
{
	self.alphaValue = sh?1:0;
}

-(void)flash
{
	if (self.alphaValue == 0.0)
	{
		[self show:YES];
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[self show:NO];
		});
	}
}

-(void)mouseExited:(NSEvent *)event
{
	[self show:NO];
}

-(void)mouseEntered:(NSEvent *)event
{
	[self show:YES];
}

CGFloat clamp01(CGFloat f)
{
	if (f > 0)
	{
		if (f < 1)
			return f;
		return 1;
	}
	return 0;
}

-(void)mouseMoved:(NSEvent *)event
{
	if (self.mouseMoveBlock)
	{
		NSPoint coord = [self convertPoint:[event locationInWindow] fromView:nil];
		CGFloat frac = clamp01(coord.x / self.bounds.size.width);
		self.mouseMoveBlock(frac);
	}
}
@end
