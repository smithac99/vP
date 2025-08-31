//
//  SleepPreventer.h
//  vP
//
//  Created by Alan Smith on 31/08/2025.
//  Copyright © 2025 Alan C Smith. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SleepPreventer : NSObject

/// Start preventing the display from sleeping / screensaver from starting.
- (void)beginPreventingSleep;

/// Stop preventing, restoring normal system behavior.
- (void)endPreventingSleep;


@end

NS_ASSUME_NONNULL_END
