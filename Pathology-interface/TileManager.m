//
//  TileManager.m
//  GigaPixel
//
//  Created by Axel Hansen on 2/10/10.
//  Copyright 2010 Harvard University. All rights reserved.
//

/*
	This manages tiles, particularly caching them
	Also, this is the highest level class for a slice
	es1renderer frees and creates this to switch slices
	getTile method deals with caching, managing texture ids, and signaling when to load tiles
 */

#import "TileManager.h"



@implementation TileManager

int CPU_CACHE_SIZE = 500; //~250 seems good for iPhone, ~500 for iPad
int DISK_CACHE_SIZE = 2000; //~250 seems good for iPhone, ~500 for iPad

NetCacheManager *ncGlob;

- (void)dealloc
{
	for(int j=0;j<pyramidCount;j++)
	{
		PyramidLevel** pyramid=pyramids[j];
		for(int i=0;i<pyramidDepth;i++)
			[pyramid[i] release];
		
		free(pyramid);
	}
	free(pyramids);
	[cacheManager release];
	[netCacheManager release];
	[availableTextureIDs release];
	[tl release];
	tl = NULL;
	[tmLock release];
	[super dealloc];
}

- (id)initWithFileInfo:(struct FileInfo **)tileDatas andSlice:(int)s andCount:(int)c
{
	curSlice = s;
	pyramidCount=c;
	pyramidDepth = tileDatas[0]->pLevel;
#ifdef DEBUG	
	NSLog(@"Creating tile manager with pyramid depth %d", pyramidDepth);
#endif
	pyramids = (PyramidLevel***)malloc(sizeof(PyramidLevel**)*pyramidCount);
	for(int j=0;j<pyramidCount;j++)
	{
		struct FileInfo *tileData = tileDatas[j];
		pyramids[j] = (PyramidLevel**)malloc(sizeof(PyramidLevel*)*pyramidDepth);
		PyramidLevel** pyramid=pyramids[j];
		int counter = 0;
		for(int i=0;i<pyramidDepth;i++)
		{
			int c = tileData->levelSizes[i][0];
			int r = tileData->levelSizes[i][1];
			int w = tileData->levelSizes[i][2];
			//NSLog(@"TM: using %s for data source", tileData->dataFileName);
			int h = tileData->levelSizes[i][3];

			pyramid[i]=[[PyramidLevel alloc] initWithRows:r andCols:c andWidth:w andHeight:h andBase:counter andSlice:j andData:tileData->dataFileName andMatrix:tileData->levelMatrices[i]];
			counter+=r*c;
		}
	}
	
	
	cacheManager = [[CacheManager alloc] initWithCapacity:CPU_CACHE_SIZE];
	netCacheManager = [[NetCacheManager alloc] initWithCapacity:DISK_CACHE_SIZE];
	[TileManager SetNetCache:netCacheManager];
	availableTextureIDs = [[Stack alloc] init];
	tl = [[TileLoader alloc] init];
	[TileManager setTL:tl];
	//NSLog(@"Test tl, in TM");
	//[tl test];
	//int test = [tl test];
	//NSLog(@"Test done with %d, in TM", test);
	
	tmLock = [[NSLock alloc] init];
	return self;
}

//- (Tile*)getTileForPreLoadWithX:(int)x andY: (int) y inDepth:(int)d


-(void)killTileLoader
{
	[tl killThread];
	while(![tl isKilled])
		[tl signalNewTile]; //keep looping until the thread is shutdown
}

-(void)resetTileLoading:(TileManager*)tm
{
	[tl reset:self];
}

