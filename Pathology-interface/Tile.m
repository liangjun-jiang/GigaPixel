//
//  Tile.m
//  GigaPixel
//
//  Created by Axel Hansen on 2/19/10.
//  Copyright 2010 Harvard University. All rights reserved.
//

/*
	Basic tile representation.  tiles choose themselves when to be downloaded (when they get preloaded usually)
	The tilemanager tells a tile it is being preloaded, which sets some state variables.
	The tileloader thread then finishes loading the tile when it gets around to it
 */

#import "Tile.h"
#import "ES1Renderer.h"
#import "TileManager.h"

int MAX_PREDOWNLOAD = 5;
bool USING_PVRTC = TRUE;

BOOL USING_ADV_COMP = TRUE;

int TILES_PER_FILE = 1;

@implementation Tile

-(int)getX
{
	return xPos;
}
-(int)getY
{
	return yPos;
}
-(int)getID
{
	return tileID;
}

int num_downloaded = 0; //this is GLOBAL

- (void) connectionDidFail:(URLCacheConnection *)theConnection
{
	NSLog(@"Failed to download image at %d %d", xPos, yPos);
	[theConnection release];
}
- (void) connectionDidFinish:(URLCacheConnection *)theConnection andLength:(NSTimeInterval) length
{
	
	[tileLock lock];
	//NSLog(@"Tile %d %d %d finished downloading", xPos, yPos, tileID);

/*	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString * dataPath = [paths objectAtIndex:0];
	NSString *fileName = [ NSString stringWithFormat: @"%d.tmp", tileID];
	NSLog(fileName);
	NSLog(dataPath);
	NSString * filePath = [dataPath stringByAppendingPathComponent:fileName];
	path = [NSString stringWithString:filePath];
	NSLog(@"Finished downloading, starting print:");
	NSLog(fileName);
	NSLog(dataPath);
	NSLog(filePath);
	NSLog(path);
	NSLog(@"Done printing");*/
	//NSLog(@"Download finished, using image");

/*	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString * dataPath = [paths objectAtIndex:0];
	NSString *dirName = [ NSString stringWithFormat: @"tiles%d", curSlice];
	NSString *dirPath =  [dataPath stringByAppendingPathComponent:dirName];
	if([[NSFileManager defaultManager] fileExistsAtPath:dirPath] == NO)
		[[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];*/
	NSString *fileName = [ NSString stringWithFormat: @"%d.tmp", tileID];
	//NSLog(fileName);
	//NSLog(dataPath);
	NSString * filePath = [dirPath stringByAppendingPathComponent:fileName];
	
	//NSLog(@"%@", filePath);
	//printf("Write path:");
	//if ([[NSFileManager defaultManager] fileExistsAtPath:filePath] == NO) {
	//	NSLog(@"Creating file");
        /* file doesn't exist, so create it */
		[[NSFileManager defaultManager] createFileAtPath:filePath 
                                                contents:theConnection.receivedData 
                                              attributes:nil];
	//}

	//[paths release];
	//[dataPath release];
	//[fileName release];
	//[filePath release];
	//}
	//else {
	//	NSLog(@"File already exists");
	//}
	downloadingtoDisk = FALSE;
	onDisk = TRUE;
	int dataReceivedBytes = [theConnection.receivedData length];
	float dataReceivedKb = ((float)dataReceivedBytes)/16384.0;
	float rate = dataReceivedBytes/(float)length;
	//NSLog(@"Got %d bytes in %f seconds rate=%f", dataReceivedBytes, (float)length, rate);

	//[[GLLock getEAGLVIEW] bandwidthUpdate:rate andInt:5];
	ES1Renderer *es1 = [GLLock getES1Renderer];
	[es1 bandwidthUpdate:dataReceivedBytes andTime:(float)length];

	[theConnection release];
	//NSLog(@"Downloader unlocking");
	//NSLog(@"Tile at %d %d finished downloading", xPos, yPos);
	[tileLock unlock];
	if([TileManager getTL]!=NULL)
	{
		[[TileManager getTL] tileDownloaded];
		[[TileManager getTL] signalNewTile];
	}
	//NSLog(@"Number in download: %d", num_downloaded);
	num_downloaded--;
}

- (void)dealloc
{
	[tileLock release];
	if(texture[0]!=0)
		glDeleteTextures(1, texture);
	//free(texture);
	[url release];
	[super dealloc];
}

