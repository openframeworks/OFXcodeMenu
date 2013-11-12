#import "OFPlugin.h"
#import "OFAddon.h"
#import "OFAddonMenuItem.h"
#import <objc/objc-runtime.h>

NSString * const kOpenFrameworksAddonsPath = @"openframeworks-addons-path";

@interface OFPlugin() {
	
	NSMenu * _OFMenu;
	NSMenu * _addonsListMenu;
	NSString * _addonsPath;
	NSMenuItem * _topLevelMenuItem;
	NSMenuItem * _addAddonItem;
	NSMenuItem * _websiteItem;
}

@property (nonatomic, strong) NSBundle * bundle;

@end

@implementation OFPlugin

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static id sharedPlugin = nil;
    static dispatch_once_t onceToken;
    NSString * currentAppName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentAppName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[self alloc] initWithBundle:plugin];
        });
    }
}

- (id)initWithBundle:(NSBundle *)plugin {
	
	if (self = [super init]) {
		self.bundle = plugin;
		[self generateMenu];
		
		_addonsPath = [[NSUserDefaults standardUserDefaults] stringForKey:kOpenFrameworksAddonsPath];
		if(!_addonsPath) {
			[self setAddonsPath:[@"~/openFrameworks/addons/" stringByExpandingTildeInPath]];
		}
		
		[self scanAddons];
	}
	return self;
}

#pragma mark - Menu stuffs

- (void)generateMenu {
	_topLevelMenuItem = [[NSMenuItem alloc] initWithTitle:@"openFrameworks"
												   action:@selector(menuSelected:)
											keyEquivalent:@""];
	[_topLevelMenuItem setTarget:self];
	
	_OFMenu = [[NSMenu alloc] initWithTitle:@"OF"];
	[_topLevelMenuItem setSubmenu:_OFMenu];
	
	NSMenuItem * addonsPathItem = [_OFMenu addItemWithTitle:@"Set addons path..."
													 action:@selector(showAddonsPathSelectionPanel:)
											  keyEquivalent:@""];
	[addonsPathItem setTarget:self];
	[addonsPathItem setEnabled:YES];
	
	_addAddonItem = [_OFMenu addItemWithTitle:@"Add addon" action:@selector(menuSelected:) keyEquivalent:@""];
	_addonsListMenu = [[NSMenu alloc] initWithTitle:@"addon-list"];
	[_addAddonItem setTarget:self];
	[_addAddonItem setSubmenu:_addonsListMenu];
	
	[_OFMenu addItem:[NSMenuItem separatorItem]];
	
	_websiteItem = [_OFMenu addItemWithTitle:@"Open ofxaddons.com" action:@selector(showAddonsWebsite:) keyEquivalent:@""];
	[_websiteItem setTarget:self];
	[_websiteItem setEnabled:YES];
	
	NSUInteger menuIndex = [[NSApp mainMenu] indexOfItemWithTitle:@"Navigate"];
	[[NSApp mainMenu] insertItem:_topLevelMenuItem atIndex:menuIndex > 0 ? menuIndex : 5];
}

- (void)menuSelected:(id)sender {
	
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	
	if(menuItem == _topLevelMenuItem) {
		[self scanAddons];
	} else if(menuItem == _addAddonItem) {
		return _addonsListMenu.itemArray.count > 0;
	}
	
	return YES;
}

- (void)showAddonsWebsite:(NSMenuItem *)sender {
	
	if(sender == _websiteItem) {
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://ofxaddons.com"]];
	} else {
		if([sender respondsToSelector:@selector(addon)]) {
			OFAddon * addon = [(OFAddonMenuItem *)sender addon];
			[addon setMetadataFromURL:[NSURL fileURLWithPath:addon.path]];
			if(addon.url) {
				[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:addon.url]];
			}
		} else {
			NSString * searchTerm = [[sender title] stringByReplacingOccurrencesOfString:@"..." withString:@""];
			NSString * searchURL = [NSString stringWithFormat:@"https://www.google.com/search?q=%@&btnI", searchTerm];
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:searchURL]];
		}
	}
}

#pragma mark - Addons directory

