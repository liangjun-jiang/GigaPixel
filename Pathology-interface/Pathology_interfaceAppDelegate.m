//
//  Pathology_interfaceAppDelegate.m
//  Pathology-interface
//
//  Created by Liangjun Jiang on 7/7/11.
//  Copyright 2011 Harvard University Extension School. All rights reserved.
//

#import "Pathology_interfaceAppDelegate.h"
#import "SectionsViewController.h"

@implementation Pathology_interfaceAppDelegate

@synthesize window=_window;
@synthesize viewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [self.window addSubview:viewController.view];
    [self.window makeKeyAndVisible];
    return YES;
}



- (void)dealloc
{
    [viewController release];
    [_window release];
    [super dealloc];
}

@end
