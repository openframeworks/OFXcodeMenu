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

- (NSArray *)extraHeaderSearchPaths {
	
	if([self.name isEqualToString:@"ofxCv"]) {
		return @[@"../../../addons/ofxOpenCv/libs/opencv/include/",
				 @"../../../addons/ofxCv/libs/ofxCv/include/"];
	}
	return nil;
}

- (NSArray *)extraLibPaths {
	if([self.name isEqualToString:@"ofxCv"]) {
		return @[@"../../../addons/ofxOpenCv/libs/opencv/lib/osx/opencv.a"];
	}
	return nil;
}

@end
