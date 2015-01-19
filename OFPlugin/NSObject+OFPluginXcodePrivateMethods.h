//
// This is a list of private methods used in Xcode, partially
// for documentation and partially to silence compiler warnings
//

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
- (id /* XCConfigurationList */) buildConfigurationList;
- (NSArray *) buildConfigurationNames;
- (id) appropriateBuildPhaseForFileReference:(id)arg1;
- (id) copyFilesBuildPhases;

// PBXFileReference
- (id /* PBXFileType */) fileType;

// PBXFileType
- (NSString *) UTI;
- (BOOL) isStaticLibrary;
- (BOOL) isFramework;

// PBXBuildPhase
+ (id) identifier;

// XCConfigurationList
- (NSArray *)buildSettingDictionariesForConfigurationName:(NSString *)name errors:(id)err;
- (void) invalidateCaches;

// drilling down to the console text storage
- (id) editorArea;
- (id) activeDebuggerArea;
- (id) consoleArea;

@end
