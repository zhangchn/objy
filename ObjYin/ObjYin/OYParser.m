//
//  OYParser.m
//  ObjYin
//
//  Created by Chen Zhang on 5/18/14.
//  Copyright (c) 2014 Chen Zhang. All rights reserved.
//

#import "OYParser.h"
#import "OYScope.h"
#import "OYValue.h"
#import "OYPreParser.h"
#import "OYAst.h"
#import "OYParserException.h"

OYNode *parseURL(NSURL *URL) {
    OYPreParser *preparser = [[OYPreParser alloc] initWithURL:URL];
    OYNode *prenode = [preparser parse];
    return parseNode(prenode);
}

id parseIncompleteString(NSString *string) {
    OYPreParser *preparser = [[OYPreParser alloc] initWithString:string];
    id prenode = [preparser parseIncomplete];
    if ([prenode isKindOfClass:[NSError class]]) {
        return prenode;
    }
    return parseNode(prenode);
}


OYNode *parseNode(OYNode *prenode) {
    
    if (!([prenode isKindOfClass:[OYTuple class]])) {
        // Case 1: node is not of form (..) or [..], return the node itself
        return prenode;
    } else {

        // Case 2: node is of form (..) or [..]
        OYTuple *tuple = (OYTuple *)prenode;
        NSMutableArray *elements = tuple.elements;

        if (delimType(tuple.open, @"[")) {
            // Case 2.1: node is of form [..]
            return [[OYVectorLiteral alloc] initWithURL:tuple.URL elements:parseList(elements) start:tuple.start end:tuple.end line:tuple.line column:tuple.col];
        } else {
            // Case 2.2: node is (..)
            if (!elements.count) {
                [[[OYParserException alloc] initWithMessage:@"syntax error" node:tuple] raise];
                return nil;
            } else {
                // Case 2.2.2: node is of form (keyword ..)
                OYNode *keyNode = elements[0];

                if ([keyNode isKindOfClass:[OYName class]]) {
                    NSString *identifier = ((OYName *)keyNode).identifier;
                    if ([identifier isEqualToString:@"seq"]) {
                        return parseBlock(tuple);
                    } else if ([identifier isEqualToString:@"if"]) {
                        return parseIf(tuple);
                    } else if ([identifier isEqualToString:@"define"]) {
                        return parseDef(tuple);
                    } else if ([identifier isEqualToString:@"set!"]) {
                        return parseAssign(tuple);
                    } else if ([identifier isEqualToString:@"declare"]) {
                        return parseDeclare(tuple);
                    } else if ([identifier isEqualToString:@"fun"]) {
                        return parseFun(tuple);
                    } else if ([identifier isEqualToString:@"record"]) {
                        return parseRecordDef(tuple);
                    } else {
                        return parseCall(tuple);
                    }
                } else {
                    // applications whose operator is not a name
                    // e.g. ((foo 1) 2)
                    return parseCall(tuple);
                }
            }
        }
    }
}

OYBlock *parseBlock(OYTuple *tuple) {
    NSMutableArray *elements = tuple.elements;
    NSMutableArray *statements = parseList([elements subarrayWithRange:NSMakeRange(1, elements.count - 1)]);
//    [[[OYParserException alloc] initWithMessage:@"syntax error" node:tuple] raise];
    return [[OYBlock alloc] initWithURL:tuple.URL statements:statements start:tuple.start end:tuple.end line:tuple.line column:tuple.col];
}

OYIf *parseIf(OYTuple *tuple){
    NSMutableArray *elements = tuple.elements;
    if (elements.count != 4) {
        [[[OYParserException alloc] initWithMessage:@"incorrect format of if" node:tuple] raise];
    }
    OYNode *test = parseNode(elements[1]);
    OYNode *conseq = parseNode(elements[2]);
    OYNode *alter = parseNode(elements[3]);
    return [[OYIf alloc] initWithURL:tuple.URL test:test then:conseq orelse:alter start:tuple.start end:tuple.end line:tuple.line column:tuple.col];
}

OYDef *parseDef(OYTuple *tuple) {
    NSMutableArray *elements = tuple.elements;
    if (elements.count != 3) {
        [[[OYParserException alloc] initWithMessage:@"incorrect format of definition" node:tuple] raise];
    }
    OYNode *pattern = parseNode(elements[1]);
    OYNode *value = parseNode(elements[2]);
    return [[OYDef alloc] initWithURL:tuple.URL pattern:pattern value:value start:tuple.start end:tuple.end line:tuple.line column:tuple.col];
}