- (id)initWithIdent:(int)ident x: (int) x y: (int) y img:(NSString *)img andSlice:(int)slice andDirPath:(NSString*)dS andData:(char*)dataName
{
	dataFileName = dataName;
	curSlice = slice;
	image = img;
#ifdef DEBUG
	NSLog(@"Create tile with identity %d at %d,%d", ident, x, y);
#endif
	tileID = ident;
	channelId=0;
	if(USING_PVRTC==TRUE)
	{
		tileID = ident/TILES_PER_FILE;
		channelId = ident%TILES_PER_FILE;
		//NSLog(@"Create tile with identity %d and channel %d from %d", tileID, channelId, ident);

	}
		
	xPos = x;
	yPos = y;
	inMemory = FALSE;
	loadingToMemory = FALSE;
	inPreload = FALSE;
	inCache = FALSE;
	
	onDisk=FALSE;
	downloadingtoDisk=FALSE;

	url = NULL;
	//[self loadToMemory];
		 
	tileLock = [[NSRecursiveLock alloc] init];
	
	//printf("Write path:");
	
	//NSLog(dS);
	dirPath = dS;
	[dirPath retain];
	return self;
}	

//-(void)unPrepareLoad:
//{
	
//}

-(BOOL)isOnDisk
{
	return onDisk;
}

-(BOOL) isInCache
{
	return inCache;
}

-(void) setInCacheTo:(BOOL)b
{
	inCache = b;
}

-(void)lockTile
{
	[tileLock lock];
}

-(void) unLockTile
{
	[tileLock unlock];
}

-(void)stopDownload
{
	[tileLock lock];
	if(downloadingtoDisk)
		[download stopDownload];
	downloadingtoDisk = FALSE;
	[tileLock unlock];
}

-(void)startDownload
{
	
	//NOT USED.  Download code is inline below
	/*[tileLock lock];
	if(!onDisk && !downloadingtoDisk)
	{//begin download of tile
		NSLog(@"Tile %d %d %d starting to download", xPos, yPos, tileID);
		NSString * str = @"http://74.52.35.51/testCortex";
		NSString *fileName = [NSString stringWithFormat: @"%d/%d.tmp", curSlice, tileID];
		//NSLog([fileName stringByAppendingString:@" beginning to be loaded from the net"]);
		url = [[NSURL alloc] initWithString:[str stringByAppendingString:fileName]];
		//	NSLog([url absoluteString]);
		
		download = [[URLCacheConnection alloc] initWithURL:url delegate:self];
		downloadingtoDisk = TRUE;
	}	
	[tileLock unlock];*/
}	

-(void)resetTileLoadPrepWithTM:(TileManager*)tm
{
	[tileLock lock];
	GLuint gb = 0;
	if(loadingToMemory)
	{
		inMemory = FALSE;
		loadingToMemory = FALSE;
		inPreload = FALSE;
		gb = texture[0];
		texture[0]=0;
	}
	[tileLock unlock];
	if(gb!=0)
		[tm giveTexBack:gb];

}
		

NSString *baseUrl;

int focalLevel;
void setFocalLevelForAllTiles(int level)
{
	focalLevel = level;
}

void setBaseURLForAllTiles(NSString *base)
{
	baseUrl = base;
}

NSString* getBaseURL()
{
	return baseUrl;
}

