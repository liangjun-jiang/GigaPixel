//
//  ChaptersViewController.h
//  Pathology-interface
//
//  Created by Liangjun Jiang on 7/7/11.
//  Copyright 2011 Harvard University Extension School. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AQGridView.h"
#import "CellLoading.h"

@class Section;

@interface ChaptersViewController : UIViewController <AQGridViewDelegate, AQGridViewDataSource>{
    IBOutlet AQGridView *gridView;
        
    NSString *sectionName;
    
    UINavigationBar *navBar;
    UIBarButtonItem *detailButton;
    
    NSMutableDictionary *chapters;
    
    //NSInteger page;
}

@property (retain) IBOutlet UINavigationBar *navBar;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *detailButton;
@property (nonatomic, retain) NSString *sectionName;
@property (copy) NSMutableDictionary *chapters;
@property (retain) AQGridView *gridView;



-(IBAction)back;
-(IBAction)detail;

@end
