//
//  PathologyViewController.h
//  Pathology-interface
//
//  Created by Liangjun Jiang on 7/7/11.
//  Copyright 2011 Harvard University Extension School. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ButtonGroup;
@class Chapter;

@interface PathologyViewController : UIViewController <UIAlertViewDelegate, UIWebViewDelegate>{
    ButtonGroup *keywordButtonGroup;
    ButtonGroup *otherInfoButtonGroup;
    
    UILabel *pathologyNameLabel;  
    
    UITextView *synoposisView; 
    UIImageView *largeImage;
    
    UINavigationBar *navBar;
    UIBarButtonItem *gigaPixelButton;
    NSMutableDictionary *chapter;
    //NSArray *keywords;
    
    NSInteger gigapixelIdentifier;
    
    UILabel *anotherLabel; //TODO: some meaningful name
    UILabel *helpfulLabel;
    UIButton *createProjectButton; //TODO: 
    UITextField *noteField;
    
    
    
}

@property (nonatomic, retain) NSMutableDictionary *chapter;
//@property (copy) NSArray *keywords;
@property (nonatomic, retain) IBOutlet ButtonGroup *keywordButtonGroup;
@property (nonatomic, retain) IBOutlet ButtonGroup *otherInfoButtonGroup;
@property (nonatomic, retain) IBOutlet UILabel *helpfulLabel;
@property (nonatomic, retain) IBOutlet UILabel *pathologyNameLabel;

@property (nonatomic, retain) IBOutlet UILabel *anotherLabel;

@property (nonatomic, retain) IBOutlet UITextView *synoposisView;
@property (nonatomic, retain) IBOutlet UIImageView *largeImage;
@property (nonatomic, retain) IBOutlet UINavigationBar *navBar;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *gigaPixelButton;
@property (nonatomic, retain) IBOutlet UIButton *createProjectButton;
@property (nonatomic, retain) IBOutlet UITextField *noteField;


-(IBAction)back;
-(IBAction)displayGigapixel;

@end
