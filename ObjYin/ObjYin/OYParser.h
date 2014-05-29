//
//  OYParser.h
//  ObjYin
//
//  Created by Chen Zhang on 5/18/14.
//  Copyright (c) 2014 Chen Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>
@class OYNode;
@class OYScope;

OYNode *parseURL(NSURL *URL);
OYNode *parseNode(OYNode *prenode);
NSMutableArray *parseList(NSArray *prenodes);
NSMutableDictionary *parseMap(NSArray *prenodes);
OYScope *parseProperties(NSArray *fields);
BOOL delimType(OYNode *c, NSString *d);
//
//@interface OYParser : NSObject
//+ (OYNode *)parseURL:(NSURL *)URL;
//+ (OYNode *)parseNode:(OYNode *)prenode;
//+ (NSArray *)parseList:(NSArray *)prenodes;
//+ (NSDictionary *)parseMap:(NSArray *)prenodes;
//+ (OYScope *)parseProperties:(NSArray *)fields;
//+ (OYNode *)groupAttr:(OYNode *)prenode;
//+ (BOOL)delimType:(OYNode *)c string:(NSString *)d;
//
//@end
