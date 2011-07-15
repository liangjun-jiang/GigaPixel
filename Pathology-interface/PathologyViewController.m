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
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(IBAction)addUserAction
{
    UIAlertView *userNameAlert = [[UIAlertView alloc] initWithTitle:@"Your name" message:@"user name" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    usernameField = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 45.0, 260.0, 25.0)];
    [usernameField setKeyboardType:UIKeyboardTypeAlphabet];
    CGAffineTransform myTransform = CGAffineTransformMakeTranslation(0.0, 130.0);
    [userNameAlert setTransform:myTransform];
    
    [usernameField setBackgroundColor:[UIColor whiteColor]];
    [userNameAlert addSubview:usernameField];
    [usernameField becomeFirstResponder];
    [userNameAlert show];
 }

-(void)displayGigapixel
{
    GigaPixelViewController *vc =[[[GigaPixelViewController alloc] initWithNibName:nil bundle:nil] autorelease];
    vc.gigapixelIdentifier = gigapixelIdentifier;   
    vc.username = usernameField.text;
    [usernameField release];
    vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentModalViewController:vc animated:YES];
    
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1 && usernameField.text !=nil) {
        //NSLog(@"user name:%@", usernameField.text);
        [usernameField resignFirstResponder];
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  	[alertView release];
    [self displayGigapixel];
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

// For a moment, we let the keyword point to GigaPixel
-(void)buttonTapped:(ButtonGroupButton *)inButton
{
    GigaPixelViewController *vc = [[GigaPixelViewController alloc] initWithNibName:nil bundle:nil];
    vc.gigapixelIdentifier = [inButton.titleLabel.text intValue];
    
    vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentModalViewController:vc animated:YES];
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#define PI 3.14

/*
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    NSLog(@"will called?");
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        [[NSBundle mainBundle] loadNibNamed:@"PathologyPortaitViewController" owner:self options:nil];
        if (toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
            self.view.transform = CGAffineTransformMakeRotation(PI);
        }
        
    } else if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)){
        NSLog(@"landscape");
        [[NSBundle mainBundle] loadNibNamed:@"PathologyViewController" owner:self options:nil];
        if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
            self.view.transform = CGAffineTransformMakeRotation(PI + PI/2);
        } else {
            self.view.transform = CGAffineTransformMakeRotation(PI/2);
        }
    }
}
 */
@end