-(void)prepareTileToLoadWithTex:(GLuint*)tex andPreload:(BOOL)p
{
	[tileLock lock];

	/*if(tex==NULL)
		texture[0]=NULL;
	else
		texture[0] = tex[0];*/
	
	
	if(inMemory && !loadingToMemory)
	{
		[tileLock unlock];
		return;
	}
	inMemory = TRUE;
	loadingToMemory = TRUE;
	inPreload = p;
	texture[0] = tex[0];
	if(!onDisk && !downloadingtoDisk)
	{//begin download of tile
		NSString *fileName = [ NSString stringWithFormat: @"%d.tmp", tileID];
		//NSLog(fileName);
		//NSLog(dataPath);
		NSString * filePath = [dirPath stringByAppendingPathComponent:fileName];
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:filePath] == YES) {
			onDisk = TRUE;
			downloadingtoDisk = FALSE;
		}		
		else if(!p || num_downloaded<=MAX_PREDOWNLOAD)
		{
			//NSString * str = @"http://3of.me/slices/slice";
			//NSString * str = @"http://127.0.0.1/~axel/brainFiles/slices/slice";
			//NSString * str = [baseUrl stringByAppendingString:@"/slice"];

			//NSString *fileName = [NSString stringWithFormat: @"%d/%d.tmp", curSlice, 0];  //TODO: THIS IS TEMPORARY
			//NSString *fileName = [NSString stringWithFormat: @"%d/%d.tmp", curSlice, tileID];
			//NSLog([fileName stringByAppendingString:@" beginning to be loaded from the net"]);
			size_t data_size = 65536+16384;
			
			//size_t iElem = (36+5*data_size)*0;// * tileID;
			size_t iElem = (44+5*data_size) * tileID;
			
//			NSString *postData = [NSString stringWithFormat:@"start=%d&size=%d&message=%s", 0, 0, dataFileName];
			NSString *postData = [NSString stringWithFormat:@"start=%d&size=%d&message=%s", iElem, 44+5*data_size, dataFileName];
//			url = [[NSURL alloc] initWithString:@"http://neurotrace.seas.harvard.edu/tile/slice1/0.tmp"];
			url = [[NSURL alloc] initWithString:@"http://neurotrace.seas.harvard.edu/test/GETIMAGE"];
			
			//NSLog(@"Downloading %@ w/%@", [url absoluteString], postData);

			download = [[URLCacheConnection alloc] initWithURL:url delegate:self andPost:postData];
			downloadingtoDisk = TRUE;
			num_downloaded++;
		}
	}
		
	//NSLog(@"Preparing to load tile at %d %d to memory given texture %d", xPos, yPos, tex[0]);

	[tileLock unlock];
}

-(BOOL)isInPreload
{
	return inPreload;
}

-(float*)getIKLT
{
	return iKLT;
}