- (void)scanAddons
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSArray * allAddons = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_addonsPath error:nil];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			NSArray * sortedAddons = [allAddons sortedArrayUsingComparator:^NSComparisonResult(NSString * a, NSString * b) {
				return [a compare:b];
			}];
			
			[_addonsListMenu removeAllItems];
			
			for(NSString * addon in sortedAddons) {
				if([addon rangeOfString:@"ofx"].location != NSNotFound) {
					OFAddonMenuItem * addonItem = [[OFAddonMenuItem alloc] initWithTitle:addon
																				  action:@selector(addAddonForMenuItem:)
																		   keyEquivalent:@""];
					
					NSString * addonPath = [NSString stringWithFormat:@"%@/%@/", _addonsPath, addon];
					[addonItem setAddon:[OFAddon addonWithPath:addonPath name:addon]];
					[addonItem setTarget:self];
					[_addonsListMenu addItem:addonItem];
					
					OFAddonMenuItem * alt = [[OFAddonMenuItem alloc] initWithTitle:[addon stringByAppendingString:@"..."]
																			action:@selector(showAddonsWebsite:)
																	 keyEquivalent:@""];
					
					[alt setKeyEquivalentModifierMask:NSAlternateKeyMask];
					[alt setTarget:self];
					[alt setEnabled:YES];
					[alt setAlternate:YES];
					[alt setAddon:addonItem.addon];
					[_addonsListMenu addItem:alt];
				}
			}
			
			[_addAddonItem setSubmenu:_addonsListMenu];
		});
	});
}

- (void)showAddonsPathSelectionPanel:(id)sender
{
	dispatch_async(dispatch_get_main_queue(), ^{
		NSOpenPanel * openPanel = [NSOpenPanel openPanel];
		[openPanel setDirectoryURL:[NSURL fileURLWithPath:[@"~" stringByExpandingTildeInPath]]];
		[openPanel setCanChooseDirectories:YES];
		[openPanel setTitle:@"Point me at your addons folder"];
		[openPanel beginWithCompletionHandler:^(NSInteger result) {
			if(result == NSFileHandlingPanelOKButton) {
				[self setAddonsPath:[[[openPanel URLs] objectAtIndex:0] path]];
			}
		}];
	});
}

- (void)setAddonsPath:(NSString *)addonsPath {
	_addonsPath = addonsPath;
	[[NSUserDefaults standardUserDefaults] setObject:addonsPath forKey:kOpenFrameworksAddonsPath];
	[self scanAddons];
}

#pragma mark - Actions

- (void)addAddonForMenuItem:(OFAddonMenuItem *)addonMenuItem
{
	// These Obj-C classes found via class-dumping Xcode's internal frameworks
	
	// IDEWorkspaceDocument -> IDEKit
	// IDEWorkspace -> IDEFoundation
	// Xcode3Project, Xcode3Group -> DevToolsCore
	
	@try {
		id /* IDEWorkspaceDocument */ document = [[[NSApp keyWindow] windowController] document];
		id /* IDEWorkspace */ workspace = objc_msgSend(document, @selector(workspace));
		id /* Xcode3Project */ container = objc_msgSend(workspace, @selector(wrappedXcode3Project));
		id /* PBXProject */ project = objc_msgSend(container, @selector(pbxProject));
		id /* Xcode3Group */ addonsGroup = [self findAddonsGroupFromRoot:objc_msgSend(container, @selector(rootGroup))];
		[addonMenuItem.addon setMetadataFromURL:[NSURL fileURLWithPath:addonMenuItem.addon.path]];
		
		if(addonsGroup) {
			NSArray * targets = objc_msgSend(project, @selector(targets));
			[self addAddon:addonMenuItem.addon toGroup:addonsGroup andTargets:targets inProject:project];
			[self modifyBuildSettingsInTargets:targets forAddon:addonMenuItem.addon];
		} else {
			[[NSAlert alertWithMessageText:@"Couldn't find an \"addons\" group"
							 defaultButton:@"Oh, right"
						   alternateButton:nil
							   otherButton:nil
				 informativeTextWithFormat:@"You should have a group called \"addons\" in your project"] runModal];
		}
	}
	@catch (NSException *exception) {
		NSLog(@"OFPlugin problem! : %@", exception);
	}
	@finally {
		
	}
}

