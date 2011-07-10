//
//  NetCacheManager.m
//  GigaPixelInterface
//
//  Created by Axel Hansen on 4/27/10.
//  Copyright 2010 Harvard University. All rights reserved.
//

/*
	Cache manager for disk/net.  similar to memory cache manager, but has to deal with locking, because accessed from different
 threads.
 */

#import "NetCacheManager.h"


@implementation NetCacheManager
- (id)initWithCapacity:(int)s
{
	capacity = s;
	currentSize = 0;
	cacheLock = [[NSLock alloc] init];
	return self;
}

-(void)dealloc
{
	[cacheLock release];
	[super dealloc];
}

-(void)print
{
	Tile *cur = head;
	int i = 0;
	while(cur!=NULL)
	{
		//printf("%d->",[cur getID]);
		i++;
		cur = [cur getPrevNet];
	}
	printf("Counted:%d reported:%d\n", i, currentSize);
	if(currentSize!=i)
		NSLog(@"ALERT!!!");
}
			   

-(void)addToCache:(Tile*) tile
{
	//printf("adding to cache %d\n", [tile getID]);

	//[cacheLock lock];
	//printf("Add to cache\n");
	//[self print];

	if(tile==NULL)
	{
		NSLog(@"Null tile added to cache");
		return;
	}
	currentSize++;
	if(tail == NULL)
	{
		tail = tile;
		head = tile;
	}
	else 
	{
		[tile setNextNet:tail];
		[tail setPrevNet:tile];
		tail = tile;
	}
	//printf("add: ");
	//[cacheLock unlock];
	//printf("Done add to cache\n");

}

-(void) removeFromCacheWithTile:(Tile*)remove
{
	return; //SHOULD NOT BE USED
	[cacheLock lock];
	currentSize--;
	if(head==remove)
		head=[remove getPrevNet];
	if(tail==remove)
		tail=[remove getNextNet];
	[remove setInCacheNetTo:FALSE];
	[remove deleteFromCacheNet];

	[cacheLock unlock];

}

-(Tile*)removeLeastRecentlyUsed
{
	[cacheLock lock];
	//printf("Rem LRU\n");

	//printf("rem LRU: ");

//	[self print];

	if(head != NULL)
	{
		/*if([head isLoading] || [head isInPreload])
		{
			NSLog(@"head at %d %d with id %d is loading, not removing", [head getX], [head getY], [head getID]);
			return NULL;
		}*/
		currentSize--;
		Tile* remove = head;
		//printf("Remvoing %d\n", [remove getID]);

		[remove setInCacheNetTo:FALSE];
		head = [remove getPrevNet];
		[remove deleteFromCacheNet];
		if(head==NULL)
			tail = NULL;
		if(head == NULL)
			NSLog(@"Removed a tile from cache, now head IS NULL!!! with currentsize %d", currentSize);
		[cacheLock unlock];
		[remove freeFromDisk]; //do this outside of cachelock to prevent deadlock
		return remove;
	}
	//printf("Done LRU\n");
	[cacheLock unlock];
	return NULL;
}

-(void)touchTile:(Tile*) tile
{
	[cacheLock lock];
	if(tile == tail)
	{
		[cacheLock unlock];
		return;
	}
	//printf("Touch tile\n");
	//[self print];
	//printf("Touching %d\n", [tile getID]);
	if(head==tile)
		head = [tile getPrevNet];
	
	if([tile isInCacheNet])
	{
		currentSize--; //to make sure we don't over increment cache size
		[tile deleteFromCacheNet];
	}
	else {
		[tile setInCacheNetTo:TRUE];
	}
	
	[self addToCache:tile];
	//printf("Done Touch tile\n");
	[cacheLock unlock];
}

-(BOOL)isFull
{
	//NSLog(@"Current net cache size = %d", currentSize);
	return currentSize>=capacity;
}

-(int)getSize
{
	return currentSize;
}

@end
