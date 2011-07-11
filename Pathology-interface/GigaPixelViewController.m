//
//  GigaPixelViewController.m
//  Pathology-interface
//
//  Created by Liangjun Jiang on 7/7/11.
//  Copyright 2011 Harvard University Extension School. All rights reserved.
//

#import "GigaPixelViewController.h"
#import "EAGLView.h"

@implementation GigaPixelViewController
@synthesize gigapixelIdentifier;
@synthesize nav;


-(IBAction)back
{
    [self dismissModalViewControllerAnimated:YES];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSMutableDictionary *gigapixels = [[[NSMutableDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"GigaPixel" ofType:@"plist"]] autorelease];
    
    NSMutableDictionary *gigapixel = [[[NSMutableDictionary alloc] init] autorelease];
    
    gigapixel = [gigapixels objectForKey:[NSString stringWithFormat:@"%d", gigapixelIdentifier]];
    
    NSString *theImg = [gigapixel objectForKey:@"theImg"];
    NSString *theUrl = [gigapixel objectForKey:@"theUrl"];
    int nS = [[gigapixel objectForKey:@"numSlice"] intValue];
    
    if (theImg && theUrl && nS) {
        NSLog(@"theImage: %@, theURL:%@, thens: %d", theImg, theUrl, nS);
        
        [[UIApplication sharedApplication] 
         setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:NO];
        [[UIApplication sharedApplication] setStatusBarHidden:TRUE animated:NO];
        
        EAGLView *glView = [[EAGLView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] andImg:theImg andUrl:theUrl andNumSlices:nS];
        
        glView.multipleTouchEnabled = TRUE;
        
        [self.view addSubview:glView];
    }
    
    
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
