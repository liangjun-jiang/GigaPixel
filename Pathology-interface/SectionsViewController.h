//
//  SectionsViewController.h
//  Pathology-interface
//
//  Created by Liangjun Jiang on 7/7/11.
//  Copyright 2011 Harvard University Extension School. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AQGridViewController.h"
#import "CellLoading.h"
#import "AQGridView.h"
#import "SearchViewController.h"



@interface SectionsViewController : UIViewController <AQGridViewDelegate, AQGridViewDataSource, UIActionSheetDelegate, UIPopoverControllerDelegate>{
    AQGridView *gridView;
    NSMutableDictionary *sections;
    
    UIBarButtonItem *infoButton;
    UIBarButtonItem *searchButton; 
    UIPopoverController *popoverController;
    
    SearchViewController *searchView;
   // UserId *user;
    
}

@property (nonatomic, retain) NSMutableDictionary *sections;
@property (nonatomic, retain) IBOutlet AQGridView *gridView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *infoButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *searchButton; 
@property (nonatomic, retain) IBOutlet UIPopoverController *popoverController;

//@property (retain) UserId *user;

- (IBAction)search; //TODO
- (IBAction)info;


@end
