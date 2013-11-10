//
//  OFAddon.m
//  OFPlugin
//
//  Created by Adam Carlucci on 11/9/2013.
//  Copyright (c) 2013 lol. All rights reserved.
//

#import "OFAddon.h"

@implementation OFAddon

+ (id) addonWithPath:(NSString *)path name:(NSString *)name
{
	OFAddon * a = [[self alloc] init];
	a.path = path;
	a.name = name;
	return a;
}

- (NSArray *)foldersToExclude {
	
	if([self.name isEqualToString:@"ofxKinect"]) {
		return @[@"libfreenect"];
	}
	
	return nil;
}

@end
