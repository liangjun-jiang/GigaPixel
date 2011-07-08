//
//  WebViewController.h
//  Pathology-interface
//
//  Created by Liangjun Jiang on 7/7/11.
//  Copyright 2011 Harvard University Extension School. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface WebViewController : UIViewController<UIWebViewDelegate> {
    UIWebView   *webView;
	UIBarButtonItem *demoButton;
	NSString	*urlString;
}

@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *demoButton;


- (id) initWithUrlString:(NSString *)aString;
- (IBAction)back;
- (IBAction)demo;
- (void)webViewDidFinishLoad:(UIWebView *)webView;

@end
