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
        NSLog(@"parsing error: %@", program);
        return nil;
    }
    return [program interpretInScope:[OYScope initialScope]];
}
@end

int interpreter_main(int argc, const char ** argv){
    NSString *argv1 = [NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding];// argv[1];
    
    NSURL *URL = [NSURL URLWithString:argv1];
    OYInterpreter *i = [[OYInterpreter alloc] initWithContentOfURL:URL];
    NSLog(@"%@", [i interpreteContentOfURL:URL]);
//    _.msg(i.interp(args[0]).toString());
    return 0;
}