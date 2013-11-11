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

- (BOOL)setMetadataFromURL:(NSURL *)addonURL {
	
	NSURL * configURL = [addonURL URLByAppendingPathComponent:@"addon_config.mk"];
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[configURL path]];
	
	if(exists) {
		NSString * config = [NSString stringWithContentsOfURL:configURL encoding:NSUTF8StringEncoding error:nil];
		if(config) {
			[self parseAddonConfig:config];
		}
	}
	
	return exists;
}

- (void) parseAddonConfig:(NSString *)config {
	NSString * settings = [self osxSettingsInConfig:config];
	NSLog(@"found addon settings: %@", settings);
}

// TODO: handle errors
- (NSString *) osxSettingsInConfig:(NSString *)config {
	NSError * err = nil;
	NSRegularExpression * osxSectionRegex = [NSRegularExpression regularExpressionWithPattern:@"osx:(.|\\n)*?:"
																					  options:NSRegularExpressionCaseInsensitive
																						error:&err];
	
	__block NSString * relevantSection = nil;
	[osxSectionRegex enumerateMatchesInString:config
									  options:0
										range:NSMakeRange(0, config.length)
								   usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop)
	 {
		 relevantSection = [config substringWithRange:result.range];
		 *stop = YES;
	 }];
	
	NSRegularExpression * labelsRegex = [NSRegularExpression regularExpressionWithPattern:@".*?:"
																				  options:NSRegularExpressionCaseInsensitive
																					error:&err];
	
	NSString * noLabels = [labelsRegex stringByReplacingMatchesInString:relevantSection
																options:0
																  range:NSMakeRange(0, relevantSection.length)
														   withTemplate:@""];
	
	NSRegularExpression * commentsRegex = [NSRegularExpression regularExpressionWithPattern:@".*?\\#.*"
																					options:0
																					  error:&err];
	
	NSString * noComments = [commentsRegex stringByReplacingMatchesInString:noLabels
																	options:0
																	  range:NSMakeRange(0, noLabels.length)
															   withTemplate:@""];
	
	return noComments;
}

@end
