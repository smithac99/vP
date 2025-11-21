//
//  SubtitleCue.h
//  vP
//
//  Created by Alan Smith on 20/11/2025.
//  Copyright © 2025 Alan C Smith. All rights reserved.
//

#import <Foundation/Foundation.h>
@import AVKit;

NS_ASSUME_NONNULL_BEGIN

@interface SubtitleCue : NSObject
@property (assign) CMTime start;
@property (assign) CMTime end;
@property (copy) NSString *text;

+ (NSArray<SubtitleCue *> *)parseSRTAtURL:(NSURL *)url;

@end

CMTime timeFromSRTTimeString(NSString *s);

NS_ASSUME_NONNULL_END
