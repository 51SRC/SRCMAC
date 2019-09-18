//
//  NSMyWindowController.m
//  SRC
//
//  Created by TianYuan on 2019/9/18.
//  Copyright © 2019 TianYuan. All rights reserved.
//

#import "NSMyWindowController.h"

@interface NSMyWindowController () <NSWindowDelegate>


@end

@implementation NSMyWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
    [self.myWindow setDelegate:self];
}

- (BOOL)windowShouldClose:(id)sender //close box quits the app
{
    [NSApp terminate:self];
    return YES;
}



@end
