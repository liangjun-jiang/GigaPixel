//
//  PyramidLevel.m
//  GigaPixel
//
//  Created by Axel Hansen on 2/19/10.
//  Copyright 2010 Harvard University. All rights reserved.
//

/*
 Simple class used to represent a single level of a pyramid (basically a wrapper to a 2d array)
 also precomputes most of the path to a tile
 */

#import "PyramidLevel.h"


@implementation PyramidLevel


-(void)dealloc
{

	for(int a=0;a<rows;a++)
	{
		for(int b=0;b<cols;b++)
		{
			[tiles[a][b] release];
			//printf("Retain count for tile %d %d %d\n", a, b, [tiles[a][b] retainCount]);

		}
	}
	for(int i=0;i<rows;i++)
		free(tiles[i]);
	free(tiles);
}

-(float**)getMatrix
{
	return matrix;
}

- (id)initWithRows:(int)r andCols: (int) c andWidth:(int)w andHeight: (int) h andBase:(int)b andSlice:(int)slice andData:(char*)dataName andMatrix:(float**)mat
{
#ifdef DEBUG
	NSLog(@"Creating pyramid level with size %d,%d and base image %d", r, c, b);
#endif
	rows = r;
	cols = c;
	width = w;
	height = h;
	imageBase = b;
	matrix = mat;
	
	tiles = (Tile***)malloc(sizeof(Tile**)*r);
	NSString *img = [[GLLock getES1Renderer] getImage];

	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString * dataPath = [paths objectAtIndex:0];
	NSString *dirName = [ NSString stringWithFormat: @"tiles%d", slice];
	NSString *dirPath =  [[dataPath stringByAppendingPathComponent:img] stringByAppendingPathComponent:dirName];
	if([[NSFileManager defaultManager] fileExistsAtPath:dirPath] == NO)
		[[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];
	
	if(tiles == NULL)
		NSLog(@"Out of memory!!");
	for(int i=0;i<r;i++)
	{
		tiles[i]=(Tile**)malloc(sizeof(Tile*)*c);
		if(tiles[i] == NULL)
			NSLog(@"Out of memory!!");
		
	}
	
	int counter = 0;
	for(int a=r-1;a>=0;a--)
	{
		for(int b=0;b<c;b++)
//			for(int b=c-1;b>=0;b--)
		{
			//size_t s = sizeof(Tile*);
			tiles[a][b]=[[Tile alloc] initWithIdent:(counter+imageBase) x:b y:a img:img andSlice:slice andDirPath:dirPath andData:dataName];
			counter++;
		}
	}
	//NSLog(@"Done creating tiles");
	return self;
}

- (Tile*)getTileWithX:(int)x andY: (int) y
{
	//NSLog(@"Getting tile %d %d", x, y);
	
	
	return tiles[y][x];
}

- (int)getCols
{
	return cols;
}
- (int)getRows
{
	return rows;
}

- (int)getWidth
{
	return width;
}
- (int)getHeight
{
	return height;
}



@end
