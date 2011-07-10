//
//  PrefetchManager.h
//  GigaPixel
//
//  Created by Axel Hansen on 3/15/10.
//  Copyright 2010 Harvard University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GigaPixel.h"
#import "TileManager.h"


@interface PrefetchManager : NSObject {
	NSThread *thread;
	semaphore_t *signalSem;
	
	CFRunLoopSourceRef runLoopSource;
	TileManager *tm;
	
	//current bounds
	int left;
	int right;
	int bottom;
	int top;
	int curLevel;
	float floatLevel;
	NSLock *boundsLock;
	CGRect windowBounds;
	float *ctrPos;
	NSLock *pauseLock; //will be used to pause the thread
}
-(NSThread*) getThread;
- (void)prefetch;
-(void) startThread;
-(void) setTileManager:(TileManager*) t;
-(void)setCurBoundsWithLeft:(int)l andRight:(int)r andTop:(int)t andBottom:(int)b andLevel:(int)level andFloatLevel:(float)fL andCtrPos:(float*)cP;
-(void)pauseThread;
-(void)unPauseThread;


@end
