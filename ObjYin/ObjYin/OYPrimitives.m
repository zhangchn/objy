//
//  OYPrimitives.m
//  ObjYin
//
//  Created by Chen Zhang on 5/17/14.
//  Copyright (c) 2014 Chen Zhang. All rights reserved.
//

#import "OYPrimitives.h"

@implementation OYAdd

- (id)init {
    self = [super initWithName:@"+" arity:2];
    return self;
}

- (OYValue *)apply:(NSArray *)args inLocation:(OYNode *)location {
    OYValue *v1 = args[0];
    OYValue *v2 = args[1];
    
    if ([v1 isKindOfClass:[OYIntValue class]] && [v2 isKindOfClass:[OYIntValue class]]) {
        return [[OYIntValue alloc] initWithInteger:((OYIntValue *)v1).value + ((OYIntValue *)v2).value];
    } else if ([v1 isKindOfClass:[OYFloatValue class]] && [v2 isKindOfClass:[OYFloatValue class]]) {
        return [[OYFloatValue alloc] initWithValue:((OYFloatValue *)v1).value + ((OYFloatValue *)v2).value];
    } else if ([v1 isKindOfClass:[OYFloatValue class]] && [v2 isKindOfClass:[OYIntValue class]]) {
        return [[OYFloatValue alloc] initWithValue:((OYFloatValue *)v1).value + ((OYIntValue *)v2).value];

    } else if ([v1 isKindOfClass:[OYIntValue class]] && [v2 isKindOfClass:[OYFloatValue class]]) {
        return [[OYFloatValue alloc] initWithValue:((OYIntValue *)v1).value + ((OYFloatValue *)v2).value];
    }
    
    NSAssert(0,@"%@\n incorrect argument types for +: %@, %@", location, v1, v2);
    return nil;
}

- (OYValue *)typeCheck:(NSArray *)args inLocation:(OYNode *)location {
    OYValue *v1 = args[0];
    OYValue *v2 = args[1];
    
    if ([v1 isKindOfClass:[OYFloatType class]] || [v2 isKindOfClass:[OYFloatType class]]) {
        return [OYFloatType new];
    }
    if ([v1 isKindOfClass:[OYIntType class]] && [v2 isKindOfClass:[OYIntType class]]) {
        return [OYType intType];
    }
    
    NSAssert(0, @"%@\n incorrect argument types for +: %@, %@", location, v1, v2);
    return nil;
}
@end


@implementation OYAnd

- (id)init {
    self = [super initWithName:@"and" arity:2];
    return self;
}

- (OYValue *)apply:(NSArray *)args inLocation:(OYNode *)location {
    OYValue *value1 = args[0];
    OYValue *value2 = args[1];

    if ([value1 isKindOfClass:[OYBoolValue class]] && [value2 isKindOfClass:[OYBoolValue class]]) {
        return [[OYBoolValue alloc] initWithBoolean:((OYBoolValue *)value1).value  && ((OYBoolValue *)value2).value];
    }
    NSAssert(0, @"%@\nincorrect argument types for and: %@, %@", location, value1, value2);
    return nil;
}

- (OYValue *)typeCheck:(NSArray *)args inLocation:(OYNode *)location {
    OYValue *value1 = args[0];
    OYValue *value2 = args[1];

    if ([value1 isKindOfClass:[OYBoolType class]] && [value2 isKindOfClass:[OYBoolType class]]) {
        return [OYType boolType];
    }
    NSAssert(0, @"%@\nincorrect argument types for and: %@, %@", location, value1, value2);
    return nil;
}
@end

@implementation OYDiv
- (id)init {
    self = [super initWithName:@"/" arity:2];
    return self;
}

- (OYValue *)apply:(NSArray *)args inLocation:(OYNode *)location {
    OYValue *value1 = args[0];
    OYValue *value2 = args[1];

    if ([value1 isKindOfClass:[OYIntValue class]] && [value2 isKindOfClass:[OYIntValue class]]) {
        return [[OYIntValue alloc] initWithInteger:((OYIntValue *)value1).value  / ((OYIntValue *)value2).value];
    }
    if ([value1 isKindOfClass:[OYFloatValue class]] && [value2 isKindOfClass:[OYFloatValue class]]) {
        return [[OYFloatValue alloc] initWithValue:((OYFloatValue *)value1).value  / ((OYFloatValue *)value2).value];
    }
    if ([value1 isKindOfClass:[OYFloatValue class]] && [value2 isKindOfClass:[OYIntValue class]]) {
        return [[OYFloatValue alloc] initWithValue:((OYFloatValue *)value1).value  / ((OYIntValue *)value2).value];
    }
    if ([value1 isKindOfClass:[OYIntValue class]] && [value2 isKindOfClass:[OYFloatValue class]]) {
        return [[OYFloatValue alloc] initWithValue:((OYIntValue *)value1).value  / ((OYFloatValue *)value2).value];
    }

    NSAssert(0, @"%@\nincorrect argument types for /: %@, %@", location, value1, value2);
    return nil;
}

