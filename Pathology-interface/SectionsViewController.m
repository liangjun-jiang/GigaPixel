//
//  SectionsViewController.m
//  Pathology-interface
//
//  Created by Liangjun Jiang on 7/7/11.
//  Copyright 2011 Harvard University Extension School. All rights reserved.
//
#import <unistd.h>

#import "SectionsViewController.h"
#import "Section.h"
#import "SectionCell.h"
#import "ChaptersViewController.h"
#import "CJSONDeserializer.h"
#import "GigaPixelViewController.h"
#import "WebViewController.h"
//#import "UserId.h"
#import "AQGridView.h"
#import "PresoModeViewController.h"
#import "Chapter.h"

@implementation SectionsViewController
@synthesize sections;
@synthesize gridView;
@synthesize infoButton;
@synthesize externalDisplayButton;
@synthesize popoverController;
@synthesize presoModeViewController;
@synthesize extWindow;
//@synthesize user;


- (void)viewWillAppear:(BOOL)animated;
{
	[super viewWillAppear:animated];
  	[gridView deselectItemAtIndex: [self.gridView indexOfSelectedItem] animated: animated];
	[gridView reloadData];
    
}

- (void)viewDidLoad;
{
    if (sections == nil) {
        sections = [[NSMutableDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Pathology" ofType:@"plist"]];
    }
    
    presoModeViewController.contentSizeForViewInPopover = CGSizeMake(320, 252);
    NSLog(@"preso: %@", presoModeViewController);
    
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
    [infoButton release];
    [externalDisplayButton release];
    [popoverController release];
    [presoModeViewController release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)externalDisplay
{
    if (popoverController == nil) {
        Class cls = NSClassFromString(@"UIPopoverController");
        if (cls != nil) {
            UIPopoverController *aPopoverController =
            [[cls alloc] initWithContentViewController:self.presoModeViewController];
            aPopoverController.delegate = self;
            self.popoverController = aPopoverController;
            [aPopoverController release];
            [popoverController presentPopoverFromBarButtonItem:externalDisplayButton permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
            
        }
    }
    
}

-(void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.popoverController = nil;
}

-(void)externalWindow:(UIWindow *)window
{
    self.extWindow = window;
}

-(void)presoMode:(BOOL)isOn
{
    self.extWindow.hidden = YES;
    if (isOn == YES) {
        [extWindow addSubview:self.view];
    }
    
    self.extWindow.hidden = NO;
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
    sections = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
