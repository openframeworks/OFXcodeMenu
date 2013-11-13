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

#pragma mark - Menu

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
					
					NSString * addonPath = [self pathForAddonWithName:addon];
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

- (NSString *)pathForAddonWithName:(NSString *)addonName {
	return [NSString stringWithFormat:@"%@/%@/", _addonsPath, addonName];
}

#pragma mark - Actions

- (void)addAddonForMenuItem:(OFAddonMenuItem *)addonMenuItem {
	[self addAddon:addonMenuItem.addon];
}

- (void)addAddon:(OFAddon *)addon {
	
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
		[addon setMetadataFromURL:[NSURL fileURLWithPath:addon.path]];
		
		if(addonsGroup) {
			NSArray * targets = objc_msgSend(project, @selector(targets));
			[self addAddon:addon toGroup:addonsGroup andTargets:targets inProject:project];
			[self modifyBuildSettingsInTargets:targets forAddon:addon];
		} else {
			[[NSAlert alertWithMessageText:@"Couldn't find an \"addons\" group"
							 defaultButton:@"Oh, right"
						   alternateButton:nil
							   otherButton:nil
				 informativeTextWithFormat:@"You should have a group called \"addons\" in your project"] runModal];
		}
		
		[self handleUnresolvedDependenciesInAddon:addon];
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

- (void)handleUnresolvedDependenciesInAddon:(OFAddon *)addon {
	
	NSMutableArray * unresolvedDependencies = [[NSMutableArray alloc] init];
	
	for(NSString * dependency in addon.dependencies) {
		BOOL found = NO;
		for(NSMenuItem * item in _addonsListMenu.itemArray) {
			if([item.title isEqualToString:dependency]) {
				found = YES;
				[self addAddon:[OFAddon addonWithPath:[self pathForAddonWithName:dependency]
												 name:dependency]];
				break;
			}
			
		}
		if(!found) {
			[unresolvedDependencies addObject:dependency];
		}
	}
	
	if(unresolvedDependencies.count > 0) {
		NSMutableString * msg = [[NSMutableString alloc] init];
		for(NSString * dep in unresolvedDependencies) {
			[msg appendString:[NSString stringWithFormat:@"%@, ", dep]];
		}
		[msg deleteCharactersInRange:NSMakeRange(msg.length - 2, 2)];
		
		NSAlert * a = [NSAlert alertWithMessageText:@"Unresolved dependencies"
									  defaultButton:@"Get them!"
									alternateButton:@"I'll do it myself"
										otherButton:nil
						  informativeTextWithFormat:@"This addon has the following dependencies: %@", msg];
		
		[a beginSheetModalForWindow:[NSApp keyWindow]
					  modalDelegate:self
					 didEndSelector:@selector(dependencyAlertDidEnd:returnCode:contextInfo:)
						contextInfo:(__bridge_retained void *)(@{@"deps":unresolvedDependencies, @"addon":addon})];
	}
}

#pragma mark - Group Utils

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
	   [fileUTI rangeOfString:@"header"].location != NSNotFound || // is a header file?
	   ((BOOL (*)(id, SEL))objc_msgSend)(fileType, @selector(isStaticLibrary)) || // is a static lib?
	   ((BOOL (*)(id, SEL))objc_msgSend)(fileType, @selector(isFramework))) // is a framework?
	{
		return YES;
	}
	
	return NO;
}

#pragma mark - Build Settings Utils

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

#pragma mark - Dependency Utils

- (void) dependencyAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	
	NSDictionary * ctx = (__bridge_transfer NSDictionary *)(contextInfo);
	NSArray * dependencies = ctx[@"deps"];
	if(returnCode == NSAlertDefaultReturn) {
		NSURL * jsonURL = [NSURL URLWithString:@"http://ofxaddons.com/api/v1/all.json"];
		NSURLRequest * req = [NSURLRequest requestWithURL:jsonURL];
		
		[self printToConsole:@"asking ofxaddons.com for repo URLs ... "];
		
		[NSURLConnection sendAsynchronousRequest:req
										   queue:[[NSOperationQueue alloc] init]
							   completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
		{
			BOOL success = NO;
			NSString * errMsg = nil;
			
			if(data) {
				id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
				if(jsonObject) {
					[self printToConsole:@"done!\n"];
					[self cloneDependencies:dependencies forAddon:ctx[@"addon"] withJSON:jsonObject];
					success = YES;
				} else {
					errMsg = @"Couldn't parse result from ofxaddons.com";
				}
			} else {
				errMsg = connectionError.localizedDescription;
			}
			
			if(!success) {
				dispatch_async(dispatch_get_main_queue(), ^{
					NSAlert * a = [NSAlert alertWithMessageText:@"Couldn't get addon info from ofxaddons.com"
												  defaultButton:nil
												alternateButton:nil
													otherButton:nil
									  informativeTextWithFormat:@"%@", errMsg];
					
					[a beginSheetModalForWindow:[NSApp keyWindow]
								  modalDelegate:nil
								 didEndSelector:nil
									contextInfo:nil];
				});
			}
		}];
	}
}