- (OYValue *)typeCheck:(NSArray *)args inLocation:(OYNode *)location {
    OYValue *value1 = args[0];
    OYValue *value2 = args[1];

    if ([value1 isKindOfClass:[OYFloatType class]] || [value2 isKindOfClass:[OYFloatType class]]) {
        return [OYFloatType new];
    }
    if ([value1 isKindOfClass:[OYIntType class]] && [value2 isKindOfClass:[OYIntType class]]) {
        return [OYType intType];
    }
    NSAssert(0, @"%@\nincorrect argument types for and: %@, %@", location, value1, value2);
    return nil;

}
@end

@implementation OYEq
- (id)init {
    self = [super initWithName:@"=" arity:2];
    return self;
}

- (OYValue *)apply:(NSArray *)args inLocation:(OYNode *)location {
    OYValue *value1 = args[0];
    OYValue *value2 = args[1];

    if ([value1 isKindOfClass:[OYIntValue class]] && [value2 isKindOfClass:[OYIntValue class]]) {
        return [[OYBoolValue alloc] initWithBoolean:((OYIntValue *)value1).value  == ((OYIntValue *)value2).value];
    }
    if ([value1 isKindOfClass:[OYFloatValue class]] && [value2 isKindOfClass:[OYFloatValue class]]) {
        return [[OYBoolValue alloc] initWithBoolean:((OYFloatValue *)value1).value  == ((OYFloatValue *)value2).value];
    }
    if ([value1 isKindOfClass:[OYFloatValue class]] && [value2 isKindOfClass:[OYIntValue class]]) {
        return [[OYBoolValue alloc] initWithBoolean:((OYFloatValue *)value1).value  == ((OYIntValue *)value2).value];
    }
    if ([value1 isKindOfClass:[OYIntValue class]] && [value2 isKindOfClass:[OYFloatValue class]]) {
        return [[OYBoolValue alloc] initWithBoolean:((OYIntValue *)value1).value  == ((OYFloatValue *)value2).value];
    }

    NSAssert(0, @"%@\nincorrect argument types for =: %@, %@", location, value1, value2);
    return nil;

}

- (OYValue *)typeCheck:(NSArray *)args inLocation:(OYNode *)location {
    OYValue *value1 = args[0];
    OYValue *value2 = args[1];

    if (!([value1 isKindOfClass:[OYFloatType class]] || [value1 isKindOfClass:[OYIntType class]])
        || !([value2 isKindOfClass:[OYFloatType class]] || [value2 isKindOfClass:[OYIntType class]])) {
        NSAssert(0, @"%@\nincorrect argument types for =: %@, %@", location, value1, value2);
    }

    return [OYType boolType];
    
}
@end

@implementation OYGt

- (id)init {
    self = [super initWithName:@">" arity:2];
    return self;
}

- (OYValue *)apply:(NSArray *)args inLocation:(OYNode *)location {
    OYValue *value1 = args[0];
    OYValue *value2 = args[1];

    if ([value1 isKindOfClass:[OYIntValue class]] && [value2 isKindOfClass:[OYIntValue class]]) {
        return [[OYBoolValue alloc] initWithBoolean:((OYIntValue *)value1).value  > ((OYIntValue *)value2).value];
    }
    if ([value1 isKindOfClass:[OYFloatValue class]] && [value2 isKindOfClass:[OYFloatValue class]]) {
        return [[OYBoolValue alloc] initWithBoolean:((OYFloatValue *)value1).value  > ((OYFloatValue *)value2).value];
    }
    if ([value1 isKindOfClass:[OYFloatValue class]] && [value2 isKindOfClass:[OYIntValue class]]) {
        return [[OYBoolValue alloc] initWithBoolean:((OYFloatValue *)value1).value  > ((OYIntValue *)value2).value];
    }
    if ([value1 isKindOfClass:[OYIntValue class]] && [value2 isKindOfClass:[OYFloatValue class]]) {
        return [[OYBoolValue alloc] initWithBoolean:((OYIntValue *)value1).value > ((OYFloatValue *)value2).value];
    }

    NSAssert(0, @"%@\nincorrect argument types for >: %@, %@", location, value1, value2);
    return nil;
}

