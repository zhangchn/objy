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
@class OYTuple;
@class OYCall, OYBlock, OYIf, OYDef, OYAssign, OYDeclare, OYFun, OYRecordDef;


OYNode *parseURL(NSURL *URL);
OYNode *parseNode(OYNode *prenode);
NSMutableArray *parseList(NSArray *prenodes);
NSMutableDictionary *parseMap(NSArray *prenodes);
OYScope *parseProperties(NSArray *fields);
BOOL delimType(OYNode *c, NSString *d);

OYBlock *parseBlock(OYTuple *tuple);
OYIf *parseIf(OYTuple *tuple);
OYDef *parseDef(OYTuple *tuple);
OYAssign *parseAssign(OYTuple *tuple);
OYDeclare *parseDeclare(OYTuple *tuple);
OYFun *parseFun(OYTuple *tuple);
OYRecordDef *parseRecordDef(OYTuple *tuple);
OYCall *parseCall(OYTuple *tuple);

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
