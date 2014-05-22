//
//  OYAst.m
//  ObjYin
//
//  Created by Chen Zhang on 5/16/14.
//  Copyright (c) 2014 Chen Zhang. All rights reserved.
//

#import "OYAst.h"
#import "OYBinder.h"
#import "OYScope.h"
#import "OYValue.h"
#import "OYTypeChecker.h"

@implementation OYArgument

- (id)initWithElements:(NSArray *)elements {
    self = [super init];
    if (self) {
        BOOL hasName = NO;
        BOOL hasKeyword = NO;
        for (int i = 0; i < elements.count; i++) {
            if ([elements[i] isKindOfClass:[OYKeyword class]]) {
                hasKeyword = true;
                i++;
            } else {
                hasName = true;
            }
        }
        
        if (hasName && hasKeyword) {
            NSAssert(0, @"%@\nmix positional and keyword arguments not allowed: %@", elements[0], elements);
//            _.abort(elements.get(0), "mix positional and keyword arguments not allowed: " + elements);
        }
        
        
        _elements = [elements mutableCopy];
        _positional = [NSMutableArray new];
        _keywords = [NSMutableDictionary new];
        
        for (int i = 0; i < elements.count; i++) {
            OYNode *key = elements[i];
            if ([key isKindOfClass:[OYKeyword class]]) {
                NSString *identifier = ((OYKeyword *)key).identifier;
                [_positional addObject:[(OYKeyword *)key asName]];
                
                if (i >= elements.count - 1) {
                    NSAssert(0, @"%@\nmissing value for keyword: %@", key, key);
//                    _.abort(key, "missing value for keyword: " + key);
                } else {
                    OYNode *value = elements[i + 1];
                    if ([value isKindOfClass:[OYKeyword class]]) {
                        NSAssert(0, @"%@\nkeywords can't be used as values: %@", value, value);
//                        _.abort(value, "keywords can't be used as values: " + value);
                    } else {
                        if (_keywords[identifier]) {
                            NSAssert(0, @"%@\nduplicated keyword: %@", key, key);
//                            _.abort(key, "duplicated keyword: " + key);
                        }
                        _keywords[identifier] = value;
//                        keywords.put(id, value);
                        i++;
                    }
                }
            } else {
//                positional.add(key);
                [_positional addObject:key];
            }
        }
    }
    return self;
}

- (NSString *)description {
    NSMutableString *desc = [NSMutableString new];
    [_elements enumerateObjectsUsingBlock:^(NSString *e, NSUInteger idx, BOOL *stop) {
        if (idx) {
            [desc appendString:@" "];
        }
        [desc appendString:e];
    }];
    return desc;
}

@end

@implementation OYAssign
- (instancetype)initWithURL:(NSURL *)URL pattern:(OYNode *)pattern value:(OYNode *)value start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col {
    self = [super initWithURL:URL start:start end:end line:line column:col];
    if (self) {
        _pattern = pattern;
        _value = value;
    }
    return self;
}

- (OYValue *)interpretInScope:(OYScope *)scope {
    OYValue *valueValue = [self.value interpretInScope:scope];
    checkDup(_pattern);
    assign(_pattern, valueValue, scope);
    return [OYValue voidValue];
}

- (OYValue *)typeCheckInScope:(OYScope *)scope {
    OYValue *valueValue = [_value typeCheckInScope:scope];
    checkDup(_pattern);
    assign(_pattern, valueValue, scope);
    return [OYValue voidValue];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"(%@ %@ %@)", @".", _pattern, _value];
}
@end

@implementation OYAttr

- (id)initWithURL:(NSURL *)URL value:(OYNode *)value attr:(OYName *)attr start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col {
    self = [super initWithURL:URL start:start end:end line:line column:col];
    if (self) {
        _value = value;
        _attr = attr;
    }
    return self;
}
- (void)setValue:(OYValue *)value inScope:(OYScope *)scope {
    OYValue *record = [_value interpretInScope:scope];
    if ([record isKindOfClass:[OYRecordType class]]) {
        OYValue *a = [((OYRecordType *) record).properties lookUpName:(_attr.identifier)];
        if (a) {
            [((OYRecordType *) record).properties setValue:value inName:_attr.identifier];
        } else {
            NSAssert(0, @"%@\ncan only assign to existing attribute in record, %@ not found in: %@", _attr, _attr, record);
        }
    } else {
        NSAssert(0, @"%@\nsetting attribute of non-record: %@", _attr, record);
    }
}