OYAssign *parseAssign(OYTuple *tuple) {
    NSMutableArray *elements = tuple.elements;
    if (elements.count != 3) {
        [[[OYParserException alloc] initWithMessage:@"incorrect format of assignment" node:tuple] raise];
    }
    OYNode *pattern = parseNode(elements[1]);
    OYNode *value = parseNode(elements[2]);
    return [[OYAssign alloc] initWithURL:tuple.URL pattern:pattern value:value start:tuple.start end:tuple.end line:tuple.line column:tuple.col];
}

OYDeclare *parseDeclare(OYTuple *tuple) {
    NSMutableArray *elements = tuple.elements;

    if (elements.count < 2) {
        [[[OYParserException alloc] initWithMessage:@"syntax error in record type definition" node:tuple] raise];
    }
    OYScope *properties = parseProperties([elements subarrayWithRange:NSMakeRange(1, elements.count - 1)]);
    return [[OYDeclare alloc] initWithURL:tuple.URL propertyForm:properties start:tuple.start end:tuple.end line:tuple.line column:tuple.col];

}

OYFun *parseFun(OYTuple *tuple) {
    NSMutableArray *elements = tuple.elements;
    if (elements.count < 3) {
        [[[OYParserException alloc] initWithMessage:@"syntax error in function definition" node:tuple] raise];
    }

    // construct parameter list
    OYNode *preParams = elements[1];
    if (!([preParams isKindOfClass:[OYTuple class]])) {
        [[[OYParserException alloc] initWithMessage:[NSString stringWithFormat:@"incorrect format of parameters: %@", preParams] node:preParams] raise];
    }

    // parse the parameters, test whether it's all names or all tuples
    __block BOOL hasName = NO;
    __block BOOL hasTuple = NO;
    NSMutableArray *paramNames = [NSMutableArray new];
    NSMutableArray *paramTuples = [NSMutableArray new];
    [((OYTuple *) preParams).elements enumerateObjectsUsingBlock:^(OYNode *p, NSUInteger idx, BOOL *stop) {
        if ([p isKindOfClass:[OYName class]]) {
            hasName = true;
            [paramNames addObject:p];
        } else if ([p isKindOfClass:[OYTuple class]]) {
            hasTuple = true;
            NSMutableArray *argElements = ((OYTuple *) p).elements;
            if (argElements.count == 0) {
                [[[OYParserException alloc] initWithMessage:[NSString stringWithFormat:@"illegal argument format: %@", p] node:p] raise];
            }
            if (!([argElements[0] isKindOfClass:[OYName class]])) {
                [[[OYParserException alloc] initWithMessage:[NSString stringWithFormat:@"illegal argument name : %@", argElements[0]] node:p] raise];
            }

            OYName *name = (OYName *) argElements[0];
            if (![name.identifier isEqualToString:@"->"]) {
                [paramNames addObject:name];
            }
            [paramTuples addObject:p];
        }
    }];

    if (hasName && hasTuple) {
        [[[OYParserException alloc] initWithMessage:[NSString stringWithFormat:@"parameters must be either all names or all tuples: %@", preParams] node:preParams] raise];
    }

    OYScope *properties;
    if (hasTuple) {
        properties = parseProperties(paramTuples);
    } else {
        properties = nil;
    }

    // construct body
    NSMutableArray *statements = parseList([elements subarrayWithRange:NSMakeRange(2, elements.count - 2)]);
    NSInteger start = [(OYNode *)statements[0] start];
    NSInteger end = [(OYNode *)statements[statements.count - 1] end];
    OYNode *body = [[OYBlock alloc] initWithURL:tuple.URL statements:statements start:start end:end line:tuple.line column:tuple.col];

    return [[OYFun alloc] initWithURL:tuple.URL params:paramNames propertyForm:properties body:body start:tuple.start end:tuple.end line:tuple.line column:tuple.col];

}

OYRecordDef *parseRecordDef(OYTuple *tuple) {
    NSMutableArray *elements = tuple.elements;
    if (elements.count < 2) {
        [[[OYParserException alloc] initWithMessage:@"syntax error in record type definition" node:tuple] raise];
    }

    OYNode *name = elements[1];
    OYNode *maybeParents = elements[2];

    NSMutableArray *parents;
    NSArray *fields;

    if (!([name isKindOfClass:[OYName class]])) {
        [[[OYParserException alloc] initWithMessage:[NSString stringWithFormat:@"syntax error in record name: %@", name] node:name] raise];
    }

    // check if there are parents (record A (B C) ...)
    if ([maybeParents isKindOfClass:[OYTuple class]] &&

        delimType(((OYTuple *) maybeParents).open, @"("))
    {
        NSMutableArray *parentNodes = ((OYTuple *) maybeParents).elements;
        parents = [NSMutableArray new];
        for (OYNode *p in parentNodes) {
            if (!([p isKindOfClass:[OYName class]])) {
                [[[OYParserException alloc] initWithMessage:@"parents can only be names" node:p] raise];
            }
            [parents addObject:p];
        }
        fields = [elements subarrayWithRange:NSMakeRange(3, elements.count - 3)];
    } else {
        parents = nil;
        fields = [elements subarrayWithRange:NSMakeRange(2, elements.count - 2)];
    }

    OYScope *properties = parseProperties(fields);
    return [[OYRecordDef alloc] initWithURL:tuple.URL name:(OYName *)name parents:parents propertyForm:properties start:tuple.start end:tuple.end line:tuple.line column:tuple.col];
}

