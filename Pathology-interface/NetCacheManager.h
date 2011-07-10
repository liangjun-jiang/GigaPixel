//
//  NetCacheManager.h
//  GigaPixelInterface
//
//  Created by Axel Hansen on 4/27/10.
//  Copyright 2010 Harvard University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Tile.h"

@interface NetCacheManager : NSObject {
	Tile* head;
	Tile* tail;
	int capacity;
	int currentSize;
	NSLock *cacheLock;
}

-(void)addToCache:(Tile*) tile;
-(Tile*)removeLeastRecentlyUsed;
-(void)touchTile:(Tile*) tile;
-(BOOL)isFull;
-(void) removeFromCacheWithTile:(Tile*)remove;


@end
