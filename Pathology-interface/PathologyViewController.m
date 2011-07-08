//
//  PathologyViewController.m
//  Pathology-interface
//
//  Created by Liangjun Jiang on 7/7/11.
//  Copyright 2011 Harvard University Extension School. All rights reserved.
//

#import "PathologyViewController.h"
#import "Chapter.h"
#import "ButtonGroup.h"
#import "ButtonGroupButton.h"
#import "ChaptersViewController.h"

@implementation PathologyViewController
@synthesize keywordButtonGroup;
@synthesize otherInfoButtonGroup;
@synthesize pathologyNameLabel;  
@synthesize anotherLabel, helpfulLabel; 

@synthesize synoposisView; 

@synthesize largeImage;

@synthesize navBar;
@synthesize gigaPixelButton;

@synthesize createProjectButton; //TODO: 
@synthesize noteField;
@synthesize chapter;

- (void)dealloc
{
    [pathologyNameLabel release];
    [navBar release];
    [gigaPixelButton release];
    [chapter release];
    [noteField release];
    [createProjectButton release];
    [largeImage release];
    [synoposisView release];
    
    [keywordButtonGroup release];
    [otherInfoButtonGroup release];
   
    [anotherLabel release];
    [helpfulLabel release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(IBAction)back;
{
    [self dismissModalViewControllerAnimated:YES];
}
-(IBAction)doSomething;
{
    
}

-(void)buttonTapped:(ButtonGroupButton *)inButton
{
    //ChaptersViewController *vc = (ChaptersViewController *)self.parentViewController;
    //vc.section = inButton.section;
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    //NSLog(@"chapter image: %@", [chapter objectForKey:@"image"]);
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
   
}

//TODO: able to handle portrait
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

@end
