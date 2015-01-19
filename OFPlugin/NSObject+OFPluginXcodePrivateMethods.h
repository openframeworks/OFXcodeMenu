//
// This is a list of private methods used in Xcode, partially
// for documentation and partially to silence compiler warnings
//

// this specifies a copy files build phase with a "Frameworks" destination
// presumably this is actually an enum and can't be extracted by otool
static const int kPBXCopyFilesBuildPhaseFrameworksDestination = 10;

@interface NSObject (OFPluginXcodePrivateMethods)

// IDEWorkspaceDocument
- (id /* IDEWorkspace */ ) workspace;

// IDEWorkspace
- (id /* Xcode3Project */) wrappedXcode3Project;

// Xcode3Project
- (id /* PBXProject */) pbxProject;
- (id /* Xcode3Group */) rootGroup;

// Xcode3Group
- (id /* PBXGroup */) group;
- (id /* PBXGroupEnumerator */) groupEnumerator;

// PBXProject
- (NSArray *) targets;

// PBXGroup
+ (id /* PBXGroup */) groupWithName:(NSString *)name;
- (void) addFiles:(NSArray *)files copy:(BOOL)copy createGroupsRecursively:(BOOL)recursive;
- (void) removeItemsAtIndexes:(NSIndexSet *)indexes;
- (void) setContainer:(id /* PBXContainer */)container;

// PBXTarget
- (BOOL) addReference:(id)reference;
- (void) addBuildPhase:(id /* PBXBuildPhase */)arg1;
- (id /* XCConfigurationList */) buildConfigurationList;
- (NSArray *) buildConfigurationNames;
- (id) appropriateBuildPhaseForFileReference:(id)arg1;
- (id) copyFilesBuildPhases;
- (id) defaultFrameworksBuildPhase;

// PBXFileReference
- (id /* PBXFileType */) fileType;

// PBXFileType
- (NSString *) UTI;
- (BOOL) isStaticLibrary;
- (BOOL) isFramework;

// PBXBuildPhase
+ (id) identifier;

// PBXCopyFilesBuildPhase
- (int)destinationSubfolder;
- (void)setSubpath:(id)arg1 relativeToSubfolder:(int)arg2;

// XCConfigurationList
- (NSArray *)buildSettingDictionariesForConfigurationName:(NSString *)name errors:(id)err;
- (void) invalidateCaches;

// drilling down to the console text storage
- (id) editorArea;
- (id) activeDebuggerArea;
- (id) consoleArea;

@end