- (void)addAddon:(OFAddon *)addon toGroup:(id /* Xcode3Group */)addonsGroup andTargets:(NSArray *)targets inProject:(id /* PBXProject */)project {
	
	id /* PBXGroup */ addonsPbxGroup = objc_msgSend(addonsGroup, @selector(group));
    id /* PBXGroup */ newPbxGroup = objc_msgSend(NSClassFromString(@"PBXGroup"), @selector(groupWithName:), addon.name);
	[addonsPbxGroup insertItem:newPbxGroup atIndex:0];
	
	// add "src" and "libs"
	objc_msgSend(newPbxGroup, @selector(addFiles:copy:createGroupsRecursively:), [self srcAndLibsFoldersForAddon:addon], NO, YES);
	
	// add any system frameworks
	objc_msgSend(newPbxGroup, @selector(addFiles:copy:createGroupsRecursively:), [self systemFrameworksForAddon:addon], NO, YES);
	
	// add any extra libs
	NSArray * extraLibs = addon.extraLibPaths;
	NSString * projectPath = [objc_msgSend(project, @selector(path)) stringByDeletingLastPathComponent];
	for(NSString * libPath in extraLibs) {
		NSString * fullLibPath = [NSString stringWithFormat:@"%@/%@", projectPath, libPath];
		objc_msgSend(newPbxGroup, @selector(addFiles:copy:createGroupsRecursively:), @[fullLibPath], 0, YES);
	}
	
	// remove stuff excluded by addons_config.mk
	[self recursivelyRemoveFilesInGroup:newPbxGroup forAddon:addon path:@""];
	
	// add all the new stuff to the project's build phases in all targets
	[self addSourceFilesAndLibsFromGroup:newPbxGroup toTargets:targets];
	
	// add any external header search paths the addon requires
	[self modifyBuildSettingsInTargets:targets forAddon:addon];
}

#pragma mark - Util

- (void) recursivelyRemoveFilesInGroup:(id /* PBXGroup */)group forAddon:(OFAddon *)addon path:(NSString *)path {
	
	Class groupClass = NSClassFromString(@"PBXGroup");
	
	if(!group || [group class] != groupClass) {
		return;
	} else {
		__block NSMutableIndexSet * childrenToRemove = [[NSMutableIndexSet alloc] init];
		
		[[group children] enumerateObjectsUsingBlock:^(id child, NSUInteger idx, BOOL *stop) {
			if([child class] == groupClass) {
				NSString * seperator = [path isEqualToString:@""] ? @"" : @"/";
				NSString * nextPath = [[path stringByAppendingString:seperator] stringByAppendingString:[child name]];
				[self recursivelyRemoveFilesInGroup:child forAddon:addon path:nextPath];
			}
			
			NSString * childPath = [[path stringByAppendingString:@"/"] stringByAppendingString:[child name]];
			
			for(NSString * exclusionPrefix in addon.sourceFoldersToExclude) {
				if([childPath hasPrefix:exclusionPrefix]) {
					[childrenToRemove addIndex:idx];
				}
			}
			
			for(NSString * exclusionPrefix in addon.headerFoldersToExclude) {
				if([childPath hasPrefix:exclusionPrefix]) {
					[childrenToRemove addIndex:idx];
				}
			}
		}];
		
		if(childrenToRemove.count > 0) {
			objc_msgSend(group, @selector(removeItemsAtIndexes:), childrenToRemove);
		}
	}
}

- (void)modifyBuildSettingsInTargets:(NSArray * /* PBXTarget */)targets forAddon:(OFAddon *)addon {
	
	for(id /* PBXTarget */ target in targets) {
		id /* XCConfigurationList */ configurationList = objc_msgSend(target, @selector(buildConfigurationList));
		NSArray * buildConfigurationNames = objc_msgSend(configurationList, @selector(buildConfigurationNames));
		
		for(NSString * configName in buildConfigurationNames) {
			NSArray * settings = objc_msgSend(configurationList, @selector(buildSettingDictionariesForConfigurationName:errors:), configName, nil);
			for(id /* DVTMacroDefinitionTable */ macroTable in settings) {
				[self addPaths:addon.extraHeaderSearchPaths forSetting:@"USER_HEADER_SEARCH_PATHS" toTable:macroTable];
			}
		}
		objc_msgSend(configurationList, @selector(invalidateCaches));
	}
}