OYCall *parseCall(OYTuple *tuple) {
    NSMutableArray *elements = tuple.elements;
    OYNode *func = parseNode(elements[0]);
    NSMutableArray *parsedArgs = parseList([elements subarrayWithRange:NSMakeRange(1, elements.count - 1)]);
    OYArgument *args = [[OYArgument alloc] initWithElements:parsedArgs];
    return [[OYCall alloc] initWithURL:tuple.URL op:func arguments:args start:tuple.start end:tuple.end line:tuple.line column:tuple.col];
}


NSMutableArray *parseList(NSArray *prenodes) {
    NSMutableArray *parsed = [NSMutableArray new];
    [prenodes enumerateObjectsUsingBlock:^(OYNode *s, NSUInteger idx, BOOL *stop) {
        [parsed addObject:parseNode(s)];
    }];

    return parsed;
}


// treat the list of nodes as key-value pairs like (:x 1 :y 2)
NSMutableDictionary *parseMap(NSArray *prenodes) {
    NSMutableDictionary *ret = [NSMutableDictionary new];
    if (prenodes.count % 2 != 0) {
        [[[OYParserException alloc] initWithMessage:[NSString stringWithFormat:@"must be of the form (:key1 value1 :key2 value2), but got: %@" , prenodes] node:nil] raise];
    }
    for (int i = 0; i < prenodes.count; i += 2) {
        OYNode *key = prenodes[i];
        OYNode *value = prenodes[i + 1];
        if (!([key isKindOfClass:[OYKeyword class]])) {
            [[[OYParserException alloc] initWithMessage:[NSString stringWithFormat:@"key must be a keyword, but got: %@", key] node:key] raise];
        }
        ret[((OYKeyword *)key).identifier] = value;
    }
    return ret;
}


OYScope *parseProperties(NSArray *fields) {
    OYScope *properties = [[OYScope alloc] init];
    for (OYNode *field in fields) {
        if (!([field isKindOfClass:[OYTuple class]] &&
            delimType(((OYTuple *) field).open, @"[") &&
              ((OYTuple *) field).elements.count >= 2))
        {
            [[[OYParserException alloc] initWithMessage:[NSString stringWithFormat:@"incorrect form of descriptor: %@", field] node:field] raise];
        } else {
            NSMutableArray *elements = parseList(((OYTuple *) field).elements);
            OYNode *nameNode = elements[0];
            if (!([nameNode isKindOfClass:[OYName class]])) {
                [[[OYParserException alloc] initWithMessage:[NSString stringWithFormat:@"expect field name, but got: %@", nameNode] node:nameNode] raise];
            }
            NSString *identifier = ((OYName *) nameNode).identifier;
            if ([properties containsKey:identifier]) {
                [[[OYParserException alloc] initWithMessage:[NSString stringWithFormat:@"duplicated name: %@", nameNode] node:nameNode] raise];
            }
            
            OYNode *typeNode = elements[1];
            [properties setValue:typeNode forKey:@"type" inName:identifier];
            if (![typeNode isKindOfClass:[OYName class]]) {
                [[[OYParserException alloc] initWithMessage:[NSString stringWithFormat:@"type must be a name, but got: %@", typeNode] node:typeNode] raise];
            }

            [properties setValue:typeNode forKey:@"type" inName:identifier];

            NSMutableDictionary *props = parseMap([elements subarrayWithRange:NSMakeRange(2, elements.count - 2)]);
            NSMutableDictionary *propsObj = [NSMutableDictionary dictionaryWithDictionary:props];
            [properties setValuesFromProperties:propsObj inName:((OYName *)nameNode).identifier];
        }
    }
    return properties;
}


BOOL delimType(OYNode *c, NSString *d) {
    return [c isKindOfClass:[OYDelimeter class]] && [((OYDelimeter *) c).shape isEqualToString:d];
}