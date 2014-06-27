//
//  main.m
//  ObjYin
//
//  Created by Chen Zhang on 5/16/14.
//  Copyright (c) 2014 Chen Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OYInterpreter.h"
#import "OYREPL.h"

int main(int argc, const char * argv[])
{

    int r;
    @autoreleasepool {
        
//        interpreter_main(argc, argv);
        r = repl_main(argc, argv);
    }
    return r;
}