- (void) cloneDependencies:(NSArray *)dependencies forAddon:(OFAddon *)addon withJSON:(NSDictionary *)json {
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		
		NSString * gitPath = [self gitPath];
		if(!gitPath) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[[NSAlert alertWithMessageText:@"Couldn't locate git"
								 defaultButton:nil
							   alternateButton:nil
								   otherButton:nil
					 informativeTextWithFormat:@"Dependencies not installed"] runModal];
			});
			return;
		}
		
		NSString * owner = nil;
		for(NSDictionary * repo in json[@"repos"]) {
			if([repo[@"name"] isEqualToString:addon.name]) {
				owner = repo[@"owner"];
			}
		}
		
		NSArray * reposToClone = [self bestReposFromJSON:json forDependencies:dependencies owner:owner];
		
		@try {
			[self printToConsole:[NSString stringWithFormat:@"using git at %@\n", gitPath]];
			
			// do the cloning
			for(NSDictionary * repo in reposToClone) {
				NSString * repoName = repo[@"name"];
				[self printToConsole:[NSString stringWithFormat:@"cloning %@ ... ", repoName]];
				
				NSTask * cloneTask = [[NSTask alloc] init];
				[cloneTask setLaunchPath:gitPath];
				[cloneTask setCurrentDirectoryPath:_addonsPath];
				[cloneTask setArguments:@[@"clone", repo[@"clone_url"]]];
				[cloneTask launch];
				[cloneTask waitUntilExit];
				
				[self printToConsole:[NSString stringWithFormat:@"done!\n"]];
				
				dispatch_async(dispatch_get_main_queue(), ^{
					[self addAddon:[OFAddon addonWithPath:[self pathForAddonWithName:repoName] name:repoName]];
				});
			}
			[self printToConsole:@"done cloning\n"];
		}
		@catch (NSException *exception) {
			[self printToConsole:[NSString stringWithFormat:@"issue while cloning: %@\n", exception.reason]];
		}
		@finally {
			
		}
	});
}

- (NSArray *)bestReposFromJSON:(NSDictionary *)json forDependencies:(NSArray *)dependencies owner:(NSString *)owner {
	
	NSMutableArray * repos = [[NSMutableArray alloc] init];
	for(NSString * dep in dependencies) {
		NSMutableArray * candidates = [[NSMutableArray alloc] init];
		
		for(NSDictionary * repo in json[@"repos"]) {
			if ([repo[@"name"] isEqualToString:dep] && repo[@"clone_url"]) {
				[candidates addObject:repo];
			}
		}
		
		if(candidates.count == 0) {
			[self printToConsole:[NSString stringWithFormat:@"couldn't find repo for %@\n", dep]];
		} else if(candidates.count == 1) {
			[repos addObject:candidates[0]];
		} else {
			NSDictionary * chosenCandidate = nil;
			
			// search for a fork by the same owner
			for(NSDictionary * candidate in candidates) {
				if([candidate[@"owner"] isEqualToString:owner]) {
					chosenCandidate = candidate;
				}
			}
			
			// search for the most recently updated fork
			if(!chosenCandidate) {
				[candidates sortUsingComparator:^NSComparisonResult(NSDictionary * a, NSDictionary * b) {
					NSDate * aDate = [NSDate dateWithString:a[@"last_pushed_at"]];
					NSDate * bDate = [NSDate dateWithString:b[@"last_pushed_at"]];
					return [aDate compare:bDate];
				}];
				
				chosenCandidate = [candidates lastObject];
			}
			
			[repos addObject:chosenCandidate];
		}
	}
	return repos;
}

- (NSString *)gitPath {
	
	// first, try and find the user's preferred git install
	NSTask * findGit = [[NSTask alloc] init];
	NSPipe * outputPipe = [NSPipe pipe];
	NSPipe * inputPipe = [NSPipe pipe];
	[findGit setLaunchPath:@"/bin/bash"];
	[findGit setArguments:@[@"--login"]];
	[findGit setStandardOutput:outputPipe];
	[findGit setStandardInput:inputPipe];
	[findGit launch];
	[[inputPipe fileHandleForWriting] writeData:[@"which git; logout;\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[findGit waitUntilExit];
	NSData * output = [[outputPipe fileHandleForReading] readDataToEndOfFile];
	NSString * gitPath = [[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding];
	gitPath = [gitPath stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if(gitPath && [[NSFileManager defaultManager] fileExistsAtPath:gitPath]) {
		return gitPath;
	}
	// if we couldn't find one, try /usr/bin/git as a fallback
	else if([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/git"]) {
		return @"/usr/bin/git";
	}
	// no git :(
	else {
		return nil;
	}
}

#pragma mark - Extra Utils

- (void)printToConsole:(NSString *)string {
	dispatch_async(dispatch_get_main_queue(), ^{
		@try {
			NSAttributedString * attrString = [[NSAttributedString alloc] initWithString:string attributes:[[self consoleView] typingAttributes]];
			[[[self consoleView] textStorage] appendAttributedString:attrString];
		}
		@catch (NSException *exception) {
			
		}
		@finally {
			
		}
	});
}

- (NSTextView *) consoleView {
	id workspaceController = [[NSApp keyWindow] windowController];
	id editorArea = objc_msgSend(workspaceController, @selector(editorArea));
    id activeDebuggerArea = objc_msgSend(editorArea, @selector(activeDebuggerArea));
    id consoleArea = objc_msgSend(activeDebuggerArea, @selector(consoleArea));
    return (NSTextView *)[consoleArea valueForKeyPath:@"_consoleView"];
}

@end
