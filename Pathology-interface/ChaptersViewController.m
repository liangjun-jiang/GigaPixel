//
//  ChaptersViewController.m
//  Pathology-interface
//
//  Created by Liangjun Jiang on 7/7/11.
//  Copyright 2011 Harvard University Extension School. All rights reserved.
//

#import "ChaptersViewController.h"
#import "AQGridView.h"
#import "Chapter.h"
#import "ChapterCell.h"
#import "PathologyViewController.h"
#import "Section.h"


@implementation ChaptersViewController
@synthesize navBar, section, gridView, chapters, networkQueue, detailButton;

- (void)dealloc
{
    [networkQueue cancelAllOperations];
    [networkQueue release];
    networkQueue = nil;
    
    [gridView release];
    gridView = nil;
    
    [section release];
    section = nil;
    
    [chapters release];
    chapters = nil;
    
    [navBar release];
    navBar = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.gridView deselectItemAtIndex: [self.gridView indexOfSelectedItem] animated: animated];
	[gridView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    gridView.leftContentInset = 60.0f;
    gridView.rightContentInset = 60.0f;
    navBar.topItem.title = self.title;
    //navBar.topItem.rightBarButtonItem.title = [NSString stringWithFormat:@"Section: %@", section.number];
    
}

/*
-(void)setSection:(Section *)value
{
    if (section == value) {
        return;
    }
    [section release];
    section = [value retain];
    self.title = @"test title";
    //self.title = [NSString stringWithFormat:@"Section: %@",section.number];
    navBar.topItem.title = self.title;
    navBar.topItem.rightBarButtonItem.title = @"Detail";//[NSString stringWithFormat:@"", section.number];
    page = 0;
    [self requestSectionPage]; //
    [gridView reloadData];
    
}
*/


- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

-(IBAction)back;
{
    [self dismissModalViewControllerAnimated:YES];
}

//TODO:
-(IBAction)detail;
{
    
}


-(NSUInteger)numberOfItemsInGridView:(AQGridView *)gridView
{
    //return [chapters count];
    return 5;
}

-(AQGridViewCell *)gridView: (AQGridView *)inGridView cellForItemAtIndex:(NSUInteger)index
{
    ChapterCell *cell = (ChapterCell *)[inGridView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [ChapterCell cell];
        cell.reuseIdentifier = @"cell";
    }
    
    return cell;
}


-(void)gridView:(AQGridView *)gridView didSelectItemAtIndex:(NSUInteger)index
{
    PathologyViewController *vc = [[[PathologyViewController alloc] initWithNibName:nil bundle:nil] autorelease];
    
    Chapter *chapter = [[chapters allKeys] objectAtIndex:index];
    vc.chapter = chapter;
    
    vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentModalViewController:vc animated:YES];
    
}

-(CGSize)portraitGridCellSizeForGridView:(AQGridView *)gridView
{
    return CGSizeMake(200, 250);
}

@end
