//
//  Document.m
//  vP
//
//  Created by alan on 24/10/15.
//  Copyright © 2015 Alan C Smith. All rights reserved.
//

#import "Document.h"
@import AVKit;

#import "ImageExportController.h"
#import "ControlsView.h"

@interface Document ()
{
	float whRatio,wExtra,hExtra;
}
@property (weak) IBOutlet NSSlider *timeSlider;
@property (strong) IBOutlet NSWindow *mainWindow;
@property (strong) IBOutlet ControlsView *controlsView;
@property (weak) IBOutlet NSTextField *playSecs;
@property (weak) IBOutlet NSTextField *secsLeft;
@property (strong) IBOutlet NSPanel *previewWindow;
@property (weak) IBOutlet NSImageView *preView;
@property AVPlayer *player;
@property (weak) IBOutlet NSView *playerView;

@property AVPlayerLayer *playerLayer;
@property NSArray *chapterMetadataGroups;
@property NSURL *exportDirectory;
@property NSArray *thumbnails;

@end

@implementation Document

-(void)dealloc
{
	[_previewWindow orderOut:self];
}

-(void)setUpControlsView
{
	NSView *sup = [self.mainWindow contentView];
	self.controlsView.autoresizingMask = NSViewWidthSizable;
	[sup addSubview:self.controlsView];
	CGRect frame = [self.controlsView frame];
	CGRect superBounds = [sup bounds];
	frame.origin.y = 0;
	frame.origin.x = 0;
	frame.size.width = superBounds.size.width;
	[self.controlsView setFrame:frame];
	[[self.controlsView layer]setBackgroundColor:[[NSColor colorWithWhite:0 alpha:0.5]CGColor]];
}

- (IBAction)sliderHit:(id)sender
{
	float rt = self.player.rate;
	self.player.rate = 0;
	CGFloat val = [sender doubleValue];
	CGFloat secs = val * CMTimeGetSeconds(self.player.currentItem.duration);
	[self.player seekToTime:CMTimeMakeWithSeconds(secs, 600)];
	self.player.rate = rt;
}

- (IBAction)playHit:(id)sender
{
	if (self.player.rate == 0.0)
		[self.player play];
	else
		self.player.rate = 0.0;
}
NSString* secsToHms(CGFloat secs)
{
	NSString *sgn = secs < 0?@"-":@"";
	secs = fabs(secs);
	int intsecs = secs;
	int mm = intsecs / 60;
	int ss = intsecs % 60;
	int hh = mm / 60;
	mm = mm % 60;
	return [NSString stringWithFormat:@"%@%01d:%02d:%02d",sgn,hh,mm,ss];
}

NSString* secsToHmst(CGFloat secs)
{
	NSString *sgn = secs < 0?@"-":@"";
	secs = fabs(secs);
	int intsecs = secs;
	int mm = intsecs / 60;
	int ss = intsecs % 60;
	int hh = mm / 60;
	mm = mm % 60;
	CGFloat frac = secs - intsecs;
	int t = frac * 1000;
	return [NSString stringWithFormat:@"%@%01d:%02d:%02d.%003d",sgn,hh,mm,ss,t];
}


-(void)updateTimes:(CGFloat)secs
{
	CGFloat duration = CMTimeGetSeconds(self.player.currentItem.duration);
	[self.playSecs setStringValue:secsToHmst(secs)];
	[self.secsLeft setStringValue:secsToHmst(secs-duration)];
	[self.timeSlider setFloatValue:secs/duration];
}

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController
{
	[super windowControllerDidLoadNib:windowController];
	
	self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
	self.playerLayer.autoresizingMask = kCALayerWidthSizable|kCALayerHeightSizable;
	self.mainWindow.contentView.wantsLayer = YES;
	[self.playerLayer setFrame:self.mainWindow.contentView.bounds];
	[self.mainWindow.contentView.layer addSublayer:self.playerLayer];
	[self setUpControlsView];
	[self.previewWindow setLevel:NSFloatingWindowLevel];
	__weak Document *weakself = self;
	[self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(0.1, 600) queue:NULL usingBlock:^(CMTime time) {
		CGFloat secs = CMTimeGetSeconds(time);
		[weakself updateTimes:secs];
	}];
	self.controlsView.mouseMoveBlock = ^(CGPoint windowLoc){
		NSPoint coord = [weakself.timeSlider convertPoint:windowLoc fromView:nil];
		[weakself showPreviewForFraction:coord.x / [weakself.timeSlider frame].size.width];
		coord = [weakself.timeSlider convertPoint:coord toView:self.controlsView];
		coord.y = [weakself.controlsView bounds].size.height;
		coord = [weakself.controlsView convertPoint:coord toView:nil];
		coord = [weakself.mainWindow convertPointToScreen:coord];
		coord.x -= [self.previewWindow frame].size.width / 2;
		[weakself.previewWindow setFrameOrigin:coord];
	};
	[self.previewWindow setBackgroundColor:[NSColor clearColor]];
	[self.previewWindow setOpaque:0.0];
	[self updateTimes:0];
}

