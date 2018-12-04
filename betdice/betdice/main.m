//
//  main.m
//  betdice
//
//  Created by BlueHedgehog on 2018/12/3.
//  Copyright © 2018年 BlueHedgehog. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

int main(int argc, const char * argv[]) {
    NSApplication *app = [NSApplication sharedApplication];
    id delegate = [[AppDelegate alloc]init];
    app.delegate = delegate;
    
    return NSApplicationMain(argc, argv);

}
