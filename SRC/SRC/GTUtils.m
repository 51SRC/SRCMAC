//
//  GTUtils.m
//  SRC
//
//  Created by TianYuan on 2019/9/22.
//  Copyright © 2019 TianYuan. All rights reserved.
//

#import "GTUtils.h"

@interface GTUtils ()

@property (nonatomic,strong) NSSavePanel*  panel;


@end

@implementation GTUtils

- (void)setFileName:(NSString *)fileName andTextView:(NSTextView *)textView window:(NSWindow *)window{

    self.panel = [NSSavePanel savePanel];
    [self.panel setMessage:@"选择存储路径"];
    [self.panel setAllowsOtherFileTypes:YES];
    [self.panel setAllowedFileTypes:@[@"txt"]];
    [self.panel setExtensionHidden:YES];
    [self.panel setCanCreateDirectories:YES];
    
    
    
    [self.panel setNameFieldStringValue: fileName];
    
    [self.panel beginSheetModalForWindow: window completionHandler:^(NSModalResponse result) {
        if (result == NSFileHandlingPanelOKButton)
        {
            NSString *path = [[self.panel URL] path];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [textView.textStorage.mutableString writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
            });
        }
    }];
    
    
}



- (NSString *)getDateTime
{
    char dateTime[15];
    time_t t;
    struct tm tm;
    t = time( NULL );
    memcpy(&tm, localtime(&t), sizeof(struct tm));
    sprintf(dateTime, "%04d%02d%02d%02d%02d%02d",
            tm.tm_year+1900, tm.tm_mon+1, tm.tm_mday,
            tm.tm_hour, tm.tm_min,tm.tm_sec);
    return [[NSString alloc] initWithCString:dateTime encoding:NSASCIIStringEncoding];
}

- (NSString *)get2DateTime
{
    //    char dateTime[15];
    //    time_t t;
    //    struct tm tm;
    //    t = time( NULL );
    //    memcpy(&tm, localtime(&t), sizeof(struct tm));
    //    sprintf(dateTime, "%02d:%02d:%02d",
    //            tm.tm_hour, tm.tm_min,tm.tm_sec);
    //    return [[NSString alloc] initWithCString:dateTime encoding:NSASCIIStringEncoding];
    
    NSString* date;
    NSDateFormatter * formatter = [[NSDateFormatter alloc ] init];
    //[formatter setDateFormat:@"YYYY.MM.dd.hh.mm.ss"];
    [formatter setDateFormat:@"hh:mm:ss.SSS"];
    date = [formatter stringFromDate:[NSDate date]];
    NSString * timeNow = [[NSString alloc] initWithFormat:@"%@", date];
    return timeNow;
}

@end
