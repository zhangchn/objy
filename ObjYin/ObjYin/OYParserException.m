//
//  OYParserException.m
//  ObjYin
//
//  Created by Chen Zhang on 5/18/14.
//  Copyright (c) 2014 Chen Zhang. All rights reserved.
//

#import "OYParserException.h"
#import "OYAst.h"

@implementation OYParserException
- (id)initWithMessage:(NSString *)message line:(NSInteger)line col:(NSInteger)col start:(NSInteger)start {
    self = [super initWithName:@"Parser Exception" reason:message userInfo:nil];
    if (self) {
        _line = line;
        _col = col;
        _start = start;
    }
    return self;
}
-(id)initWithMessage:(NSString *)message node:(OYNode *)node {
    self = [super initWithName:@"Parser Exception" reason:message userInfo:nil];
    if (self) {
        _line = node.line;
        _col = node.col;
        _start = node.start;
    }
    return self;
}
@end
