//
//  main.m
//  oyi
//
//  Created by Chen Zhang on 6/28/14.
//  Copyright (c) 2014 Chen Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OYREPL.h"
int main(int argc, const char * argv[])
{
    int r;

    @autoreleasepool {
        r = repl_main(argc, argv);
        
    }
    return r;
}

