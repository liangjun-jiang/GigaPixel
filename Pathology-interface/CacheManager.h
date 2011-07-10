//
//  CacheManager.h
//  GigaPixel
//
//  Created by Axel Hansen on 3/13/10.
//  Copyright 2010 Harvard University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Tile.h"


@interface CacheManager : NSObject {
	Tile* head;
	Tile* tail;
	int capacity;
	int currentSize;
}

-(void)addToCache:(Tile*) tile;
-(Tile*)removeLeastRecentlyUsed;
-(void)touchTile:(Tile*) tile;
-(BOOL)isFull;
-(void) removeFromCacheWithTile:(Tile*)remove;
@end
