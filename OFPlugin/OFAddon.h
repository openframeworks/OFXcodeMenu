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

@property (nonatomic, readonly) NSArray * foldersToExclude;
@property (nonatomic, readonly) NSArray * extraHeaderSearchPaths;
@property (nonatomic, readonly) NSArray * extraLibPaths;
@property (nonatomic, readonly) NSArray * systemFrameworks;

// returns YES if it found an addons_config.mk file
- (BOOL) setMetadataFromURL:(NSURL *)URL;

@end
