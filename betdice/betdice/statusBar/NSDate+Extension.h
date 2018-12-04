//
//  NSDate+Extend.h
//  CoreCategory
//
//  Created by 成林 on 15/4/6.
//  Copyright (c) 2015年 沐汐. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (Extension)

/*
 *  时间戳
 */
@property (nonatomic,copy,readonly) NSString *timestamp;





/**
 *  两个时间比较
 *
 *  @param unit     成分单元
 *  @param fromDate 起点时间
 *  @param toDate   终点时间
 *
 *  @return 时间成分对象
 */
+(NSDateComponents *)dateComponents:(NSCalendarUnit)unit fromDate:(NSDate *)fromDate toDate:(NSDate *)toDate;

+(BOOL )isValidTime:(NSString *)timestamps withSeconds:(NSInteger)seconds;



@end
