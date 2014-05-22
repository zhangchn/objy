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

OYNode *parseURL(NSURL *URL) {
    OYPreParser *preparser = [[OYPreParser alloc] initWithURL:URL];
    OYNode *prenode = [preparser parse];
    OYNode *grouped = groupAttr(prenode);
    return parseNode(grouped);
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
    if ([prenode isKindOfClass:[OYTuple class]]) {
        OYTuple *tuple = (OYTuple *) prenode;
        NSMutableArray *elements = tuple.elements;
        
        if (delimType(tuple.open, @"{")) {
            return [[OYRecordLiteral alloc] initWithURL:tuple.URL contents:parseList(elements) start:tuple.start end:tuple.end line:tuple.line column:tuple.col];
        }
        
        if (delimType(tuple.open, @"[")) {
            return [[OYVectorLiteral alloc] initWithURL:tuple.URL elements:parseList(elements) start:tuple.start end:tuple.end line:tuple.line column:tuple.col];
        }
        
        // (...) form must be non-empty
        if (elements.count == 0) {
            NSCAssert(0, @"%@" "\n" "syntax error", tuple);
        }
        
        OYNode *keyNode = elements[0];
        
        if ([keyNode isKindOfClass:[OYName class]]) {
            NSString *keyword = ((OYName *) keyNode).identifier;
            
            // -------------------- sequence --------------------
            if ([keyword isEqualToString:@"seq"]) {
                NSMutableArray *statements = parseList([elements subarrayWithRange:NSMakeRange(1, elements.count - 1)]);
//                List<Node> statements = parseList(elements.subList(1, elements.count));
                return [[OYBlock alloc] initWithURL:prenode.URL statements:statements start:prenode.start end:prenode.end line:prenode.line column:prenode.col];
//                return new Block(statements, prenode.file, prenode.start, prenode.end, prenode.line, prenode.col);
            }
            
            // -------------------- if --------------------
            if ([keyword isEqualToString:@"if"]) {
                if (elements.count == 4) {
                    OYNode *test = parseNode(elements[1]);
                    OYNode *conseq = parseNode(elements[2]);
                    OYNode *alter = parseNode(elements[3]);
                    return [[OYIf alloc] initWithURL:prenode.URL test:test then:conseq orelse:alter start:prenode.start end:prenode.end line:prenode.line column:prenode.col];
                } else {
                    NSCAssert(0, @"%@" "\n" "incorrect format of if", tuple);
//                    _.abort(tuple, "incorrect format of if");
                }
            }
            
            // -------------------- definition --------------------
            if ([keyword isEqualToString:@"define"]) {
                if (elements.count == 3) {
                    OYNode *pattern = parseNode(elements[1]);
                    OYNode *value = parseNode(elements[2]);
                    return [[OYDef alloc] initWithURL:prenode.URL pattern:pattern value:value start:prenode.start end:prenode.end line:prenode.line column:prenode.col];
                } else {
                    NSCAssert(0, @"%@\nincorrect format of definition", tuple);
                }
            }
            
            // -------------------- assignment --------------------
            if ([keyword isEqualToString:(@"set!")]) {
                if (elements.count == 3) {
                    OYNode *pattern = parseNode(elements[1]);
                    OYNode *value = parseNode(elements[2]);
                    return [[OYAssign alloc] initWithURL:prenode.URL pattern:pattern value:value start:prenode.start end:prenode.end line:prenode.line column:prenode.col];
//                    return new Assign(pattern, value, prenode.file, prenode.start, prenode.end, prenode.line,
//                                      prenode.col);
                } else {
                    NSCAssert(0, @"%@\nincorrect format of definition", tuple);
//                    _.abort(tuple, "incorrect format of definition");
                }
            }
            
            // -------------------- declare --------------------
            if ([keyword isEqualToString:@"declare"]) {
                if (elements.count < 2) {
                    NSCAssert(0, @"%@\nsyntax error in record type definition", tuple);
                }
                OYScope *properties = parseProperties([elements subarrayWithRange:NSMakeRange(1, elements.count - 1)]);
                return [[OYDeclare alloc] initWithURL:prenode.URL propertyForm:properties start:prenode.start end:prenode.end line:prenode.line column:prenode.col];
            }
            
            // -------------------- anonymous function --------------------
            if ([keyword isEqualToString:@"fun"]) {
                if (elements.count < 3) {
                    NSCAssert(0, @"%@\nsyntax error in function definition", tuple);
                }
                
                // construct parameter list
                OYNode *preParams = elements[1];
                if (!([preParams isKindOfClass:[OYTuple class]])) {
                    NSCAssert(0, @"%@\nincorrect format of parameters: %@", tuple, preParams);
//                    _.abort(preParams, "incorrect format of parameters: " + preParams);
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
                            NSCAssert(0, @"%@\nillegal argument format: %@", p, p);
                        }
                        if (!([argElements[0] isKindOfClass:[OYName class]])) {
                            NSCAssert(0, @"%@\nillegal argument name : %@", p, argElements[0]);
                        }
                        
                        OYName *name = (OYName *) argElements[0];
                        if (![name.identifier isEqualToString:@"->"]) {
                            [paramNames addObject:name];
                        }
                        [paramTuples addObject:p];
                    }
                }];
                
                if (hasName && hasTuple) {
                    NSCAssert(0, @"%@\nparameters must be either all names or all tuples: %@", preParams, preParams);
                    return nil;
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
                    NSCAssert(0, @"%@\nsyntax error in record type definition", tuple);
//                    _.abort(tuple, "syntax error in record type definition");
                }
                
                OYNode *name = elements[1];
                OYNode *maybeParents = elements[2];
                
                NSMutableArray *parents;
                NSArray *fields;
                
                if (!([name isKindOfClass:[OYName class]])) {
                    NSCAssert(0, @"%@\nsyntax error in record name: %@", tuple, name);
//                    _.abort(name, "syntax error in record name: " + name);
                    return nil;
                }
                
                // check if there are parents (record A (B C) ...)
                if ([maybeParents isKindOfClass:[OYTuple class]] &&
                    
                    delimType(((OYTuple *) maybeParents).open, @"("))
                {
                    NSMutableArray *parentNodes = ((OYTuple *) maybeParents).elements;
                    parents = [NSMutableArray new];
                    for (OYNode *p in parentNodes) {
                        if (!([p isKindOfClass:[OYName class]])) {
                            NSCAssert(0, @"%@\nparents can only be names", p);
//                            _.abort(p, "parents can only be names");
                        }
                        [parents addObject:p];
                    }
                    fields = [elements subarrayWithRange:NSMakeRange(3, elements.count - 3)];
                    //fields = elements.subList(3, elements.count);
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
        //        return new Call(func, args, prenode.file, prenode.start, prenode.end, prenode.line, prenode.col);
    }
    
    // defaut return the OYNode *untouched
    return prenode;
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
        NSCAssert(0, @"must be of the form (:key1 value1 :key2 value2), but got: %@", prenodes);
//        _.abort("must be of the form (:key1 value1 :key2 value2), but got: " + prenodes);
        return nil;
    }
    for (int i = 0; i < prenodes.count; i += 2) {
        OYNode *key = prenodes[i];
        OYNode *value = prenodes[i + 1];
        if (!([key isKindOfClass:[OYKeyword class]])) {
            NSCAssert(0, @"%@\nkey must be a keyword, but got: %@", key, key);
//            _.abort(key, "key must be a keyword, but got: " + key);
        }
//        ret.put(((Keyword) key).id, value);
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
                NSCAssert(0, @"%@\nempty record slot not allowed", field);
//                _.abort(field, "empty record slot not allowed");
            }
            
            OYNode *nameNode = elements[0];
            if (!([nameNode isKindOfClass:[OYName class]])) {
                NSCAssert(0, @"%@\nexpect field name, but got: %@", nameNode, nameNode);
//                _.abort(nameNode, "expect field name, but got: " + nameNode);
            }
            NSString *identifier = ((OYName *) nameNode).identifier;
            if ([properties containsKey:identifier]) {
                NSCAssert(0, @"%@\nduplicated field name: %@", nameNode, nameNode);
//                _.abort(nameNode, "duplicated field name: " + nameNode);
            }
            
            OYNode *typeNode = elements[1];
            [properties setValue:typeNode forKey:@"type" inName:identifier];
