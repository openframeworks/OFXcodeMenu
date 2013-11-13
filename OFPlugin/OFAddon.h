//
//  OFAddon.h
//  OFPlugin
//
//  Created by Adam Carlucci on 11/9/2013.
//  Copyright (c) 2013 lol. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OFAddon : NSObject

+ (instancetype) addonWithPath:(NSString *)path name:(NSString *)name;

@property (nonatomic, strong) NSString * path;
@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSString * url;

@property (nonatomic, readonly) NSArray * sourceFoldersToExclude;
@property (nonatomic, readonly) NSArray * headerFoldersToExclude;
@property (nonatomic, readonly) NSArray * extraHeaderSearchPaths;
@property (nonatomic, readonly) NSArray * extraLibPaths;
@property (nonatomic, readonly) NSArray * systemFrameworks;
@property (nonatomic, readonly) NSArray * dependencies;

- (void) setMetadataFromURL:(NSURL *)URL forPlatform:(NSString *)platform;

@end
