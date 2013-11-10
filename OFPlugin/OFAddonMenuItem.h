//
//  OFAddonMenuItem.h
//  OFPlugin
//
//  Created by Adam Carlucci on 11/9/2013.
//  Copyright (c) 2013 lol. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OFAddon.h"

@interface OFAddonMenuItem : NSMenuItem

@property (nonatomic, strong) OFAddon * addon;

@end
