//
//  SearchViewController.h
//  Pathology-interface
//
//  Created by Liangjun Jiang on 7/12/11.
//  Copyright 2011 Harvard University Extension School. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SearchViewController : UITableViewController<UISearchBarDelegate> {
    UIPopoverController *popoverController;
    UISearchBar *keywordSearchBar;
    NSDictionary *keywordLibrary;
    NSArray *searchResults;
}

@property (nonatomic, retain) NSArray *searchResults;
-(void)setPopup:(UIPopoverController*)p;
-(BOOL)performSeachWithKeyword:(NSString *)searchString;

@end
