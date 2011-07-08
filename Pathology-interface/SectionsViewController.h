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
//#import "UserId.h" //TODO
#import "AQGridView.h"


@interface SectionsViewController : UIViewController <AQGridViewDelegate, AQGridViewDataSource, UIActionSheetDelegate>{
    AQGridView *gridView;
    NSMutableDictionary *sectionArray;
    
    UIBarButtonItem *infoButton;
    UIBarButtonItem *pathologyButton; //TODO
    
   // UserId *user;
    
}

@property (nonatomic, retain) NSMutableDictionary *sectionArray;
@property (nonatomic, retain) IBOutlet AQGridView *gridView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *infoButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *pathologyButton; //TODO
//@property (retain) UserId *user;

- (IBAction)pathology; //TODO
- (IBAction)info;


@end