//            properties.put(id, "type", typeNode);
            
            NSMutableDictionary *props = parseMap([elements subarrayWithRange:NSMakeRange(2, elements.count - 2)]);
//            Map<String, Node> props = parseMap(elements.subList(2, elements.count));
            NSMutableDictionary *propsObj = [NSMutableDictionary dictionaryWithDictionary:props];
            
//            Map<String, Object> propsObj = new LinkedHashMap<>();
//            for (Map.Entry<String, Node> e : props.entrySet()) {
//                propsObj.put(e.getKey(), e.getValue());
//            }
            [properties setValuesFromProperties:propsObj inName:((OYName *)nameNode).identifier];
//            properties.putProperties(((OYName *) nameNode).identifier, propsObj);
        }
    }
    return properties;
}


OYNode *groupAttr(OYNode *prenode) {
    if ([prenode isKindOfClass:[OYTuple class]]) {
        OYTuple *t = (OYTuple *) prenode;
        NSMutableArray *elements = t.elements;
        NSMutableArray *newElems = [NSMutableArray new];
        
        if (elements.count >= 1) {
            OYNode *grouped = elements[0];
            if (delimType(grouped, @".")) {
                NSCAssert(0, @"%@\nillegal keyword: %@", grouped, grouped);
//                _.abort(grouped, "illegal keyword: " + grouped);
            }
            grouped = groupAttr(grouped);
            
            for (int i = 1; i < elements.count; i++) {
                OYNode *node1 = elements[i];
                if (delimType(node1, @".")) {
                    if (i + 1 >= elements.count) {
                        NSCAssert(0, @"%@\nillegal position for .", node1);
//                        _.abort(node1, "illegal position for .");
                    }
                    OYNode *node2 = elements[i + 1];
                    if (delimType(node1, @".")) {
                        if (!([node2 isKindOfClass:[OYName class]])) {
                            NSCAssert(0, @"%@\nattribute is not a name", node2);
//                            _.abort(node2, "attribute is not a name");
                        }
                        grouped = [[OYAttr alloc] initWithURL:grouped.URL value:grouped attr:(OYName *)node2 start:grouped.start end:node2.end line:grouped.line column:grouped.col];
                        i++;   // skip
                    }
                } else {
                    [newElems addObject:grouped];
//                    newElems.add(grouped);
                    grouped = groupAttr(node1);
                }
            }
            [newElems addObject:grouped];
//            newElems.add(grouped);
        }
        return [[OYTuple alloc] initWithURL:t.URL elements:newElems open:t.open close:t.close start:t.start end:t.end line:t.line column:t.col];
//        return new Tuple(newElems, t.open, t.close, t.file, t.start, t.end, t.line, t.col);
    } else {
        return prenode;
    }
}


BOOL delimType(OYNode *c, NSString *d) {
    return [c isKindOfClass:[OYDelimeter class]] && [((OYDelimeter *) c).shape isEqualToString:d];
}