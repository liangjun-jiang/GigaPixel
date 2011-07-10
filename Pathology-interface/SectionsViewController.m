//
//  SectionsViewController.m
//  Pathology-interface
//
//  Created by Liangjun Jiang on 7/7/11.
//  Copyright 2011 Harvard University Extension School. All rights reserved.
//

#import "SectionsViewController.h"
#import "Section.h"
#import "SectionCell.h"
#import "ChaptersViewController.h"
#import "CJSONDeserializer.h"
#import "GigaPixelViewController.h"
#import "WebViewController.h"
//#import "UserId.h"
#import "AQGridView.h"
#import "Chapter.h"

@implementation SectionsViewController
@synthesize sections;
@synthesize gridView;
@synthesize infoButton;
@synthesize pathologyButton;
//@synthesize user;


- (void)viewWillAppear:(BOOL)animated;
{
	[super viewWillAppear:animated];
  	[gridView deselectItemAtIndex: [self.gridView indexOfSelectedItem] animated: animated];
	[gridView reloadData];
    
}

- (void)viewDidLoad;
{
    sections = [[NSMutableDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Pathology" ofType:@"plist"]];
}


- (NSUInteger) numberOfItemsInGridView: (AQGridView *) gridView;
{
	return [self.sections count];
}



- (AQGridViewCell *) gridView: (AQGridView *)inGridView cellForItemAtIndex: (NSUInteger) index;
{
    static NSString *identifier = @"cell";
	SectionCell *cell = (SectionCell *)[inGridView dequeueReusableCellWithIdentifier:identifier];
	
    if (!cell) {
        cell = [SectionCell cell];
      	cell.reuseIdentifier = identifier;
    }
    
	cell.backgroundColor = [UIColor clearColor];
	cell.selectionStyle = AQGridViewCellSelectionStyleGlow;
	
	cell.numberLabel.text = [[sections allKeys] objectAtIndex:index]; 
    
	return cell;
}

-(void)gridView:(AQGridView *)gridView didSelectItemAtIndex:(NSUInteger)index
{
    ChaptersViewController *vc = [[[ChaptersViewController alloc] initWithNibName:nil bundle:nil] autorelease];
    //vc.sectionName = [[sections objectForKey:[[sections allKeys] objectAtIndex:index]] objectForKey:@"title"];
    vc.chapters = [sections objectForKey:[[sections allKeys] objectAtIndex:index]];
    vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentModalViewController:vc animated:YES];
}


-(CGSize) portraitGridCellSizeForGridView:(AQGridView *)gridView
{
    return CGSizeMake(223, 250);
}


- (void)dealloc
{
    [gridView release];
    gridView = nil;
    [sections release];
    sections = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)pathology
{
    WebViewController *web = [[WebViewController alloc] initWithUrlString:@"http://neuro.med.harvard.edu/"];
    web.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentModalViewController:web animated:YES];
    [web release];
}
- (IBAction)info
{
    UIActionSheet *actionAlert = [[UIActionSheet alloc] initWithTitle:@"Info" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Credits", @"Dr.Pfister's lab", nil];
    [actionAlert showInView:[self view]];
    [actionAlert release];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
		case 0: { // Credits popup	
			UIActionSheet *actionAlert = [[UIActionSheet alloc] initWithTitle:@"Credits\n\nThanks to Harvar University for the funding and the abc for Inspiration\nDr. abc for most of the code\nDr. dedad for OData and the queries\nABDED for AQGridView\nAxel  for product concept, debug and final production\n\n"
																	 delegate:self
															cancelButtonTitle:nil
													   destructiveButtonTitle:nil
															otherButtonTitles:nil];
			[actionAlert showInView:[self view]];
			[actionAlert release];
			break;
		}
		case 1: { // Visit the Hanspeter Pfister Lab
			WebViewController *web = [[WebViewController alloc] initWithUrlString:@"http://gvi.seas.harvard.edu/pfister"];
			web.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
			[self presentModalViewController:web animated:YES];
            [WebViewController release];
			break;
		}
		default:
			break;
	}
	return;
}


#pragma mark - View lifecycle


- (void)viewDidUnload
{
    [super viewDidUnload];
    self.gridView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