-(void)updateSizes
{
	NSSize contentSize = [self naturalSize];
	if (contentSize.width == 0.0)
	{
		[self performSelector:@selector(updateSizes) withObject:nil afterDelay:0.2];
		return;
	}
	NSSize winSz = [[self.playerView window]frame].size;
	NSSize viewSz = [self.playerView frame].size;
	whRatio = contentSize.width / contentSize.height;
	wExtra = winSz.width - viewSz.width;
	hExtra = winSz.height - viewSz.height;
}

-(void)setWindowToNaturalSize
{
    if ([self.playerView window])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateSizes];
            [[self.playerView window] setContentSize:[self naturalSize]];
        });
    }
    else
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self setWindowToNaturalSize];
        });
    }
}

-(void)loadThumbnails:(AVAsset*)asset
{
	NSMutableArray *thumbs = [NSMutableArray array];
	self.thumbnails = thumbs;
	AVAssetImageGenerator *igen = [[AVAssetImageGenerator alloc]initWithAsset:asset];
	igen.maximumSize = CGSizeMake(256, 256);
	CMTime cmduration = asset.duration;
	double durationsecs = CMTimeGetSeconds(cmduration);
	NSInteger numFrames = 120;
	NSMutableArray *times = [NSMutableArray array];
	for (NSInteger i = 0;i < numFrames;i++)
	{
		double secs = durationsecs / numFrames * i;
		CMTime cm = CMTimeMakeWithSeconds(secs, cmduration.timescale);
		[times addObject:[NSValue valueWithCMTime:cm]];
	}
	[igen generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
		if (result == AVAssetImageGeneratorSucceeded)
		{
			NSInteger w = CGImageGetWidth(image);
			NSInteger h = CGImageGetHeight(image);
			NSImage *im = [[NSImage alloc]initWithCGImage:image size:CGSizeMake(w, h)];
			[thumbs addObject:im];
			dispatch_async(dispatch_get_main_queue(), ^{
				[self.preView setImage:im];
			});
		}
		else
		{
			NSLog(@"%@",error.localizedDescription);
		}
	}];
}

NSInteger clampint(NSInteger from,NSInteger to,NSInteger val)
{
	if (val <= from)
		return from;
	if (val >= to)
		return to;
	return val;
}

-(void)showPreviewForFraction:(CGFloat)frac
{
	if ([_thumbnails count] > 0)
	{
		NSInteger idx = clampint(0, [_thumbnails count] - 1,round(frac * [_thumbnails count]));
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.preView setImage:_thumbnails[idx]];
		});
	}
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	_player = [AVPlayer playerWithURL:absoluteURL];
	
	[self.player.currentItem.asset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self setWindowToNaturalSize];
			[self loadThumbnails:self.player.currentItem.asset];
		});
	}];
	// Load chapters to be used by the next/previous chapter menu items
	[_player.currentItem.asset loadValuesAsynchronouslyForKeys:@[@"availableChapterLocales"] completionHandler:^{
		self.chapterMetadataGroups = [_player.currentItem.asset chapterMetadataGroupsBestMatchingPreferredLanguages:[NSLocale preferredLanguages]];
	}];
	
	return YES;
}

