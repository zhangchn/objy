//
//  OYTypeChecker.m
//  ObjYin
//
//  Created by Chen Zhang on 5/17/14.
//  Copyright (c) 2014 Chen Zhang. All rights reserved.
//

#import "OYTypeChecker.h"
#import "OYValue.h"
#import "OYParser.h"
#import "OYScope.h"
#import "OYAst.h"

@implementation OYTypeChecker
- (instancetype)initWithURL:(NSURL *)URL {
    self = [super init];
    if (self) {
        _URL = URL;
    }
    return self;
}

+ (OYTypeChecker *)selfChecker {
    static OYTypeChecker *checker;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        checker = [OYTypeChecker new];
    });
    return checker;
}
- (OYValue *)typeCheckURL:(NSURL *)URL {
    OYNode *program;
    @try {
        program = parseURL(URL);
    } @catch (NSException *e) {
        NSAssert(0, @"parsing error: %@",e);
        return nil;
    }
    OYScope *s = [OYScope initialTypeScope];
    OYValue *ret = [program typeCheckInScope:s];
    
    while (self.uncalled.count) {
        NSMutableArray *toRemove = [self.uncalled mutableCopy];
        [toRemove enumerateObjectsUsingBlock:^(OYFunType *ft, NSUInteger idx, BOOL *stop) {
            [self invokeUncalledFunction:ft inScope:s];
        }];
        [toRemove enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [self.uncalled removeObject:obj];
        }];
    }
    
    return ret;
}

- (void)invokeUncalledFunction:(OYFunType *)fun inScope:(OYScope *)scope {
    OYScope *funScope = [[OYScope alloc] initWithParentScope:fun.env];
    if (fun.properties) {
        [OYDeclare mergeTypeProperties:fun.properties scope:funScope];
//        Declare.mergeType(fun.properties, funScope);
    }
    OYTypeChecker *selfChecker = [OYTypeChecker selfChecker];
    [selfChecker.callStack addObject:fun];
//    TypeChecker.self.callStack.add(fun);
    OYValue *actual = [fun.fun.body typeCheckInScope:funScope];
//    Value actual = fun.fun.body.typecheck(funScope);
    [selfChecker.callStack removeObject:fun];
//    TypeChecker.self.callStack.remove(fun);
    
    id retNode = [fun.properties lookUpPropertyLocalName:@"->" key:@"type"];
//    Object retNode = fun.properties.lookupPropertyLocal(Constants.RETURN_ARROW, "type");
    
    if (!retNode || !([retNode isKindOfClass:[OYNode class]])) {
        NSAssert(0, @"illegal return type: %@", retNode);
        return;
    }
//    if (retNode == null || !(retNode instanceof Node)) {
//        _.abort("illegal return type: " + retNode);
//        return;
//    }

    OYValue *expected = [((OYNode *)retNode) typeCheckInScope:funScope];
//    Value expected = ((Node) retNode).typecheck(funScope);
    if (! TypeIsSubtypeOfType(actual, expected, true)) {
        NSAssert(0, @"%@" "\n" "type error in return value, expected: %@, actual: %@", fun.fun, expected, actual);
    }
//    if (!Type.subtype(actual, expected, true)) {
//        _.abort(fun.fun, "type error in return value, expected: " + expected + ", actual: " + actual);
//    }
}
@end
