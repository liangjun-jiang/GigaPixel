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
@synthesize navBar, gridView, chapters, detailButton, sectionName;

- (void)dealloc
{
    [gridView release];
    gridView = nil;
    
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
    navBar.topItem.title = sectionName;
}

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

//TODO: Maybe open a webview to check the online pdf or web or something
-(IBAction)detail;
{
    
}


-(NSUInteger)numberOfItemsInGridView:(AQGridView *)gridView
{
    return [chapters count];
}

-(AQGridViewCell *)gridView: (AQGridView *)inGridView cellForItemAtIndex:(NSUInteger)index
{
    ChapterCell *cell = (ChapterCell *)[inGridView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [ChapterCell cell];
        cell.reuseIdentifier = @"cell";
    }
    
    cell.backgroundColor = [UIColor clearColor];
	cell.selectionStyle = AQGridViewCellSelectionStyleGlow;
    
    
    NSString *imageName = [[chapters objectForKey:[[chapters allKeys] objectAtIndex:index]] objectForKey:@"image"];
    
	cell.thumbnailImageView.image = [UIImage imageNamed:imageName]; 
    
    cell.chapterNameLabel.text = [[chapters objectForKey:[[chapters allKeys] objectAtIndex:index]] objectForKey:@"title"];
    if ([[[chapters objectForKey:[[chapters allKeys] objectAtIndex:index]] objectForKey:@"gigapixel"] intValue] == 0) {
        cell.gigaPixelAvailable.hidden = YES;
    }
    
    return cell;
}


-(void)gridView:(AQGridView *)gridView didSelectItemAtIndex:(NSUInteger)index
{
    
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if (deviceOrientation == UIInterfaceOrientationLandscapeLeft || deviceOrientation == UIInterfaceOrientationLandscapeRight)
    {
       PathologyViewController *vc = [[[PathologyViewController alloc] initWithNibName:nil bundle:nil] autorelease];
        vc.chapter =[chapters objectForKey:[[chapters allKeys] objectAtIndex:index]];
        vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self presentModalViewController:vc animated:YES];
    }
    
    else 
    {
        PathologyViewController *vc = [[[PathologyViewController alloc] initWithNibName:@"PathologyPortaitViewController" bundle:nil] autorelease];
        vc.chapter =[chapters objectForKey:[[chapters allKeys] objectAtIndex:index]];
        vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self presentModalViewController:vc animated:YES];
    }
}

-(CGSize)portraitGridCellSizeForGridView:(AQGridView *)gridView
{
    return CGSizeMake(200, 250);
}

@end
