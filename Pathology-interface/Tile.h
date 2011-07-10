//
//  Tile.h
//  GigaPixel
//
//  This class represents a tile object with a texture
//  Created by Axel Hansen on 2/19/10.
//  Copyright 2010 Harvard University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <Foundation/Foundation.h>
#import "GigaPixel.h"
#import "GLLock.h"
#import "URLCacheConnection.h"


@interface Tile : NSObject {
	GLuint texture[2];//AH, the texture for this thile
	float iKLT[9];
	int tileID; //id, from the filename
	int channelId; //channel id (if using compression
	//tile position in canvas
	int xPos;
	int yPos;

	BOOL downloadingtoDisk;
	BOOL onDisk;
	BOOL inMemory;
	BOOL loadingToMemory;
	BOOL inPreload;
	BOOL inCache;
	BOOL inCacheNet;
	Tile* nextInCache;
	Tile * prevInCache;
	Tile* nextInCacheNet;
	Tile * prevInCacheNet;
	
	char* dataFileName;

	
	NSString * image;
	
	//NSString *path;
	
	NSRecursiveLock *tileLock;
	
	NSURL *url;
	
	int curSlice;
	NSString *dirPath;
	URLCacheConnection *download;
}

-(float*)getIKLT;
-(BOOL) isOnDisk;
-(void)lockTile;
-(void)unLockTile;
-(BOOL) isInCache;
-(void) setInCacheTo:(BOOL)b;
- (GLuint*)getTexture;
-(void)prepareTileToLoadWithTex:(GLuint*)tex andPreload:(BOOL)p;
-(void)loadToMemory;
-(void)loadCompToMemory;
-(GLuint*)freeFromMemory;
-(BOOL)isInPreload;
-(BOOL)isInMemory;
-(BOOL)isLoading;
-(int)getChannel;
- (void)setNext:(Tile*)t;
- (void)setPrev:(Tile*)t;
- (Tile*)getNext;
- (Tile*)getPrev;
-(void)deleteFromCache;
- (void)setNextNet:(Tile*)t;
- (void)setPrevNet:(Tile*)t;
- (Tile*)getNextNet;
- (Tile*)getPrevNet;
-(void)deleteFromCacheNet;
-(BOOL) isInCacheNet;
-(void) setInCacheNetTo:(BOOL)b;
-(void)freeFromDisk;
- (void) connectionDidFail:(URLCacheConnection *)theConnection;
- (void) connectionDidFinish:(URLCacheConnection *)theConnection andLength:(NSTimeInterval) length;
-(void)startDownload;
-(void)resetTex;
void setBaseURLForAllTiles(NSString *base);
NSString* getBaseURL();
//-(void)resetTileLoadPrepWithTM:(TileManager*)tm;

-(void)bandwidthUpdate:(float)rate andInt:(int)i;


@end
