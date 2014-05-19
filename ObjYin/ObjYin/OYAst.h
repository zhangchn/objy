//
//  OYAst.h
//  ObjYin
//
//  Created by Chen Zhang on 5/16/14.
//  Copyright (c) 2014 Chen Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OYValue;
@class OYScope;
@class OYName;

@protocol OYNode <NSObject>

- (OYValue *)interpretInScope:(OYScope *)scope;
- (OYValue *)typeCheckInScope:(OYScope *)scope;
@end

@interface OYNode : NSObject <OYNode>

@property (nonatomic, strong) NSURL *URL;
@property (nonatomic) NSInteger start;
@property (nonatomic) NSInteger end;
@property (nonatomic) NSInteger line;
@property (nonatomic) NSInteger col;
- (instancetype)initWithURL:(NSURL *)URL start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col;
- (NSString *)positionInFile;
+ (NSMutableArray *)interpretNodes:(NSArray *)listOfNodes inScope:(OYScope *)scope;
+ (NSMutableArray *)typeCheckNodes:(NSArray *)listOfNodes inScope:(OYScope *)scope;
+ (NSString *)descriptionForNodes:(NSArray *)listOfNodes;

@end

@interface OYFun : OYNode
@property (nonatomic, strong) NSMutableArray *params;
@property (nonatomic, strong) OYNode *body;
@property (nonatomic, strong) OYScope *propertyForm;

- (id)initWithURL:(NSURL *)URL params:(NSMutableArray *)params propertyForm:(OYScope *)propertyForm body:(OYNode *)body start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col;
- (OYValue *)interpretInScope:(OYScope *)scope;
@end


@interface OYArgument : NSObject
@property (nonatomic, strong) NSMutableArray *elements;
@property (nonatomic, strong) NSMutableArray *positional;
@property (nonatomic, strong) NSMutableDictionary *keywords;
- (id)initWithElements:(NSArray *)elements;
@end

@interface OYAssign : OYNode
@property (nonatomic, strong) OYNode *pattern;
@property (nonatomic, strong) OYNode *value;
- (id)initWithURL:(NSURL *)URL pattern:(OYNode *)pattern value:(OYNode *)value start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col;
@end

@interface OYAttr : OYNode
@property (nonatomic, strong) OYNode *value;
@property (nonatomic, strong) OYName *attr;
- (id)initWithURL:(NSURL *)URL value:(OYNode *)value attr:(OYName *)attr start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col;
- (void)setValue:(OYValue *)value inScope:(OYScope *)scope;
@end

@interface OYBigInt : OYNode
@property (nonatomic, copy) NSString *content;
- (instancetype)initWithURL:(NSURL *)URL content:(NSString *)content start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col;
+ (OYBigInt *)parseContent:(NSString *)content inURL:(NSURL *)URL start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col;
@end

@interface OYBlock : OYNode
@property (nonatomic, strong) NSMutableArray *statements;
- (instancetype)initWithURL:(NSURL *)URL statements:(NSMutableArray *)statements start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col;

@end

@interface OYCall : OYNode
@property (nonatomic, strong) OYNode *op;
@property (nonatomic, strong) OYArgument *args;
- (instancetype)initWithURL:(NSURL *)URL op:(OYNode *)op arguments:(OYArgument *)args start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col;

@end

@interface OYDeclare : OYNode
@property (nonatomic, strong) OYScope *propertyForm;
- (instancetype)initWithURL:(NSURL *)URL propertyForm:(OYScope *)propertyForm start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col;
+ (OYScope *)evalProperties:(OYScope *)unevaled inScope:(OYScope *)scope;
+ (OYScope *)typeCheckProperties:(OYScope *)unevaled inScope:(OYScope *)scope;
+ (void)mergeDefaultProperties:(OYScope *)properties scope:(OYScope *)scope;
+ (void)mergeTypeProperties:(OYScope *)properties scope:(OYScope *)s;
//+ (OYScope *)evalProperties:(OYScope *)unevaled scope:(OYScope *)s;
@end


@interface OYDef : OYNode
@property (nonatomic, strong) OYNode *pattern;
@property (nonatomic, strong) OYNode *value;

