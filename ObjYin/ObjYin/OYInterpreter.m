//
//  OYInterpreter.m
//  ObjYin
//
//  Created by Chen Zhang on 5/16/14.
//  Copyright (c) 2014 Chen Zhang. All rights reserved.
//

#import "OYInterpreter.h"
#import "OYScope.h"
#import "OYAst.h"
#import "OYValue.h"
#import "OYParser.h"

@interface OYInterpreter ()
@property (nonatomic, strong) NSURL *URL;
@end
@implementation OYInterpreter
- (instancetype)initWithContentOfURL:(NSURL *)URL {
    self = [super init];
    if (self) {
        _URL = URL;
    }
    return self;
}

- (OYValue *)interpreteContentOfURL:(NSURL *)URL {
    OYNode *program;
    @try {
        program = parseURL(URL);
    }
    @catch (NSException *exception) {
        fprintf(stderr, "parsing error: %s\n", exception.description.UTF8String);
        fprintf(stderr, "%s\n", [[exception.callStackSymbols componentsJoinedByString:@"\n"] UTF8String]);
        return nil;
    }
    return [program interpretInScope:[OYScope initialScope]];
}
@end

int interpreter_main(int argc, const char ** argv){
    NSString *argv1 = nil;
    if (argc > 1) {
        argv1 = @(argv[1]);
        if (!([argv1 hasPrefix:@"file://"] || [argv1 hasPrefix:@"http://"])) {
            NSFileManager *fm = [NSFileManager new];
            if ([argv1 hasPrefix:@"./"]) {
                argv1 = [[[fm currentDirectoryPath] stringByAppendingPathComponent:[argv1 substringFromIndex:2]] stringByStandardizingPath];
            } else if ([argv1 hasPrefix:@"../"]) {
                argv1 = [[[fm currentDirectoryPath] stringByAppendingPathComponent:argv1] stringByStandardizingPath];
            } else if ([argv1 hasPrefix:@"~/"]) {
                argv1 = [argv1 stringByStandardizingPath];
            } else if (![argv1 hasPrefix:@"/"]) {
                argv1 = [[fm currentDirectoryPath] stringByAppendingPathComponent:[argv1 stringByStandardizingPath]];
            } else {
                // string starts with "/"
                argv1 = [argv1 stringByStandardizingPath];
            }
            argv1 = [@"file://" stringByAppendingString:argv1];
        }
    }
    NSURL *URL = [NSURL URLWithString:argv1];
    OYInterpreter *i = [[OYInterpreter alloc] initWithContentOfURL:URL];
    printf("%s\n", [[[i interpreteContentOfURL:URL] description] UTF8String]);

    return 0;
}