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


OYNode *parseNode(OYNode *prenode) {
    
    // initial program is in a block
    if ([prenode isKindOfClass:[OYBlock class]]) {
        NSMutableArray *parsed = parseList(((OYBlock *) prenode).statements);
        return [[OYBlock alloc] initWithURL:prenode.URL statements:parsed start:prenode.start end:prenode.end line:prenode.line column:prenode.col];
    }
    
    if ([prenode isKindOfClass:[OYAttr class]]) {
        OYAttr *a = (OYAttr *)prenode;
        return [[OYAttr alloc] initWithURL:a.URL value:parseNode(a.value) attr:a.attr start:a.start end:a.end line:a.line column:a.col]; //Attr(parseNode(a.value), a.attr, a.file, a.start, a.end, a.line, a.col);
    }
    
    // most structures are encoded in a tuple
    // (if t c a) (+ 1 2) (f x y) ...
    // decode them by their first map

    if (!([prenode isKindOfClass:[OYTuple class]])) {
        // default return the node untouched
        return prenode;
    }

    // following: actually do something
    OYTuple *tuple = (OYTuple *)prenode;
    NSMutableArray *elements = tuple.elements;

    if (delimType(tuple.open, @"{")) {
        return [[OYRecordLiteral alloc] initWithURL:tuple.URL contents:parseList(elements) start:tuple.start end:tuple.end line:tuple.line column:tuple.col];
    }

    if (delimType(tuple.open, @"[")) {
        return [[OYVectorLiteral alloc] initWithURL:tuple.URL elements:parseList(elements) start:tuple.start end:tuple.end line:tuple.line column:tuple.col];
    }

    // (...) form must be non-empty
    if (!elements.count) {
        [[[OYParserException alloc] initWithMessage:@"syntax error" node:tuple] raise];
    }

    OYNode *keyNode = elements[0];

    if ([keyNode isKindOfClass:[OYName class]]) {
        NSString *keyword = ((OYName *) keyNode).identifier;
        // -------------------- sequence --------------------
        if ([keyword isEqualToString:@"seq"]) {
            NSMutableArray *statements = parseList([elements subarrayWithRange:NSMakeRange(1, elements.count - 1)]);
            return [[OYBlock alloc] initWithURL:prenode.URL statements:statements start:prenode.start end:prenode.end line:prenode.line column:prenode.col];
        }
        // -------------------- if --------------------
        if ([keyword isEqualToString:@"if"]) {
            if (elements.count != 4) {
                [[[OYParserException alloc] initWithMessage:@"incorrect format of if" node:tuple] raise];
            }
            OYNode *test = parseNode(elements[1]);
            OYNode *conseq = parseNode(elements[2]);
            OYNode *alter = parseNode(elements[3]);
            return [[OYIf alloc] initWithURL:prenode.URL test:test then:conseq orelse:alter start:prenode.start end:prenode.end line:prenode.line column:prenode.col];
        }
        // -------------------- definition --------------------
        if ([keyword isEqualToString:@"define"]) {
            if (elements.count != 3) {
                [[[OYParserException alloc] initWithMessage:@"incorrect format of definition" node:tuple] raise];
            }
            OYNode *pattern = parseNode(elements[1]);
            OYNode *value = parseNode(elements[2]);
            return [[OYDef alloc] initWithURL:prenode.URL pattern:pattern value:value start:prenode.start end:prenode.end line:prenode.line column:prenode.col];

        }
        // -------------------- assignment --------------------
        if ([keyword isEqualToString:(@"set!")]) {
            if (elements.count != 3) {
                [[[OYParserException alloc] initWithMessage:@"incorrect format of assignment" node:tuple] raise];
            }
            OYNode *pattern = parseNode(elements[1]);
            OYNode *value = parseNode(elements[2]);
            return [[OYAssign alloc] initWithURL:prenode.URL pattern:pattern value:value start:prenode.start end:prenode.end line:prenode.line column:prenode.col];
        }

        // -------------------- declare --------------------
        if ([keyword isEqualToString:@"declare"]) {
            if (elements.count < 2) {
                [[[OYParserException alloc] initWithMessage:@"syntax error in record type definition" node:tuple] raise];
            }
            OYScope *properties = parseProperties([elements subarrayWithRange:NSMakeRange(1, elements.count - 1)]);
            return [[OYDeclare alloc] initWithURL:prenode.URL propertyForm:properties start:prenode.start end:prenode.end line:prenode.line column:prenode.col];
        }
        // -------------------- anonymous function --------------------
        if ([keyword isEqualToString:@"fun"]) {
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
            OYNode *body = [[OYBlock alloc] initWithURL:prenode.URL statements:statements start:start end:end line:prenode.line column:prenode.col];

            return [[OYFun alloc] initWithURL:prenode.URL params:paramNames propertyForm:properties body:body start:prenode.start end:prenode.end line:prenode.line column:prenode.col];
        }
        // -------------------- record type definition --------------------
        if ([keyword isEqualToString:@"record"]) {
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
                        [[[OYParserException alloc] initWithMessage:@"%@\nparents can only be names" node:p] raise];
                    }
                    [parents addObject:p];
                }
                fields = [elements subarrayWithRange:NSMakeRange(3, elements.count - 3)];
            } else {
                parents = nil;
                fields = [elements subarrayWithRange:NSMakeRange(2, elements.count - 2)];
            }

            OYScope *properties = parseProperties(fields);
            return [[OYRecordDef alloc] initWithURL:prenode.URL name:(OYName *)name parents:parents propertyForm:properties start:prenode.start end:prenode.end line:prenode.line column:prenode.col];
        }
    }

    // -------------------- application --------------------
    // must go after others because it has no keywords
    OYNode *func = parseNode(elements[0]);
    NSMutableArray *parsedArgs = parseList([elements subarrayWithRange:NSMakeRange(1, elements.count - 1)]);
    OYArgument *args = [[OYArgument alloc] initWithElements:parsedArgs];//new Argument(parsedArgs);
    return [[OYCall alloc] initWithURL:prenode.URL op:func arguments:args start:prenode.start end:prenode.end line:prenode.line column:prenode.col];
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
        if ([field isKindOfClass:[OYTuple class]] &&
            delimType(((OYTuple *) field).open, @"["))
        {
            NSMutableArray *elements = parseList(((OYTuple *) field).elements);
            if (elements.count < 2) {
                [[[OYParserException alloc] initWithMessage:@"empty record slot not allowed" node:field] raise];
            }
            
            OYNode *nameNode = elements[0];
            if (!([nameNode isKindOfClass:[OYName class]])) {
                [[[OYParserException alloc] initWithMessage:[NSString stringWithFormat:@"expect field name, but got: %@", nameNode] node:nameNode] raise];
            }
            NSString *identifier = ((OYName *) nameNode).identifier;
            if ([properties containsKey:identifier]) {
                NSCAssert(0, @"%@\nduplicated field name: %@", nameNode, nameNode);
            }
            
            OYNode *typeNode = elements[1];
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