- (id)initWithURL:(NSURL *)URL pattern:(OYNode *)pattern value:(OYNode *)value start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col;
@end

@interface OYDelimeter : OYNode

@property (nonatomic, copy) NSString *shape;
- (instancetype)initWithURL:(NSURL *)URL shape:(NSString *)shape start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col;
+ (void)addDelimiterPairOpen:(NSString *)open close:(NSString *)close;
+ (void)addDelimiter:(NSString *)delim;
+ (BOOL)isDelimiter:(unichar)c;
+ (BOOL)isOpenNode:(OYNode *)node;
+ (BOOL)isCloseNode:(OYNode *)node;
+ (BOOL)matchDelimeterOpen:(OYNode *)open close:(OYNode *)close;
+ (NSMutableSet *)delims;
+ (NSMutableDictionary *)delimMap;
@end

@interface OYFloatNum : OYNode
@property (nonatomic, copy) NSString *content;
@property (nonatomic) double value;
- (instancetype)initWithURL:(NSURL *)URL content:(NSString *)content start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col;
+ (OYFloatNum *)parseURL:(NSURL *)URL content:(NSString *)content start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col;
@end

@interface OYIf : OYNode
@property (nonatomic, strong) OYNode *test;
@property (nonatomic, strong) OYNode *then;
@property (nonatomic, strong) OYNode *orelse;
- (instancetype)initWithURL:(NSURL *)URL test:(OYNode *)test then:(OYNode *)then orelse:(OYNode *)orelse start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col;

@end

@interface OYIntNum : OYNode
@property (nonatomic, copy) NSString *content;
@property (nonatomic) NSInteger value;
@property (nonatomic) NSInteger base;
- (instancetype)initWithURL:(NSURL *)URL content:(NSString *)content start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col;
+ (OYIntNum *)parseURL:(NSURL *)URL content:(NSString *)content start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col;
@end

@interface OYKeyword : OYNode
@property (nonatomic, copy) NSString *identifier;
- (instancetype)initWithURL:(NSURL *)URL identifier:(NSString *)identifier start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col;
- (OYName *)asName;
@end

@interface OYName : OYNode
@property (nonatomic, copy) NSString *identifier;
- (instancetype)initWithURL:(NSURL *)URL identifier:(NSString *)identifier start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col;
+ (OYName *)nameWithIdentifier:(NSString *)identifier;
@end

@interface OYRecordDef : OYNode
@property (nonatomic, strong) OYName *name;
@property (nonatomic, strong) NSMutableArray *parents;
@property (nonatomic, strong) OYScope *propertyForm;
@property (nonatomic, strong) OYScope *properties;
- (instancetype)initWithURL:(NSURL *)URL name:(OYName *)name parents:(NSMutableArray *)parents propertyForm:(OYScope *)propertyForm start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col;
@end

@interface OYRecordLiteral : OYNode
@property (nonatomic, strong) NSMutableDictionary *map;
- (instancetype)initWithURL:(NSURL *)URL contents:(NSArray *)contents start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col;
@end

@interface OYStr : OYNode
@property (nonatomic, copy) NSString *value;
- (instancetype)initWithURL:(NSURL *)URL value:(NSString *)value start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col;
@end

@interface OYSubscript : OYNode
@property (nonatomic, strong) OYNode *value;
@property (nonatomic, strong) OYNode *index;

- (instancetype)initWithURL:(NSURL *)URL value:(OYNode *)value index:(OYNode *)index start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col;
- (void)setValue:(id)value inScope:(OYScope *)scope;
@end

@interface OYTuple : OYNode
@property (nonatomic, strong) NSMutableArray *elements;
@property (nonatomic, strong) OYNode *open;
@property (nonatomic, strong) OYNode *close;
- (instancetype)initWithURL:(NSURL *)URL elements:(NSMutableArray *)elements open:(OYNode *)open close:(OYNode *)close start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col;
- (OYNode *)getHead;
@end

@interface OYVectorLiteral : OYNode
@property (nonatomic, strong) NSMutableArray *elements;
- (instancetype)initWithURL:(NSURL *)URL elements:(NSArray *)elements start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col;
@end
