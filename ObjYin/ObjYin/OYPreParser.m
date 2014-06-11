//
//  OYPreParser.m
//  ObjYin
//
//  Created by Chen Zhang on 5/18/14.
//  Copyright (c) 2014 Chen Zhang. All rights reserved.
//

#import "OYPreParser.h"
#import "OYLexer.h"
#import "OYAst.h"
#import "OYParserException.h"

@implementation OYPreParser
- (id)initWithURL:(NSURL *)URL {
    self = [super init];
    if (self) {
        _URL = URL;
        _lexer = [[OYLexer alloc] initWithURL:URL];
    }
    return self;
}

- (OYNode *)nextNode {
    return [self nextNode1:0];
}
- (OYNode *)nextNode1:(int)depth {
    OYNode *first = [_lexer nextToken];
    
    // end of file
    if (!first) {
        return nil;
    }
    
    if ([OYDelimeter isOpenNode:first]) {   // try to get matched (...)
        NSMutableArray *elements = [NSMutableArray new];
        OYNode *next;
        for (next = [self nextNode1:depth + 1];
             ![OYDelimeter matchDelimeterOpen:first close:next];
             next = [self nextNode1:depth + 1]){
            if (!next) {
                [[[OYParserException alloc] initWithMessage:[NSString stringWithFormat:@"unclosed delimeter till end of file: %@", first] node:first] raise];
                
            } else if ([OYDelimeter isCloseNode:next]) {
                
                [[[OYParserException alloc] initWithMessage:[NSString stringWithFormat:@"unclosed closing delimeter: %@ does not close: %@", next, first] node:next] raise];
            } else {
                [elements addObject:next];
            }
        }
        return [[OYTuple alloc] initWithURL:first.URL elements:elements open:first close:next start:first.start end:next.end line:first.line column:first.col];
    } else if (depth == 0 && [OYDelimeter isCloseNode:first]) {
        [[[OYParserException alloc] initWithMessage:[NSString stringWithFormat:@"unmatched closing delimeter: %@ does not close any open delimeter", first] node:first] raise];
        return nil;
    } else {
        return first;
    }
}

- (OYNode *)parse {
    NSMutableArray *elements = [NSMutableArray new];
    [elements addObject:[OYName nameWithIdentifier:@"seq"]];// synthetic block keyword
    
    OYNode *s = [self nextNode];
    OYNode *first = s;
    OYNode *last = nil;
    for (; s; last = s, s = [self nextNode]) {
        [elements addObject:s];
    }
    return [[OYTuple alloc] initWithURL:self.URL elements:elements open:[OYName nameWithIdentifier:@"("] close:[OYName nameWithIdentifier:@")"] start:first ? first.start : 0 end:last ? last.end : 0 line:0 column:0];
}
@end
