//
//  CacheManager.m
//  GigaPixel
//
//  Created by Axel Hansen on 3/13/10.
//  Copyright 2010 Harvard University. All rights reserved.
//

/*
 Basic cache manager to manage cache for main memory.  LRU removal.  doubly linked list built into tile class, but access methods
 in here
 */

#import "CacheManager.h"


@implementation CacheManager
- (id)initWithCapacity:(int)s
{
	capacity = s;
	currentSize = 0;
	return self;
}
	


-(void)addToCache:(Tile*) tile
{
	currentSize++;
	if(tail == NULL)
	{
		tail = tile;
		head = tile;
	}
	else 
	{
		[tile setNext:tail];
		[tile setPrev:NULL];
		[tail setPrev:tile];
		tail = tile;
	}

}


-(void) removeFromCacheWithTile:(Tile*)remove
{
	if(head==remove)
		head=[remove getPrev];
	if(tail==remove)
		tail=[remove getNext];
	[remove setInCacheTo:FALSE];
	[remove deleteFromCache];
}


-(Tile*)removeLeastRecentlyUsed
{
	if(head != NULL)
	{
		currentSize--;
		Tile* remove = head;
		[remove lockTile];
		[remove setInCacheTo:FALSE];
		head = [remove getPrev];
		[remove deleteFromCache];
		[remove freeFromMemory];
		if(head==NULL)
			tail = NULL;
		[remove unLockTile];
		return remove;
	}
	return NULL;
}

-(void)touchTile:(Tile*) tile
{
	if([tile isInCache])
		currentSize--; //to make sure we don't over increment cache size
	else {
		[tile setInCacheTo:TRUE];
	}
	if(head==tile)
		head = [tile getPrev];

	[tile deleteFromCache];
	[self addToCache:tile];
}

-(BOOL)isFull
{
//	NSLog(@"Current cache size = %d", currentSize);
	return currentSize>=capacity;
}



@end
