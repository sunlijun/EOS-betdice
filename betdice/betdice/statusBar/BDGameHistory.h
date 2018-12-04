//
//  BDGameHistory.h
//  betdice
//
//  Created by BlueHedgehog on 2018/12/3.
//  Copyright © 2018年 BlueHedgehog. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDGameHistory : NSObject

@property (nonatomic,assign)BOOL isBankerPair;
@property (nonatomic,assign)BOOL isPlayerPair;
@property (nonatomic,copy)NSString * result;

@end

NS_ASSUME_NONNULL_END