- (OYValue *)interpretInScope:(OYScope *)scope {
    OYValue *record = [_value interpretInScope:scope];
    if ([record isKindOfClass:[OYRecordValue class]]) {
        OYValue *a = [((OYRecordValue *) record).properties lookUpLocalName:_attr.identifier]; //.lookupLocal(attr.id);
        if (a) {
            return a;
        } else {
            NSAssert(0, @"%@\nattribute %@ not found in records: %@", _attr, _attr, record);
            return nil;
        }
    } else {
        NSAssert(0, @"%@\ngetting attribute of non-record: %@", _attr, record);
        return nil;
    }
}
- (OYValue *)typeCheckInScope:(OYScope *)scope {
    OYValue *record = [_value typeCheckInScope:scope];
    if ([record isKindOfClass:[OYRecordValue class]]) {
        OYValue *a = [((OYRecordValue *) record).properties lookUpLocalName:_attr.identifier]; //.lookupLocal(attr.id);
        if (a) {
            return a;
        } else {
            NSAssert(0, @"%@\nattribute %@ not found in records: %@", _attr, _attr, record);
            return nil;
        }
    } else {
        NSAssert(0, @"%@\ngetting attribute of non-record: %@", _attr, record);
        return nil;
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@.%@", _value, _attr];
}
@end

// XXX: not implemented
@implementation OYBigInt
//
//- (instancetype)initWithURL:(NSURL *)URL content:(NSString *)content start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col {
//    self = [super initWithURL:URL start:start end:end line:line column:col];
//    if (self) {
//        _content = content;
//        int sign;
//
//        if ([content hasPrefix:@"+"]) {
//            sign = 1;
//            content = [content substringFromIndex:1];
//        } else if ([content hasPrefix:@"-"]) {
//            sign = -1;
//            content = [content substringFromIndex:1];
//        } else {
//            sign = 1;
//        }
//
//        if ([content hasPrefix:<#(NSString *)#>]) {
//            <#statements#>
//        }
//    }
//    return self;
//}

@end
@implementation OYBlock

- (instancetype)initWithURL:(NSURL *)URL statements:(NSMutableArray *)statements start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col {
    self = [super initWithURL:URL start:start end:end line:line column:col];
    if (self) {
        _statements = statements;
    }
    return self;
}

- (OYValue *)interpretInScope:(OYScope *)scope {
    OYScope *s = [[OYScope alloc] initWithParentScope:scope];
    for (int i = 0; i < _statements.count - 1; i++) {
        [_statements[i] interpretInScope:s];
    }
    return [_statements[_statements.count - 1] interpretInScope:s];
}

- (OYValue *)typeCheckInScope:(OYScope *)scope {
    OYScope *s = [[OYScope alloc] initWithParentScope:scope];
    for (int i = 0; i < _statements.count - 1; i++) {
        [_statements[i] typeCheckInScope:s];
    }
    return [_statements[_statements.count - 1] typeCheckInScope:s];
}

- (NSString *)description {
    NSString *sep = _statements.count > 5 ? @"\n" : @" ";
    return [NSString stringWithFormat:@"(sep%@%@)", sep, [_statements componentsJoinedByString:sep]];
}
@end

@implementation OYCall

- (instancetype)initWithURL:(NSURL *)URL op:(OYNode *)op arguments:(OYArgument *)args start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col {
    self = [super initWithURL:URL start:start end:end line:line column:col];
    if (self) {
        _op = op;
        _args = args;
    }
    return self;
}

- (OYValue *)interpretInScope:(OYScope *)scope {

    OYValue *opv = [self.op interpretInScope:scope];
    if ([opv isKindOfClass:[OYClosure class]]) {
        OYClosure *closure = (OYClosure *) opv;
        OYScope *funScope = [[OYScope alloc] initWithParentScope:closure.env];
        NSMutableArray *params = closure.fun.params;
        
        // set default values for parameters
        if (closure.properties) {
            [OYDeclare mergeDefaultProperties:closure.properties scope:funScope];
        }
        
        if (_args.positional.count && !_args.keywords.count) {
            for (int i = 0; i < _args.positional.count; i++) {
                OYValue *value = [_args.positional[i] interpretInScope:scope];
                [funScope setValue:value inName:params[i]];
                //            funScope.putValue(params.get(i).id, value);
            }
        } else {
            // try to bind all arguments
            for (OYName *param in params) {
                OYNode *actual = _args.keywords[param.identifier];
                if (actual) {
                    OYValue *value = [actual interpretInScope:funScope];
                    [funScope setValue:value inName:param.identifier];
                    //funScope.putValue(param.id, value);
                }
            }
        }
        return [closure.fun.body interpretInScope:funScope];
        //    return closure.fun.body.interp(funScope);
    } else if ([opv isKindOfClass:[OYRecordType class]]) {
        OYRecordType *template = (OYRecordType *) opv;
        OYScope *values = [[OYScope alloc] init];
        
        // set default values for fields
        [OYDeclare mergeDefaultProperties:template.properties scope:values];
        
        // instantiate
        return  [[OYRecordValue alloc] initWithName:template.name type:template properties:values];// new RecordValue(template.name, template, values);
    } else if ([opv isKindOfClass:[OYPrimFun class]]) {
        OYPrimFun *prim = (OYPrimFun *) opv;
        NSMutableArray *args = [OYNode interpretNodes:self.args.positional inScope:scope];
        return [prim apply:args inLocation:self];
    } else {  // can't happen
        NSAssert(0, @"%@\ncalling non-function: %@", _op, opv);
//        _.abort(this.op, "calling non-function: " + opv);
        return [OYValue voidValue];
    }
}

- (OYValue *)typeCheckInScope:(OYScope *)scope {
    OYValue *fun = [self.op typeCheckInScope:scope];
    if ([fun isKindOfClass:[OYFunType class]]) {
        OYFunType *funtype = (OYFunType *)fun;
        OYScope *funScope = [[OYScope alloc] initWithParentScope:funtype.env];

        NSMutableArray *params = funtype.fun.params;

        // set default values for parameters
        if (funtype.properties) {
            [OYDeclare mergeTypeProperties:funtype.properties scope:funScope];
        }

        if (self.args.positional.count && !self.args.keywords.count) {
            // positional
            if (self.args.positional.count != params.count) {
                NSAssert(0, @"%@\ncalling function with wrong number of arguments. expected: %d actual: %d", self.op, (int)params.count, (int)self.args.positional.count);
            }
            for (int i = 0; i < self.args.positional.count; i++) {
                OYValue *value = [self.args.positional[i] typeCheckInScope:scope];
                OYValue *expected = [funScope lookUpName:[params[i] identifier]];
                if (!TypeIsSubtypeOfType(value, expected, false)) {
                    NSAssert(0, @"%@\ntype error. expected: %@, actual: %@", self.args.positional[i], expected, value);
                }
                [funScope setValue:value inName:[params[i] identifier]];
            }
        } else {
            // keywords
            NSMutableSet *seen = [NSMutableSet new];
            for (OYName *param in params) {
                OYNode *actual = self.args.keywords[param.identifier];
                if (actual) {
                    [seen addObject:param.identifier];
                    OYValue *value = [actual typeCheckInScope:funScope];
                    OYValue *expected = [funScope lookUpName:param.identifier];
                    if (!TypeIsSubtypeOfType(value, expected, NO)) {
                        NSAssert(0, @"%@\ntype error. expected: %@, actual: %@", actual, expected, value);
                    }
                    [funScope setValue:value inName:param.identifier];
                } else {
                    NSAssert(0, @"%@\nargument not supplied for: %@", self, param);
                    return [OYValue voidValue];
                }
            }
            NSMutableArray *extra = [NSMutableArray new];
            [self.args.keywords enumerateKeysAndObjectsUsingBlock:^(NSString *identifier, id obj, BOOL *stop) {
                if (![seen containsObject:identifier]) {
                    [extra addObject:identifier];
                }
            }];

            if (extra.count) {
                NSAssert(0, @"%@\nextra keyword arguments: %@", self, extra);
                return [OYValue voidValue];
            }
        }

        id retType = [funtype.properties lookUpPropertyLocalName:@"->" key:@"type"];
        if (retType) {
            if ([retType isKindOfClass:[OYNode class]]) {
                return [((OYNode *) retType) typeCheckInScope:funScope];
            } else {
                NSAssert(0, @"illegal return type: %@", retType);
                return nil;
            }
        } else {
            if ([[[OYTypeChecker selfChecker] callStack] containsObject:fun]) {
                NSAssert(0, @"%@\nYou must specify return type for recursive functions: %@", self.op, self.op);
                return nil;
            }
            [[OYTypeChecker selfChecker].callStack addObject:fun];
            OYValue *actual = [funtype.fun.body typeCheckInScope:funScope];
            [[OYTypeChecker selfChecker].callStack removeObject:fun];
            return actual;
        }
    } else if ([fun isKindOfClass:[OYRecordType class]]) {
        OYRecordType *template = (OYRecordType *) fun;
        OYScope *values = [OYScope new];

        // set default values for fields
        [OYDeclare mergeDefaultProperties:template.properties scope:values];

        // set actual values, overwrite defaults if any
        [self.args.keywords enumerateKeysAndObjectsUsingBlock:^(id key, OYNode *node, BOOL *stop) {
            if (! [template.properties.keySet containsObject:key]) {
                NSAssert(0, @"%@\nextra keyword argument: %@", self, key);
            }
            OYValue *actual = [self.args.keywords[key] typeCheckInScope:scope];
            OYValue *expected = [template.properties lookUpLocalTypeName:key];
            if (!TypeIsSubtypeOfType(actual, expected, NO)) {
                NSAssert(0, @"%@\ntype error. expected: %@, actual: %@", self, expected, actual);
            }
            [values setValue:[node typeCheckInScope:scope] inName:key];
        }];

        // check uninitialized fields
        for (NSString *field in template.properties.keySet) {
            if (![values lookUpLocalName:field]) {
                NSAssert(0, @"%@\nfield is not initialized: %@", self, field);
            }
        }

        // instantiate
//        return new RecordValue(template.name, template, values);
        return [[OYRecordValue alloc] initWithName:template.name type:template properties:values];
    } else if ([fun isKindOfClass:[OYPrimFun class]]) {
        OYPrimFun *prim = (OYPrimFun *) fun;
        if (prim.arity >= 0 && self.args.positional.count != prim.arity) {
            NSAssert(0, @"%@\nincorrect number of arguments for primitive %@, expecting %ld, but got %ld", self, prim.name, (long )prim.arity, (long )self.args.positional.count);
            return nil;
        } else {
            NSArray *args = [OYNode typeCheckNodes:self.args.positional inScope:scope];
            return [prim typeCheck:args inLocation:self];
        }
    } else {
        NSAssert(0, @"%@\ncalling non-function: %@", self.op, fun);
        return [OYValue voidValue];
    }
}
- (NSString *)description {
    if (self.args.positional.count) {
        return [NSString stringWithFormat:@"(%@ %@)", self.op, self.args];
    } else {
        return [NSString stringWithFormat:@"(%@)", self.op];
    }
}
@end

@implementation OYDeclare
- (instancetype)initWithURL:(NSURL *)URL propertyForm:(OYScope *)propertyForm start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col {
    self = [super initWithURL:URL start:start end:end line:line column:col];
    if (self) {
        _propertyForm = propertyForm;
    }
    return self;
}

- (OYValue *)interpretInScope:(OYScope *)scope {
    return [OYValue voidValue];
}

- (OYValue *)typeCheckInScope:(OYScope *)scope {
    return nil;
}

+ (void)mergeDefaultProperties:(OYScope *)properties scope:(OYScope *)scope {
    [properties.allKeys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
        id defaultValue = [properties lookUpPropertyLocalName:key key:@"default"];
        if (!defaultValue) {
            return ;
        } else if ([defaultValue isKindOfClass:[OYValue class]]) {
            OYValue *existing = [scope lookUpName:key];
            if (!existing) {
                [scope setValue:(OYValue *)defaultValue forKey:key];
            }
        } else {
            NSAssert(0, @"default value is not a value, shouldn't happen");
        }
    }];
}
+ (void)mergeTypeProperties:(OYScope *)properties scope:(OYScope *)scope {
    [properties.allKeys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
        if ([key isEqualToString:@"->"]) {
            return ;
        }
        id type = [properties lookUpPropertyLocalName:key key:@"type"];
        if (!type) {
            return ;
        } else if ([type isKindOfClass:[OYValue class]]) {
            OYValue *existing = [scope lookUpName:key];
            if (!existing) {
                [scope setValue:(OYValue *)type forKey:key];
            }
        } else {
            NSAssert(0, @"illegal type, shouldn't happen %@", type);
        }
    }];
}