// breadth first search for a group named "addons"
- (id) findAddonsGroupFromRoot:(id /* Xcode3Group */)root {
	
	if(root == nil) return nil;
	
	NSMutableArray * queue = [[NSMutableArray alloc] init];
	[queue addObject:root];
	
	while([queue count] > 0) {
		id node = [queue objectAtIndex:0];
		[queue removeObjectAtIndex:0];
		NSString * nodeName = objc_msgSend(node, @selector(name));
		if([nodeName caseInsensitiveCompare:@"addons"] == NSOrderedSame) {
			return node;
		} else {
			if([node respondsToSelector:@selector(subitems)]) {
				NSArray * subitems = objc_msgSend(node, @selector(subitems));
				for(id item in subitems) {
					[queue addObject:item];
				}
			}
		}
	}
	
	return nil;
}

- (void) addSourceFilesAndLibsFromGroup:(id /* Xcode3Group */)group toTargets:(NSArray *)targets {
	
	id /* PBXGroupEnumerator */ pbxGroupEnumerator = objc_msgSend(group, @selector(groupEnumerator));
	
	NSMutableArray * referencesToAdd = [[NSMutableArray alloc] init];
	for(id item in pbxGroupEnumerator) {
		if([self shouldAddItemToTarget:item]) {
			[referencesToAdd addObject:item];
		}
	}
	// add source file, library and framework references to all targets
	for(id target in targets) {
		for (id ref in referencesToAdd) {
			objc_msgSend(target, @selector(addReference:), ref);
		}
	}
}

- (BOOL) shouldAddItemToTarget:(id)item {
	
	if([item class] != NSClassFromString(@"PBXFileReference")) return NO;
	
	id /* PBXFileType */ fileType = objc_msgSend(item, @selector(fileType));
	NSString * fileUTI = objc_msgSend(fileType, @selector(UTI));
	
	if([fileUTI rangeOfString:@"source"].location != NSNotFound || // is a source file?
	   ((BOOL (*)(id, SEL))objc_msgSend)(fileType, @selector(isStaticLibrary)) || // is a static lib?
	   ((BOOL (*)(id, SEL))objc_msgSend)(fileType, @selector(isFramework))) // is a framework?
	{
		return YES;
	}
	
	return NO;
}

- (void) addPaths:(NSArray *)paths forSetting:(NSString *)setting toTable:(id /* DVTMacroDefinitionTable */)table {
	
	if(!paths || !table) return;
	
	NSArray * currentPaths = objc_msgSend(table, @selector(valueForKey:), setting);
	NSArray * modifiedPaths = nil;
	
	if(currentPaths) {
		modifiedPaths = [currentPaths arrayByAddingObjectsFromArray:paths];
	} else {
		modifiedPaths = paths;
	}
	
	objc_msgSend(table, @selector(setObject:forKeyedSubscript:), modifiedPaths, setting);
}

- (NSArray *) srcAndLibsFoldersForAddon:(OFAddon *)addon {
	NSArray * paths = @[[addon.path stringByAppendingString:@"src"],
						[addon.path stringByAppendingString:@"libs"]];
	
	NSMutableArray * folders = [[NSMutableArray alloc] init];
	for(NSString * path in paths) {
		if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
			[folders addObject:path];
		}
	}
	return folders;
}

- (NSArray *) systemFrameworksForAddon:(OFAddon *)addon {
	
	NSMutableArray * frameworkPaths = [[NSMutableArray alloc] init];
	for(NSString * frameworkName in addon.systemFrameworks) {
		[frameworkPaths addObject:[NSString stringWithFormat:@"/System/Library/Frameworks/%@.framework", frameworkName]];
	}
	
	return frameworkPaths;
}

@end
