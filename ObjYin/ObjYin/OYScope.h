//
//  OYScope.h
//  ObjYin
//
//  Created by Chen Zhang on 5/17/14.
//  Copyright (c) 2014 Chen Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>
@class OYValue;
@interface OYScope : NSObject <NSCopying>
@property (nonatomic, strong) NSMutableDictionary *table;
@property (nonatomic, weak) OYScope *parent;

- (id)initWithParentScope:(OYScope *)parent;
- (void)putAllFromScope:(OYScope *)anotherScope;
- (OYValue *)lookUpName:(NSString *)name;
- (OYValue *)lookUpLocalName:(NSString *)name;
- (OYValue *)lookUpTypeName:(NSString *)name;
- (OYValue *)lookUpLocalTypeName:(NSString *)name;
- (OYValue *)lookUpPropertyName:(NSString *)name key:(NSString *)key;
- (id)lookUpPropertyLocalName:(NSString *)name key:(NSString *)key;
- (NSMutableDictionary *)lookUpAllPropsName:(NSString *)name;
- (OYScope*) findDefiningScope:(NSString *)name;

+ (OYScope *)initialScope;
+ (OYScope *)initialTypeScope;

- (void)setValue:(id)value forKey:(NSString *)key inName:(NSString *)name;
- (void)setValuesFromProperties:(NSDictionary *)properties inName:(NSString *)name;
- (void)setValue:(OYValue *)value inName:(NSString *)name;
- (void)setType:(OYType *)type inName:(NSString *)name;
- (NSSet *)keySet;
- (NSArray *)allKeys;
- (BOOL)containsKey:(NSString *)key;
@end
