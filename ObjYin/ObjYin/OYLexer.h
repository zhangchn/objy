//
//  OYLexer.h
//  ObjYin
//
//  Created by Chen Zhang on 5/18/14.
//  Copyright (c) 2014 Chen Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>
@class OYNode;

@interface OYLexer : NSObject
@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, copy) NSString *text;
@property (nonatomic) NSInteger offset;
@property (nonatomic) NSInteger line;
@property (nonatomic) NSInteger col;

- (id)initWithURL:(NSURL *)URL;
- (instancetype)initWithString:(NSString *)string;
- (void)forward;
- (void)skip:(NSInteger )n;
- (BOOL)skipSpaces;
- (BOOL)skipComments;
- (void)skipSpacesAndComments;
- (OYNode *)scanString;
+ (BOOL)isNumberChar:(unichar )c;
+ (BOOL)isIdentifierChar:(unichar )c;
- (OYNode *)scanNumber;
- (OYNode *)scanNameOrKeyword;
- (OYNode *)nextToken;

@end

BOOL isIdentifierChar(unichar c);
int parser_main(int argc, char ** argv);