//
//  Pathology_interfaceAppDelegate.h
//  Pathology-interface
//
//  Created by Liangjun Jiang on 7/7/11.
//  Copyright 2011 Harvard University Extension School. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SectionsViewController;

@interface Pathology_interfaceAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    SectionsViewController *viewController;

}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet SectionsViewController *viewController;

@end
