//
//  PollMsg.h
//  GigaPixel
//
//  Created by Axel Hansen on 3/1/11.
//  Copyright 2011 Harvard University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ES1Renderer.h"

int maxId;


@interface PollMsg : NSObject {
	ES1Renderer *renderer;
	struct Messages* data;

}

- (void) connectionDidFinish:(URLCacheConnection *)theConnection andLength:(NSTimeInterval) length;
- (void) connectionDidFail:(URLCacheConnection *)theConnection;
@end
