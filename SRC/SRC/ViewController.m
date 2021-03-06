//
//  ViewController.m
//  SRC
//
//  Created by TianYuan on 2019/9/18.
//  Copyright © 2019 TianYuan. All rights reserved.
//

#import "ViewController.h"
#import "ORSSerialPortManager.h"
#import "ORSSerialPort.h"
//#import "ORSSerialPortManager.h"
#import "ORSSerialRequest.h"
#import "ORSSerialPacketDescriptor.h"


#define BaudRatesArray @[@300, @1200, @2400, @4800, @9600, @14400, @19200, @28800, @38400, @57600, @115200, @230400]


@implementation ViewController


- (void)awakeFromNib{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        self.serialPortManager = [ORSSerialPortManager sharedSerialPortManager];
        self.availableBaudRates = BaudRatesArray;
        self.serialPortMArr = [[NSMutableArray alloc]init];
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(serialPortsWereConnected:) name:ORSSerialPortsWereConnectedNotification object:nil];
        [nc addObserver:self selector:@selector(serialPortsWereDisconnected:) name:ORSSerialPortsWereDisconnectedNotification object:nil];
        
#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)
        [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
#endif
        

        self.isLoopSend = NO;
        self.isWorkInSend = NO;
        self.isOnlyDisplayRxData = YES;

        self.utils = [[GTUtils alloc] init];
        
    });
}


-(void)viewDidAppear{
    [super viewDidAppear];
    
    if(self.serialPortManager.availablePorts.count>0){
        self.serialPort=self.serialPortManager.availablePorts[0];
        for (int i=0; i<self.serialPortManager.availablePorts.count; i++) {
            [self.serialPortMArr addObject:self.serialPortManager.availablePorts[i]];
        }
    }
}



- (void)viewDidLoad {
    [super viewDidLoad];

    [self.RXDataDisplayTextView setEditable:NO];
    [self.RXCounter setEditable:NO];
    [self.TXCounter setEditable:NO];
    self.isRXHexString = YES;
    self.isTXHexString = YES;
    self.isRXGBKString = NO;
    self.isTXGBKString = NO;
    self.TXNumber = 0;
    self.RXNumber = 0;
    // Do any additional setup after loading the view.
    self.TXDataDisplayTextView.delegate = self;

    
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    
    [_statusItem setImage:[NSImage imageNamed:@"icon"]];
    [_statusItem setToolTip:@"StatusItem"];
    [_statusItem setHighlightMode:YES];
  
    
}


//设置只显示数据
- (IBAction)setDisplayRxDataOnly:(NSButton *)sender {
    if(sender.intValue==1){
        self.isOnlyDisplayRxData = NO;
    }else{
        self.isOnlyDisplayRxData = YES;
    }
}

//设置循环发送数据
- (IBAction)setSendLoop:(NSButton *)sender {
    if(sender.intValue==1){
        self.isLoopSend = YES;
    }else{
        self.isLoopSend = NO;
    }
    [self stopTimer];
}


- (IBAction)openComPort:(id)sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.serialPort.isOpen ? [self.serialPort close] : [self.serialPort open];
    });
}

//设置接收区采用hexstring还是字符串显示方式
- (IBAction)setDisplayMode:(NSMatrix *)sender {
    if (sender.selectedTag==1) {
        self.isRXHexString = YES;
    }else if(sender.selectedTag==2){
        self.isRXHexString = NO;
        self.isRXGBKString = NO;
    }
}

//设置发送区采用hexstring还是字符串发送
- (IBAction)setDisplayMode_TX:(NSMatrix *)sender {
    
    if (sender.selectedTag==1) {
        self.isTXHexString = YES;
    }else{
        self.isTXHexString = NO;
        _isTXGBKString = NO;
    }
}


//发送数据
- (IBAction)sendData:(NSButton *)sender {
    
    //停止循环发送
    if (self.isWorkInSend) {
        [self stopTimer];
        return;
    }
    
    self.StatusText.stringValue = @"发送数据中...";
    NSString *textStr = self.TXDataDisplayTextView.textStorage.mutableString;
    if(textStr.length==0){
        self.StatusText.stringValue = @"发送数据为空";
        return;
    }
    
    if (_isLoopSend) {
        //获取次数和间隔值
        double timeout = [self.TimeInternel.stringValue doubleValue]/1000.0;
        
        if( timeout <= 0){
            self.StatusText.stringValue = @"请填入循环时间间隔";
            return;
        }
        
        _timer = [NSTimer scheduledTimerWithTimeInterval:timeout target:self selector:@selector(sendDataWithPort) userInfo:nil repeats:YES];
        self.StatusText.stringValue = @"循环发送中...";
        self.SendButton.title = @"发送";
        _isWorkInSend = YES;
        
    }else{
        [self sendDataWithPort];
    }
}

