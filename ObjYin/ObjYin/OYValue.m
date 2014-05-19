//
//  OYValue.m
//  ObjYin
//
//  Created by Chen Zhang on 5/17/14.
//  Copyright (c) 2014 Chen Zhang. All rights reserved.
//

#import "OYValue.h"
#import "OYAst.h"
#import "OYScope.h"

@implementation OYValue
+ (OYValue *)voidValue
{
    static OYValue *theVoid;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        theVoid = [OYVoidValue new];
    });
    return theVoid;
}
+ (OYValue *)trueValue {
    static OYValue *theTrue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        theTrue = [[OYBoolValue alloc] initWithBoolean:YES];
    });
    return theTrue;
}

+ (OYValue *)falseValue {
    static OYValue *theFalse;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        theFalse = [[OYBoolValue alloc] initWithBoolean:YES];
    });
    return theFalse;
}

+ (OYValue *)anyValue {
    static OYValue *theVoid;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        theVoid = [OYAnyType new];
    });
    return theVoid;
}
@end

@implementation OYAnyType

- (NSString *)description {
    return @"Any";
}

@end

@implementation OYBoolType

- (NSString *)description {
    return @"Bool";
}

@end

@implementation OYBoolValue

- (instancetype)initWithBoolean:(BOOL)boolean {
    self = [super init];
    if (self) {
        _value = boolean;
    }
    return self;
}

- (NSString *)description {
    return self.value ? @"true" : @"false";
}
@end


@implementation OYClosure

- (instancetype)initWithFunction:(OYFun *)fun properties:(OYScope *)properties envirionment:(OYScope *)env {
    self = [super init];
    if (self) {
        _fun = fun;
        _properties = properties;
        _env = env;
    }
    return self;
}
- (NSString *)description {
    return [self.fun description];
}
@end

@implementation OYFunType

- (instancetype)initWithFunction:(OYFun *)fun properties:(OYScope *)properties envirionment:(OYScope *)env {
    self = [super init];
    if (self) {
        _fun = fun;
        _properties = properties;
        _env = env;
    }
    return self;
}
- (NSString *)description {
    return [self.properties description];
}
@end

@implementation OYVoidValue

- (NSString *)description {
    return @"void";
}

@end

@implementation OYFloatType

- (NSString *)description {
    return @"Float";
}

@end

@implementation OYFloatValue

- (id)initWithValue:(double)value {
    self = [super init];
    if (self) {
        _value = value;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%f", _value];
}
@end
@implementation OYIntType

- (NSString *)description {
    return @"Int";
}

@end

@implementation OYIntValue

- (id)initWithInteger:(NSInteger )value {
    self = [super init];
    if (self) {
        _value = value;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%ld", (long)_value];
}
@end


@implementation OYPrimFun
- (id)initWithName:(NSString *)name arity:(NSInteger)arity {
    self = [super init];
    if (self) {
        _name = name;
        _arity = arity;
    }
    return self;
}
- (NSString *)description {
    return _name;
}

@end

@implementation OYRecordType

- (id)initWithName:(NSString *)name definition:(OYNode *)definition properties:(OYScope *)properties {
    self = [super init];
    if (self) {
        _name = name;
        _definition = definition;
        _properties = properties;
    }
    return self;
}
- (NSString *)description {
    NSMutableString *result = [NSMutableString new];
    [result appendString:@"(record "];
    [result appendString: _name ? _name :@"_"];
    [_properties.keySet enumerateObjectsUsingBlock:^(NSString *field, BOOL *stop) {
        [result appendFormat:@" [%@", field];
        NSMutableDictionary *m = [self.properties lookUpAllPropsName:field];
        [m enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
            id value  = m[key];
            if (value) {
                [result appendFormat:@" :%@ %@", key, value];
            }
        }];
    }];
    [result appendString:@"]"];
    return result;
}
@end

@implementation OYUnionType

- (id)init {
    self = [super init];
    if (self) {
        _values = [NSMutableSet set];
    }
    return self;
}
+ (OYValue *)unionWithValues:(NSArray *)values {
    OYUnionType *u = [[OYUnionType alloc] init];
    for (OYValue *v in values) {
        [u addValue:v];
    }
    if (u.size == 1) {
        return u.first;
    } else {
        return u;
    }
}

+ (OYValue *)unionWithValue:(OYValue *)value, ...{
    OYUnionType *u = nil;
    OYValue *aValue;
    va_list argList;
    if (value) {
        u = [[OYUnionType alloc] init];
        [u addValue:value];
        va_start(argList, value);
        while ((aValue = va_arg(argList, id))) {
            [u addValue:value];
        }
        va_end(argList);
    }
    return u;
}

- (void)addValue:(OYValue *)value {
    if ([value isKindOfClass:[OYUnionType class]]) {
        [self.values addObjectsFromArray:((OYUnionType *)value).values.allObjects];
    } else {
        [self.values addObject:value];
    }
}
- (NSInteger)size {
    return self.values.count;
}

- (OYValue *)first {
    return [self.values.objectEnumerator nextObject];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"(U %@)", [self.values.allObjects componentsJoinedByString:@" "]];
}


@end
