//
//  UserId.m
//  Pathology-interface
//
//  Created by Liangjun Jiang on 7/7/11.
//  Copyright 2011 Harvard University Extension School. All rights reserved.
//

#import "UserId.h"

#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"

#define USERKEY @"USERID"
#define GIGAPIXELKEY @"GIGAPIXELID"

@implementation UserId

@synthesize networkQueue;

- (void) obtainUserIdWithAsyncRequest {
	NSURL *webUrl = [NSURL URLWithString:@"https://www.netflix.com/YourAccount"];
	[networkQueue cancelAllOperations];
	networkQueue = [ASINetworkQueue queue];
	[networkQueue retain];
	networkQueue.delegate = self;
	networkQueue.requestDidFinishSelector = @selector(idDidLoad:);
	networkQueue.requestDidFailSelector = @selector(requestFailed:);
	networkQueue.queueDidFinishSelector = @selector(queueFinished:);
	[networkQueue addOperation:[ASIHTTPRequest requestWithURL:webUrl]];
	[networkQueue go];
}

- (void)idDidLoad:(ASIHTTPRequest *)request {
	//NSLog(@"NetflixShopperId async request succeeded");
	NSArray *cookies = [request responseCookies];
	for(NSHTTPCookie *oneCookie in cookies) {
		NSLog(@"Cookie %@ = %@", [oneCookie name], [oneCookie value]);
		if ([@"NetflixShopperId" isEqualToString:[oneCookie name]]) {
			[self setUserId:[oneCookie value]];
		} else if ([@"GigaPixelId" isEqualToString:[oneCookie name]]) {
			[self setGigaPixelUserId:[oneCookie value]];
		}
	}
}

- (void)requestFailed:(ASIHTTPRequest *)inRequest;
{
	NSLog(@"NetflixShopperId async request failed for: %@", [[inRequest url] absoluteURL]);
}

- (void)queueFinished:(ASIHTTPRequest *)inRequest;
{
	//NSLog(@"MovieInfoView async request queue finished");
}

- (NSString *)getUserId
{

	return [[NSUserDefaults standardUserDefaults] stringForKey:USERKEY];
}

- (void)setUserId:(NSString *)sid
{
	return [[NSUserDefaults standardUserDefaults] setObject:sid forKey:USERKEY];
}

- (NSString *)getGigaPixelUserId
{
	return [[NSUserDefaults standardUserDefaults] stringForKey:GIGAPIXELKEY];
}

- (void)setGigaPixelUserId:(NSString *)nid
{
	[[NSUserDefaults standardUserDefaults] setObject:nid forKey:GIGAPIXELKEY];
}

- (void)dealloc {
	[networkQueue cancelAllOperations];
	[networkQueue release];
	networkQueue = nil;
	[super dealloc];
}


@end
