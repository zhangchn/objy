//
//  OYBinder.h
//  ObjYin
//
//  Created by Chen Zhang on 5/17/14.
//  Copyright (c) 2014 Chen Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OYValue;
@class OYNode;
@class OYScope;

void define(OYNode *pattern, OYValue *value, OYScope *env);
void assign(OYNode *pattern, OYValue *value, OYScope *env);

void checkDup(OYNode *pattern);

void checkDup1(OYNode *pattern, NSMutableSet *seen);
