//
//  ControlsView.h
//  vP
//
//  Created by alan on 20/03/22.
//  Copyright © 2022 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Document.h"

NS_ASSUME_NONNULL_BEGIN

@interface ControlsView : NSView

@property void (^mouseMoveBlock)(CGPoint);
@property  (weak) IBOutlet Document *document;
-(void)show:(BOOL)sh;
-(void)flash;
@end

NS_ASSUME_NONNULL_END
