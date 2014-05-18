//
//  OYTypeChecker.h
//  ObjYin
//
//  Created by Chen Zhang on 5/17/14.
//  Copyright (c) 2014 Chen Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OYValue;
@class OYFunType;
@class OYScope;

@interface OYTypeChecker : NSObject
@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, strong) NSMutableSet *uncalled;
@property (nonatomic, strong) NSMutableSet *callStack;
- (instancetype)initWithURL:(NSURL *)URL;
- (OYValue *)typeCheckURL:(NSURL *)URL;
- (void)invokeUncalledFunction:(OYFunType *)fun inScope:(OYScope *)scope;
+ (OYTypeChecker *)selfChecker;
@end
