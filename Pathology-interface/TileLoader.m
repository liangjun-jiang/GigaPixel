//
//  TileLoader.m
//  GigaPixel
//
//  Created by Axel Hansen on 3/18/10.
//  Copyright 2010 Harvard University. All rights reserved.
//

/*
	Tile loader deals with loading tiles from memory.  It runs in its own thread, and should be signaled when there are
	new tiles that need to be loaded.  This calls render on the main thread after it loads a few tiles.  That setting needs to be
	optimized.
 */

#import "TileLoader.h"
#import "TileManager.h"
#import "ES1Renderer.h"

@implementation TileLoader

int MAX_DOWNLOAD = 15;
int EARLY_RENDER_THRESH = 2;//2 for ipod, 4 for ipad (ipad needs higher, because shows more tiles)

-(void)dealloc
{
	semaphore_destroy(mach_task_self(), *signalSem);
	free(signalSem);
	[tileLoaderLock release];
	[tilePreLoaderLock release];
	[toLoad release];
	[toPreLoad release];
	[thread release];
	[super dealloc];
}

-(id)init
{
	//NSLog(@"Starting to init tile loader");
	tileLoaderLock = [[NSRecursiveLock alloc] init];
	tilePreLoaderLock = [[NSRecursiveLock alloc] init];
	toPreLoad = [[NSMutableArray alloc] init];
	toLoad = [[NSMutableArray alloc] init];
	signalSem = (semaphore_t*)malloc(sizeof(semaphore_t));
	//if(sem_init(signalSem, 0, 0)==-1)
	if(semaphore_create(mach_task_self(), signalSem, SYNC_POLICY_FIFO, 0))
	{
		NSLog(@"Semaphore init failed with %d", errno);
		if(errno==EINVAL)
			NSLog(@"Einval");
		else if(errno==ENOSYS)
			NSLog(@"Enosys");
	}
	
	shouldDie = false;
	didDie = false;
	num_downloading = 0;
	
	thread = [[NSThread alloc] initWithTarget:self selector:@selector(tileLoad) object:NULL];
	[thread start];
		
	
	//LaunchThread(self);
	//NSLog(@"Done initing tile loader");
	return self;
}

-(int)test
{
	//NSLog(@"Testing tile loader from TileLoader object!!");
	return 10;
}

-(void)killThread
{
	shouldDie = TRUE;
	//NSLog(@"Killed thread");
}
	
-(BOOL)isKilled
{
	return didDie;
}
	

	
-(semaphore_t*)getSemaphore
{
	return signalSem;
}


/*void LaunchThread(TileLoader *tl)
{
    // Create the thread using POSIX routines.
    pthread_attr_t  attr;
    pthread_t       posixThreadID;
    int             returnVal;
	
    returnVal = pthread_attr_init(&attr);
    assert(!returnVal);
    returnVal = pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
    assert(!returnVal);
	
    int threadError = pthread_create(&posixThreadID, &attr, &tileLoad, tl);
	
    returnVal = pthread_attr_destroy(&attr);
    assert(!returnVal);
    if (threadError != 0)
    {
		// Report an error.
    }
}*/

-(void)tileLoad
//void* tileLoad(void* data)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; // Top-level pool
	//TileLoader *tl = (TileLoader*)data;
	//NSLog(@"Launched new tileLoad thread");
	
	
	bool rerender = FALSE;
	bool shouldSleep = FALSE;
	int loadedSinceLastRender = 0;
	ES1Renderer *es1r = [GLLock getES1Renderer];
	while(!shouldDie)
	{
		//NSLog(@"Tile loading");

		int count = [self getTileToLoadCount];
		if(![es1r isThreadRendering]&&( (count==0 && rerender) || (loadedSinceLastRender>=EARLY_RENDER_THRESH)))
		{
		//	NSLog(@"Calling render from loader");
			[es1r performSelectorOnMainThread:@selector(render) withObject:nil waitUntilDone:NO];
			rerender = FALSE;
			loadedSinceLastRender = 0;
		}
		else if(count!=0) {
			rerender = TRUE;
		}

		int totCount = count+[self getTileToPreloadCount];
		//NSLog(@"count=%d, precount=%d", count, [self getTileToPreloadCount]);

		//NSLog(@"Tiles to load %d, total to load %d", count, totCount);
		if(totCount==0 || shouldSleep)
		{
			//NSLog(@"Tile loader waiting");
			if(semaphore_wait(*([self getSemaphore])))
				NSLog(@"Semaphore failed waiting");
			//NSLog(@"TileLoader fired");
			shouldSleep = FALSE;
		}
		//NSLog(@"Out of waiting");
		Tile *tile = [self getNextTileToLoadwithTried:NULL];
		if(tile == NULL)
		{
			//NSLog(@"Got null");
			//if(semaphore_wait(*([self getSemaphore])))
			//	NSLog(@"Semaphore failed waiting");
			shouldSleep = TRUE;
			continue;
		}
		
		//if(![tile isOnDisk]
		
		//NSLog(@"pf Locking on tile");
		//[tile lockTile];
		//NSLog(@"pf In lock");
		[tile loadToMemory];
		loadedSinceLastRender++;
		//[tile unLockTile];
		//NSLog(@"Done tile loading");

	}

	didDie = TRUE;
	
	NSLog(@"Exiting new thread");
	
	[pool release];  // Release the objects in the pool.
	
}