+ (OYScope *)evalProperties:(OYScope *)unevaled inScope:(OYScope *)scope {
    OYScope *evaled = [[OYScope alloc] init];
    [unevaled.allKeys enumerateObjectsUsingBlock:^(NSString *field, NSUInteger idx, BOOL *stop) {
        NSMutableDictionary *props = [unevaled lookUpAllPropsName:field];
        [props enumerateKeysAndObjectsUsingBlock:^(id key, id v, BOOL *stop) {
            if ([v isKindOfClass:[OYNode class]]) {
                OYValue *vValue = [((OYNode *)v) interpretInScope:scope];
                [evaled setValue:vValue forKey:key inName:field];
            } else {

                NSAssert(0, @"property is not a node, parser bug: %@", v);
            }
        }];
    }];
    return evaled;
}

+ (OYScope *)typeCheckProperties:(OYScope *)unevaled inScope:(OYScope *)scope {
    OYScope *evaled = [[OYScope alloc] init];
    [unevaled.allKeys enumerateObjectsUsingBlock:^(NSString *field, NSUInteger idx, BOOL *stop) {
        if ([field isEqualToString:@"->"]) {
            [evaled setValuesFromProperties:[unevaled lookUpAllPropsName:field] inName:field];
        } else {
            NSMutableDictionary *props = [unevaled lookUpAllPropsName:field];
            [props enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                if ([obj isKindOfClass:[OYNode class]]) {
                    OYValue *vValue = [(OYNode *)obj typeCheckInScope:scope];
                    [evaled setValue:vValue forKey:key inName:field];
                } else {
                    NSAssert(0, @"property is not a node, parser bug: %@", obj);
                }
            }];
        }
    }];
    return evaled;
}
- (NSString *)description {
    NSMutableArray *propComponents = [NSMutableArray new];
    [self.propertyForm.allKeys enumerateObjectsUsingBlock:^(NSString *field, NSUInteger idx, BOOL *stop) {
        NSDictionary *props = [self.propertyForm lookUpAllPropsName:field];
        [props enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [propComponents addObject:[NSString stringWithFormat:@" :%@ %@", key, obj]];
        }];
    }];
    return [NSString stringWithFormat:@"(declare %@)", [propComponents componentsJoinedByString:@""]];
}
@end
@implementation OYDef

