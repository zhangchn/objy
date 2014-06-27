//
//  OYInterpreter.h
//  ObjYin
//
//  Created by Chen Zhang on 5/16/14.
//  Copyright (c) 2014 Chen Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OYValue;
@class OYScope;
@interface OYInterpreter : NSObject
- (instancetype)initWithContentOfURL:(NSURL *)URL;
- (OYValue *)interpretContentOfURL:(NSURL *)URL;
@end

int interpreter_main(int argc, const char ** argv);

@interface OYInterpreter (Incomplete)
- (id)interpretIncompleteText:(NSString *)text inScope:(OYScope *)scope;
@end

NSString *const OYInterpreterErrorDomain;
NS_ENUM(NSInteger, OYInterpreterError) {
    OYInterpreterErrorNotCatched
};