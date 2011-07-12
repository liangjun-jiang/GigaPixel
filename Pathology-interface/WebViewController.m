//
//  WebViewController.m
//  Pathology-interface
//
//  Created by Liangjun Jiang on 7/7/11.
//  Copyright 2011 Harvard University Extension School. All rights reserved.
//

#import "WebViewController.h"


@implementation WebViewController
@synthesize webView, demoButton;

- (void)dealloc
{
    [webView release];
    [demoButton release];
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
   
    webView.scalesPageToFit = YES;
    if (urlString == nil) {
        [self demo];
    } else {
        NSLog(@"url: %@", urlString);
        [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
    }
        
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    self.webView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
 	return YES;
}

- (id) initWithUrlString:(NSString *)aString
{
    urlString = aString;
    [urlString retain];
    return self;
}
- (IBAction)back;
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self dismissModalViewControllerAnimated:YES];
}
- (IBAction)demo;
{
    /*
    urlString = @"http://www.youtube.com/gigaPixelDemo";
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
    */
}
- (void)webViewDidFinishLoad:(UIWebView *)webView;
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}


@end