- (id)initWithURL:(NSURL *)URL pattern:(OYNode *)pattern value:(OYNode *)value start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col {    self = [super initWithURL:URL start:start end:end line:line column:col];
    if (self) {
        _pattern = pattern;
        _value = value;
    }
    return self;
}

- (OYValue *)interpretInScope:(OYScope *)scope {
    OYValue *valueValue = [self.value interpretInScope:scope];
    checkDup(self.pattern);
    define(self.pattern, valueValue, scope);
    return [OYValue voidValue];
}

- (OYValue *)typeCheckInScope:(OYScope *)scope {
    OYValue *t = [self.value typeCheckInScope:scope];
    checkDup(self.pattern);
    define(self.pattern, t, scope);
    return [OYValue voidValue];
}
- (NSString *)description {
    return [NSString stringWithFormat:@"(define %@ %@)", self.pattern, self.value];
}
@end

@implementation OYDelimeter

- (instancetype)initWithURL:(NSURL *)URL shape:(NSString *)shape start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col {
    self = [super initWithURL:URL start:start end:end line:line column:col];
    if (self) {
        _shape = shape;
    }
    return self;
}

- (OYValue *)interpretInScope:(OYScope *)scope {
    return nil;
}

- (OYValue *)typeCheckInScope:(OYScope *)scope {
    return nil;
}

