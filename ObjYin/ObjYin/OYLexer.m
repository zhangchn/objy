//
//  OYLexer.m
//  ObjYin
//
//  Created by Chen Zhang on 5/18/14.
//  Copyright (c) 2014 Chen Zhang. All rights reserved.
//

#import "OYLexer.h"
#import "OYAst.h"
#import "OYParserException.h"

@implementation OYLexer
- (id)initWithURL:(NSURL *)URL {
    self = [super init];
    if (self) {
        _URL = URL;
        NSError *err;
        _text = [NSString stringWithContentsOfURL:URL encoding:NSUTF8StringEncoding error:&err];
        _offset = 0;
        _line = 0;
        _col = 0;
        if (!_text) {
            NSAssert(0, @"failed to read file: %@", URL);
        }
        [OYDelimeter addDelimiterPairOpen:@"(" close:@")"];
        [OYDelimeter addDelimiterPairOpen:@"[" close:@"]"];
        [OYDelimeter addDelimiter:@"."];
    }
    return self;
}

- (instancetype)initWithString:(NSString *)string {
    self = [super init];
    if (self) {
        _URL = nil;
        _text = string;
        _offset = 0;
        _line = 0;
        _col = 0;
        if (!_text) {
            NSAssert(0, @"text cannot be nil!");
        }
        [OYDelimeter addDelimiterPairOpen:@"(" close:@")"];
        [OYDelimeter addDelimiterPairOpen:@"[" close:@"]"];
        [OYDelimeter addDelimiter:@"."];
    }
    return self;
}

- (void)forward {
    if ([self.text characterAtIndex:self.offset] == '\n') {
        _line ++;
        _col = 0;
        _offset ++;
    } else {
        _col ++;
        _offset ++;
    }
}

- (void)skip:(NSInteger )n {
    for (int i = 0; i < n; i++) {
        [self forward];
    }
}


- (BOOL)skipSpaces {
    BOOL found = false;
    
    while (_offset < _text.length &&
           isspace([_text characterAtIndex:_offset]))
    {
        found = true;
        [self forward];
    }
    return found;
}


- (BOOL)skipComments {
    BOOL found = false;
    
    if ([[_text substringFromIndex:_offset] hasPrefix:@"--"]) {
        found = true;
        
        // skip to line end
        while (_offset < _text.length && [_text characterAtIndex:_offset] != '\n') {
            [self forward];
        }
        if (_offset < _text.length) {
            [self forward];
        }
    }
    return found;
}

- (void)skipSpacesAndComments {
    while ([self skipSpaces] || [self skipComments]) {
        // actions are performed by skipSpaces() and skipComments()
    }
}

- (OYNode *)scanString {
    NSInteger start = _offset;
    NSInteger startLine = _line;
    NSInteger startCol = _col;
    [self skip:[@"\"" length]];    // skip quote mark

    while (true) {
        // detect runaway strings at end of file or at newline
        if (_offset >= _text.length || [_text characterAtIndex:_offset] == '\n') {
            [[[OYParserException alloc] initWithMessage:@"runaway string" line:startLine col:startCol start:_offset] raise];
        }
        
        // end of string
        else if ([[_text substringFromIndex:_offset] hasPrefix:@"\""]) {
            [self skip:[@"\"" length]];    // skip quote mark // Constants.STRING_END.length
            break;
        }
        
        // skip any char after STRING_ESCAPE
        else if ([[_text substringFromIndex:_offset] hasPrefix:@"\\"] && _offset + 1 < _text.length) {
            [self skip:[@"\\" length] + 1];
            //skip(Constants.STRING_ESCAPE.length() + 1);
        }
        
        // other characters (string content)
        else {
            [self forward];
        }
    }
    
    NSInteger end = _offset;
    NSString *content = [_text substringWithRange:NSMakeRange(start + [@"\"" length], end - [@"\"" length] - start - [@"\"" length])];
    return [[OYStr alloc] initWithURL:self.URL value:content start:start end:end line:startLine column:startCol];
}

