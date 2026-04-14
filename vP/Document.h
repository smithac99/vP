//
//  Document.h
//  vP
//
//  Created by alan on 24/10/15.
//  Copyright © 2015 Alan C Smith. All rights reserved.
//

@import Cocoa;
@import AVFoundation;
@import AVKit;

@class ImageExportController;

@interface Subtitle : NSObject

@property NSString *lang,*desc;
@property AVMediaSelectionOption *option;

@end

@interface Document : NSDocument<AVRoutePickerViewDelegate>

@property IBOutlet ImageExportController *imageExportController;
@property NSMutableDictionary *exportImageSettings;
@property (weak) IBOutlet NSView *pickerHome;
@property AVRoutePickerView *routePickerView;
@property NSArray<Subtitle*>* subtitleLanguageList;
@property AVMediaSelectionGroup *subtitleGroup;
-(void)showPreviewWindow:(BOOL)sh;

@end