- (NSString *)windowNibName {
	return @"Document";
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
	// Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
	// You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
	// If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
	[NSException raise:@"UnimplementedMethod" format:@"%@ is unimplemented", NSStringFromSelector(_cmd)];
	return YES;
}

#pragma mark -

-(NSSize)naturalSize
{
	AVPlayerItem *item = self.player.currentItem;
	AVAsset *asset = item.asset;
	NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
	CGFloat w = 0,h = 0;
	for (AVAssetTrack *track in tracks)
	{
		NSSize sz = track.naturalSize;
		if (sz.width > w)
			w = sz.width;
		if (sz.height > h)
			h = sz.height;
	}
	return NSMakeSize(w,h);
}

#pragma mark -

- (IBAction)doFaster:(id)sender
{
	float rate = [self.player rate];
	if (rate == 0.0)
		rate = 1.0;
	else
		rate = rate * 2.0;
	[self.player setRate:rate];
}

- (IBAction)doSlower:(id)sender
{
	float rate = [self.player rate];
	if (rate == 0.0)
		rate = 1.0;
	else
		rate = rate / 2.0;
	[self.player setRate:rate];
}

- (IBAction)doReverse:(id)sender
{
	float rate = [self.player rate];
	rate = rate * -1;
	[self.player setRate:rate];
}

- (IBAction)jumpBack:(id)sender
{
	CMTime ct = [self.player currentTime];
	ct = CMTimeMakeWithSeconds(CMTimeGetSeconds(ct) - 10, ct.timescale);
	[self.player seekToTime:ct];
	[self.controlsView flash];
}

- (IBAction)jumpBackLittle:(id)sender
{
	CMTime ct = [self.player currentTime];
	ct = CMTimeMakeWithSeconds(CMTimeGetSeconds(ct) - 5, ct.timescale);
	[self.player seekToTime:ct];
	[self.controlsView flash];
}

- (IBAction)jumpForward:(id)sender
{
	CMTime ct = [self.player currentTime];
	ct = CMTimeMakeWithSeconds(CMTimeGetSeconds(ct) + 20, ct.timescale);
	[self.player seekToTime:ct];
	[self.controlsView flash];
}

- (IBAction)jumpForwardLittle:(id)sender
{
	CMTime ct = [self.player currentTime];
	ct = CMTimeMakeWithSeconds(CMTimeGetSeconds(ct) + 4, ct.timescale);
	[self.player seekToTime:ct];
	[self.controlsView flash];
}

- (void)windowDidResize:(NSNotification *)notification
{
	if ([[self.playerView window] resizeFlags] & NSCommandKeyMask)
	{
		NSSize viewSz = [self.playerView frame].size;
		whRatio = viewSz.width / viewSz.height;
	}
}

- (NSSize)windowWillResize:(NSWindow *)window toSize:(NSSize)proposedFrameSize
{
	if ([window resizeFlags] & NSCommandKeyMask)
		return proposedFrameSize;
	float newRatio  = (proposedFrameSize.width - wExtra) / (proposedFrameSize.height - hExtra);
	if (newRatio > whRatio)
		proposedFrameSize.width = ((proposedFrameSize.height - hExtra) * whRatio) + wExtra;
	else
		proposedFrameSize.height = ((proposedFrameSize.width - wExtra) / whRatio) + hExtra;
	return proposedFrameSize;
}

#pragma mark -

-(NSImage*)imageAtCurrentTime
{
    CMTime ct = [self.player currentTime];
    AVAssetImageGenerator *imageGenerator =
    [AVAssetImageGenerator assetImageGeneratorWithAsset:self.player.currentItem.asset];
    imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
    NSError *error = nil;
    CMTime usedTime;
    CGImageRef imr = [imageGenerator copyCGImageAtTime:ct actualTime:&usedTime error:&error];
    NSImage *im = [[NSImage alloc]initWithCGImage:imr size:NSZeroSize];
    CGImageRelease(imr);
    return im;
}
-(void)copy:(id)sender
{
    [[NSPasteboard generalPasteboard]clearContents];
    [[NSPasteboard generalPasteboard]writeObjects:@[[self imageAtCurrentTime]]];
}