//a new version of loadToMemory that loads pvrtc stack compressed images
-(void)loadCompToMemory
{
	NSTimeInterval time = [NSDate timeIntervalSinceReferenceDate];

	//NSLog(@"in loadComptoMemory");
	[tileLock lock];
	
	//NSLog(@"Loading to memory");
	if(!onDisk)
	{
		NSLog(@"ERROR: loading undownloaded file to memory");
		inMemory = FALSE;
		loadingToMemory = FALSE;
		inPreload = FALSE;
		[tileLock unlock];
		return;
	}
	
	if(loadingToMemory)
	{
		NSString *fileName = [ NSString stringWithFormat: @"%d.tmp", tileID];
		NSString * filePath = [dirPath stringByAppendingPathComponent:fileName];
		NSString *path = [NSString stringWithString:filePath];
		NSData *texData = [[NSData alloc] initWithContentsOfFile:path];
		char *fp = (char*)malloc([texData length]);
		memcpy(fp, [texData bytes], [texData length]);
		
		float rWidth, rHeight, rDepth;
		unsigned char bpp, halfres;
		unsigned int uiMode;
		size_t data_size = 65536+16384;

		//size_t iElem = (36+5*data_size)*0;// * tileID;
		size_t iElem = (44+5*data_size) * tileID;
		//size_t iElem = (36+5*data_size) * tileID;

		iElem = 0;

	//	NSLog(@"ielem=%d",iElem);

		int dimX, dimY;
		memcpy(&dimX, fp+iElem, sizeof(int));
		iElem += 4; 
		memcpy(&dimY, fp+iElem, sizeof(int));
		iElem += 4; 

		
		//memcpy(&rWidth, fp+iElem, sizeof(unsigned short));
		//iElem+=sizeof(unsigned short);
		//memcpy(&rHeight, fp+iElem, sizeof(unsigned short));
		//iElem+=sizeof(unsigned short);
		//memcpy(&rDepth, fp+iElem, sizeof(unsigned short));
		//iElem+=sizeof(unsigned short);
		//memcpy(&bpp, fp+iElem, sizeof(unsigned char));
		//iElem+=sizeof(unsigned char);
		//memcpy(&halfres, fp+iElem, sizeof(unsigned char));
		//iElem+=sizeof(unsigned char);
		memcpy(&iKLT, fp+iElem, sizeof(float)*9);
		iElem+=sizeof(float)*9;
		//memcpy(&uiMode, fp+iElem, sizeof(unsigned int));
		//iElem+=sizeof(unsigned int);
		
		rWidth = 512;
		rHeight = 512;
		rDepth = 15;
		bpp = 2;
		
	//	NSLog(@"Width=%f height=%f depth=%f bpp=%c ielem=%d tileid=%d dimX=%d dimY=%d", rWidth, rHeight, rDepth, bpp, iElem, tileID, dimX, dimY);
		
		
		//if(iElem!=15) NSLog(@"Error reading initial header");
		
		unsigned int size = 0;
		//memcpy(&size, fp+iElem, sizeof(unsigned int));
		//iElem+=sizeof(unsigned int);
		/*unsigned char *FullResHeader = (unsigned char*)malloc(size);
		memcpy(FullResHeader,&size,sizeof(unsigned int));
		memcpy(&FullResHeader[4], fp+iElem, size-4);
		iElem+=size-4;
		
		unsigned char *HalfResHeader = (unsigned char*)malloc(size);
		memcpy(HalfResHeader, fp+iElem, size);
		iElem+=size;*/
		
		/*size_t data_size = ((rDepth+2)/3)*(((rWidth*rHeight*bpp)/8)
										  +2*(((rWidth/2)*(rHeight/2)*bpp)/8)
										  +(((rWidth/4)*(rHeight/4)*bpp)/8));*/
		//iElem += (44+5*data_size) * tileID;

		int focalId = (int)((focalLevel-1)/3);
		//NSLog(@"Focal id=%d", focalId);
		iElem+=data_size*focalId;
		unsigned char *data = (unsigned char*)malloc(data_size);
		memcpy(data, fp+iElem, data_size);
		iElem+=data_size;
		
		/*int numSlices = ((rDepth+2)/3);
		int sliceStride = ((rWidth*rHeight*bpp)/8) + 2*((rWidth/2)*(rHeight/2)*bpp)/8 + ((rWidth/4)*(rHeight/4)*bpp)/8;
		
		void **FullResPtr = (void**)malloc(sizeof(void*)*numSlices);
		void **HalfResPtr = (void**)malloc(sizeof(void*)*numSlices);

		for (unsigned int n=0; n<numSlices; n++) {
			FullResPtr[n] = &data[n*sliceStride];
			HalfResPtr[n] = &data[n*sliceStride+(rWidth*rHeight*bpp)/8];
		}*/
		
		
		int off = 0;
		
		[GLLock acquireGLLock];
		
		ES1Renderer *es1 = [GLLock getES1Renderer];
		[EAGLContext setCurrentContext:[es1 getContextA]];
		
		glBindTexture(GL_TEXTURE_2D, 0);
		
		// 2. Call flush on context A 
		glFlush(); 
		//[GLLock releaseGLLock];
		
		// 3. Modify the texture on context B
		[EAGLContext setCurrentContext:[es1 getContextB]];
		if(texture[0]==0)
		{
	//		NSLog(@"Generating a new texture for [0]");
			glGenTextures(1, &texture);
		}
		//TODO: make sure this gets freed
		if(texture[1]==0)
		{
	//		NSLog(@"Generating a new texture for [1]");
			glGenTextures(1, &texture[1]);
		}
		
		//load in the first texture
		glBindTexture(GL_TEXTURE_2D, texture[0]);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR); 
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
		//glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_CLAMP_TO_EDGE);
		//glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_CLAMP_TO_EDGE);
		//TODO: used a different slice id
		glCompressedTexImage2D(GL_TEXTURE_2D, 0, GL_COMPRESSED_RGB_PVRTC_2BPPV1_IMG, 512, 512, 0, 65536, data);
		
		//load in the second texture
		glBindTexture(GL_TEXTURE_2D, texture[1]);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR); 
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
		//glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_CLAMP_TO_EDGE);
		//glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_CLAMP_TO_EDGE);
		//TODO: used a different slice id
		glCompressedTexImage2D(GL_TEXTURE_2D, 0, GL_COMPRESSED_RGB_PVRTC_2BPPV1_IMG, 256, 256, 0, 16384, data+65536);
		
		
		[EAGLContext setCurrentContext:[es1 getContextA]];
		
		[GLLock releaseGLLock];
		
		//free([texData bytes]);
		[texData release];
		free(fp);
		//printf("Actually loaded tile into a tex for %d %d\n", xPos, yPos);
		inMemory = TRUE;
	}
	
	loadingToMemory = FALSE;
	inPreload = FALSE;
	
	//NSLog(@"Done loading texture at %d %d to memory", xPos, yPos);
