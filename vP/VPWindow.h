//
//  VPWindow.h
//  vP
//
//  Created by alan on 20/03/22.
//  Copyright © 2022 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VPContentView.h"


@interface VPWindow : NSWindow
@property (weak) IBOutlet VPContentView *playView;

@end

