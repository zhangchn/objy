//
//  OYPreParser.h
//  ObjYin
//
//  Created by Chen Zhang on 5/18/14.
//  Copyright (c) 2014 Chen Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>
@class OYLexer;
@class OYNode;

@interface OYPreParser : NSObject
@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong) OYLexer *lexer;
- (id)initWithURL:(NSURL *)URL;
- (OYNode *)nextNode;
- (OYNode *)nextNode1:(int)depth;
- (OYNode *)parse;
@end


NSString *const OYParseErrorDomain;
NS_ENUM(NSInteger, OYParseErrorCode) {
    OYParseErrorCodeUnclosedDelimeter,
    OYParseErrorCodeDelimeterPairMismatch,
};

@interface OYPreParser (Incomplete)
- (instancetype)initWithString:(NSString *)string;
- (id)nextIncompleteNodeAtDepth:(int)depth;
- (id)parseIncomplete;
@end