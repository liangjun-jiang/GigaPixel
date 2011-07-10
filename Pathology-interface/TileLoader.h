//
//  TileLoader.h
//  GigaPixel
//
//  Created by Axel Hansen on 3/18/10.
//  Copyright 2010 Harvard University. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "GigaPixel.h"
#include "Tile.h"

@interface TileLoader : NSObject {
	NSThread *thread;
	NSMutableArray *toLoad;
	NSMutableArray *toPreLoad;
	NSRecursiveLock *tileLoaderLock;
	NSRecursiveLock *tilePreLoaderLock;
	semaphore_t *signalSem;
	BOOL shouldDie;
	BOOL didDie;
	int num_downloading;

}
-(void)killThread;
-(BOOL)isKilled;
//-(void)reset:(TileManager*)tm;
-(int)test;
-(void)tileLoad;
-(Tile*)getNextTileToLoadwithTried:(NSMutableArray*)tried;
-(void)addTileToLoad:(Tile*)t;
-(void)addTileToPreLoad:(Tile*)t;
-(void)signalNewTile;
-(semaphore_t*)getSemaphore;
-(int)getTileToLoadCount;
-(int)getTileToPreloadCount;
-(void)tileDownloaded;
//void LaunchThread(TileLoader *tl);
//void* tileLoad(void* data);


@end
