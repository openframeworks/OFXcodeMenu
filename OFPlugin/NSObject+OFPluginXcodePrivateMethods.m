//
//  NSObject+OFPrivateMethods.m
//  OFPlugin
//
//  Created by Michael Cornell on 4/23/15.
//
//

#import "NSObject+OFPluginXcodePrivateMethods.h"
#import <objc/objc-runtime.h>
@implementation NSObject (OFPluginXcodePrivateMethods)
-(id /*IDEContainer*/)wrappedContainer {
    //id wrappedContainer;
    //object_getInstanceVariable(self, "_wrappedContainer", (void *)&wrappedContainer);
    return [self valueForKey:@"_wrappedContainer"];
}
@end