- (OYNode *)scanNumber {
    NSInteger start = _offset;
    NSInteger startLine = _line;
    NSInteger startCol = _col;
    
    while (_offset < _text.length && [OYLexer isNumberChar:[_text characterAtIndex:_offset]]) {
        [self forward];
    }
    
    NSString *content = [_text substringWithRange:NSMakeRange(start, _offset - start)];
    
    OYIntNum *intNum = [OYIntNum parseURL:self.URL content:content start:start end:_offset line:startLine column:startCol];
    if (intNum) {
        return intNum;
    } else {
        OYFloatNum *floatNum = [OYFloatNum parseURL:self.URL content:content start:start end:_offset line:startLine column:startCol];
        if (floatNum) {
            return floatNum;
        } else {
            NSString *message = [NSString stringWithFormat:@"incorrect number format: %@", content];
            [[[OYParserException alloc] initWithMessage:message line:startLine col:startCol start:start] raise];
        }
        return nil;
    }
}

- (OYNode *)scanNameOrKeyword {
    NSInteger start = _offset;
    NSInteger startLine = _line;
    NSInteger startCol = _col;
    
    while (_offset < _text.length && [OYLexer isIdentifierChar:[_text characterAtIndex:_offset]]) {
        [self forward];
    }
    
    NSString *content = [_text substringWithRange:NSMakeRange(start, _offset - start)];
    if ([content hasPrefix:@":"]) {
        return [[OYKeyword alloc] initWithURL:self.URL identifier:[content substringFromIndex:1] start:start end:_offset line:startLine column:startCol];
    } else {
        return [[OYName alloc] initWithURL:self.URL identifier:content start:start end:_offset line:startLine column:startCol];
    }
}

+ (BOOL)isNumberChar:(unichar)c {
    return isalnum(c) || c == '.' || c == '+' || c == '-';
}

- (OYNode *)nextToken {
    [self skipSpacesAndComments];
    
    // end of file
    if (_offset >= _text.length) {
        return nil;
    }
    
    {
        // case 1. delimiters
        unichar cur = [_text characterAtIndex:_offset];
        if ([OYDelimeter isDelimiter:cur]) {
            OYNode *ret = [[OYDelimeter alloc] initWithURL:self.URL shape:[NSString stringWithCharacters:&cur length:1] start:_offset end:_offset + 1 line:_line column:_col];

            [self forward];
            return ret;
        }
    }
    
    // case 2. string
    if ([[_text substringFromIndex:_offset] hasPrefix:@"\""]) {
        return [self scanString];
    }
    
    // case 3. number
    if (isnumber([_text characterAtIndex:_offset]) ||
        (([_text characterAtIndex:_offset] == '+' || [_text characterAtIndex:_offset] == '-')
         && _offset + 1 < _text.length && isnumber([_text characterAtIndex:_offset + 1])))
    {
        return [self scanNumber];
    }
    
    // case 4. name or keyword
    if ([OYLexer isIdentifierChar:[_text characterAtIndex:_offset]]) {
        return [self scanNameOrKeyword];
    }
    
    // case 5. syntax error
    NSString *message = [NSString stringWithFormat:@"unrecognized syntax: %@", [_text substringWithRange:NSMakeRange(_offset, 1)]];
    [[[OYParserException alloc] initWithMessage:message line:_line col:_col start:_offset] raise];

    return nil;
}

+ (BOOL)isIdentifierChar:(unichar)c {
    return isIdentifierChar(c);
}
@end

BOOL isIdentifierChar(unichar c) {
    static NSCharacterSet *identifierCharSet;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *charSet = [NSMutableCharacterSet alphanumericCharacterSet];
        [charSet addCharactersInString:@"~!@#$%^&*-_=+|:;,<>?/"];
        identifierCharSet = charSet;
    });
    return isalnum(c) || [identifierCharSet characterIsMember:c];
}
int parser_main(int argc, char ** argv) {
    NSString *argv1 = @(argv[1]);
    NSURL *URL = [NSURL URLWithString:argv1];
    OYLexer *lex = [[OYLexer alloc] initWithURL:URL];
    
    NSMutableArray *tokens = [NSMutableArray new];
    
    OYNode *n = [lex nextToken];
    while (n) {
        [tokens addObject:n];
        n = [lex nextToken];
    }
    NSLog(@"lexer result: ");
    for (OYNode *node in tokens) {
        NSLog(@"%@", node);
    }
    return 0;
}
