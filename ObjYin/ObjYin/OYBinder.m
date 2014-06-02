//
//  OYBinder.m
//  ObjYin
//
//  Created by Chen Zhang on 5/17/14.
//  Copyright (c) 2014 Chen Zhang. All rights reserved.
//

#import "OYBinder.h"
#import "OYValue.h"
#import "OYAst.h"
#import "OYScope.h"

@class OYRecordLiteral;

void define(OYNode *pattern, OYValue *value, OYScope *env) {
    if ([pattern isKindOfClass:[OYName class]]) {
        NSString *identifier = ((OYName *) pattern).identifier;
        OYValue *v = [env lookUpLocalName:identifier];

        if (v) {
            
            NSCAssert2(0, @"%@\n trying to redefine name: %@", pattern, identifier);
            
        } else {
            [env setValue:value inName:identifier];
        }
    } else if ([pattern isKindOfClass:[OYRecordLiteral class]]) {
        if ([value isKindOfClass:[OYRecordType class]]) {
            NSMutableDictionary *elms1 = ((OYRecordLiteral *)pattern).map;
            OYScope *elms2 = ((OYRecordType *)value).properties;
            
            if ([[NSSet setWithArray:elms1.allKeys] isEqualToSet:elms2.keySet]) {
                [elms1 enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    define(elms1[key], [elms2 lookUpLocalName:key], env);
                }];
            } else {
                NSCAssert(0, @"%@\n define with records of different attributes: %@ v.s. %@", pattern, elms1.allKeys, elms2.allKeys);
            }
        } else {
            NSCAssert(0, @"%@\ndefine with incompatible types: record and %@", pattern, value);
        }
    } else if ([pattern isKindOfClass:[OYVectorLiteral class]]) {
        if ([value isKindOfClass:[NSArray class]]) {
            NSArray *elms1 = ((OYVectorLiteral *)pattern).elements;
            NSArray *elms2 = ((NSArray *)value);
            
            if (elms1.count == elms2.count) {
                for (int i = 0; i < elms1.count; i++) {
                    define(elms1[i], elms2[i], env);
                }
            } else {
                NSCAssert(0, @"%@\ndefine with vectors of different sizes: %d v.s. %d", pattern, (int)elms1.count, (int)elms2.count);
            }
        } else {
            NSCAssert(0, @"%@\ndefine with incompatible types: vector and %@",pattern, value);
        }
    } else {
        NSCAssert(0, @"%@\nunsupported pattern of define: %@", pattern, pattern);
    }
}


void assign(OYNode *pattern, OYValue *value, OYScope *env){
    if ([pattern isKindOfClass:[OYName class]]) {
        NSString *identifier = ((OYName *) pattern).identifier;
        OYScope *d = [env findDefiningScope:identifier];
        
        if (!d) {
            NSCAssert(0, @"%@\nassigned name was not defined: %@", pattern, identifier);
        } else {
            [d setValue:value inName:identifier];
        }
    } else if ([pattern isKindOfClass:[OYSubscript class]]) {
        [(OYSubscript *)pattern setValue:value inScope:env];
    } else if ([pattern isKindOfClass:[OYAttr class]]) {
        [(OYAttr *)pattern setValue:value inScope:env];
    } else if ([pattern isKindOfClass:[OYRecordLiteral class]]) {
        if ([value isKindOfClass:[OYRecordType class]]) {
            NSDictionary *elms1 = ((OYRecordLiteral *)pattern).map;
            OYScope *elms2 = ((OYRecordType *)value).properties;
            if ([[NSSet setWithArray:elms1.allKeys] isEqualToSet:elms2.keySet]) {
                [elms1 enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    assign(obj, [elms2 lookUpLocalName:key], env);
                }];
            } else {
                NSCAssert(0, @"%@\nassign with records of different attributes: %@ v.s. %@", pattern, elms1.allKeys, elms2.allKeys);
            }
        } else {
            NSCAssert(0, @"%@\nassign with incompatible types: record and %@", pattern, value);
        }
    } else if ([pattern isKindOfClass:[OYVectorLiteral class]]) {
        if ([value isKindOfClass:[NSArray class]]) {
            NSArray *elms1 = ((OYVectorLiteral *)pattern).elements;
            NSArray *elms2 = ((NSArray *)value);
            
            if (elms1.count == elms2.count) {
                for (int i = 0; i < elms2.count; i++) {
                    assign(elms1[i], elms2[i], env);
                }
            } else {
                NSCAssert(0, @"%@" "\n" "assign vectors of different sizes: %ld v.s. %ld", pattern, elms1.count, elms2.count);
            }
        } else {
            NSCAssert(0, @"%@" "\n" "assign incompatible types: vector and %@", pattern, value);
        }
    } else {
        NSCAssert(0, @"%@" "\n" "unsupported pattern of assign: %@",
                  pattern, pattern);
    }
}


void checkDup(OYNode *pattern) {
    checkDup1(pattern, [NSMutableSet set]);
}


void checkDup1(OYNode *pattern, NSMutableSet *seen) {
    
    if ([pattern isKindOfClass:[OYName class]]) {
        NSString *identifer = ((OYName *) pattern).identifier;
        if ([seen containsObject:identifer]) {
            NSCAssert(0, @"%@" "\n" "duplicated name found in pattern: %@", pattern, pattern);
        } else {
            [seen addObject:identifer];
        }
    } else if ([pattern isKindOfClass:[OYRecordLiteral class]]) {
        [((OYRecordLiteral *)pattern).map enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            checkDup1(obj, seen);
        }];
    } else if ([pattern isKindOfClass:[OYVectorLiteral class]]) {
        [((OYVectorLiteral *)pattern).elements enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            checkDup1(obj, seen);
        }];
    }
}