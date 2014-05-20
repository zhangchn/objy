//
//  OYScope.m
//  ObjYin
//
//  Created by Chen Zhang on 5/17/14.
//  Copyright (c) 2014 Chen Zhang. All rights reserved.
//

#import "OYScope.h"
#import "OYValue.h"
#import "OYAst.h"
#import "OYPrimitives.h"

@implementation OYScope
- (id)init {
    self = [super init];
    if (self) {
        _parent = nil;
        _table = [NSMutableDictionary new];
    }
    return self;
}

- (id)initWithParentScope:(OYScope *)parent {
    self = [super init];
    if (self) {
        _parent = parent;
        _table = [NSMutableDictionary new];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    OYScope *s = [[OYScope allocWithZone:zone] init];
    [self.table enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        s.table[key] = [obj mutableCopy];
    }];
    return s;
}

- (void)putAllFromScope:(OYScope *)anotherScope {
    [anotherScope.table enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        self.table[key] = [obj mutableCopy];
    }];
}

- (OYValue *)lookUpName:(NSString *)name {
    id v = [self lookUpPropertyName:name key:@"value"];
    if (!v) {
        return nil;
    } else if ([v isKindOfClass:[OYValue class]]) {
        return v;
    } else {
        NSAssert(@"value is not a Value, shouldn't happen: %@", v);
        return nil;
    }
}

- (OYValue *)lookUpLocalName:(NSString *)name {
    id v = [self lookUpPropertyLocalName:name key:@"value"];
    if (!v) {
        return nil;
    } else if ([v isKindOfClass:[OYValue class]]) {
        return v;
    } else {
        NSAssert(@"value is not a Value, shouldn't happen: %@", v);
        return nil;
    }
}


- (OYValue *)lookUpTypeName:(NSString *)name {
    id v = [self lookUpPropertyName:(NSString *)name key:@"type"];
    if (!v) {
        return nil;
    } else if ([v isKindOfClass:[OYValue class]]) {
        return v;
    } else {
        NSAssert(@"value is not a Value, shouldn't happen: %@", v);
        return nil;
    }
    
}
- (OYValue *)lookUpLocalTypeName:(NSString *)name {
    id v = [self lookUpPropertyLocalName:(NSString *)name key:@"type"];
    if (!v) {
        return nil;
    } else if ([v isKindOfClass:[OYValue class]]) {
        return v;
    } else {
        NSAssert(@"value is not a Value, shouldn't happen: %@", v);
        return nil;
    }
    
}
- (OYValue *)lookUpPropertyName:(NSString *)name key:(NSString *)key {
    id v = [self lookUpPropertyLocalName:(NSString *)name key:key];
    if (!v) {
        return nil;
    } else if (self.parent) {
        return [self.parent lookUpPropertyName:name key:key];
    } else {
        
        return nil;
    }
}



- (id)lookUpPropertyLocalName:(NSString *)name key:(NSString *)key {
    return self.table[name][key];
}

- (NSMutableDictionary *)lookUpAllPropsName:(NSString *)name {
    return self.table[name];
}

- (OYScope*) findDefiningScope:(NSString *)name {
    id v = self.table[name];
    if (v) {
        return self;
    } else if (self.parent) {
        return [self.parent findDefiningScope:name];
    } else {
        return nil;
    }
}

+ (OYScope *)initialScope {
    OYScope *s = [OYScope new];
    [s setValue:[OYAdd new] inName:@"+"];
    [s setValue:[OYSub new] inName:@"-"];
    [s setValue:[OYMult new] inName:@"*"];
    [s setValue:[OYDiv new] inName:@"/"];

    [s setValue:[OYLt new] inName:@"<"];
    [s setValue:[OYLtE new] inName:@"<="];
    [s setValue:[OYGt new] inName:@">"];
    [s setValue:[OYGtE new] inName:@">-="];
    [s setValue:[OYEq new] inName:@"="];
    [s setValue:[OYAnd new] inName:@"and"];
    [s setValue:[OYOr new] inName:@"or"];
    [s setValue:[OYNot new] inName:@"not"];

    [s setValue:[OYPrint new] inName:@"print"];
    [s setValue:[[OYBoolValue alloc] initWithBoolean:YES] inName:@"true"];
    [s setValue:[[OYBoolValue alloc] initWithBoolean:NO] inName:@"false"];
    [s setValue:[OYType intType] inName:@"Int"];
    [s setValue:[OYType boolType] inName:@"Bool"];
    [s setValue:[OYType stringType] inName:@"String"];
    return s;
}

+ (OYScope *)initialTypeScope {
    OYScope *s = [OYScope new];

    [s setValue:[OYAdd new] inName:@"+"];
    [s setValue:[OYSub new] inName:@"-"];
    [s setValue:[OYMult new] inName:@"*"];
    [s setValue:[OYDiv new] inName:@"/"];

    [s setValue:[OYLt new] inName:@"<"];
    [s setValue:[OYLtE new] inName:@"<="];
    [s setValue:[OYGt new] inName:@">"];
    [s setValue:[OYGtE new] inName:@">-="];
    [s setValue:[OYEq new] inName:@"="];
    [s setValue:[OYAnd new] inName:@"and"];
    [s setValue:[OYOr new] inName:@"or"];
    [s setValue:[OYNot new] inName:@"not"];
    [s setValue:[OYU new] inName:@"U"];

    [s setValue:[OYType boolType] inName:@"true"];
    [s setValue:[OYType boolType] inName:@"false"];

    [s setValue:[OYType intType] inName:@"Int"];
    [s setValue:[OYType boolType] inName:@"Bool"];

    [s setValue:[OYType stringType] inName:@"String"];
    [s setValue:[OYValue anyValue] inName:@"Any"];

    return s;
}
// put(name,key,value)
- (void)setValue:(id)value forKey:(NSString *)key inName:(NSString *)name {
    if (!self.table[name]) {
        self.table[name] = [NSMutableDictionary new];
    }
    self.table[name][key] = value;
}

// putProperties(name,props)
- (void)setValuesFromProperties:(NSDictionary *)properties inName:(NSString *)name {
    if (!self.table[name]) {
        self.table[name] = [NSMutableDictionary new];
    }
    [self.table[name] setValuesForKeysWithDictionary:properties];
}


// putValue(name,value)
- (void)setValue:(OYValue *)value inName:(NSString *)name {
    
    [self setValue:value forKey:@"value" inName:name];
}

- (NSSet *)keySet {
    return [NSSet setWithArray:self.table.allKeys];
}
- (NSArray *)allKeys {
    return self.table.allKeys;
}
- (BOOL)containsKey:(NSString *)key {
    return self.table[key] != nil;
}

- (NSString *)description {
    NSMutableString *result = [NSMutableString new];
    [self.table enumerateKeysAndObjectsUsingBlock:^(NSString *name, NSDictionary *tableItem, BOOL *stop) {
        [result appendFormat:@"[%@ ", name];
        [tableItem enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [result appendFormat:@":%@ %@", key, obj];
        }];
        [result appendFormat:@"]"];
        
    }];
    return result;
}
@end
