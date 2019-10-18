//
//  ViewController.h
//  SRC
//
//  Created by TianYuan on 2019/9/18.
//  Copyright © 2019 TianYuan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ORSSerialPort.h"
#import "GTUtils.h"
#import <AppKit/AppKit.h>

@class ORSSerialPortManager ;

@interface ViewController : NSViewController <ORSSerialPortDelegate, NSUserNotificationCenterDelegate,NSTextViewDelegate>

@property (weak) IBOutlet NSButton *OpenOrClose;

@property (weak) IBOutlet NSTextField *StatusText;

@property (weak) IBOutlet NSTextField *RXCounter;
@property (nonatomic, assign) long RXNumber;

@property (weak) IBOutlet NSTextField *TXCounter;
@property (nonatomic, assign) long TXNumber;

@property (unsafe_unretained) IBOutlet NSTextView *RXDataDisplayTextView;

@property (unsafe_unretained) IBOutlet NSTextView *TXDataDisplayTextView;

@property (weak) IBOutlet NSTextField *TimeInternel;
@property (weak) IBOutlet NSButton *SendButton;

@property (nonatomic, assign) BOOL isRXHexString;

@property (nonatomic, assign) BOOL isTXHexString;

@property (nonatomic, assign) BOOL isRXGBKString;
@property (nonatomic, assign) BOOL isTXGBKString;

@property (nonatomic, strong) ORSSerialPortManager *serialPortManager;
@property (nonatomic, strong) ORSSerialPort *serialPort;
@property (nonatomic, strong) NSArray *availableBaudRates;
@property (nonatomic, strong) NSMutableArray *serialPortMArr;

@property (nonatomic, assign) BOOL isLoopSend;
@property (nonatomic, assign) BOOL isWorkInSend;
@property (nonatomic, assign) BOOL isOnlyDisplayRxData;
@property (assign,nonatomic) int sendCount;
@property (assign,nonatomic) NSTimer *timer;

@property (nonatomic, strong) GTUtils *utils;

@property (nonatomic, assign) BOOL timerFlag;

@property (nonatomic, strong) NSStatusItem *statusItem;

@end

