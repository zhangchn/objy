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