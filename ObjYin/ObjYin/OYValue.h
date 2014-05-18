//
//  OYValue.h
//  ObjYin
//
//  Created by Chen Zhang on 5/17/14.
//  Copyright (c) 2014 Chen Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OYBoolValue;
@class OYAnyType;
@class OYVoidValue;
@class OYFun;
@class OYScope;
@class OYNode;

@interface OYValue : NSObject
+ (OYValue *)voidValue;
+ (OYBoolValue *)trueValue;
+ (OYBoolValue *)falseValue;
+ (OYValue *)anyValue;
@end

@interface OYBoolValue : OYValue
@property (nonatomic) BOOL value;
- (instancetype)initWithBoolean:(BOOL)boolean;
@end

@interface OYVoidValue : OYValue

@end

@interface OYAnyType : OYValue

@end

@interface OYBoolType : OYValue

@end

@interface OYClosure : OYValue
@property (nonatomic, strong) OYFun *fun;
@property (nonatomic, strong) OYScope *properties;
@property (nonatomic, strong) OYScope *env;
- (instancetype)initWithFunction:(OYFun *)fun properties:(OYScope *)properties envirionment:(OYScope *)env;
@end

@interface OYFunType : OYValue
@property (nonatomic, strong) OYFun *fun;
@property (nonatomic, strong) OYScope *properties;
@property (nonatomic, strong) OYScope *env;
- (instancetype)initWithFunction:(OYFun *)fun properties:(OYScope *)properties envirionment:(OYScope *)env;
@end

@interface OYIntType : OYValue

@end

@interface OYIntValue : OYValue
@property (nonatomic) NSInteger value;
- (id)initWithInteger:(NSInteger )value;
@end

@interface OYFloatType : OYValue

@end

@interface OYFloatValue : OYValue
@property (nonatomic) double value;
- (id)initWithValue:(double)value;
@end

@protocol OYPrimFun <NSObject>
@optional
- (OYValue *)apply:(NSArray *)args inLocation:(OYNode *)location;
- (OYValue *)typeCheck:(NSArray *)args inLocation:(OYNode *)location;
@end

@interface OYPrimFun : OYValue <OYPrimFun>
@property (nonatomic, copy) NSString *name;
@property (nonatomic) NSInteger arity;
- (id)initWithName:(NSString *)name arity:(NSInteger)arity;
@end


@interface OYRecordType : OYValue
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) OYNode *definition;
@property (nonatomic, strong) OYScope *properties;
- (id)initWithName:(NSString *)name definition:(OYNode *)definition properties:(OYScope *)properties;
@end

@interface OYRecordValue : OYValue
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) OYRecordType *type;
@property (nonatomic, strong) OYScope *properties;
- (id)initWithName:(NSString *)name type:(OYRecordType *)type properties:(OYScope *)properties;
@end

@interface OYStringType : OYValue
@end

@interface OYStringValue : OYValue
@property (nonatomic, strong) NSString *value;
- (id)initWithString:(NSString *)value;
@end



BOOL TypeIsSubtypeOfType(OYValue *type1, OYValue *type2, BOOL ret);

@interface OYType : OYValue
+ (OYValue *)boolType; // BOOL
+ (OYValue *)intType; // INT
+ (OYValue *)stringType; // STRING
@end

@interface OYUnionType : OYValue
@property (nonatomic, strong) NSMutableSet *values;
+ (OYValue *)unionWithValues:(id<NSFastEnumeration>)values;
- (void)addValue:(OYValue *)value;
- (int)size;
- (OYValue *)first;
@end

