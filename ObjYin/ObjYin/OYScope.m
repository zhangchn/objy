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
//    init.putValue("+", new Add());
//    init.putValue("-", new Sub());
//    init.putValue("*", new Mult());
//    init.putValue("/", new Div());
//    
//    init.putValue("<", new Lt());
//    init.putValue("<=", new LtE());
//    init.putValue(">", new Gt());
//    init.putValue(">=", new GtE());
//    init.putValue("=", new Eq());
//    init.putValue("and", new And());
//    init.putValue("or", new Or());
//    init.putValue("not", new Not());
//    
//    init.putValue("print", new Print());
//    
//    init.putValue("true", new BoolValue(true));
//    init.putValue("false", new BoolValue(false));
//    
//    init.putValue("Int", Type.INT);
//    init.putValue("Bool", Type.BOOL);
//    init.putValue("String", Type.STRING);
    return s;
}

+ (OYScope *)initialTypeScope {
    OYScope *s = [OYScope new];
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
