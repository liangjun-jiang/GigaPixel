//
//  PrefetchManager.m
//  GigaPixel
//
//  Created by Axel Hansen on 3/15/10.
//  Copyright 2010 Harvard University. All rights reserved.
//

/*
	This thread deals with prefetching other tiles.  It should run in its own thread, and get signaled
	when the view has changed and it should reprocess available tiles to prefetch.  goes in xy plane and depth (but not
	int z axis between slices...yet)
 */

#import "PrefetchManager.h"
#import "ES1Renderer.h"

#define PREFETCH_DIST_SAME_LEV 2 //how many extra tiles around
#define PREFETCH_DIST_SURROUND_LEV 1 //how many surrounding levels

@implementation PrefetchManager

-(id)initWithLock:(semaphore_t *) s
{
	signalSem = s;
	thread = [[NSThread alloc] initWithTarget:self selector:@selector(startRunLoop) object:NULL];
	//[thread start];
	tm=NULL;
	boundsLock = [[NSLock alloc] init];
	pauseLock = [[NSLock alloc] init];

	return self;
}

-(NSThread*) getThread
{
	return thread;
}
-(void) setTileManager:(TileManager*) t
{
	tm = t;
}

-(void)pauseThread
{
	[pauseLock lock];
}

-(void)unPauseThread
{
	[pauseLock unlock];
}


-(void) startThread
{
	windowBounds = [[GLLock getES1Renderer] getWinBounds];

//	NSLog(@"Trying to start prefetch manager thread");
	[thread start];
}


-(void)setCurBoundsWithLeft:(int)l andRight:(int)r andTop:(int)t andBottom:(int)b andLevel:(int)level andFloatLevel:(float)fL andCtrPos:(float*)cP
{
	[boundsLock lock];
	free(ctrPos);//free the old control position, getting a new one
	left = l;
	right = r;
	bottom = b;
	top = t;
	curLevel = level;
	floatLevel = fL;
	ctrPos = cP;
	[boundsLock unlock];
}

//-(void)resetPrefetch
//{
//	[

-(void)startRunLoop
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; // Top-level pool
	
	do
    {
		//NSLog(@"Starting run loop");
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate distantFuture]];
    } while (TRUE);
	
	
	[pool release];  // Release the objects in the pool.


}

-(void)test
{
	NSLog(@"Fired!!");
	for(int i=0;i<15;i++)
		NSLog(@"Pre %d", i);
}