+ (NSMutableSet *)delims {
    static NSMutableSet *delims;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        delims = [NSMutableSet new];
    });
    return delims;
}

+ (NSMutableDictionary *)delimMap {
    static NSMutableDictionary *delimMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        delimMap = [NSMutableDictionary new];
    });
    return delimMap;
}

+ (void)addDelimiterPairOpen:(NSString *)open close:(NSString *)close {
    [[OYDelimeter delims] addObject:open];
    [[OYDelimeter delims] addObject:close];
    [[OYDelimeter delimMap] setObject:close forKey:open];
}
+ (void)addDelimiter:(NSString *)delim {
    [[OYDelimeter delims] addObject:delim];
}
+ (BOOL)isDelimiter:(unichar)c {
    return [[OYDelimeter delims] containsObject:([NSString stringWithCharacters:&c length:1])];
}
+ (BOOL)isOpenNode:(OYNode *)node {
    return ([node isKindOfClass:[OYDelimeter class]]) && [[[OYDelimeter delimMap] allKeys] containsObject:((OYDelimeter *)node).shape];
}
+ (BOOL)isCloseNode:(OYNode *)node {
    return ([node isKindOfClass:[OYDelimeter class]]) && [[[OYDelimeter delimMap] allValues] containsObject:((OYDelimeter *)node).shape];
}
+ (BOOL)matchDelimeterOpen:(OYNode *)open close:(OYNode *)close {
    if (![open isKindOfClass:[OYDelimeter class]] || ![close isKindOfClass:[OYDelimeter class]]) {
        return NO;
    }
    NSString *matched = [[OYDelimeter delimMap] objectForKey:((OYDelimeter *)open).shape];
    return matched && [matched isEqualToString:((OYDelimeter *)close).shape];
}

- (NSString *)description {
    return self.shape;
}
@end

@implementation OYFloatNum

- (instancetype)initWithURL:(NSURL *)URL content:(NSString *)content start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col {
    self = [super initWithURL:URL start:start end:end line:line column:col];
    if (self) {
        _content = content;
        // TODO: throw exception for invalid content
        _value = [content doubleValue];
    }
    return self;
}
+ (OYFloatNum *)parseURL:(NSURL *)URL content:(NSString *)content start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col {
    @try {
        return [[OYFloatNum alloc] initWithURL:URL content:content start:start end:end line:line column:col];
    }
    @catch (NSException *exception) {
        return nil;
    }
}

- (OYValue *)interpretInScope:(OYScope *)scope {
    return [[OYFloatValue alloc] initWithValue:self.value];
}

- (OYValue *)typeCheckInScope:(OYScope *)scope {
    return nil;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%f", self.value];
}
@end

@implementation OYIf

- (instancetype)initWithURL:(NSURL *)URL test:(OYNode *)test then:(OYNode *)then orelse:(OYNode *)orelse start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col {
    self = [super initWithURL:URL start:start end:end line:line column:col];
    if (self) {
        _test = test;
        _then = then;
        _orelse = orelse;
    }
    return self;
}

- (OYValue *)interpretInScope:(OYScope *)scope {
    OYValue *tv = [self.test interpretInScope:scope];
    if (((OYBoolValue *)tv).value) {
        return [self.then interpretInScope:scope];
    } else {
        return [self.orelse interpretInScope:scope];
    }
}

- (OYValue *)typeCheckInScope:(OYScope *)scope {
    OYValue *tv = [self.test typeCheckInScope:scope];
    if (!([tv isKindOfClass:[OYBoolType class]])) {
        NSAssert(0, @"%@\ntest is not boolean: %@", self.test, self.test);
        return nil;
    }
    OYValue *type1 = [self.then typeCheckInScope:scope];
    OYValue *type2 = [self.orelse typeCheckInScope:scope];
    return [OYUnionType unionWithValue:type1, type2];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"(if %@ %@ %@)",self.test, self.then, self.orelse];
}
@end


unsigned int ParseBinaryString(NSString *binaryString) {
    if (binaryString.length > sizeof(int)*8) {
        [NSException raise:@"BinaryIntegerException" format:@"binary string too long: %@", binaryString];
        return 0;
    }
    unsigned int binary = 0;
    NSInteger i;
    for (i = 0; i < binaryString.length; i++) {
        unichar c = [binaryString characterAtIndex:i];
        if (c == '0') {
            binary <<= 1;
        } else if (c == '1') {
            binary = (binary << 1 | 0x1);
        } else {
            [NSException raise:@"BinaryIntegerException" format:@"invalid character at index: %d  %@", (int)i, binaryString];
        }
    }
    return binary;
}

