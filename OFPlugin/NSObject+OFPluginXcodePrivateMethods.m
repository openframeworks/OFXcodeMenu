//
//  NSObject+OFPrivateMethods.m
//  OFPlugin
//
//  Created by Michael Cornell on 4/23/15.
//
//

#import "NSObject+OFPluginXcodePrivateMethods.h"
#import <objc/objc-runtime.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"

@implementation NSObject (OFPluginXcodePrivateMethods)
-(id /*IDEContainer*/)wrappedContainer {
    return [self valueForKey:@"_wrappedContainer"];
}
#pragma clang diagnostic pop
@end