//needs to go through all 
-(void)reset:(TileManager*) tm
{
	[tm lock];
	[tileLoaderLock lock];
	NSEnumerator * enumerator = [toLoad objectEnumerator];
	Tile *element;
	while(element = [enumerator nextObject])
    {
		[element resetTileLoadPrepWithTM:tm]; 
    }
	//NSLog(@"Reset %d load tiles", [toLoad count]);
	[toLoad removeAllObjects];
	[tileLoaderLock unlock];
	[tilePreLoaderLock lock];
	enumerator = [toPreLoad objectEnumerator];
	while(element = [enumerator nextObject])
    {
		[element resetTileLoadPrepWithTM:tm]; 
    }	
	//NSLog(@"Reset %d preload tiles", [toPreLoad count]);
	[toPreLoad removeAllObjects];
	[tilePreLoaderLock unlock];
	[tm unlock];
}

//should be called from main thread
-(void)signalNewTile
{
	//NSLog(@"Signaling loadTile");
	if(semaphore_signal_all(*signalSem))
		NSLog(@"Semaphore failed signaling all");	
}

-(int)getTileToPreloadCount
{
	[tilePreLoaderLock lock];
	int r = [toPreLoad count];
	[tilePreLoaderLock unlock];
	return r;
}

-(int)getTileToLoadCount
{
	[tileLoaderLock lock];
	int r = [toLoad count];
	[tileLoaderLock unlock];
	return r;
}
//should be called from tileLoader thread
-(Tile*)getNextTileToLoadwithTried:(NSMutableArray*)tried
{
	//NSLog(@"Getting next tile to load");
	[tileLoaderLock lock];
	if([toLoad count]<=0)
	{
		[tileLoaderLock unlock];
		[tilePreLoaderLock lock];
		if([toPreLoad count]<=0)
		{
			[tilePreLoaderLock unlock];
			return NULL;
		}
		Tile *t = [toPreLoad objectAtIndex:0];
		//[toPreLoad removeObjectAtIndex:0];
		[toPreLoad removeObjectIdenticalTo:t];
		if(![t isOnDisk])//add tile back, it's not on disk yet
		{
			
			//NSLog(@"Tile loader skipping %d %d id=%d", [t getX], [t getY], [t getID]);

			[self addTileToPreLoad:t];
			Tile *t2 = [toPreLoad objectAtIndex:0];
			//[toPreLoad removeObjectAtIndex:0];
			[toPreLoad removeObjectIdenticalTo:t2];
			while(![t2 isOnDisk] && t2 != t)
			{
				[self addTileToPreLoad:t2];
				
				t2 = [toPreLoad objectAtIndex:0];
				//[toPreLoad removeObjectAtIndex:0];
				[toPreLoad removeObjectIdenticalTo:t2];
			}

			if(![t2 isOnDisk])
			{
				[self addTileToPreLoad:t2];
				[tilePreLoaderLock unlock];
				return NULL;
			}
			t = t2;
		}
		[tilePreLoaderLock unlock];
		//tile is no longer being preloaded (it was added to the actual load list)
		if(![t isInPreload])
			return NULL;
		return t;
	}
	Tile *t = [toLoad objectAtIndex:0];
	[toLoad removeObjectIdenticalTo:t];
	//[toLoad removeObjectAtIndex:0];
	if(![t isOnDisk])//add tile back, it's not on disk yet
	{
		//NSLog(@"Tile loader skipping %d %d id=%d", [t getX], [t getY], [t getID]);
		//[tileLoaderLock unlock];
		[self addTileToLoad:t];
		//return NULL;
		Tile *t2 = [toLoad objectAtIndex:0];
		//[toPreLoad removeObjectAtIndex:0];
		[toLoad removeObjectIdenticalTo:t2];
		while(![t2 isOnDisk] && t2 != t)
		{
			[self addTileToLoad:t2];
			t2 = [toLoad objectAtIndex:0];
			//[toLoad removeObjectAtIndex:0];
			[toLoad removeObjectIdenticalTo:t2];
		}
		
		if(![t2 isOnDisk])
		{
			[self addTileToLoad:t2];
		//	NSLog(@"no real tiles to load");
			[tileLoaderLock unlock];
			return NULL;
		}
	//	NSLog(@"Got a real tile to load");
		t = t2;
	}
	[tileLoaderLock unlock];


	return t;
}

//should be called from main thread
-(void)addTileToLoad:(Tile*)t
{
	[tileLoaderLock lock];
	//NSLog(@"Tile added to queue for loading");
	[toLoad addObject:t];
	[tileLoaderLock unlock];
}

//will be called from prefetch thread
-(void)addTileToPreLoad:(Tile *)t
{
	[tilePreLoaderLock lock];
	[toPreLoad addObject:t];
	[tilePreLoaderLock unlock];
}

-(void)tileDownloaded
{
	num_downloading--;
}
	
@end
