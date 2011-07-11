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
#import "GigaPixelViewController.h"

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
//@synthesize keywords;


-(IBAction)back
{
    [self dismissModalViewControllerAnimated:YES];
}

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
    //[keywords release];
    //keywords = nil;
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}



-(IBAction)displayGigapixel
{
    GigaPixelViewController *vc =[[[GigaPixelViewController alloc] initWithNibName:nil bundle:nil] autorelease];
    vc.gigapixelIdentifier = gigapixelIdentifier;   
    vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentModalViewController:vc animated:YES];

}

-(NSMutableArray *)parseKeywords:(NSString *)keywordsString
{
    NSCharacterSet *semicolonSet;
    NSScanner *theScanner;
    NSString *keyword;
    
    semicolonSet = [NSCharacterSet characterSetWithCharactersInString:@","];
    theScanner = [NSScanner scannerWithString:keywordsString];
    NSMutableArray *keywordArray = [NSMutableArray array];
    while ([theScanner isAtEnd] == NO)
    {
        if ([theScanner scanUpToCharactersFromSet:semicolonSet
                                       intoString:&keyword] &&
            [theScanner scanString:@"," intoString:NULL])
        {
            [keywordArray addObject:keyword];
        }
    }
    return keywordArray;    
}

-(void)buttonTapped:(ButtonGroupButton *)inButton
{
    //TODO: Have not thought about how to handle keyword yet.
    
    //ChaptersViewController *vc = (ChaptersViewController *)self.parentViewController;
    //vc.section = inButton.section;
    [self dismissModalViewControllerAnimated:YES];
}

- (void)displayKeywords:(NSMutableArray *)keywordsArray
{
    [keywordButtonGroup removeAllSubviews];
    for (NSString *str in keywordsArray){
        ButtonGroupButton *button = [ButtonGroupButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:str forState:UIControlStateNormal];
        [keywordButtonGroup addSubview:button];
        
        [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        button.keyword = str;
    }
    
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navBar.topItem.title = [chapter objectForKey:@"title"];
    gigaPixelButton.enabled = FALSE;
    largeImage.image = [UIImage imageNamed:[chapter objectForKey:@"image"]];
    pathologyNameLabel.text = [chapter objectForKey:@"title"];
    synoposisView.text = [chapter objectForKey:@"synoposis"];
    
    gigapixelIdentifier = [[chapter objectForKey:@"gigapixel"] intValue];
    
    if (gigapixelIdentifier) {
        gigaPixelButton.enabled = TRUE;
    }
    
    NSString *keywordStr = [NSString stringWithFormat:@"%@", [chapter objectForKey:@"keywords"]];
   [self displayKeywords:[self parseKeywords:keywordStr]];
    
    
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
