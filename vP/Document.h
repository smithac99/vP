//
//  Document.h
//  vP
//
//  Created by alan on 24/10/15.
//  Copyright © 2015 Alan C Smith. All rights reserved.
//

@import Cocoa;
@import AVFoundation;

@class ImageExportController;

@interface Document : NSDocument

@property IBOutlet ImageExportController *imageExportController;
@property NSMutableDictionary *exportImageSettings;

-(void)showPreviewWindow:(BOOL)sh;

@end

