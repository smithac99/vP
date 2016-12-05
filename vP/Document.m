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

@interface Document ()
{
	float whRatio,wExtra,hExtra;
}
@property (weak) IBOutlet AVPlayerView *playerView;
@property AVPlayer *player;
@property NSArray *chapterMetadataGroups;
@property NSURL *exportDirectory;

@end

@implementation Document


- (void)windowControllerDidLoadNib:(NSWindowController *)windowController
{
	[super windowControllerDidLoadNib:windowController];
	
	// Associate AVPlayer with AVPlayerView once the NIB is loaded
	self.playerView.player = _player;
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

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	_player = [AVPlayer playerWithURL:absoluteURL];
	
	[self.player.currentItem.asset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
        [self setWindowToNaturalSize];
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
}

- (IBAction)jumpForward:(id)sender
{
	CMTime ct = [self.player currentTime];
	ct = CMTimeMakeWithSeconds(CMTimeGetSeconds(ct) + 20, ct.timescale);
	[self.player seekToTime:ct];
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
@end
