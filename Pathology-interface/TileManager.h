//
//  TileManager.h
//  GigaPixel
//
//  This class manages the list of tiles
//  Created by Axel Hansen on 2/10/10.
//  Copyright 2010 Harvard University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Tile.h"
#import "PyramidLevel.h"
#import "GigaPixel.h"
#import "CacheManager.h"
#import "TileLoader.h"
#import "GLLock.h"
#import "Stack.h"
#import "NetCacheManager.h"

@interface TileManager : NSObject {
	PyramidLevel ***pyramids;
	int pyramidDepth;
	int pyramidCount;
	
	CacheManager* cacheManager;
	
	NetCacheManager* netCacheManager;
	
	Stack *availableTextureIDs;
	
	TileLoader *tl;
	
	NSLock *tmLock;
	
	int curSlice;
	
}

-(void)resetTileLoading:(TileManager*)tm;
- (Tile*)getTileWithX:(int)x andY: (int) y inDepth:(int)d andPreload:(BOOL) preload;
- (int)getLevelWidth:(int)d;
- (int)getLevelHeight:(int)d;
- (int)getLevelWidthPixels:(int)d;
- (int)getLevelHeightPixels:(int)d;

- (int)getDepth;
-(int)calculateDepthFromSize:(float)s andHeight:(float) h usingWidth:(BOOL)useWidth;

+(NetCacheManager*)getNetCache;
+(void)SetNetCache:(NetCacheManager*)nc;

+(TileLoader*)getTL;
+(void)setTL:(TileLoader*)tlSet;



struct FileInfo {
	NSString *path;
	int tileSize;
	int pLevel; //levels in pyramid
	int **levelSizes;
	float **levelMatrices;
	char* dataFileName;
};



@end