- (void)exportImage:(id)menuItem
{
    NSSavePanel *sp;
    NSString *fName = [[self displayName]stringByDeletingPathExtension];
    sp = [NSSavePanel savePanel];
    [sp setNameFieldLabel:@"Export Image:"];
    [sp setNameFieldStringValue:fName];
    if (!self.exportImageSettings)
    {
        self.exportImageSettings = [[NSMutableDictionary alloc]initWithCapacity:5];
        [self.exportImageSettings setObject:[NSNumber numberWithFloat:0.7] forKey:@"compressionQuality"];
    }
    NSSize sz = [self naturalSize];
    [self.exportImageSettings setObject:@(sz.width) forKey:@"imageWidth"];
    [self.exportImageSettings setObject:@(sz.height) forKey:@"imageHeight"];
    [self.imageExportController setControls:self.exportImageSettings];
    [self.imageExportController prepareSavePanel:sp];
    [sp setTitle:@"Export Image"];
    [sp beginSheetModalForWindow:[self.playerView window] completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton)
        {
            int resolution = 72;
            [self.imageExportController updateSettingsFromControls:self.exportImageSettings];
            NSSize sz;
            sz.width = [[self.exportImageSettings objectForKey:@"imageWidth"]floatValue];
            sz.height = [[self.exportImageSettings objectForKey:@"imageHeight"]floatValue];
            float compressionQuality = [[self.exportImageSettings objectForKey:@"compressionQuality"]floatValue];
            [self setExportDirectory:[(NSSavePanel*)sp directoryURL]];
            CGImageRef cgr = [[self imageAtCurrentTime]CGImageForProposedRect:NULL context:nil hints:nil];
            CGImageRetain(cgr);
            CGImageDestinationRef dest = CGImageDestinationCreateWithURL((CFURLRef)[sp URL],(CFStringRef)[self.imageExportController uti],1,nil);
            NSDictionary *props = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:compressionQuality],kCGImageDestinationLossyCompressionQuality,
                                   [NSNumber numberWithInt:resolution],kCGImagePropertyDPIHeight,[NSNumber numberWithInt:resolution],kCGImagePropertyDPIWidth,nil];
            CGImageDestinationAddImage(dest,cgr,(CFDictionaryRef)props);
            CGImageDestinationFinalize(dest);
            CFRelease(dest);
            CGImageRelease(cgr);
        }
    }];
}

-(IBAction)normalSize:(id)sender
{
	[[self.playerView window] setContentSize:[self naturalSize]];
}

-(IBAction)doubleSize:(id)sender
{
	NSSize sz = [self naturalSize];
	sz.width *= 2;
	sz.height *= 2;
	[[self.playerView window] setContentSize:sz];
}

-(IBAction)halfSize:(id)sender
{
	NSSize sz = [self naturalSize];
	sz.width = (int)(sz.width / 2);
	sz.height = (int)(sz.height * 2);
	[[self.playerView window] setContentSize:sz];
}

-(IBAction)centreWindow:(id)sender
{
	[[self.playerView window]center];
}

-(IBAction)makeQuieter:(id)sender
{
	float v = self.player.volume;
	self.player.volume = v * 0.9;
	
}
-(IBAction)makeLouder:(id)sender
{
	float v = self.player.volume;
	if (v == 0)
		self.player.volume = 0.1;
	else
		self.player.volume = v * 1.1;
	
}

-(void)showPreviewWindow:(BOOL)sh
{
	if (sh)
		[self.previewWindow orderFront:self];
	else
		[self.previewWindow orderOut:self];
}

- (IBAction)stepForward:(id)sender
{
	[self.player.currentItem stepByCount:1];
}
- (IBAction)stepBack:(id)sender
{
	[self.player.currentItem stepByCount:-1];
}

- (void)shouldCloseWindowController:(NSWindowController *)windowController delegate:(id)delegate shouldCloseSelector:(SEL)shouldCloseSelector contextInfo:(void *)contextInfo
{
	if (self.player.rate != 0)
		[self.player pause];
	[_previewWindow orderOut:self];
	[super shouldCloseWindowController:windowController delegate:delegate shouldCloseSelector:shouldCloseSelector contextInfo:contextInfo];
}
@end
