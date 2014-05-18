//
//  OYParserException.h
//  ObjYin
//
//  Created by Chen Zhang on 5/18/14.
//  Copyright (c) 2014 Chen Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OYNode;

@interface OYParserException : NSException
@property (nonatomic) NSInteger line;
@property (nonatomic) NSInteger col;
@property (nonatomic) NSInteger start;
- (id)initWithMessage:(NSString *)message line:(NSInteger)line col:(NSInteger)col start:(NSInteger)start;
- (id)initWithMessage:(NSString *)message node:(OYNode *)node;
@end
