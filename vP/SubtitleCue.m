//
//  SubtitleCue.m
//  vP
//
//  Created by Alan Smith on 20/11/2025.
//  Copyright © 2025 Alan C Smith. All rights reserved.
//

#import "SubtitleCue.h"

CMTime timeFromSRTTimeString(NSString *s)
{
    // Format: hh:mm:ss,SSS
    NSArray<NSString *> *parts = [s componentsSeparatedByString:@","];
    if (parts.count != 2)
    {
        return kCMTimeZero;
    }

    NSString *hms = parts[0];
    NSString *msString = parts[1];

    NSArray<NSString *> *hmsParts = [hms componentsSeparatedByString:@":"];
    if (hmsParts.count != 3)
    {
        return kCMTimeZero;
    }

    NSInteger hours   = [hmsParts[0] integerValue];
    NSInteger minutes = [hmsParts[1] integerValue];
    NSInteger seconds = [hmsParts[2] integerValue];
    NSInteger millis  = [msString integerValue];

    int64_t totalMillis = (hours * 3600 + minutes * 60 + seconds) * 1000 + millis;
    CMTime t = CMTimeMake(totalMillis, 1000); // timescale 1000 = ms

    return t;
}

@implementation SubtitleCue

+ (NSArray<SubtitleCue *> *)parseSRTAtURL:(NSURL *)url
{
    NSError *error = nil;
    NSString *contents = [NSString stringWithContentsOfURL:url
                                                  encoding:NSUTF8StringEncoding
                                                     error:&error];
    if (!contents)
    {
        NSLog(@"Failed to read SRT: %@", error);
        return @[];
    }

    NSMutableArray *result = [NSMutableArray array];

    // Split on blank lines
    NSArray<NSString *> *blocks = [contents componentsSeparatedByString:@"\n\n"];

    for (NSString *block in blocks)
    {
        // Normalize line endings
        NSString *normalized = [block stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        NSArray<NSString *> *lines = [normalized componentsSeparatedByString:@"\n"];
        if (lines.count < 2)
        {
            continue;
        }

        // lines[0] is the index, usually; we can ignore it
        if (lines.count < 2)
        {
            continue;
        }

        NSString *timeLine = lines[1];
        NSArray<NSString *> *parts = [timeLine componentsSeparatedByString:@" --> "];
        if (parts.count != 2)
        {
            continue;
        }

        CMTime start = timeFromSRTTimeString(parts[0]);
        CMTime end   = timeFromSRTTimeString(parts[1]);

        // Remaining lines = text (may be multiple lines)
        NSMutableArray *textLines = [NSMutableArray array];
        for (NSUInteger i = 2; i < lines.count; i++)
        {
            [textLines addObject:lines[i]];
        }
        NSString *text = [textLines componentsJoinedByString:@"\n"];

        SubtitleCue *cue = [SubtitleCue new];
        cue.start = start;
        cue.end = end;
        cue.text = text;

        [result addObject:cue];
    }

    return result;
}
@end

