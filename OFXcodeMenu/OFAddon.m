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

+ (id) addonWithPath:(NSString *)path name:(NSString *)name {
	OFAddon * a = [[self alloc] init];
	a.path = path;
	a.name = name;
	return a;
}

- (id)init {
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

- (NSArray *)includeFoldersToExclude {
	return _config[kIncludesToExclude];
}

- (NSArray *)dependencies {
	return _config[kDependencies];
}

- (NSArray *)sourceFoldersToExclude {
	if(_config[kSourcesToExclude]) {
		return _config[kSourcesToExclude];
	} else {
		return nil;
	}
}

- (NSArray *)extraHeaderSearchPaths {
	
	if(_config[kIncludes]) {
		return _config[kIncludes];
	} else if([self.name isEqualToString:@"ofxCv"]) {
		return @[@"../ofxOpenCv/libs/opencv/include/"];
	} else {
		return nil;
	}
}

- (NSArray *)extraLibPaths {
	if([self.name isEqualToString:@"ofxCv"]) {
		return @[@"../ofxOpenCv/libs/opencv/lib/osx/opencv.a"];
	}
	return nil;
}

- (NSArray *)systemFrameworks {
	return _config[kFrameworksToInclude];
}

#pragma mark - addon_config parsing

- (void)setMetadataFromURL:(NSURL *)addonURL forPlatform:(NSString *)platform {

	NSURL * configURL = [addonURL URLByAppendingPathComponent:@"addon_config.mk"];
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[configURL path]];
	if(!platform) platform = @"osx";

	if(exists) {
		NSString * config = [NSString stringWithContentsOfURL:configURL encoding:NSUTF8StringEncoding error:nil];
		if(config) {
			[self parseAddonConfig:config forPlatform:platform];
		}
	}
}

- (void) parseAddonConfig:(NSString *)config forPlatform:(NSString *)platform {

	NSArray * sections = @[@"meta", @"common", platform];
	for(NSString * section in sections) {
		NSString * rawSettings = [self rawSettingsForSection:section inConfig:config];
		if(rawSettings) {
			NSRegularExpression * settingRegex = [NSRegularExpression regularExpressionWithPattern:@"[[A-Z]_]+.*" options:0 error:nil];
			[settingRegex enumerateMatchesInString:rawSettings
										   options:0
											 range:NSMakeRange(0, rawSettings.length)
										usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
											[self parseSetting:[rawSettings substringWithRange:result.range]];
										}];

		}
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

	// regex breakdown:
	// (^section:\s*$) "find the section's label then.."
	// [\s\S]+? "match anything until.."
	// (^\w+:\s*$) "the next label"
	
	NSString * sectionRegex = [NSString stringWithFormat:@"(^%@:\\s*$)[\\s\\S]+?(^\\w+:\\s*$)", section];
	NSString * relevantSection = [self firstHitForRegex:sectionRegex inString:config];
	
	if(relevantSection) {
		relevantSection = [self stringRemovingAllHitsForRegex:@"\n[a-z]+:.*" fromString:relevantSection]; // remove labels
		relevantSection = [self stringRemovingAllHitsForRegex:@".*?\\#.*" fromString:relevantSection]; // remove comments
		return relevantSection;
	} else {
		return nil;
	}
}

#pragma mark - Util

static const NSRegularExpressionOptions regexOptions = NSRegularExpressionAnchorsMatchLines;

- (NSString *) firstHitForRegex:(NSString *)regex inString:(NSString *)string {
	NSRegularExpression * expression = [NSRegularExpression regularExpressionWithPattern:regex options:regexOptions error:nil];
	NSRange range = [expression rangeOfFirstMatchInString:string options:0 range:NSMakeRange(0, string.length)];
	return (range.location == NSNotFound ? nil : [string substringWithRange:range]);
}

- (NSString *) stringRemovingAllHitsForRegex:(NSString *)regex fromString:(NSString *)string {
	NSRegularExpression * expression = [NSRegularExpression regularExpressionWithPattern:regex options:regexOptions error:nil];
	return [expression stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, string.length) withTemplate:@""];
}

@end