- (OYValue *)typeCheck:(NSArray *)args inLocation:(OYNode *)location {
    OYValue *value1 = args[0];
    OYValue *value2 = args[1];

    if (!([value1 isKindOfClass:[OYFloatType class]] || [value1 isKindOfClass:[OYIntType class]])
        || !([value2 isKindOfClass:[OYFloatType class]] || [value2 isKindOfClass:[OYIntType class]])) {
        NSAssert(0, @"%@\nincorrect argument types for >: %@, %@", location, value1, value2);
    }

    return [OYType boolType];
}
@end

@implementation OYGtE

- (id)init {
    self = [super initWithName:@">=" arity:2];
    return self;
}

- (OYValue *)apply:(NSArray *)args inLocation:(OYNode *)location {
    OYValue *value1 = args[0];
    OYValue *value2 = args[1];

    if ([value1 isKindOfClass:[OYIntValue class]] && [value2 isKindOfClass:[OYIntValue class]]) {
        return [[OYBoolValue alloc] initWithBoolean:((OYIntValue *)value1).value >= ((OYIntValue *)value2).value];
    }
    if ([value1 isKindOfClass:[OYFloatValue class]] && [value2 isKindOfClass:[OYFloatValue class]]) {
        return [[OYBoolValue alloc] initWithBoolean:((OYFloatValue *)value1).value >= ((OYFloatValue *)value2).value];
    }
    if ([value1 isKindOfClass:[OYFloatValue class]] && [value2 isKindOfClass:[OYIntValue class]]) {
        return [[OYBoolValue alloc] initWithBoolean:((OYFloatValue *)value1).value >= ((OYIntValue *)value2).value];
    }
    if ([value1 isKindOfClass:[OYIntValue class]] && [value2 isKindOfClass:[OYFloatValue class]]) {
        return [[OYBoolValue alloc] initWithBoolean:((OYIntValue *)value1).value >= ((OYFloatValue *)value2).value];
    }

    NSAssert(0, @"%@\nincorrect argument types for >=: %@, %@", location, value1, value2);
    return nil;
}

- (OYValue *)typeCheck:(NSArray *)args inLocation:(OYNode *)location {
    OYValue *value1 = args[0];
    OYValue *value2 = args[1];

    if (!([value1 isKindOfClass:[OYFloatType class]] || [value1 isKindOfClass:[OYIntType class]])
        || !([value2 isKindOfClass:[OYFloatType class]] || [value2 isKindOfClass:[OYIntType class]])) {
        NSAssert(0, @"%@\nincorrect argument types for >: %@, %@", location, value1, value2);
    }

    return [OYType boolType];
}
@end

@implementation OYLt

- (id)init {
    self = [super initWithName:@"<" arity:2];
    return self;
}

- (OYValue *)apply:(NSArray *)args inLocation:(OYNode *)location {
    OYValue *value1 = args[0];
    OYValue *value2 = args[1];

    if ([value1 isKindOfClass:[OYIntValue class]] && [value2 isKindOfClass:[OYIntValue class]]) {
        return [[OYBoolValue alloc] initWithBoolean:((OYIntValue *)value1).value  < ((OYIntValue *)value2).value];
    }
    if ([value1 isKindOfClass:[OYFloatValue class]] && [value2 isKindOfClass:[OYFloatValue class]]) {
        return [[OYBoolValue alloc] initWithBoolean:((OYFloatValue *)value1).value  < ((OYFloatValue *)value2).value];
    }
    if ([value1 isKindOfClass:[OYFloatValue class]] && [value2 isKindOfClass:[OYIntValue class]]) {
        return [[OYBoolValue alloc] initWithBoolean:((OYFloatValue *)value1).value  < ((OYIntValue *)value2).value];
    }
    if ([value1 isKindOfClass:[OYIntValue class]] && [value2 isKindOfClass:[OYFloatValue class]]) {
        return [[OYBoolValue alloc] initWithBoolean:((OYIntValue *)value1).value < ((OYFloatValue *)value2).value];
    }

    NSAssert(0, @"%@\nincorrect argument types for <: %@, %@", location, value1, value2);
    return nil;
}

- (OYValue *)typeCheck:(NSArray *)args inLocation:(OYNode *)location {
    OYValue *value1 = args[0];
    OYValue *value2 = args[1];

    if (!([value1 isKindOfClass:[OYFloatType class]] || [value1 isKindOfClass:[OYIntType class]])
        || !([value2 isKindOfClass:[OYFloatType class]] || [value2 isKindOfClass:[OYIntType class]])) {
        NSAssert(0, @"%@\nincorrect argument types for <: %@, %@", location, value1, value2);
    }

    return [OYType boolType];
}
@end