-(void)stopTimer{
    [_timer invalidate];
    _timer = nil;
    if (_isLoopSend) {
        self.SendButton.title = @"发送";
    }else{
        self.SendButton.title = @"发送";
    }
    self.isWorkInSend = NO;
}

-(void)sendDataWithPort{
    
    if (!self.serialPort.isOpen) {
        self.StatusText.stringValue = @"请打开串口";
        return;
    }
    
    NSData *sendData;
    NSString *textStr = self.TXDataDisplayTextView.textStorage.mutableString;
    if (self.isTXHexString) {
        textStr = [textStr stringByReplacingOccurrencesOfString:@"," withString:@""];
        textStr = [textStr stringByReplacingOccurrencesOfString:@" " withString:@""];
        textStr = [textStr stringByReplacingOccurrencesOfString:@"0x" withString:@""];
        textStr = [textStr stringByReplacingOccurrencesOfString:@"\\x" withString:@""];
        if (textStr.length%2!=0) {
            self.StatusText.stringValue = @"发送16进制数据长度错误！";
            return;
        }
        
        NSString* number=@"^[a-f|A-F|0-9]+$";
        NSPredicate *numberPre = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",number];
        if(![numberPre evaluateWithObject:textStr]){
            self.StatusText.stringValue = @"包含非[0-9A-Fa-f]字符！";
            return;
        }
        
        
        self.TXNumber += textStr.length/2;
        sendData = [ORSSerialPortManager twoOneData:textStr];
        if([self.serialPort sendData:sendData]){
            self.StatusText.stringValue = @"发送HEX数据成功";
            self.TXCounter.stringValue = [NSString stringWithFormat:@"%ld Bytes",self.TXNumber];
        }else{
            self.StatusText.stringValue = @"发送HEX数据失败";
            return;
        }
        
        //显示文字为深灰色，大小为14
        NSInteger startPorint = self.RXDataDisplayTextView.textStorage.length;
        
        NSString *sendStr =@"";
        if(self.isOnlyDisplayRxData){
            sendStr = [NSString stringWithFormat:@"%@\n",[ORSSerialPortManager oneTwoData:sendData]];
        }else{
            sendStr = [NSString stringWithFormat:@"%@ %@\n",[self.utils get2DateTime],[ORSSerialPortManager oneTwoData:sendData]];
        }
        
        NSInteger length = sendStr.length;
        [self.RXDataDisplayTextView.textStorage.mutableString appendString:sendStr];
        [self.RXDataDisplayTextView.textStorage addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Andale Mono" size:14] range:NSMakeRange(startPorint, length)];
        [self.RXDataDisplayTextView.textStorage addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:NSMakeRange(startPorint, length)];
        
        [self.RXDataDisplayTextView scrollRangeToVisible:NSMakeRange(self.RXDataDisplayTextView.string.length, 1)];
        return;
    }else{
        
        const char* cstr;
        NSString *tmp;

        cstr = [textStr cStringUsingEncoding:NSUTF8StringEncoding];
        tmp = @"发送UTF8编码数据成功";
        
        if(cstr!=NULL){
            self.TXNumber += strlen(cstr);
            sendData = [NSData dataWithBytes:cstr length:strlen(cstr)];
            if([self.serialPort sendData:sendData]){
                self.TXCounter.stringValue = [NSString stringWithFormat:@"%ld Bytes",self.TXNumber];
                self.StatusText.stringValue = tmp;
            }else{
                self.StatusText.stringValue = @"发送数据失败";
                return;
            }
        }else{
            self.StatusText.stringValue=@"字符串按选定编码转为字节流失败";
            return;
        }
        
        //显示文字为深灰色，大小为14
        NSInteger startPorint = self.RXDataDisplayTextView.textStorage.length;
        
        NSString *sendStr =@"";
        if(self.isOnlyDisplayRxData){
            sendStr = [NSString stringWithFormat:@"%@\n",textStr];
        }else{
            sendStr = [NSString stringWithFormat:@"%@ %@\n",[self.utils get2DateTime],textStr];
        }
        
        
        NSInteger length = sendStr.length;
        [self.RXDataDisplayTextView.textStorage.mutableString appendString:sendStr];
        [self.RXDataDisplayTextView.textStorage addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Andale Mono" size:14] range:NSMakeRange(startPorint, length)];
        [self.RXDataDisplayTextView.textStorage addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor ] range:NSMakeRange(startPorint, length)];
        
        [self.RXDataDisplayTextView scrollRangeToVisible:NSMakeRange(self.RXDataDisplayTextView.string.length, 1)];
        return;
    }
}

- (IBAction)clearRXDataDisplayTextView:(id)sender {
    [self.RXDataDisplayTextView setString:@""];
    self.RXNumber = 0;
    self.RXCounter.stringValue = @"0 Bytes";
    self.TXNumber = 0;
    self.TXCounter.stringValue=@"0 Bytes";
}

-(void)textDidChange:(NSNotification *)notification {
    
    [self.TXDataDisplayTextView.textStorage addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Andale Mono" size:14] range:NSMakeRange(0, [self.TXDataDisplayTextView string].length)];
    [self.TXDataDisplayTextView.textStorage addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:NSMakeRange(0, [self.TXDataDisplayTextView string].length)];
    [self.TXDataDisplayTextView.textStorage addAttribute:NSBackgroundColorAttributeName value:[NSColor whiteColor] range:NSMakeRange(0, [self.TXDataDisplayTextView string].length)];
}

#pragma mark - ORSSerialPortDelegate Methods

- (void)serialPortWasOpened:(ORSSerialPort *)serialPort
{
    self.OpenOrClose.title = @"关闭";
    self.StatusText.stringValue = @"串口已打开";
    
}

- (void)serialPortWasClosed:(ORSSerialPort *)serialPort
{
    self.OpenOrClose.title = @"打开";
    self.StatusText.stringValue = @"串口已关闭";
}

-(void)timerBegin{
    if (self.timerFlag) {
        
        return;
    }
     self.timerFlag = true;
    
    //__block int timeout=30; //倒计时时间
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_source_t _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,queue);
    
    //开始的时间
    dispatch_time_t startTime = dispatch_walltime(NULL, 1.0 * 0);
    //间隔的时间 ms
    uint64_t interval = 50.0 * NSEC_PER_MSEC;
    
    dispatch_source_set_timer(_timer,startTime,interval, 0); //每5ms秒执行
    dispatch_source_set_event_handler(_timer, ^{
        
        dispatch_source_cancel(_timer);
        dispatch_async(dispatch_get_main_queue(), ^{
            //设置界面的按钮显示 根据自己需求设置
            [self.RXDataDisplayTextView.textStorage.mutableString appendString:@"\n"];
            self.timerFlag = false;
        });
    });
    //启动定时器
    dispatch_resume(_timer);
}


- (void)serialPort:(ORSSerialPort *)serialPort didReceiveData:(NSData *)data
{
    if(serialPort!=self.serialPort){//不是同一个对象，直接返回
        return;
    }
    
    [self timerBegin];
    
    self.RXNumber += data.length;
    self.RXCounter.stringValue = [NSString stringWithFormat:@"%ld Bytes",self.RXNumber];
    
    NSString *string;
    if (self.isRXHexString) {
        string = [ORSSerialPortManager oneTwoData:data];
    }else{
        string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    if ([string length] == 0){
        return;
    }
    
    int prelen = (int)string.length;
    if(self.isOnlyDisplayRxData){
        string = [NSString stringWithFormat:@"%@",string];
        prelen = 0;
    }else{
        string = [NSString stringWithFormat:@"%@ %@\n",[self.utils get2DateTime],string];
        prelen = (int)string.length-prelen-1;
    }
    
    //显示文字为深灰色，大小为14
    NSInteger startPorint = self.RXDataDisplayTextView.textStorage.length;
    NSInteger length = string.length;
    [self.RXDataDisplayTextView.textStorage.mutableString appendString:string];
    [self.RXDataDisplayTextView.textStorage addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Andale Mono" size:14] range:NSMakeRange(startPorint, length)];
    
    [self.RXDataDisplayTextView scrollRangeToVisible:NSMakeRange(self.RXDataDisplayTextView.string.length, 1)];
    
    [self.RXDataDisplayTextView setNeedsDisplay:YES];
}

- (void)serialPortWasRemovedFromSystem:(ORSSerialPort *)serialPort;
{
    // After a serial port is removed from the system, it is invalid and we must discard any references to it
    self.serialPort = nil;
    self.OpenOrClose.title = @"打开";
}

//各种错误，比如打开，关闭，发送数据等发生错误
- (void)serialPort:(ORSSerialPort *)serialPort didEncounterError:(NSError *)error
{
    NSLog(@"Serial port %@ encountered an error: %@", serialPort, error);
    self.StatusText.stringValue = [NSString stringWithFormat:@"错误:%@",error.userInfo[@"NSLocalizedDescription"]];
    
}

#pragma mark - NSUserNotificationCenterDelegate

#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification
{
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 3.0 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [center removeDeliveredNotification:notification];
    });
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

#endif

#pragma mark - Notifications

- (void)serialPortsWereConnected:(NSNotification *)notification
{
    NSArray *connectedPorts = [notification userInfo][ORSConnectedSerialPortsKey];
    NSLog(@"Ports were connected: %@", connectedPorts);
    [self postUserNotificationForConnectedPorts:connectedPorts];
}

- (void)serialPortsWereDisconnected:(NSNotification *)notification
{
    NSArray *disconnectedPorts = [notification userInfo][ORSDisconnectedSerialPortsKey];
    NSLog(@"Ports were disconnected: %@", disconnectedPorts);
    [self postUserNotificationForDisconnectedPorts:disconnectedPorts];
    
}

- (void)postUserNotificationForConnectedPorts:(NSArray *)connectedPorts
{
#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)
    if (!NSClassFromString(@"NSUserNotificationCenter")) return;
    
    NSUserNotificationCenter *unc = [NSUserNotificationCenter defaultUserNotificationCenter];
    for (ORSSerialPort *port in connectedPorts)
    {
        NSUserNotification *userNote = [[NSUserNotification alloc] init];
        userNote.title = NSLocalizedString(@"侦测到串口线连接", @"侦测到串口线连接");
        NSString *informativeTextFormat = NSLocalizedString(@"串口设备 %@ 已经连接到你的 Mac电脑.", @"Serial port connected user notification informative text");
        userNote.informativeText = [NSString stringWithFormat:informativeTextFormat, port.name];
        userNote.soundName = nil;
        [unc deliverNotification:userNote];
        
        //连接刚刚插入的串口设备
        [self setSerialPort:port];
    }
#endif
}

- (void)postUserNotificationForDisconnectedPorts:(NSArray *)disconnectedPorts
{
#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)
    if (!NSClassFromString(@"NSUserNotificationCenter")) return;
    
    NSUserNotificationCenter *unc = [NSUserNotificationCenter defaultUserNotificationCenter];
    for (ORSSerialPort *port in disconnectedPorts)
    {
        NSUserNotification *userNote = [[NSUserNotification alloc] init];
        userNote.title = NSLocalizedString(@"侦测到串口线断开", @"侦测到串口线断开");
        NSString *informativeTextFormat = NSLocalizedString(@"串口设备 %@ 已从你的 Mac电脑断开物理连接.", @"Serial port disconnected user notification informative text");
        userNote.informativeText = [NSString stringWithFormat:informativeTextFormat, port.name];
        userNote.soundName = nil;
        [unc deliverNotification:userNote];
        
        [self.serialPortMArr removeObject:port];
        
         //连接默认第一个设备
        if(self.serialPortMArr.count>0){
           
            [self setSerialPort:self.serialPortMArr[0]];
        }
    }
#endif
}


#pragma mark - Properties

- (void)setSerialPort:(ORSSerialPort *)port
{
    if (port != _serialPort)
    {
//        [_serialPort close];
        _serialPort.delegate = nil;
        _serialPort = port;
        _serialPort.delegate = self;
        self.OpenOrClose.title = self.serialPort.isOpen ? @"关闭" : @"打开";
        NSString *tmp=[NSString stringWithFormat:@"%@%@",_serialPort.name,(self.serialPort.isOpen ? @"串口已打开" : @"串口已关闭")];
        self.StatusText.stringValue = tmp;
    }
}




// 保存日志文件
- (IBAction)SaveLog:(id)sender {
    
    [self.utils setFileName:[NSString stringWithFormat:@"%@-%@.txt",_serialPort.name,[self.utils getDateTime]] andTextView:self.RXDataDisplayTextView window:self.view.window];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    // Update the view, if already loaded.
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
