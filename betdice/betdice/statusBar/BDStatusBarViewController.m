//
//  BDStatusBarViewController.m
//  betdice
//
//  Created by BlueHedgehog on 2018/12/3.
//  Copyright © 2018年 BlueHedgehog. All rights reserved.
//

#import "BDStatusBarViewController.h"
#import <SocketRocket/SocketRocket.h>
#import "BDGameHistory.h"
#import <MJExtension/MJExtension.h>
#import "NSDate+Extension.h"

@interface BDStatusBarViewController ()<SRWebSocketDelegate>
@property (strong)SRWebSocket *webSocket;
// 定时器
@property (nonatomic,strong) NSTimer *timer;

// 参数
// 发送内容
@property (copy) NSString *sendMsg;
// 历史结果
@property (nonatomic,strong) NSMutableArray <BDGameHistory *>*historyList;
// 记录时长戳
@property (nonatomic,assign) NSInteger timestamp;

// 成功次数提醒
@property (nonatomic,assign)NSInteger winNum;

// 控件
// 连赢方，次数
@property (weak) IBOutlet NSTextField *conWin;
// 最近赢家
@property (weak) IBOutlet NSTextField *recWin;
// 比率
@property (weak) IBOutlet NSTextField *rate;
// 平局累加
@property (weak) IBOutlet NSButton *tieCheck;

@property (weak) IBOutlet NSPopUpButton *tipsNumBtn;
@property (weak) IBOutlet NSPopUpButton *tipsTimeBtn;
@property (weak) IBOutlet NSTextField *resultText;



@end

@implementation BDStatusBarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self reconnect];
    NSLog(@"self.tieCheck.state  %ld",self.tieCheck.state);
}

-(void)viewWillAppear
{
    [super viewWillAppear];
    
}

// 链接
- (void)reconnect
{
    if (_webSocket ){
        _webSocket.delegate = nil;
        [_webSocket close];
    }
    
    NSLog(@"%@  %@ ",self.tipsTimeBtn.selectedItem.title,self.tipsNumBtn.selectedItem.title);
    _webSocket = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:@"wss://betdice.one/baccarat/prod/ws/?EIO=3&transport=websocket"]];
    
    //    wss://betdice.one/baccarat/prod/ws/?EIO=3&transport=websocket
    //    wss://betdice.one/baccarat/prod/ws/?EIO=3&transport=websocket
    _webSocket.delegate = self;
    self.conWin.stringValue = @"webSocket Opening Connection...";
    [_webSocket open];
}

- (void)sendPing:(id)sender;
{
    if (self.timer.timeInterval < 7) {
        [self.webSocket send:@"40/EOS,"];
    }else {
        [self.webSocket send:@"2"];
    }
}

- (void)pushNotification:(NSString *)title body:(NSString *)body
{
    NSUserNotification *localNotify = [[NSUserNotification alloc] init];
    localNotify.title = title;
    localNotify.informativeText = body;
    localNotify.soundName = NSUserNotificationDefaultSoundName;
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:localNotify];
}


- (void)viewDidDisappear
{
    [super viewDidDisappear];
    //    [_webSocket close];
    //    _webSocket = nil;
}


