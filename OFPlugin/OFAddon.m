#import "OFAddon.h"

NSString * const kSourcesToExclude = @"ADDON_SOURCES_EXCLUDE";
NSString * const kIncludesToExclude = @"ADDON_INCLUDES_EXCLUDE"; // try not to think about it
NSString * const kFrameworksToInclude = @"ADDON_FRAMEWORKS";
NSString * const kIncludes = @"ADDON_INCLUDES";
NSString * const kURL = @"ADDON_URL";
NSString * const kDependencies = @"ADDON_DEPENDENCIES";

@interface OFAddon()

@property (nonatomic, strong) NSMutableDictionary * config;

@end

@implementation OFAddon

+ (id) addonWithPath:(NSString *)path name:(NSString *)name
{
	OFAddon * a = [[self alloc] init];
	a.path = path;
	a.name = name;
	return a;
}

- (id)init
{
    self = [super init];
    if (self) {
        _config = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark - Accessors

- (NSString *) url {
	return [_config[kURL] objectAtIndex:0];
}

- (NSArray *)sourceFoldersToExclude {
	return _config[kSourcesToExclude];
}

- (NSArray *)includeFoldersToExclude {
	return _config[kIncludesToExclude];
}

- (NSArray *)dependencies {
	return _config[kDependencies];
}

- (NSArray *)extraHeaderSearchPaths {

	// ofxCv doesn't have an addons_config right now, but we'll check anyway to future-proof it
	if([self.name isEqualToString:@"ofxCv"] && !_config[kIncludes]) {
		return @[@"../../../addons/ofxOpenCv/libs/opencv/include/",
				 @"../../../addons/ofxCv/libs/ofxCv/include/"];
	} else

		if([self.name isEqualToString:@"ofxOsc"] && !_config[kIncludes]) {
			return @[@"../../../addons/ofxOsc/libs",
					 @"../../../addons/ofxOsc/libs/oscpack",
					 @"../../../addons/ofxOsc/libs/oscpack/src",
					 @"../../../addons/ofxOsc/libs/oscpack/src/ip",
					 @"../../../addons/ofxOsc/libs/oscpack/src/ip/posix",
					 @"../../../addons/ofxOsc/libs/oscpack/src/ip/win32",
					 @"../../../addons/ofxOsc/libs/oscpack/src/osc",
					 @"../../../addons/ofxOsc/src"];
		} else {
			return _config[kIncludes];
		}
}

- (NSArray *)extraLibPaths {
	if([self.name isEqualToString:@"ofxCv"]) {
		return @[@"../../../addons/ofxOpenCv/libs/opencv/lib/osx/opencv.a"];
	}
	return nil;
}

- (NSArray *)systemFrameworks {
	return _config[kFrameworksToInclude];
}

#pragma mark - addon_config parsing

- (void)setMetadataFromURL:(NSURL *)addonURL {

	NSURL * configURL = [addonURL URLByAppendingPathComponent:@"addon_config.mk"];
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[configURL path]];

	if(exists) {
		NSString * config = [NSString stringWithContentsOfURL:configURL encoding:NSUTF8StringEncoding error:nil];
		if(config) {
			[self parseAddonConfig:config];
		}
	}
}

- (void) parseAddonConfig:(NSString *)config {

	NSArray * sections = @[@"meta", @"common", @"osx"];
	for(NSString * section in sections) {
		NSString * rawSettings = [self rawSettingsForSection:section inConfig:config];
		NSRegularExpression * settingRegex = [NSRegularExpression regularExpressionWithPattern:@"[[A-Z]_]+.*" options:0 error:nil];
		[settingRegex enumerateMatchesInString:rawSettings
									   options:0
										 range:NSMakeRange(0, rawSettings.length)
									usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
										[self parseSetting:[rawSettings substringWithRange:result.range]];
									}];

	}
}

- (void) parseSetting:(NSString *)setting {
	NSString * name = [self firstHitForRegex:@"[[A-Z]_]+" inString:setting];
	NSString * operator = [self firstHitForRegex:@"(\\+|=)+" inString:setting];
	NSString * content = [self firstHitForRegex:@"[^=]+$" inString:setting];
	content = [content stringByReplacingOccurrencesOfString:@"/%" withString:@""]; // need to strip '/%'s
	BOOL append = [operator rangeOfString:@"+="].location != NSNotFound;

	NSMutableArray * currentSettings = _config[name];

	if(!currentSettings || !append) {
		currentSettings = [[NSMutableArray alloc] init];
	}

	if(content) {
		[currentSettings addObject:[content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
	}

	_config[name] = currentSettings;
}

- (NSString *) rawSettingsForSection:(NSString *)section inConfig:(NSString *)config {

	NSString * regex = [NSString stringWithFormat:@"%@:(.|\\n)*?\n[a-z]+:", section];
	NSRegularExpression * expression = [NSRegularExpression regularExpressionWithPattern:regex options:0 error:nil];

	__block NSString * relevantSection = nil;
	[expression enumerateMatchesInString:config
								 options:0
								   range:NSMakeRange(0, config.length)
							  usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop)
	 {
		 relevantSection = [config substringWithRange:result.range];
		 *stop = YES;
	 }];

	relevantSection = [self stringRemovingAllHitsForRegex:@"\n[a-z]+:.*" fromString:relevantSection]; // remove labels
	relevantSection = [self stringRemovingAllHitsForRegex:@".*?\\#.*" fromString:relevantSection]; // remove comments
	return relevantSection;
}

#pragma mark - Util

- (NSString *) firstHitForRegex:(NSString *)regex inString:(NSString *)string {
	NSRegularExpression * expression = [NSRegularExpression regularExpressionWithPattern:regex options:0 error:nil];
	NSRange range = [expression rangeOfFirstMatchInString:string options:0 range:NSMakeRange(0, string.length)];
	return (range.location == NSNotFound ? nil : [string substringWithRange:range]);
}

- (NSString *) stringRemovingAllHitsForRegex:(NSString *)regex fromString:(NSString *)string {
	NSRegularExpression * expression = [NSRegularExpression regularExpressionWithPattern:regex options:0 error:nil];
	return [expression stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, string.length) withTemplate:@""];
}

@end