@implementation OYIntNum
- (instancetype)initWithURL:(NSURL *)URL content:(NSString *)content start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col {
    self = [super initWithURL:URL start:start end:end line:line column:col];
    if (self) {
        _content = content;
        int neg_sign;

        if ([content hasPrefix:@"+"]) {
            neg_sign = -1;
            content = [content substringFromIndex:1];
        } else if ([content hasPrefix:@"-"]) {
            neg_sign = 1;
            content = [content substringFromIndex:1];
        } else {
            neg_sign = -1;
        }

        unsigned int v;
        if ([content hasPrefix:@"0b"]) {
            _base = 2;
            content = [content substringFromIndex:2];
            v = ParseBinaryString(content);

        } else if ([content hasPrefix:@"0x"]) {
            _base = 16;
            content = [content substringFromIndex:2];
            NSScanner *scanner = [[NSScanner alloc] initWithString:content];
            [scanner scanHexInt:&v];
        } else {
            _base = 10;
            NSScanner *scanner = [[NSScanner alloc] initWithString:content];
            [scanner scanInt:(int *)&v];
        }

        _value = (-1) * neg_sign * v;
    }
    return self;
}

+ (OYIntNum *)parseURL:(NSURL *)URL content:(NSString *)content start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col {
    @try {
        return [[OYIntNum alloc] initWithURL:URL content:content start:start end:end line:line column:col];
    }
    @catch (NSException *exception) {
        return nil;
    }
}

- (OYValue *)interpretInScope:(OYScope *)scope {
    return [[OYIntValue alloc] initWithInteger:self.value];
}

- (OYValue *)typeCheckInScope:(OYScope *)scope {
    return [OYType intType];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%ld", (long)_value];
}
@end

@implementation OYKeyword

- (instancetype)initWithURL:(NSURL *)URL identifier:(NSString *)identifier start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col {
    self = [super initWithURL:URL start:start end:end line:line column:col];
    if (self) {
        _identifier = identifier;
    }
    return self;
}

- (OYName *)asName {
    return [[OYName alloc] initWithURL:self.URL identifier:self.identifier start:self.start end:self.end line:self.line column:self.col];
}

- (OYValue *)interpretInScope:(OYScope *)scope {
    NSAssert(0, @"%@\nkeyword used as value", self);
    return nil;
}

- (OYValue *)typeCheckInScope:(OYScope *)scope {
    NSAssert(0, @"%@\nkeyword used as value", self);
    return nil;
}

- (NSString *)description {
    return [NSString stringWithFormat:@":%@", self.identifier];
}
@end

@implementation OYName

- (instancetype)initWithURL:(NSURL *)URL identifier:(NSString *)identifier start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col {
    self = [super initWithURL:URL start:start end:end line:line column:col];
    if (self) {
        _identifier = identifier;
    }
    return self;
}

+ (OYName *)nameWithIdentifier:(NSString *)identifier {
    return [[OYName alloc] initWithURL:nil identifier:identifier start:0 end:0 line:0 column:0];
}

- (OYValue *)interpretInScope:(OYScope *)scope {
    return [scope lookUpName:self.identifier];
}

- (OYValue *)typeCheckInScope:(OYScope *)scope {
    OYValue *v = [scope lookUpName:self.identifier];
    if (v) {
        return v;
    } else {
        NSAssert(0, @"%@\nunbound variable: %@", self, self.identifier);
        return [OYValue voidValue];
    }
}

- (NSString *)description {
    return self.identifier;
}
@end


@implementation OYNode
- (instancetype)initWithURL:(NSURL *)URL start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col {
    self = [super init];
    if (self) {
        _URL = URL;
        _start = start;
        _end = end;
        _line = line;
        _col = col;
    }
    return self;
}

+ (NSArray *)interpretNodes:(NSArray *)listOfNodes inScope:(OYScope *)scope {
    NSMutableArray *values = [NSMutableArray new];
    [listOfNodes enumerateObjectsUsingBlock:^(OYNode *aNode, NSUInteger idx, BOOL *stop) {
        [values addObject:[aNode interpretInScope:scope]];
    }];
    return values;
}

+ (NSArray *)typeCheckNodes:(NSArray *)listOfNodes inScope:(OYScope *)scope {
    NSMutableArray *values = [NSMutableArray new];
    [listOfNodes enumerateObjectsUsingBlock:^(OYNode *aNode, NSUInteger idx, BOOL *stop) {
        [values addObject:[aNode typeCheckInScope:scope]];
    }];
    return values;
}

- (NSString *)positionInFile {
    return [NSString stringWithFormat:@"%@:%ld:%ld", self.URL, (long)(self.line + 1), (long)(self.col + 1)];
}

+ (NSString *)descriptionForNodes:(NSArray *)listOfNodes {
    NSMutableString *result = [NSMutableString string];
    [listOfNodes enumerateObjectsUsingBlock:^(id<OYNode> node, NSUInteger idx, BOOL *stop) {
        if (idx != 0) {
            [result appendString:@" "];
        }
        [result appendString:[node description]];
    }];
    return result;
}