#ifdef DEBUG
	NSLog(@"Loading texture at %d %d to memory, using texture %d", xPos, yPos, texture[0]);
#endif
	NetCacheManager *netCacheManager = [TileManager getNetCache];
	[netCacheManager touchTile:self];
	
	
	[tileLock unlock];
	time = [NSDate timeIntervalSinceReferenceDate]-time;
	ES1Renderer *es1 = [GLLock getES1Renderer];
	//[es1 tileLoadTime:time];
	//NSLog(@"Time = %f", time);
	
	//do this outside of tile lock to prevent deadlock
}


-(void)loadToMemory
{
	if(USING_ADV_COMP)
		return [self loadCompToMemory];
	//NSLog(@"in loadtoMemory");

	[tileLock lock];

	//NSLog(@"Loading to memory");
	if(!onDisk)
	{
		NSLog(@"ERROR: loading undownloaded file to memory");
		inMemory = FALSE;
		loadingToMemory = FALSE;
		inPreload = FALSE;
		[tileLock unlock];
		return;
	}

	if(loadingToMemory)
	{
		//create the texture
		//if(texture[0]==NULL)
		//{
		//	NSLog(@"Generating a texutre for %d %d", xPos, yPos);
		//	glGenTextures(1, &texture[0]);
		//}
		NSString *fileName = [ NSString stringWithFormat: @"%d.tmp", tileID];
		//NSLog(fileName);
		//NSLog(dataPath);
		NSString * filePath = [dirPath stringByAppendingPathComponent:fileName];
		NSString *path = [NSString stringWithString:filePath];
		//NSLog("Read path:%@", path);
		//NSLog(path);
		//NSLog(@"Path of texture:");
		//NSLog(path);
		NSData *texData = [[NSData alloc] initWithContentsOfFile:path];
		char *fp = (char*)malloc([texData length]);
		memcpy(fp, [texData bytes], [texData length]);  //TODO: does this get copied again by GL, or should it be freed?
		int bufDim[2];
		int offset[2];
		int imgDim[2];
		
		int off = 0;
		
		if(!USING_PVRTC)
		{
			//NSLog(@"Length of texData %d, and texture name %d", [texData length], texture[0]);
			memcpy(bufDim, fp, sizeof(unsigned int)*2);
			off+=sizeof(unsigned int)*2;
			memcpy(offset, fp+off, sizeof(unsigned int)*2);
			off+=sizeof(unsigned int)*2;
			memcpy(imgDim, fp+off, 	sizeof(unsigned int)*2);
			off+=sizeof(unsigned int)*2;
		}
		//if(curSlice==2)
		//	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, bufDim[0], bufDim[0], 0, GL_RGBA, GL_UNSIGNED_BYTE, fp+off);
		//if(curSlice==1)
		[GLLock acquireGLLock];
		
		ES1Renderer *es1 = [GLLock getES1Renderer];
		[EAGLContext setCurrentContext:[es1 getContextA]];
		
		glBindTexture(GL_TEXTURE_2D, 0);
		
		// 2. Call flush on context A 
		glFlush(); 
		//[GLLock releaseGLLock];
		
		// 3. Modify the texture on context B
		[EAGLContext setCurrentContext:[es1 getContextB]];
		if(texture[0]==0)
		{
			//NSLog(@"Generating a new texture");
			glGenTextures(1, &texture);
		}
		
		
		glBindTexture(GL_TEXTURE_2D, texture[0]);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR); 
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_CLAMP_TO_EDGE);
		
		
		
		if(!USING_PVRTC)
		{
			//glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, bufDim[0], bufDim[0], 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, fp+off);
		}
		else {
			//NSLog(@"Using compressed, id=%d channel=%d", tileID, channelId);
			glCompressedTexImage2D(GL_TEXTURE_2D, 0, GL_COMPRESSED_RGBA_PVRTC_2BPPV1_IMG, 256, 256, 0, [texData length], fp);
		}

		[EAGLContext setCurrentContext:[es1 getContextA]];

		[GLLock releaseGLLock];

		//free([texData bytes]);
		[texData release];
		free(fp);
		//printf("Actually loaded tile into a tex for %d %d\n", xPos, yPos);
		inMemory = TRUE;
	}
	
	loadingToMemory = FALSE;
	inPreload = FALSE;
	
	//NSLog(@"Done loading texture at %d %d to memory", xPos, yPos);
		#ifdef DEBUG
	NSLog(@"Loading texture at %d %d to memory, using texture %d", xPos, yPos, texture[0]);
		#endif
	NetCacheManager *netCacheManager = [TileManager getNetCache];
	[netCacheManager touchTile:self];
	
	
	[tileLock unlock];

	//do this outside of tile lock to prevent deadlock
}

