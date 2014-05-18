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