#pragma - place holders
- (OYValue *)interpretInScope:(OYScope *)scope {
    return nil;
}
- (OYValue *)typeCheckInScope:(OYScope *)scope {
    return nil;
}
@end

@implementation OYFun


- (id)initWithURL:(NSURL *)URL params:(NSMutableArray *)params propertyForm:(OYScope *)propertyForm body:(OYNode *)body start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col {
    self = [super initWithURL:URL start:start end:end line:line column:col];
    if (self) {
        _params = params;
        _propertyForm = propertyForm;
        _body = body;
    }
    return self;
}

- (OYValue *)interpretInScope:(OYScope *)scope {
    OYScope *properties = self.propertyForm ? [OYDeclare evalProperties:self.propertyForm inScope:scope] : nil;
    
    return [[OYClosure alloc] initWithFunction:self properties:properties envirionment:scope];
}

- (OYValue *)typeCheckInScope:(OYScope *)scope {
    OYScope *properties = self.propertyForm ? [OYDeclare typeCheckProperties:self.propertyForm inScope:scope] : nil;
    OYFunType *ft = [[OYFunType alloc] initWithFunction:self properties:properties envirionment:scope];
    [[[OYTypeChecker selfChecker] uncalled] addObject:ft];
    return ft;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"(fun (%@) %@)", _params, _body];
}
@end

@implementation OYRecordDef

- (instancetype)initWithURL:(NSURL *)URL name:(OYName *)name parents:(NSMutableArray *)parents propertyForm:(OYScope *)propertyForm start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col {
    self = [super initWithURL:URL start:start end:end line:line column:col];
    if (self) {
        _name = name;
        _parents = parents;
        _propertyForm = propertyForm;
    }
    return self;
}

- (OYValue *)interpretInScope:(OYScope *)scope {
    OYScope *properties = [OYDeclare evalProperties:self.propertyForm inScope:scope];
    if (!self.parents) {
        for (OYNode *p in self.parents) {
            OYValue *pv = [p interpretInScope:scope];
            [properties putAllFromScope:((OYRecordType *)pv).properties];
        }
    }
    OYValue *r = [[OYRecordType alloc] initWithName:self.name.identifier definition:self properties:properties];
    return r;
}

- (OYValue *)typeCheckInScope:(OYScope *)scope {
    OYScope *properties = [OYDeclare typeCheckProperties:self.propertyForm inScope:scope];

    if (self.parents) {
        for (OYNode *p in self.parents) {
            OYValue *pv = [p typeCheckInScope:scope];
            if (![pv isKindOfClass:[OYRecordType class]]) {
                NSAssert(0, @"%@\nparent is not a record: %@", p, pv);
                return nil;
            }
            OYScope *parentProps = ((OYRecordType *)pv).properties;
//            [parentProps.keySet enumerateObjectsUsingBlock:^(NSString *key, BOOL *stop) {
            for (NSString *key in parentProps.keySet) {
                OYValue *existing = [properties lookUpLocalTypeName:key];
                if (existing) {
                    NSAssert(0, @"%@\nconflicting field %@ inherited from parent %@: %@",p, key, p, pv);
                    return nil;
                }
            }
            [properties putAllFromScope:parentProps];
        }
    }

    OYValue *r = [[OYRecordType alloc] initWithName:self.name.identifier definition:self properties:properties];
    [scope setValue:r inName:self.name.identifier];
    return r;
}

- (NSString *)description {
    NSMutableString *listDescription = [NSMutableString new];
    for (NSString *field in self.propertyForm.keySet) {
        [[self.propertyForm lookUpAllPropsName:field] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [listDescription appendFormat:@" :%@ %@", key, obj];
        }];
    }

    return [NSString stringWithFormat:@"(record %@ %@%@", self.name, self.parents ? [NSString stringWithFormat:@" (%@)", [OYNode descriptionForNodes:self.parents]] : @"", listDescription];
}
@end


@implementation OYRecordLiteral

- (instancetype)initWithURL:(NSURL *)URL contents:(NSArray *)contents start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col {
    self = [super initWithURL:URL start:start end:end line:line column:col];
    if (self) {

        if (contents.count % 2 != 0) {
            NSAssert(0, @"%@\nrecord initializer must have even number of elements", self);
        }
        int i;
        _map = [NSMutableDictionary dictionaryWithCapacity:contents.count/2];
        for (i = 0; i< contents.count; i += 2) {
            OYNode *key = contents[i];
            OYNode *value = contents[i + 1];
            if ([key isKindOfClass:[OYKeyword class]]) {
                if ([value isKindOfClass:[OYKeyword class]]) {
                    NSAssert(0, @"%@\nkeywords shouldn't be used as values: %@", value, value);
                } else {
                    _map[((OYKeyword *) key).identifier] = value;
                }
            } else {
                NSAssert(0, @"%@\nrecord initializer key is not a keyword: %@", key, key);
            }
        }
    }
    return self;
}