-(void) prefetch
{
	[pauseLock lock];
	//NSLog(@"Prefetching");

//	NSLog(@"Launched new prefetch thread");


	
	//while(1)
	//{
	//	if(semaphore_wait(*signalSem))
	//		NSLog(@"Semaphore failed waiting");
		//NSLog(@"Prefetch fired");
		if(tm == NULL)
			return;
		//prefetch arround
		//int preloadCount = 0;
		[boundsLock lock];
		for(int x=left-PREFETCH_DIST_SAME_LEV;x<right+PREFETCH_DIST_SAME_LEV;x++)
		{
			if(x<0 || x>=[tm getLevelWidth:curLevel])
				continue;
			for(int y=bottom-PREFETCH_DIST_SAME_LEV;y<top+PREFETCH_DIST_SAME_LEV;y++)
			{
				if(y<0||y>=[tm getLevelHeight:curLevel])
					continue;
				if(!(x>right || x<left || y>top || y<bottom))
					continue;
				//NSLog(@"Preloading tile at %d %d in %d", x, y, curLevel);
				[tm getTileWithX:x andY:y inDepth:curLevel andPreload:TRUE andImg:0];
				//preloadCount++;
			}
		}
		
		int depth = [tm getDepth];
		//prefetch layer above
		if(depth-1>curLevel && curLevel>=0)
		{
			int fetchingLevel = curLevel+1;
			float fetchingFloatLevel = floatLevel;//+1;
			
			int numRows = [tm getLevelHeight:fetchingLevel];
			int numCols = [tm getLevelWidth:fetchingLevel];

			double viewFrustum[4]; 
			viewFrustum[0] = (double)-pow(2.0,(double)fetchingFloatLevel);
			viewFrustum[1] = (double)pow(2.0,(double)fetchingFloatLevel);
			viewFrustum[2] = (double)-pow(2.0,(double)fetchingFloatLevel)/ (windowBounds.size.width / windowBounds.size.height);
			viewFrustum[3] = (double)pow(2.0,(double)fetchingFloatLevel)/ (windowBounds.size.width / windowBounds.size.height);
		//	NSLog(@"prefethcing %d level:%f height:%f width:%f", fetchingLevel, fetchingFloatLevel, windowBounds.size.height, windowBounds.size.width);
		//	NSLog(@"prefetching %d viewFrustum[0]:%f viewFrustum[1]:%f viewFrustum[2]:%f viewFrustum[3]:%f", fetchingLevel, viewFrustum[0],viewFrustum[1], viewFrustum[2], viewFrustum[3]);

			float leftBound = viewFrustum[0]+ctrPos[0];
			float rightBound = viewFrustum[1]+ctrPos[0];
			float bottomBound = viewFrustum[2]+ctrPos[1];
			float topBound = viewFrustum[3]+ctrPos[1];
			
			float width = 1-(-1);
			float height = (1.0 / (windowBounds.size.width / windowBounds.size.height))-(-1.0 / (windowBounds.size.width / windowBounds.size.height));
			float startY = (1.0 / (windowBounds.size.width / windowBounds.size.height));
			float tileDivider = pow(2, [tm getDepth]-1-fetchingLevel);
			float dx = min(width/tileDivider, width/numCols); 
			dx=(width/[tm getLevelWidthPixels:fetchingLevel])*TILE_SIZE;
			float dy = dx; //TODO: should be dx=dy if image high, dy=dx if wide
			
			int startCol = (leftBound+1)/dx;
			int endCol = (rightBound+1)/dx;
			int startRow = (-topBound+startY+dy)/dy;
			int endRow = (-bottomBound+startY)/dy;
			if(startRow>0)
				startRow--;
			if(startCol<0)
				startCol = 0;
			if(startRow<0)
				startRow = 0;
			if(endCol<0)
				endCol = 0;
			if(endRow<0)
				endRow = 0;
			if(startCol>=numCols)
				startCol = numCols-1;
			if(endCol>=numCols)
				endCol = numCols-1;
			if(startRow>=numRows)
				startRow = numRows-1;
			if(endRow>=numRows)
				endRow = numRows-1;
			
			for(int c=startCol;c<=endCol;c++)
			{
				for(int r=startRow;r<=endRow;r++)
				{
					[tm getTileWithX:c andY:r inDepth:fetchingLevel andPreload:TRUE andImg:0];
				//	preloadCount++;

				}
			}
			//NSLog(@"Prefetching level %d [%d,%d] to [%d,%d]", fetchingLevel, startCol, startRow, endCol, endRow);
		}	
		
		if(curLevel>0 && curLevel<depth)
		{
			int fetchingLevel = curLevel-1;
			float fetchingFloatLevel = floatLevel;//-1;
			
			int numRows = [tm getLevelHeight:fetchingLevel];
			int numCols = [tm getLevelWidth:fetchingLevel];
			
			double viewFrustum[4]; 
			viewFrustum[0] = (double)-pow(2.0,(double)fetchingFloatLevel);
			viewFrustum[1] = (double)pow(2.0,(double)fetchingFloatLevel);
			viewFrustum[2] = (double)-pow(2.0,(double)fetchingFloatLevel)/ (windowBounds.size.width / windowBounds.size.height);
			viewFrustum[3] = (double)pow(2.0,(double)fetchingFloatLevel)/ (windowBounds.size.width / windowBounds.size.height);
		//	NSLog(@"prefethcing %d level:%f height:%f width:%f", fetchingLevel, fetchingFloatLevel, windowBounds.size.height, windowBounds.size.width);
		//	NSLog(@"prefetching %d viewFrustum[0]:%f viewFrustum[1]:%f viewFrustum[2]:%f viewFrustum[3]:%f", fetchingLevel, viewFrustum[0],viewFrustum[1], viewFrustum[2], viewFrustum[3]);

			float leftBound = viewFrustum[0]+ctrPos[0];
			float rightBound = viewFrustum[1]+ctrPos[0];
			float bottomBound = viewFrustum[2]+ctrPos[1];
			float topBound = viewFrustum[3]+ctrPos[1];
			
			float width = 1-(-1);
			float height = (1.0 / (windowBounds.size.width / windowBounds.size.height))-(-1.0 / (windowBounds.size.width / windowBounds.size.height));
			float startY = (1.0 / (windowBounds.size.width / windowBounds.size.height));
			float tileDivider = pow(2, [tm getDepth]-1-fetchingLevel);
			float dx = min(width/tileDivider, width/numCols); 
			dx=(width/[tm getLevelWidthPixels:fetchingLevel])*TILE_SIZE;
			float dy = dx; //TODO: should be dx=dy if image high, dy=dx if wide
			
			int startCol = (leftBound+1)/dx;
			int endCol = (rightBound+1)/dx;
			int startRow = (-topBound+startY+dy)/dy;
			int endRow = (-bottomBound+startY)/dy;
			if(startRow>0)
				startRow--;
			if(startCol<0)
				startCol = 0;
			if(startRow<0)
				startRow = 0;
			if(endCol<0)
				endCol = 0;
			if(endRow<0)
				endRow = 0;
			if(startCol>=numCols)
				startCol = numCols-1;
			if(endCol>=numCols)
				endCol = numCols-1;
			if(startRow>=numRows)
				startRow = numRows-1;
			if(endRow>=numRows)
				endRow = numRows-1;
			for(int c=startCol;c<=endCol;c++)
			{
				for(int r=startRow;r<=endRow;r++)
				{
					[tm getTileWithX:c andY:r inDepth:fetchingLevel andPreload:TRUE andImg:0];
					//preloadCount++;

				}
			}
			
			//NSLog(@"Prefetching level %d [%d,%d] to [%d,%d]", fetchingLevel, startCol, startRow, endCol, endRow);
			
		}
		//NSLog(@"Preloaded %d", preloadCount);

		[boundsLock unlock];
	[pauseLock unlock];

		 
	//}

	//NSLog(@"Done prefetching");

	//NSLog(@"Exiting new thread");

}
@end