-(void)freeFromDisk
{
	[tileLock lock];
	//NSLog(@"Removed tile at %d %d with id=%d from disk", xPos, yPos, tileID);
	onDisk = FALSE;
//	if(inMemory)
//	{
//		NSLog(@"Tile being removed from disk is in memory!!!");
//	}
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString * dataPath = [paths objectAtIndex:0];
	NSString *fileName = [ NSString stringWithFormat: @"%d.tmp", tileID];
	//NSLog(fileName);
	//NSLog(dataPath);
	NSString * filePath = [dataPath stringByAppendingPathComponent:fileName];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:filePath] == YES) 
		[[NSFileManager defaultManager] removeItemAtPath:filePath error:NULL]; //remove the file
//	NSLog(@"Freed %d %d from disk", xPos, yPos);
	[tileLock unlock];
}

-(GLuint*)freeFromMemory
{
	[tileLock lock];
	//NSLog(@"Removing tile at %d %d from memory, relinquishing texture %d", xPos, yPos, texture[0]);

	if(inMemory)
	{

		//glDeleteTextures(1, texture);
		inMemory = FALSE;
		loadingToMemory = FALSE;
		inPreload = FALSE;
		#ifdef DEBUG
		NSLog(@"Removing texture at %d %d from memory", xPos, yPos);
		#endif		
		[tileLock unlock];
		return texture;
	}
	texture[0] = 0;
	inMemory = FALSE;
	loadingToMemory = FALSE;
	inPreload = FALSE;
	#ifdef DEBUG
	NSLog(@"Removing texture at %d %d from memory, but it wasn't in memory", xPos, yPos);
	#endif	
	[tileLock unlock];
	return NULL;
}

-(void)resetTex
{
	[tileLock lock];
	if(inMemory)
	{
		NSLog(@"Tried to reset texture when in memory");
		[tileLock unlock];
		return;
	}
	texture[0] = 0;
	inMemory = FALSE;
	loadingToMemory = FALSE;
	inPreload = FALSE;
	//#ifdef DEBUG
	//NSLog(@"Resetting tex at %d %d", xPos, yPos);
	//#endif	
	[tileLock unlock];

}

-(BOOL)isInMemory
{
	return inMemory;
}

-(BOOL)isLoading
{
	return loadingToMemory;
}


- (GLuint*)getTexture
{
	return texture;
}

-(void)deleteFromCache
{
	if(prevInCache!=NULL)
		[prevInCache setNext:nextInCache];
	if(nextInCache!=NULL)
		[nextInCache setPrev:prevInCache];
	prevInCache = NULL;
	nextInCache = NULL;
}
- (void)setPrev:(Tile*)t
{
	prevInCache = t;
}

- (void)setNext:(Tile*)t
{
	nextInCache = t;
}

- (Tile*)getNext
{
	return nextInCache;
}
- (Tile*)getPrev
{
	return prevInCache;
}



-(void)deleteFromCacheNet
{
	if(prevInCacheNet!=NULL)
		[prevInCacheNet setNextNet:nextInCacheNet];
	if(nextInCacheNet!=NULL)
		[nextInCacheNet setPrevNet:prevInCacheNet];
	prevInCacheNet = NULL;
	nextInCacheNet = NULL;
}
- (void)setPrevNet:(Tile*)t
{
	prevInCacheNet = t;
}

- (void)setNextNet:(Tile*)t
{
	nextInCacheNet = t;
}

- (Tile*)getNextNet
{
	return nextInCacheNet;
}
- (Tile*)getPrevNet
{
	return prevInCacheNet;
}

-(BOOL) isInCacheNet
{
	return inCacheNet;
}

-(void) setInCacheNetTo:(BOOL)b
{
	inCacheNet = b;
}

-(int)getChannel
{
	return channelId;
}




@end
