//
//  UserId.h
//  Pathology-interface
//
//  Created by Liangjun Jiang on 7/7/11.
//  Copyright 2011 Harvard University Extension School. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "ASIHTTPRequest.h"
//#import "ASINetworkQueue.h"
//#import "ASIHTTPRequestDelegate.h"


@interface UserId : NSObject  {
    //ASINetworkQueue *networkQueue;
}
//@property (retain) ASINetworkQueue *networkQueue;

- (void)obtainUserIdWithAsyncRequest;
//- (void)idDidLoad:(ASIHTTPRequest *)request;

// these functions can be accessed by an ephemeral instance
- (NSString *)getUserId;	// return the id if we have one persisted
- (void)setUserId:(NSString *)sid; // change the persisted id
- (NSString *)getGigaPixelUserId;	// return the id if we have one persisted
- (void)setGigaPixelUserId:(NSString *)nid; // change the persisted id

@end