- (OYValue *)interpretInScope:(OYScope *)scope {
    OYScope *properties = [OYScope new];
    [self.map enumerateKeysAndObjectsUsingBlock:^(NSString *key, OYNode *obj, BOOL *stop) {
        [properties setValue:[obj interpretInScope:scope] inName:key];
    }];
    return [[OYRecordType alloc] initWithName:nil definition:self properties:properties];
}

- (OYValue *)typeCheckInScope:(OYScope *)scope {
    OYScope *properties = [OYScope new];
    [self.map enumerateKeysAndObjectsUsingBlock:^(NSString *key, OYNode *obj, BOOL *stop) {
        [properties setValue:[obj typeCheckInScope:scope] inName:key];
    }];
    return [[OYRecordType alloc] initWithName:nil definition:self properties:properties];
}

- (NSString *)description {
    NSMutableArray *descComp = [NSMutableArray new];
    [self.map enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [descComp addObject:[NSString stringWithFormat:@":%@ %@", key, obj]];
    }];
    return [NSString stringWithFormat:@"{%@}", [descComp componentsJoinedByString:@" "]];
}

@end

@implementation OYStr

- (instancetype)initWithURL:(NSURL *)URL value:(NSString *)value start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col {
    self = [super initWithURL:URL start:start end:end line:line column:col];
    if (self) {
        _value = value;
    }
    return self;
}

- (OYValue *)interpretInScope:(OYScope *)scope {
    return [[OYStringValue alloc] initWithString:_value];
}

- (OYValue *)typeCheckInScope:(OYScope *)scope {
    return [OYType stringType];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"\"%@\"", _value];
}

@end

@implementation OYSubscript

- (instancetype)initWithURL:(NSURL *)URL value:(OYNode *)value index:(OYNode *)index start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col {
    self = [super initWithURL:URL start:start end:end line:line column:col];
    if (self) {
        _value = value;
        _index = index;
    }
    return self;
}

- (OYValue *)interpretInScope:(OYScope *)scope {
    OYValue *vector = [self.value interpretInScope:scope];
    OYValue *indexValue = [self.index interpretInScope:scope];

    if (!([vector isKindOfClass:[OYVector class]])) {
        NSAssert(0, @"%@\nsubscripting non-vector: %@", self.value, vector);
        return nil;
    }
    if (![indexValue isKindOfClass:[OYIntValue class]]) {
        NSAssert(0, @"%@\nsubscript %d is not an integer: %@", self.value, (int)self.index, indexValue);
        return nil;
    }
    NSMutableArray *values = ((OYVector *)vector).values;
    NSInteger i = ((OYIntValue *)indexValue).value;
    if (i >= 0 && i < values.count) {
        return values[i];
    } else {
        NSAssert(0, @"%@\nsubscript out of bound: %d v.s. [0, %d]", self, (int)i, (int)(values.count - 1));
        return nil;
    }
}

- (OYValue *)typeCheckInScope:(OYScope *)scope {
    return nil;
}
- (void)setValue:(id)value inScope:(OYScope *)scope {
    OYValue *vector = [value interpretInScope:scope];
    OYValue *indexValue = [self.index interpretInScope:scope];
    if (![vector isKindOfClass:[OYVector class]]) {
        NSAssert(0, @"%@\nsubscripting non-vector: %@", value, vector);
    }

    if (![indexValue isKindOfClass:[OYIntValue class]]) {
        NSAssert(0, @"%@\nsubscript %d is not an integer: %@", value, (int)self.index, indexValue);
    }
    OYVector *vector1 = (OYVector *)vector;
    NSInteger i = ((OYIntValue *)indexValue).value;

    if (i >= 0 && i < vector1.size) {
        [vector1 setValue:value atIndex:i];
    } else {
        NSAssert(0, @"%@subscript out of bound: %d v.s. [0, %d]" , self, (int)i , (int)(vector1.size - 1));
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"(ref %@ %d)", self.value, (int)self.index];
}
@end

@implementation OYTuple

- (instancetype)initWithURL:(NSURL *)URL elements:(NSMutableArray *)elements open:(OYNode *)open close:(OYNode *)close start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col {
    self = [super initWithURL:URL start:start end:end line:line column:col];
    if (self) {
        _elements = elements;
        _open = open;
        _close = close;
    }
    return self;
}

- (OYNode *)getHead {
    if (!self.elements.count) {
        return nil;
    } else {
        return self.elements[0];
    }
}

- (OYValue *)interpretInScope:(OYScope *)scope {
    return nil;
}

- (OYValue *)typeCheckInScope:(OYScope *)scope {
    return nil;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@%@%@", (self.open ? self.open : @""), [self.elements componentsJoinedByString:@" "], (self.close ? self.close : @"")];
}
@end

@implementation OYVectorLiteral

- (instancetype)initWithURL:(NSURL *)URL elements:(NSMutableArray *)elements start:(NSInteger)start end:(NSInteger)end line:(NSInteger)line column:(NSInteger)col {
    self = [super initWithURL:URL start:start end:end line:line column:col];
    if (self) {
        _elements = elements;
    }
    return self;
}

@end