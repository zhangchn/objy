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
#import "OYScope.h"
#import "OYValue.h"

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
            break;
        }
        
        
        NSString *string = [[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding];
        id result = [self.interpreter interpretIncompleteText:string inScope:self.persistantScope];
        if ([result isKindOfClass:[NSError class]]) {
            if (![[result domain] isEqualToString:OYParseErrorDomain]
                || ![result code] == OYParseErrorCodeUnclosedDelimeter) {
                [self dumpError:result];
                [buffer setLength:0];
            }
            continue;
        } else {
            [self printResult:result];
            [buffer setLength:0];
        }
    }
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

int repl_main(int argc, const char **argv) {
    OYREPL *repl = [OYREPL new];
    [repl run];
    return 0;
}