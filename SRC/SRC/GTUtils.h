//
//  GTUtils.h
//  SRC
//
//  Created by TianYuan on 2019/9/22.
//  Copyright © 2019 TianYuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "ORSSerialPort.h"

NS_ASSUME_NONNULL_BEGIN

@interface GTUtils : NSObject

- (void)setFileName:(NSString *)fileName andTextView:(NSTextView *)textView window:(NSWindow *)window;

- (NSString *)getDateTime;
- (NSString *)get2DateTime;

@end

NS_ASSUME_NONNULL_END
