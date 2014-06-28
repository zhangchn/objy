//
//  OYREPL.m
//  ObjYin
//
//  Created by Chen Zhang on 6/28/14.
//  Copyright (c) 2014 Chen Zhang. All rights reserved.
//

#import "OYREPL.h"
#import "OYInterpreter.h"
#import "OYPreParser.h"
#import "OYLexer.h"
#import "OYScope.h"
#import "OYValue.h"
#import "OYAst.h"

#import <objc/objc-runtime.h>

@interface OYREPL ()
@property (strong) OYInterpreter *interpreter;
@property (strong) OYScope *persistantScope;
@end

@implementation OYREPL
- (instancetype)init {
    self = [super init];
    if (self) {
        self.interpreter = [[OYInterpreter alloc] initWithContentOfURL:nil];
        self.persistantScope = [OYScope initialScope];
    }
    return self;
}

- (void)run {
    NSFileHandle *input = [NSFileHandle fileHandleWithStandardInput];
    NSMutableData *buffer = [NSMutableData new];
    //NSMutableArray *lines = [NSMutableArray new];
    
    while (1) {
        if (buffer.length) {
            printf("... ");
            fflush(stdout);
        } else {
            printf(">>> ");
            fflush(stdout);
        }
        NSData *data = [input availableData];
        if (data.length) {
            [buffer appendData:data];
        } else {
            // Ctrl + d
            if (buffer.length) {
                buffer.length = 0;
                fprintf(stderr, "(Input aborted).\n");
                fflush(stderr);
                continue;
            } else {
                break;
            }
        }
        
        
        NSString *string = [[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding];
        id result = [self.interpreter interpretIncompleteText:string inScope:self.persistantScope];
        if ([result isKindOfClass:[NSError class]]) {
            if (![self isTolerableError:result]) {
                [self dumpError:result];
                buffer.length = 0;
            }
            continue;
        } else {
            [self printResult:result];
            buffer.length = 0;
        }
    }
}

- (BOOL)isTolerableError:(NSError *)error {
    if ([error.domain isEqualToString:OYParseErrorDomain]
        && error.code == OYParseErrorCodeUnclosedDelimeter) {
        return YES;
    }
    if ([error.domain isEqualToString:OYLexerErrorDomain]
        && error.code == OYLexerErrorRunAwayString) {
        return YES;
    }
    
    return NO;
}

- (void)dumpError:(NSError *)error {
    fprintf(stderr, "%s\n", error.localizedFailureReason.UTF8String);
    fflush(stderr);
}

- (void)printResult:(OYValue *)value {
    printf("%s\n", value ? value.description.UTF8String : "");
    fflush(stdout);
}
@end


@interface OYBlock (Swizzle)
- (OYValue *)interpretInScope2:(OYScope *)scope;
@end

@implementation OYBlock (Swizzle)
- (OYValue *)interpretInScope2:(OYScope *)scope {
    for (int i = 0; i < self.statements.count - 1; i++) {
        [self.statements[i] interpretInScope:scope];
    }
    return [self.statements[self.statements.count - 1] interpretInScope:scope];
}
@end

int repl_main(int argc, const char **argv) {
    // Swizzle the implementation of -[OYBlock interpretInScope:] using an alternative scope instance, so that the modifications made to the environment by the block can be saved.
    Method original = class_getInstanceMethod([OYBlock class], @selector(interpretInScope:));
    Method replacement = class_getInstanceMethod([OYBlock class], @selector(interpretInScope2:));
    
    method_exchangeImplementations(original, replacement);
    
    OYREPL *repl = [OYREPL new];
    [repl run];
    return 0;
}