@implementation OYLtE

- (id)init {
    self = [super initWithName:@"<=" arity:2];
    return self;
}

- (OYValue *)apply:(NSArray *)args inLocation:(OYNode *)location {
    OYValue *value1 = args[0];
    OYValue *value2 = args[1];

    if ([value1 isKindOfClass:[OYIntValue class]] && [value2 isKindOfClass:[OYIntValue class]]) {
        return [[OYBoolValue alloc] initWithBoolean:((OYIntValue *)value1).value <= ((OYIntValue *)value2).value];
    }
    if ([value1 isKindOfClass:[OYFloatValue class]] && [value2 isKindOfClass:[OYFloatValue class]]) {
        return [[OYBoolValue alloc] initWithBoolean:((OYFloatValue *)value1).value <= ((OYFloatValue *)value2).value];
    }
    if ([value1 isKindOfClass:[OYFloatValue class]] && [value2 isKindOfClass:[OYIntValue class]]) {
        return [[OYBoolValue alloc] initWithBoolean:((OYFloatValue *)value1).value <= ((OYIntValue *)value2).value];
    }
    if ([value1 isKindOfClass:[OYIntValue class]] && [value2 isKindOfClass:[OYFloatValue class]]) {
        return [[OYBoolValue alloc] initWithBoolean:((OYIntValue *)value1).value <= ((OYFloatValue *)value2).value];
    }

    NSAssert(0, @"%@\nincorrect argument types for <=: %@, %@", location, value1, value2);
    return nil;
}

- (OYValue *)typeCheck:(NSArray *)args inLocation:(OYNode *)location {
    OYValue *value1 = args[0];
    OYValue *value2 = args[1];

    if (!([value1 isKindOfClass:[OYFloatType class]] || [value1 isKindOfClass:[OYIntType class]])
        || !([value2 isKindOfClass:[OYFloatType class]] || [value2 isKindOfClass:[OYIntType class]])) {
        NSAssert(0, @"%@\nincorrect argument types for <=: %@, %@", location, value1, value2);
    }

    return [OYType boolType];
}
@end


@implementation OYMult

- (id)init {
    self = [super initWithName:@"*" arity:2];
    return self;
}

- (OYValue *)apply:(NSArray *)args inLocation:(OYNode *)location {
    OYValue *v1 = args[0];
    OYValue *v2 = args[1];

    if ([v1 isKindOfClass:[OYIntValue class]] && [v2 isKindOfClass:[OYIntValue class]]) {
        return [[OYIntValue alloc] initWithInteger:((OYIntValue *)v1).value * ((OYIntValue *)v2).value];
    } else if ([v1 isKindOfClass:[OYFloatValue class]] && [v2 isKindOfClass:[OYFloatValue class]]) {
        return [[OYFloatValue alloc] initWithValue:((OYFloatValue *)v1).value * ((OYFloatValue *)v2).value];
    } else if ([v1 isKindOfClass:[OYFloatValue class]] && [v2 isKindOfClass:[OYIntValue class]]) {
        return [[OYFloatValue alloc] initWithValue:((OYFloatValue *)v1).value * ((OYIntValue *)v2).value];

    } else if ([v1 isKindOfClass:[OYIntValue class]] && [v2 isKindOfClass:[OYFloatValue class]]) {
        return [[OYFloatValue alloc] initWithValue:((OYIntValue *)v1).value * ((OYFloatValue *)v2).value];
    }

    NSAssert(0,@"%@\n incorrect argument types for *: %@, %@", location, v1, v2);
    return nil;
}

- (OYValue *)typeCheck:(NSArray *)args inLocation:(OYNode *)location {
    OYValue *v1 = args[0];
    OYValue *v2 = args[1];

    if ([v1 isKindOfClass:[OYFloatType class]] || [v2 isKindOfClass:[OYFloatType class]]) {
        return [OYFloatType new];
    }
    if ([v1 isKindOfClass:[OYIntType class]] && [v2 isKindOfClass:[OYIntType class]]) {
        return [OYType intType];
    }

    NSAssert(0, @"%@\n incorrect argument types for *: %@, %@", location, v1, v2);
    return nil;
}
@end

@implementation OYNot

- (id)init {
    self = [super initWithName:@"not" arity:1];
    return self;
}

- (OYValue *)apply:(NSArray *)args inLocation:(OYNode *)location {
    OYValue *v1 = args[0];

    if ([v1 isKindOfClass:[OYBoolValue class]]) {
        return [[OYBoolValue alloc] initWithBoolean:!((OYBoolValue *)v1).value];
    }

    NSAssert(0, @"%@\nincorrect argument type for not: %@", location, v1);
    return nil;
}