- (Tile*)getTileWithX:(int)x andY: (int) y inDepth:(int)d andPreload:(BOOL) preload andImg:(int)img
{
	//FIXME: THIS IS DISABLING PREFETCHING
	//if(preload)
	//	return;
	[tmLock lock];
#ifdef DEBUG_2
	NSLog(@"Getting tile at %d,%d", x, y);
#endif
	PyramidLevel** pyramid=pyramids[img];

	Tile* t = [pyramid[d] getTileWithX:x andY:y];
	[t lockTile];
	if(![t isInMemory] || ([t isInPreload] && !preload))
	{
		if([availableTextureIDs count]!=0)
		{
			GLuint *texToGive = (GLuint*)malloc(sizeof(GLuint));
			texToGive[0]= [availableTextureIDs pop];
		
			[t prepareTileToLoadWithTex:texToGive andPreload:preload];
			free(texToGive);
			if(preload)
				[tl addTileToPreLoad:t];
			else
				[tl addTileToLoad:t];
			[tl signalNewTile];

		}
		else 
		{
			GLuint *texToGive = (GLuint*)malloc(sizeof(GLuint));
			texToGive[0]=0;
			[t prepareTileToLoadWithTex:texToGive andPreload:preload];
			free(texToGive);
			if(preload)
				[tl addTileToPreLoad:t];
			else 
				[tl addTileToLoad:t];


			[tl signalNewTile];

		}
	}
	else if([t isInMemory] && [t isLoading])
		[tl signalNewTile];

	if(([t isInMemory]&&![t isLoading]) && [t getTexture][0]==0)
	{
		printf("tex is in memory but has no texture?!\n");
	}
	if(!preload)
	{
		[cacheManager touchTile:t];
	}
	
	//BOOL needToTouch = FALSE; //do this to check tile 
	//if(![t isInCache])
	//	[cacheManager touchTile:t];



	[t unLockTile];
	//this has to be out of critical section to prevent deadlock
	//does it open itself up to a race condition?
	if([t isInCacheNet]&&!preload)
		[netCacheManager touchTile:t];

	if([cacheManager isFull])
	{
#ifdef DEBUG
		NSLog(@"Cache is full, need to remove");
#endif
		Tile *t2 = NULL;
		t2 = [cacheManager removeLeastRecentlyUsed];
		[t2 lockTile];

		if(t2 != NULL)
		{
			[availableTextureIDs push:[t2 getTexture][0]];
			[t2 resetTex];
		}
		[t2 unLockTile];
	}
	while([netCacheManager isFull])
	{
		Tile *remT = [netCacheManager removeLeastRecentlyUsed];
		if(remT == NULL)
		{
			NSLog(@"BREAKING!!!");
			break;
		}
	}
		
	if([netCacheManager isFull])
		NSLog(@"NC is full, but something happened to break");
	[tmLock unlock];
	return t;
}

+(NetCacheManager*)getNetCache
{
	return ncGlob;
}

+(void)SetNetCache:(NetCacheManager*)nc
{
	ncGlob = nc;
}

-(float**)getMatrix:(int)d andImg:(int)img
{
	PyramidLevel** pyramid=pyramids[img];
	return [pyramid[d] getMatrix];
}


- (int)getLevelWidth:(int)d
{
	PyramidLevel** pyramid=pyramids[0];
	return [pyramid[d] getCols];
}
- (int)getLevelHeight:(int)d
{
	PyramidLevel** pyramid=pyramids[0];
	return [pyramid[d] getRows];
}

- (int)getLevelWidthPixels:(int)d
{
	PyramidLevel** pyramid=pyramids[0];
	return [pyramid[d] getWidth];
}
- (int)getLevelHeightPixels:(int)d
{
	PyramidLevel** pyramid=pyramids[0];
	return [pyramid[d] getHeight];
}


//Notes the caller needs to get the tmlock to keep synchronized
//(getting it in here creates deadlock)
-(void)giveTexBack:(GLuint) t
{
	//[tmLock lock];
	[availableTextureIDs push:t];
	//[tmLock unlock];
}

-(void)lock
{
	[tmLock lock];
}
-(void)unlock
{
	[tmLock unlock];
}
- (int)getDepth
{
	return pyramidDepth;
}

-(int)calculateDepthFromSize:(float)w andHeight:(float) h usingWidth:(BOOL)useWidth
{
	PyramidLevel** pyramid=pyramids[0];//always use the same level
//	NSLog(@"Calculating depth fro %f, %f", w, h);
	if(max(w,h)==w)
		useWidth = TRUE;
	int closest = 0;
	int minDist, calcDist;
	if(useWidth)
		minDist = [pyramid[0] getWidth]-w;
	else
		minDist = [pyramid[0] getHeight]-h;

	for(int i=0;i<pyramidDepth;i++)
	{
//		NSLog(@"\tChecking level %d with [%d, %d]", i, [pyramid[i] getWidth], [pyramid[i] getHeight]);
		if(useWidth)
		{
			calcDist = ([pyramid[i] getWidth]-w);
			if(calcDist>0 && calcDist<minDist)
			{
	//			NSLog(@"\t\tIs closer!");
				minDist = abs([pyramid[i] getWidth]-w);
				closest = i;
			}
		}
		else 
		{
			calcDist = ([pyramid[i] getHeight]-h);
			if(calcDist>=0 && calcDist<minDist)
			{
	//			NSLog(@"\t\tIs closer!");
				minDist = abs([pyramid[i] getHeight]-h);
				closest = i;
			}
			
		}
	}
	return closest;
}


TileLoader* globTL;
+(TileLoader*)getTL
{
	return globTL;
}
+(void)setTL:(TileLoader*)tlSet
{
	globTL = tlSet;
}
	



@end