#pragma mark - SRWebSocketDelegate
- (void)webSocketDidOpen:(SRWebSocket *)webSocket;
{
    NSLog(@"Websocket Connected");
    self.conWin.stringValue = @"webSocket Connected!";
    [self timerOn];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error;
{
    NSLog(@":( Websocket Failed With Error %@", error);
    self.conWin.stringValue = [NSString stringWithFormat:@"Websocket Failed With Error %@", error];
    _webSocket = nil;
    [self timerOff];
    [self reconnect];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessageWithString:(nonnull NSString *)string
{
    NSLog(@"Received \"%@\"", string);
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;
{
    NSLog(@"WebSocket closed");
    self.conWin.stringValue = @"WebSocket closed";
    _webSocket = nil;
    [self timerOff];
    [self reconnect];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload;
{
    NSLog(@"WebSocket received pong");
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
    //    NSLog(@"WebSocket didReceiveMessage:  %@",message);
    if([(NSString *)message rangeOfString:@"42/EOS,"].length){
        NSString*mess = [(NSString *)message substringFromIndex:7];
        NSData *jsonData = [mess dataUsingEncoding:NSUTF8StringEncoding];
        if (jsonData.length) {
            NSArray *array = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
            if (array.count) {
                NSString *flagTitle =  array.firstObject;
                if ([flagTitle isEqualToString:@"gameHistory"]) {
                    NSArray *hisList =  array.lastObject;
//                    NSLog(@"%@",hisList);
                    NSArray *hisModelList = [BDGameHistory mj_objectArrayWithKeyValuesArray:hisList];
                    [self setNewHistoryList:hisModelList];
                    
                }
            }
        }
    }
}

#pragma mark  timer

-(void)timerOn
{
    [self timerOff];
    if(self.timer!=nil ) return;
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:5.0f target:self selector:@selector(sendPing:) userInfo:nil repeats:YES];
    self.timer = timer;
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}


-(void)timerOff
{
    [self.timer invalidate];
    self.timer = nil;
}

- (NSMutableArray *)historyList
{
    if (!_historyList) {
        _historyList = [NSMutableArray array];
    }
    return _historyList;
}

#pragma mark source
- (void)setNewHistoryList:(NSArray *)list
{
    if (self.historyList.count) {
        [self.historyList removeAllObjects];
    }
    NSArray* reversedArray = [[list reverseObjectEnumerator] allObjects];
    [self.historyList addObjectsFromArray:reversedArray];
    NSInteger winNum = 1;
    self.recWin.stringValue = [NSString stringWithFormat:@"最近Win：%@",[self changeString:self.historyList.firstObject.result]];
    BDGameHistory *preRes = [BDGameHistory new];
    NSMutableString *resultStr = [NSMutableString string];
    for (NSInteger i = 0 ; i < self.historyList.count; i ++) {
        BDGameHistory *res = self.historyList[i];
        [resultStr appendString:[self changeString:res.result]];
    }
    self.resultText.stringValue = resultStr;
    
    for (NSInteger i = 0 ; i < self.historyList.count; i ++) {
        BDGameHistory *res = self.historyList[i];
        if(i == 0 ){preRes = res; continue;}
//        NSLog(@"preRes.result  %@   res.result %@   self.tieCheck.state  %ld",preRes.result,res.result ,self.tieCheck.state);
        if ([preRes.result isEqualToString:res.result] ||
            (self.tieCheck.state == YES && [res.result isEqualToString:@"tie"])||
            (self.tieCheck.state == YES && [preRes.result isEqualToString:@"tie"])) {
            winNum ++;
//            NSLog(@"winnum  = %ld",winNum);
        }
        else {
//            NSLog(@"winnum  = %ld",winNum);
            // 连赢，只有庄或者闲 ，次数加上平
            NSString *body = [NSString stringWithFormat:@"当前 %@ 已经连赢%ld 次",[self changeString:preRes.result],winNum];
            if (winNum >= self.tipsNumBtn.selectedItem.title.integerValue) {
                //                 NSLog(@"timestamp  %ld ,[NSDate date].timestamp.integerValue- self.timestamp %ld    date = %ld",self.timestamp,[NSDate date].timestamp.integerValue- self.timestamp, [NSDate date].timestamp.integerValue);
                if (self.timestamp == 0 ||   [NSDate date].timestamp.integerValue- self.timestamp > self.tipsTimeBtn.selectedItem.title.integerValue) {
                    self.timestamp = [NSDate date].timestamp.integerValue ;
                    [self pushNotification:@"警报！！！！" body:body];
                }
            }
            self.conWin.stringValue = body;
            winNum = 1; break;
        }
        preRes = res;
    }
}

#pragma mark 控件

- (IBAction)tieCheckBtnClick:(NSButton *)sender {
    if (sender.state) {
        sender.state = YES;
    }else {
        sender.state = NO;
    }
    
//    NSLog(@"tie---%ld",sender.state);
}

- (IBAction)tipsTimeBtnClick:(NSPopUpButton *)sender {
//    NSLog(@"选择了  %ld",sender.selectedItem.title.integerValue);
}


- (IBAction)tipsNumBtnClick:(NSPopUpButton *)sender {
//    NSLog(@"选择了  %ld",sender.selectedItem.title.integerValue);
}
- (IBAction)exitBtnClick:(NSButton *)sender {
    [[NSApplication sharedApplication] terminate:self];
}
- (IBAction)touzhuBtnClick:(NSButton *)sender {
     [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://betdice.one/baccarat/?ref=bluehedgehog"]];
}


#pragma makr TOOL

- (NSString *)changeString:(NSString *)result
{
    if ([result isEqualToString:@"banker"]) {
        return @"庄 ";
    }else if ([result isEqualToString:@"player"]) {
        return @"闲 ";
    }else if ([result isEqualToString:@"tie"]){
        return @"平 ";
    }
    return result;
}


@end