- (OYValue *)typeCheck:(NSArray *)args inLocation:(OYNode *)location {
    OYValue *v1 = args[0];

    if ([v1 isKindOfClass:[OYBoolType class]]) {
        return [OYType boolType];
    }

    NSAssert(0, @"%@\nincorrect argument type for not: %@", location, v1);
    return nil;
}
@end

@implementation OYOr

- (id)init {
    self = [super initWithName:@"or" arity:2];
    return self;
}

- (OYValue *)apply:(NSArray *)args inLocation:(OYNode *)location {
    OYValue *value1 = args[0];
    OYValue *value2 = args[1];

    if ([value1 isKindOfClass:[OYBoolValue class]] && [value2 isKindOfClass:[OYBoolValue class]]) {
        return [[OYBoolValue alloc] initWithBoolean:((OYBoolValue *)value1).value  || ((OYBoolValue *)value2).value];
    }
    NSAssert(0, @"%@\nincorrect argument types for or: %@, %@", location, value1, value2);
    return nil;
}

- (OYValue *)typeCheck:(NSArray *)args inLocation:(OYNode *)location {
    OYValue *value1 = args[0];
    OYValue *value2 = args[1];

    if ([value1 isKindOfClass:[OYBoolType class]] && [value2 isKindOfClass:[OYBoolType class]]) {
        return [OYType boolType];
    }
    NSAssert(0, @"%@\nincorrect argument types for or: %@, %@", location, value1, value2);
    return nil;
}

@end


@implementation OYPrint

- (id)init {
    self = [super initWithName:@"print" arity:1];
    return self;
}

- (OYValue *)apply:(NSArray *)args inLocation:(OYNode *)location {
    BOOL first = true;
    for (OYValue *v in args) {
        if (!first) {
            printf(", ");
        }
        printf("%s", v.description.UTF8String);
        first = false;
    }
    printf("\n");
    return [OYValue voidValue];
}

- (OYValue *)typeCheck:(NSArray *)args inLocation:(OYNode *)location {
    return [OYValue voidValue];
}
@end

@implementation OYSub


- (id)init {
    self = [super initWithName:@"-" arity:2];
    return self;
}

- (OYValue *)apply:(NSArray *)args inLocation:(OYNode *)location {
    OYValue *v1 = args[0];
    OYValue *v2 = args[1];

    if ([v1 isKindOfClass:[OYIntValue class]] && [v2 isKindOfClass:[OYIntValue class]]) {
        return [[OYIntValue alloc] initWithInteger:((OYIntValue *)v1).value - ((OYIntValue *)v2).value];
    } else if ([v1 isKindOfClass:[OYFloatValue class]] && [v2 isKindOfClass:[OYFloatValue class]]) {
        return [[OYFloatValue alloc] initWithValue:((OYFloatValue *)v1).value - ((OYFloatValue *)v2).value];
    } else if ([v1 isKindOfClass:[OYFloatValue class]] && [v2 isKindOfClass:[OYIntValue class]]) {
        return [[OYFloatValue alloc] initWithValue:((OYFloatValue *)v1).value - ((OYIntValue *)v2).value];

    } else if ([v1 isKindOfClass:[OYIntValue class]] && [v2 isKindOfClass:[OYFloatValue class]]) {
        return [[OYFloatValue alloc] initWithValue:((OYIntValue *)v1).value - ((OYFloatValue *)v2).value];
    }

    NSAssert(0,@"%@\n incorrect argument types for -: %@, %@", location, v1, v2);
    return nil;

}

- (OYValue *)typeCheck:(NSArray *)args inLocation:(OYNode *)location {
    OYValue *v1 = args[0];
    OYValue *v2 = args[1];

    if ([v1 isKindOfClass:[OYFloatType class]] || [v2 isKindOfClass:[OYFloatType class]]) {
        return [OYFloatType new];
    }
    if ([v1 isKindOfClass:[OYIntType class]] && [v2 isKindOfClass:[OYIntType class]]) {
        return [OYType intType];
    }

    NSAssert(0, @"%@\n incorrect argument types for -: %@, %@", location, v1, v2);
    return nil;
}

@end


@implementation OYU

- (id)init {
    self = [super initWithName:@"U" arity:-1];
    return self;
}

- (OYValue *)apply:(NSArray *)args inLocation:(OYNode *)location {
    return nil;
}

- (OYValue *)typeCheck:(NSArray *)args inLocation:(OYNode *)location {
    return [OYUnionType unionWithValues:args];
}
@end