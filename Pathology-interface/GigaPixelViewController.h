//
//  GigaPixelViewController.h
//  Pathology-interface
//
//  Created by Liangjun Jiang on 7/7/11.
//  Copyright 2011 Harvard University Extension School. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface GigaPixelViewController : UIViewController {
    NSInteger gigapixelIdentifier;
    NSString *username;
    UINavigationBar *nav;
    
}

@property (readwrite) NSInteger gigapixelIdentifier;
@property (copy) NSString *username;
@property (nonatomic, retain) IBOutlet UINavigationBar *nav;

-(IBAction)back;
@end
