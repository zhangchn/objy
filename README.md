ObjYin
===

ObjYin is an Objective-C translation of the Java implementation of [yinwang0](https://github.com/yinwang0)'s [Yin Programming Language](https://github.com/yinwang0/yin/).

It has no theoretical significance per se, but only serves the purpose to support a personal belief that Java IS Objective-C.

### Implementation details

Java classes and APIs were replaced with Cocoa's.

All classes were derived from `NSObject`.

`String`s were replaced with `NSString`s , `List<>`s were replaced with `NSMutableArray`s, `Map<>`s were replaced with `NSMutableDictionary`s, `Set<>`s were replaced with `NSMutableSet`s, and `null`s were replaced with `nil`s.

`toString()`s were replaced with `- description`s.

C funtions and (singleton) class methods were used to emulate the public static member variables and methods.

In some APIs, orders of parameters were changed to fit in the naming convetion of Cocoa, more or less.

`NSURL` was used to replace `file` parameters all around, so the first and only supported command-line parameter of interpreter should be prepended with 'file://' before any path. 'http' protocol was not tested but is likely to work.

In Xcode, to debug using a test script, add parameters in Edit schemes-> Run ObjYin -> Arguments -> Arguments Passed On Launch, e.g.:
  
    file://$SRCROOT/Tests/expr.yin (where $SRCROOT would be resolved to the path of the source code folder by Xcode)

### What's working so far

It seems that ObjYin has successfully interpreted `expr.yin`, `array.yin` and `recursion-direct.yin`. Bugs may exist for others.

### Missing parts

BigInteger support is missing, however, the upstream has not fully supported it either.

Due to the nature of ObjC's dynamic typing, it is impossible to reinforce many compile-time type checking, especially for the containers.

More targets (typechecker, parser, etc.) are missing for now.

GNU AGPLv3 license: I do not personally favor GNU licenses and am too lazy to add one, feel free to add if you need to.

This is a weekend-project, do not expect too much, after all.
