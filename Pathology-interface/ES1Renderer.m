//
//  ES1Renderer.m
//  GigaPixel
//
//  Created by Axel Hansen on 2/9/10.
//  Copyright Harvard University 2010. All rights reserved.
//

/*
	This is the core OpenGL code.  Has the render function.  This stays alive for multiple slices.
	to switch slices.
 */

#import "ES1Renderer.h"
#import "Tile.h"
#import "sourceUtil.h"
//#import "URLCacheConnection.h"

@implementation ES1Renderer


extern int maxId;
//gets changed for overlap by loading header file
int TILE_SIZE = 512;//508;//512;

int MAX_IMAGES = 25;

//768,1029 for iPad
int SCREEN_WIDTH = 768;
int SCREEN_HEIGHT = 1040;
int SCREEN_HEIGHT2 = 1024;


extern BOOL USING_ADV_COMP;

//320, 480 for iPhone
//int SCREEN_WIDTH = 320;
//int SCREEN_HEIGHT = 480;


BOOL SYNC_ON=FALSE;

SYNC_SENT_THRESH = 5;

//gets changed by loading header file
static GLfloat texCoords[] = {
	0.0, 0.0,
	1.0, 0.0,
	0.0, 1.0,
	1.0, 1.0
};

/*static const GLfloat texCoords[] = {
	2.0/512, 2.0/512,
	510.0/512, 2.0/512,
	2.0/512, 510.0/512,
	510.0/512, 510.0/512
};*/

-(void)turnOnSync
{
	SYNC_ON=TRUE;
}

-(void)turnOffSync
{
	SYNC_ON=FALSE;
}


-(NSString*)getImage
{
	return gigaImage;
}

-(void)switchSliceTo:(int)newS
{
	BOOL clearTiles = FALSE;
	if(((curSlice-1)%3==0&&(newS-1)%3==2)||((curSlice-1)%3==2&&(newS-1)%3==0))
	{
		clearTiles=TRUE;
	}
	curSlice = newS;
	setFocalLevelForAllTiles(curSlice);

	if(!clearTiles)
	{
		[self render];
		return;
	}
	//both thread pause and kill block until done
	[pm pauseThread];
	[tm killTileLoader];
	[tm release];
	
	//sumDeltaX=0.0;
	//sumDeltaY=0.0;
	
	//baseScale = 0;
	
	//curLevel = 0.0f;
	//ctrPos[0] = 0; 
	//ctrPos[1] = 0;
	
	finishedInit = 1;
	[self createTileManager];
	[pm setTileManager:tm];
	[pm unPauseThread];
	[self render];
	[self sendSyncUpdate];

}

- (void) drawText:(Texture2D*)statusTexture AtX:(float)X Y:(float)Y {
	// Use black
	//glColor4f(0, 0, 0, 1.0);
	
	// Set up texture
	
	// Bind texture
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, [statusTexture name]);
	
	// Enable modes needed for drawing
	//glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	//glEnableClientState(GL_VERTEX_ARRAY);
	glEnable(GL_TEXTURE_2D);
	glEnable(GL_BLEND);
	
	glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
	
	// Draw
	//[statusTexture drawInRect:CGRectMake(X,Y-1,1,1)];   
	float size=.25;
	if(curLevel<0)
		size/=(-curLevel);
	if(size>.25)
		size=.25;
	[statusTexture drawInRect:CGRectMake(X,Y-size,size,size)];   
//	[statusTexture drawInRect:CGRectMake(X,Y-.25,.25,.25)];   
    //[statusTexture drawAtPoint:CGPointMake(X, Y)];

	
	// Disable modes so they don't interfere with other parts of the program
	//glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	//glDisableClientState(GL_VERTEX_ARRAY);
	glDisable(GL_TEXTURE_2D);
	glDisable(GL_BLEND); 
}

int loadPyramidFile(struct FileInfo ** fis, NSString *img, int curSlice, ES1Renderer *rend)
{
	NSString *fileS = [NSString stringWithFormat:@"%@%d",@"header", curSlice];
	NSString *subPath = [NSString stringWithFormat:@"%@/%@.txt", img, fileS];
	NSLog(subPath);
//	NSString *subPath = [NSString stringWithFormat:@"%@%d",@"header", curSlice];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString * dataPath = [paths objectAtIndex:0];

	NSString *path = [dataPath stringByAppendingPathComponent:subPath];  //file path
	//NSLog(@"Path:%@", path);
	if([[NSFileManager defaultManager] fileExistsAtPath:path] == NO)
	{
		//NSLog(@"Needs to download header");
		NSString *hdrUrl = [NSString stringWithFormat:@"http://neurotrace.seas.harvard.edu/%d/GETFILEHEADER", atoi([getBaseURL() UTF8String])];
		NSURL *headUrl = [[NSURL alloc] initWithString:hdrUrl];
		//NSLog([headUrl absoluteString]);
		NSData *file = [[NSData alloc] initWithContentsOfURL:headUrl];
		//NSLog(@"Got data with size %d", [file length]);
		//NSLog(path);
		[file writeToFile:path atomically:NO];
	}

	
	NSData *file = [[NSData alloc] initWithContentsOfFile:path];
	
	
	FILE *fp = fopen([path UTF8String], "r");
	
	if(fp == NULL) NSLog(@"Couldn't open file");

	fscanf(fp, "v %*d %*d\n");
	int iSX, iSY, pS;
	fscanf(fp, "imgsize %d %d\n", &iSX, &iSY);
	fscanf(fp, "pixsize %d\n", &pS);
	fscanf(fp, "lensmag %*f\n");
	fscanf(fp, "channel %*d\n");
	int tileSize;
	fscanf(fp, "tiledim %d %*d\n", &tileSize);
	
	int overlap;
	fscanf(fp, "tileoverlap %d\n", &overlap);
	NSLog(@"overlap=%d", overlap);
	
	double minTexX = (double)overlap / (double)TILE_SIZE;
	double minTexY = (double)overlap / (double)TILE_SIZE;
	double maxTexX = ((double)TILE_SIZE-overlap) / (double)TILE_SIZE;
	double maxTexY = ((double)TILE_SIZE-overlap) / (double)TILE_SIZE;
	
	GLfloat texCoords2[] = {
		minTexX, minTexY,
		maxTexX, minTexY,
		minTexX, maxTexY,
		maxTexX, maxTexY
	};
	
	memcpy(texCoords, texCoords2, sizeof(GLfloat)*8);
	
	NSLog(@"texCoords[0]=%f, textCoords2[0]=%f, 510.0/512=%f", texCoords[7], texCoords2[7], 510.0/512.0);
//	texCoords = texCoords2;

	TILE_SIZE-=2*overlap;

	
	fscanf(fp, "slice %*d\n");
	int numImages;
	fscanf(fp, "%*d %d %*f\n", &numImages);
	NSLog(@"num images = %d", numImages);
	char buf[1000];
	int offset = 0;
	for(int k=0;k<numImages;k++)
	{
		struct FileInfo * fi = (struct FileInfo *)(fis[k]);
		fi->tileSize = tileSize;
		fscanf(fp, "%s\n", buf);
		char * dataName = malloc(1000);
		strncpy(dataName, buf, 1000);
		fi->dataFileName = dataName;
		NSLog(@"Using data file %s len=%d", dataName, strlen(buf));
		
		fscanf(fp, "%d\n", &fi->pLevel);

	//#ifdef DEBUG
		NSLog(@"Pyramid depth:%d", fi->pLevel);
	//#endif
		
		//NSLog(@"remaining file:%s", fp+offset);
		
		int **levelI;
		levelI = (int*)malloc(sizeof(int*)*fi->pLevel);
		float***levelMatrices = (float***)malloc(sizeof(float**)*fi->pLevel);
		//NSLog(@"remaining = %s", fp+offset);

		for(int i=0; i<fi->pLevel; i++) 
		{	
			levelI[i]=malloc(sizeof(int)*4);
			
			fscanf(fp, "%i %i %i %i\n", &(levelI[i][2]), &(levelI[i][3]), &(levelI[i][0]), &(levelI[i][1])); // w/h/nTiles per level
			sprintf(buf,"%i %i %i %i\n",(levelI[i][2]), (levelI[i][3]), (levelI[i][0]), (levelI[i][1]));
			offset += strlen(buf);
	//#ifdef DEBUG_2
			NSLog(@"Level %d, %dx%d tiles %dx%d size", i, levelI[i][0],levelI[i][1],levelI[i][2],levelI[i][3]);
	//#endif
			float **levelMatrix = (float**)malloc(sizeof(float*)*4);
			for(int j=0;j<4;j++)
			{
				levelMatrix[j]=(float*)malloc(sizeof(float)*4);
			}
			//NSLog(@"remaining = %s", fp+offset);
			for(int j=0; j<15; j++) 
			{
				//NSLog(@"j=%d", j);
				int mX, mY;
				mX = j%4;
				mY = (int)(j/4);
				//NSLog(@"[%d, %d]", mX, mY);
				fscanf(fp, "%f ", &(levelMatrix[mX][mY]));
				//NSLog(@"REad in %s as %f (%d, %d)", buf, levelMatrix[mX][mY], mX, mY);

			}
			fscanf(fp, "%f\n", &(levelMatrix[3][3]));
			
			//NSLog(@"before xform [%f, %f]", levelMatrix[0][3], levelMatrix[1][3]); 
			levelMatrix[0][3]=[rend convertX:levelMatrix[0][3] withIW:(int)(levelI[i][2])];
			levelMatrix[1][3]=[rend convertY:levelMatrix[1][3] withIH:(int)(levelI[i][3])];
			//NSLog(@"xform [%f, %f]", levelMatrix[0][3], levelMatrix[1][3]); 
			
			
			levelMatrices[i]=levelMatrix;

		}
		
		//NSLog(@"Remaining %s", fp+offset);
		fi->levelMatrices = levelMatrices;		
		
		fi->levelSizes = levelI;
	}
	[file release];
	//[path release];
#ifdef DEBUG_2
	NSLog(@"Done loading pyramid file");
#endif
	return numImages;
}

-(EAGLContext*)getContextA
{
	return context;
}
-(EAGLContext*)getContextB
{
	return contextB;
}


- (void)dealloc
{
    // Tear down GL
    if (defaultFramebuffer)
    {
        glDeleteFramebuffersOES(1, &defaultFramebuffer);
        defaultFramebuffer = 0;
    }
	
    if (colorRenderbuffer)
    {
        glDeleteRenderbuffersOES(1, &colorRenderbuffer);
        colorRenderbuffer = 0;
    }
	
    // Tear down context
    if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];
	if ([EAGLContext currentContext] == contextB)
        [EAGLContext setCurrentContext:nil];

    [context release];
	[contextB release];
	contextB = nil;
    context = nil;
	
    [super dealloc];
}

-(void)resetMessages
{
	messages = [[NSMutableArray alloc] init];
	maxId = 0;
	[self render];
}

-(void)addMessage:(Message *)msg
{
	//make sure don't add same messages.
	for(int i=0;i<[messages count];i++)
	{
		Message* oldMsg = (Message*)[messages objectAtIndex:i];
		if([msg getMessageId]!=-1 && [oldMsg getMessageId]==[msg getMessageId])
			return; //already in
	}
		
	[messages addObject:msg];
}


// Create an OpenGL ES 1.1 context
- (id)initWithBounds:(CGRect)bounds andSemaphore:(semaphore_t*)s andPrefetchManager:(PrefetchManager*)p andImg:(NSString *)img andSlice:(int)slice andId:(int)givenId
{
	loadingTime=0.0;
	tilesRendered=1;
	renderTime = 0.0;
	tilesLoaded=1;
	myId=givenId;
	syncsSent = 0;
	curSlice = slice;
	gigaImage = img;
	
	bandwidthDataPoints=1;
	bandwidthSum=0.0;
	
	messages = [[NSMutableArray alloc] init];
	
	initialLevel=-1;
	
	setFocalLevelForAllTiles(0);
	
    if (self = [super init])
    {
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
		contextB = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2 
										 sharegroup:context.sharegroup];
		if (!contextB || ![EAGLContext setCurrentContext:contextB]) {
			// Handle errors here
			NSLog(@"Error creating context b");
		}
		
		
        if (!context || ![EAGLContext setCurrentContext:context])
        {
            [self release];
            return nil;
        }
		
		[self loadShaders];
		
		[GLLock setES1Renderer:self];
		
        // Create default framebuffer object. The backing will be allocated for the current layer in -resizeFromLayer
        glGenFramebuffersOES(1, &defaultFramebuffer);
        glGenRenderbuffersOES(1, &colorRenderbuffer);
        glBindFramebufferOES(GL_FRAMEBUFFER_OES, defaultFramebuffer);
        glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
        glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, colorRenderbuffer);
		
		//====================
		
		const GLfloat zNear = 0.01, zFar = 1000.0, fieldOfView = 45.0; 
		GLfloat size; 
		glEnable(GL_DEPTH_TEST);
//		glMatrixMode(GL_PROJECTION); 
		size = zNear * tanf(DEGREES_TO_RADIANS(fieldOfView) / 2.0); 
		windowBounds = bounds;

		CGRect rect = bounds;
#ifdef DEBUG
		NSLog(@"Creating renderer with widht %f and height %f", bounds.size.width, bounds.size.height);
#endif
		glViewSize = bounds;
		
		width = 2;
		height = (1.0 / (glViewSize.size.width / glViewSize.size.height))-(-1.0 / (glViewSize.size.width / glViewSize.size.height));
		startY = (1.0 / (glViewSize.size.width / glViewSize.size.height));
		//NSLog("w=%f h=%f sY=%f", self.width, self.height, self.startY);
		NSLog(@"factor=%f height=%f news=%f",((float)SCREEN_HEIGHT/SCREEN_WIDTH), height,((float)SCREEN_HEIGHT/SCREEN_WIDTH)*startY);
		float newStartY=startY/((float)SCREEN_HEIGHT/SCREEN_WIDTH);
		startY = 2*(newStartY-startY)+startY;
		
		glViewport(0, 0, rect.size.width, rect.size.height);  
		
	//	glMatrixMode(GL_MODELVIEW);
		
		
		//AH: turn on texturing
		glEnable(GL_TEXTURE_2D);
		
				
		//Initialize translation to 0,0
		sumDeltaX=0.0;
		sumDeltaY=0.0;
		
		
		baseScale = 0;
		
		curLevel = 0.0f;
		ctrPos[0] = 0; 
		ctrPos[1] = 0;
		
		showGrid = TRUE;
		finishedInit = 1;
		
		pm = p;
		signalSem = s;
		
    }
	
	[GLLock acquireGLLock];
	glGenTextures(1, &loadingTexture[0]);
	glBindTexture(GL_TEXTURE_2D, loadingTexture[0]);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR); 
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
	
	//load the image data
	NSString *path = [[NSBundle mainBundle] pathForResource:@"checkers" ofType:@"png"];  //file path
	//NSLog(path);
	NSData *texData = [[NSData alloc] initWithContentsOfFile:path];
	UIImage *image = [[UIImage alloc] initWithData:texData];
	if (image == nil)
		NSLog(@"Failed to open image");
	
	GLuint width = CGImageGetWidth(image.CGImage);
	GLuint height = CGImageGetHeight(image.CGImage);
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	void *imageData = malloc( height * width * 4 );
	CGContextRef context2 = CGBitmapContextCreate( imageData, width, height, 8, 4 * width, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big );
	CGContextTranslateCTM (context2, 0, height);
	CGContextScaleCTM (context2, 1.0, -1.0);
	CGColorSpaceRelease( colorSpace );
	CGContextClearRect( context2, CGRectMake( 0, 0, width, height ) );
	CGContextTranslateCTM( context2, 0, height - height );
	CGContextDrawImage( context2, CGRectMake( 0, 0, width, height ), image.CGImage );
	
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
	[GLLock releaseGLLock];
	CGContextRelease(context2);
	
	
	free(imageData);
	[image release];
	[texData release];
	
	
	[self createTileManager];
	[pm setTileManager:tm];
	//NSLog(@"Renderer about to try starting pm thread");
	[pm startThread];
	//NSLog(@"pm test after thread start");
	//[pm test];
	//[self updateCurrentViewFrustum];

	/*float leftBound = viewFrustum[0]+ctrPos[0];
	float rightBound = viewFrustum[1]+ctrPos[0];
	float bottomBound = viewFrustum[2]+ctrPos[1];
	float topBound = viewFrustum[3]+ctrPos[1];
	float imageWidthPix = SCREEN_WIDTH*(width/(rightBound-leftBound));
	float imageHeightPix = SCREEN_HEIGHT*(height/(topBound-bottomBound));
	int intLevel = [tm calculateDepthFromSize:imageWidthPix andHeight:imageHeightPix usingWidth:TRUE];
	
	CGFloat y = (SCREEN_HEIGHT-imageHeightPix);
	y = 1024-(508)*2;
	CGFloat curY = -(((float)((height*y)/glViewSize.size.height)-(height/2.0))*pow(2.0,(double)curLevel))+ctrPos[1];
	NSLog(@"Have %f extra, turns into %f", y, curY);
	//startY += curY;*/
	NSLog(@"factor=%f height=%f newH=%f",((float)SCREEN_HEIGHT/SCREEN_WIDTH), height,((float)SCREEN_HEIGHT/SCREEN_WIDTH)*height);
	
	isRendering = FALSE;
    return self;
}


- (void) createTileManager
{
	int imgcount = MAX_IMAGES;
	struct FileInfo **fis;
	fis = (struct FileInfo **)malloc(sizeof(struct FileInfo*)*imgcount);
	for(int i=0;i<imgcount;i++)
		fis[i] = (struct FileInfo *)malloc(sizeof(struct FileInfo));
	numberImages = loadPyramidFile(fis, gigaImage, curSlice, self);
	adjWidth = sqrt(numberImages);
	
	
	tm = [[TileManager alloc] initWithFileInfo:fis andSlice:curSlice andCount:numberImages];//TODO:CHANGE COUNT
	for(int k=0;k<numberImages;k++)
	{
		struct FileInfo *fi = fis[k];
		for(int i=0;i<fi->pLevel;i++)
			free(fi->levelSizes[i]);
		free(fi->levelSizes);
		free(fi);	
	}
	free(fis);
	
	int depth = 0;//[tm getDepth]-1;
	imageWidth = [tm getLevelWidthPixels:depth];
	imageHeight = [tm getLevelHeightPixels:depth];
	//NSLog(@"Set imageW=%f h=%f", imageWidth, imageHeight);
	
}


//update the current frustum
- (void) updateCurrentViewFrustum
{	
	//curLevel += [tm getDepth]-2;
	viewFrustum[0] = (double)-pow(2.0,(double)curLevel);
	viewFrustum[1] = (double)pow(2.0,(double)curLevel);
	viewFrustum[2] = (double)-pow(2.0,(double)curLevel)/ (windowBounds.size.width / windowBounds.size.height);
	viewFrustum[3] = (double)pow(2.0,(double)curLevel)/ (windowBounds.size.width / windowBounds.size.height);
	//curLevel -= [tm getDepth]-2;

}	

-(CGRect)getWinBounds
{
	return windowBounds;
}

-(BOOL)isThreadRendering
{
	return isRendering;
}

- (void)render
{	
	NSTimeInterval time = [NSDate timeIntervalSinceReferenceDate];
	int tilesDrawn=0;
	isRendering = TRUE;
	//NSLog(@"Rendering");
	[tm resetTileLoading:self];
	//NSLog(@"level=%f", curLevel);
	int intLevel = (int)curLevel;
	if(intLevel <0)
		intLevel = 0;
	if(intLevel>[tm getDepth]-1)
		intLevel = [tm getDepth]-1;
	

	glUseProgram(program);
	[GLLock acquireGLLock];
	glClearColor(0.0, 0.0, 0.0, 0.0);
	glClear(GL_COLOR_BUFFER_BIT);

		ESMatrix matrix;
		ESMatrix projection;
		ESMatrix model;
		esMatrixLoadIdentity(&matrix);
		esMatrixLoadIdentity(&projection);
		esMatrixLoadIdentity(&model);

		//glMatrixMode( GL_PROJECTION );
		//glLoadIdentity();


		[self updateCurrentViewFrustum];
		//NSLog(@"drawing %d level:%f height:%f width:%d", intLevel, curLevel, windowBounds.size.height, windowBounds.size.width);

		
		//glEnableClientState(GL_VERTEX_ARRAY);
		//glEnableClientState(GL_NORMAL_ARRAY);
		//glEnableClientState(GL_TEXTURE_COORD_ARRAY);
		//glColor4f(1,1,1,1);

		//these tex coords will flip the image in the y axis
		
		//this method fits all tiles into visible area
		float leftBound = viewFrustum[0]+ctrPos[0];
		float rightBound = viewFrustum[1]+ctrPos[0];
		float bottomBound = viewFrustum[2]+ctrPos[1];
		float topBound = viewFrustum[3]+ctrPos[1];
		float imageWidthPix = SCREEN_WIDTH*(width/(rightBound-leftBound));
		float imageHeightPix = SCREEN_HEIGHT2*(height/(topBound-bottomBound));
	
	//NSLog(@"dif= %f", SCREEN_HEIGHT-imageHeightPix);
		intLevel = [tm calculateDepthFromSize:imageWidthPix/(2.0*ceil(adjWidth)) andHeight:imageHeightPix/(2.0*floor(adjWidth)) usingWidth:FALSE];
		
	if(initialLevel==-1)
		initialLevel=intLevel;

	
		float** levelMatrix = [tm getMatrix:intLevel andImg:0];
		/*NSLog(@"Matrix:");
		for(int x=0;x<4;x++)
		{
			NSString *row = @"";
			for(int y=0;y<4;y++)
				row = [NSString stringWithFormat:@"%@ %f", row, levelMatrix[x][y]];
			NSLog(row);
		}*/
		
		//esMatrixMultiply( &matrix, &matrix, levelMatrix );
		
		esOrtho(&projection, viewFrustum[0],viewFrustum[1], viewFrustum[2], viewFrustum[3], .01, 10000);
		//glOrthof(viewFrustum[0], viewFrustum[1], viewFrustum[2], viewFrustum[3], .01, 10000);
		
		
		//glMatrixMode(GL_MODELVIEW);
		//glLoadIdentity();
		
		//gluLookAt has been modified to work with the given model matrix
		gluLookAt(&model, ctrPos[0], ctrPos[1], 1, ctrPos[0], ctrPos[1], 0, 0,1,0);
		
		esMatrixMultiply( &matrix, &model, &projection );
		//esRotate(&matrix, 180, 0, 0, 0);
		
		glUniformMatrix4fv( uniforms[UNIFORM_MATRIX], 1, GL_FALSE, (GLfloat*) &matrix.m[0][0] );
		[GLLock releaseGLLock];
	for(int curImage=0;curImage<numberImages;curImage++)
	{

		
		
		
	#ifdef DEBUG_1
		NSLog(@"CtrPos[0]:%f CtrPos[1]:%f", ctrPos[0], ctrPos[1]);
		NSLog(@"viewFrustum[0]:%f viewFrustum[1]:%f viewFrustum[2]:%f viewFrustum[3]:%f", viewFrustum[0],viewFrustum[1], viewFrustum[2], viewFrustum[3]);
		NSLog(@"Redering, curLevel:%f intLevel:%d", curLevel, intLevel);
	#endif

		int numRows = [tm getLevelHeight:intLevel];
		int numCols = [tm getLevelWidth:intLevel];

		float tileDivider = pow(2, [tm getDepth]-1-intLevel);
	//	NSLog(@"tile divider:%f, depth %d", tileDivider, [tm getDepth]);
		float dx = min(width/tileDivider, width/numCols); 
		float dy;// = min(height/tileDivider,height/numCols);
	//	float dx = width/(numCols+1);
	//	float dy = height/(numRows+1);
		dx=(width/[tm getLevelWidthPixels:intLevel])*TILE_SIZE;
		dy = dx; // should be dx=dy if image high, dy=dx if wide
		
		//startY=startY+curImage*height;//(.5*startY)*(curImage+1);
		CGFloat startX = 1.0;
		//startX=startX+curImage*width;//(startX)*(curImage+1);

		

	#ifdef DEBUG_2	
		NSLog(@"Entering loop with dx %f dy %f (old dx=%f old dy=%f) for %d rows %d cols for upper corner x=%f y=%f", dx, dy, width/numCols, height/numRows, numRows, numCols, width/2, height/2);
		NSLog(@"Window x:[%f, %f] y:[%f, %f]", viewFrustum[0]+ctrPos[0], viewFrustum[1]+ctrPos[0], viewFrustum[2]+ctrPos[1], viewFrustum[3]+ctrPos[1]);
		NSLog(@"StartY=%f, width=%f, height=%f, dx=%f, dy=%f", startY, width, height, dx, dy);
		NSLog(@"Pixel dimensions: %f, %f", imageWidthPix, imageHeightPix);
	#endif

		int newL, newR, newB, newT;
		newL = numCols-1;
		newR = 0;
		newB = numRows-1;
		newT = 0;
		
		int startCol = (leftBound+1)/dx;
		//int endCol = numCols-1-((1-rightBound)/dx);
		int endCol = (rightBound+1)/dx;
		//int startRow = (bottomBound+startY)/dy;
		int startRow = (-topBound+startY+dy)/dy;
		int endRow = (-bottomBound+startY)/dy;
		//int endRow = numRows-((startY-topBound)/dy);

		//int startRow = ((startY-topBound)/dy);
		//int endRow = (startY+bottomBound)/dy;
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


		
		/*if(endCol>=numCols)
			endCol = numCols-1;
		if(endRow>=numRows)
			endRow = numRows-1;*/
		
		//NSLog(@"Drawing level %d from [%d,%d] to [%d,%d]", intLevel, startCol, startRow, endCol, endRow);
		//NSLog(@"\tDrawing viewFrustum[0]:%f viewFrustum[1]:%f viewFrustum[2]:%f viewFrustum[3]:%f", viewFrustum[0],viewFrustum[1], viewFrustum[2], viewFrustum[3]);


		//NSLog(@"Start col:%d  end col:%d start row:%d end row:%d", startCol, endCol, startRow, endRow, startY);
		//printf("ren start tile draw\n");
		//[GLLock acquireGLLock];
		int colAmt = 0;
		int rowAmt = 0;
		if(numberImages>1)
		{
			dy*=((adjWidth)/(numberImages));
			dx*=((adjWidth)/(numberImages));
			colAmt = (int)curImage%(numberImages/(int)(adjWidth));
			rowAmt = (numberImages/(int)(adjWidth))-(int)curImage/(numberImages/(int)(adjWidth))-1;

		}
		
		//NSLog(@"%d -> (%d, %d)", curImage, colAmt, rowAmt);
	//	for(int r=startRow;r<=endRow;r++)
	//	{
	//		for(int c=startCol;c<=endCol;c++)
		for(int r=0;r<numRows;r++)
		{
			for(int c=0;c<numCols;c++)
			{
				//r+=endRow*(curImage);
				//c+=endCol*(curImage);
				if(numberImages>1)
				{
					 c+=numCols*colAmt;
					 r+=numRows*rowAmt;
				}
				//r+=.5;
				 Vertex3D vertices[] = {
					{-startX+dx*c, -startY+(r)*dy, -0.0},
					{-startX+dx*(c+1), -startY+(r)*dy, -0.0},
					{-startX+dx*c, -startY+dy*(1+r), -0.0},
					{-startX+dx*(c+1), -startY+dy*(1+r), -0.0}
				};
				/*Vertex3D vertices[] = {
					{-startX+dx*c, startY-(r)*dy, -0.0},
					{ -startX+dx*(c+1), startY-(r)*dy, -0.0},
					{-startX+dx*c, startY-dy*(1+r), -0.0},
					{ -startX+dx*(c+1), startY-dy*(1+r), -0.0}
				};*/
				
				//r-=endRow*(curImage);
				//c-=endCol*(curImage);
				//r-=.5;
				if(numberImages>1)
				{
					c-=numCols*colAmt;
					r-=numRows*rowAmt;
				}
				
				if((vertices[1].x<leftBound || vertices[0].x>rightBound) || (vertices[2].y<bottomBound || vertices[1].y>topBound))
				{
	#ifdef DEBUG_2
					NSLog(@"Skipping tile %d, %d", c, r);
	#endif
					//continue;
				}
	#ifdef DEBUG_2
				NSLog(@"Drawing tile %d, %d", c, r);
	#endif
				
	#ifdef DEBUG_3
				NSLog(@"Vertices for x=%d y=%d:", c, r);
				NSLog(@"%f, %f, %f",vertices[0].x, vertices[0].y, -0.0);	  
				NSLog(@"%f, %f, %f",vertices[1].x, vertices[1].y, -0.0);	  
				NSLog(@"%f, %f, %f",vertices[2].x, vertices[2].y, -0.0);
				NSLog(@"%f, %f, %f",vertices[3].x, vertices[3].y, -0.0);
	#endif
			//	NSLog(@"Rendering tile %d %d", c, r);
				Tile* tile = [tm getTileWithX:c andY:r inDepth:intLevel andPreload:FALSE andImg:curImage];
				if(c<newL)
					newL = c;
				if(c>newR)
					newR = c;
				if(r<newB)
					newB = r;
				if(r>newT)
					newT = r;
				if(tile==nil)
					NSLog(@"Tile is nil!");
			//	printf("=!=");
				[tile lockTile];
				GLuint *t;
				BOOL loadingTex = FALSE;
				if([tile isLoading] || ![tile isInMemory])
				{
					//NSLog(@"Using loading texture");
					t = loadingTexture;
					loadingTex = TRUE;
				}
				else
				{
					t = [tile getTexture];
					//NSLog(@"Using correct loaded texture at %d %d", c ,r);
				}
				
				if(t[0]==0)
					NSLog(@"Have a zero texture for %d %d...", c, r);
				

				//printf("ren acqing gllock\n");
				//printf("ren got\n");
				//NSLog(@"\tFor %d %d, using texture %d", c, r, t[0]);
				[GLLock acquireGLLock];
				tilesDrawn++;
				if(USING_ADV_COMP)
				{
					
					//NSLog(@"t0=%d t1=%d", t[0], t[1]);
					//set the main texture
					glActiveTexture(GL_TEXTURE0);
					glBindTexture(GL_TEXTURE_2D, t[0]);
					
					int channel = [tile getChannel];
					glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, 0, 0, vertices);
					glVertexAttribPointer(ATTRIB_TEX_CO, 2, GL_FLOAT, 0, 0, texCoords);
					
					glEnableVertexAttribArray ( ATTRIB_VERTEX );
					glEnableVertexAttribArray ( ATTRIB_TEX_CO );
					
					// Set the sampler texture unit to 0
					if(loadingTex)
						glUniform1i ( uniforms[UNIFORM_CHANNEL], -3 );
					else 
						glUniform1i ( uniforms[UNIFORM_CHANNEL], (curSlice-1)%3 );
					
					//pass in iKLT var
					float *iKLT = [tile getIKLT];
					/*for(int i=0;i<9;i++)
					{
						NSLog(@"\tiKLT[%d]=%f", i, iKLT[i]);
					}*/
					
					glUniform4f(uniforms[UNIFORM_IKLT0], iKLT[0], iKLT[1], iKLT[2], iKLT[3]);
					glUniform4f(uniforms[UNIFORM_IKLT4], iKLT[4], iKLT[5], iKLT[6], iKLT[7]);
					glUniform1f(uniforms[UNIFORM_IKLT8], iKLT[8]);

					//set the secondary texture
					glActiveTexture(GL_TEXTURE1);
					glBindTexture(GL_TEXTURE_2D, t[1]);
					// Set the sampler texture unit to 0
					glUniform1i ( uniforms[UNIFORM_S_TEX], 0 );

					glUniform1i ( uniforms[UNIFORM_S_TEX2], 1 );				
					
					//glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
					glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
					
				}
				else 
				{
					glActiveTexture(GL_TEXTURE0);
					glBindTexture(GL_TEXTURE_2D, t[0]);
					//glVertexPointer(3, GL_FLOAT, 0, vertices);
					int channel = [tile getChannel];
					int channels[2];
					channels[0]=channel;
					channels[1]=0;
					glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, 0, 0, vertices);
					glVertexAttribPointer(ATTRIB_TEX_CO, 2, GL_FLOAT, 0, 0, texCoords);
					//glVertexAttribPointer(ATTRIB_CHANNEL, 2, GL_INT, 0, 0, channels);

					glEnableVertexAttribArray ( ATTRIB_VERTEX );
					glEnableVertexAttribArray ( ATTRIB_TEX_CO );
					//glEnableVertexAttribArray ( ATTRIB_CHANNEL );

					
					// Set the sampler texture unit to 0
					glUniform1i ( uniforms[UNIFORM_S_TEX], 0 );
					if(loadingTex)
						glUniform1i ( uniforms[UNIFORM_CHANNEL], -3 );
					else 
						glUniform1i ( uniforms[UNIFORM_CHANNEL], channel );

					//glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
					glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
				}
				[GLLock releaseGLLock];

				[tile unLockTile];

			}
		}
		/*[GLLock acquireGLLock];
		int numArray = (endCol-startCol)*(endRow-startRow);
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

		[GLLock releaseGLLock];*/

		//printf("rend end tile draw\n");
		float *ctrPos2 = (float*)malloc(sizeof(ctrPos));
		memcpy(ctrPos2, ctrPos, sizeof(ctrPos));

		[pm setCurBoundsWithLeft:newL andRight:newR andTop:newT andBottom:newB andLevel:intLevel andFloatLevel:curLevel andCtrPos:ctrPos2];
		
		
		[GLLock acquireGLLock];
		glBindTexture(GL_TEXTURE_2D, 0);
		for(int i=0;i<[messages count];i++)
		{
			Message* msg = (Message*)[messages objectAtIndex:i];
			
			if([msg getType]==0)
			{
				CGFloat xVal = [msg getX];
				CGFloat yVal = [msg getY];
				Vertex3D vertices[] = {
					{xVal, yVal, -0.0},
					{ xVal+.04, yVal+.01, -0.0},
					{ xVal+.015, yVal+.015, -0.0},
					{xVal, yVal, -0.0},
					//{ xVal+.01, yVal+.04, -0.0},
					//{ xVal+.015, yVal+.01, -0.0},
					//{xVal, yVal, -0.0},
					
					//{xVal+.05, yVal+.05, -0.0},
				};
				glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, 0, 0, vertices);
				glVertexAttribPointer(ATTRIB_TEX_CO, 2, GL_FLOAT, 0, 0, texCoords);
				glEnableVertexAttribArray ( ATTRIB_VERTEX );
				glEnableVertexAttribArray ( ATTRIB_TEX_CO );
				glUniform1i ( uniforms[UNIFORM_S_TEX], 0 );
				glUniform1i ( uniforms[UNIFORM_CHANNEL], -2 );
				glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
				
				Vertex3D vertices2[] = {
					{xVal, yVal, -0.0},
					{ xVal+.01, yVal+.04, -0.0},
					{ xVal+.015, yVal+.015, -0.0},
					{xVal, yVal, -0.0},
					//{ xVal+.01, yVal+.04, -0.0},
					//{ xVal+.015, yVal+.01, -0.0},
					//{xVal, yVal, -0.0},
					
					//{xVal+.05, yVal+.05, -0.0},
				};
				glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, 0, 0, vertices2);
				glVertexAttribPointer(ATTRIB_TEX_CO, 2, GL_FLOAT, 0, 0, texCoords);
				glEnableVertexAttribArray ( ATTRIB_VERTEX );
				glEnableVertexAttribArray ( ATTRIB_TEX_CO );
				glUniform1i ( uniforms[UNIFORM_S_TEX], 0 );
				glUniform1i ( uniforms[UNIFORM_CHANNEL], -2 );
				glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
				
			}
			else if([msg getType]==1)
			{
				CGFloat xVal1 = [msg getX];
				CGFloat yVal1 = [msg getY];
				CGFloat xVal2 = [msg getEndX];
				CGFloat yVal2 = [msg getEndY];
				//NSLog(@"(%f, %f) (%f, %f)", xVal1, yVal1, xVal2, yVal2);
				Vertex3D vertices[] = {
					{xVal1, yVal1, -0.0},
					{ xVal2, yVal2, -0.0},
					{xVal1, yVal1, -0.0},
				};
				glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, 0, 0, vertices);
				glVertexAttribPointer(ATTRIB_TEX_CO, 2, GL_FLOAT, 0, 0, texCoords);
				glEnableVertexAttribArray ( ATTRIB_VERTEX );
				glEnableVertexAttribArray ( ATTRIB_TEX_CO );
				glUniform1i ( uniforms[UNIFORM_S_TEX], 0 );
				glUniform1i ( uniforms[UNIFORM_CHANNEL], -2 );
				glDrawArrays(GL_LINE_STRIP, 0, 2);
			}
			else if([msg getType]==2)
			{
				//NSLog(@"Drawing some text");
				/*CGFloat xVal = [msg getX];
				CGFloat yVal = [msg getY];
				Vertex3D vertices[] = {
					{xVal, yVal, -0.0},
					{ xVal+.05, yVal, -0.0},
					{ xVal, yVal+.05, -0.0},
					{xVal+.05, yVal+.05, -0.0},
				};
				glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, 0, 0, vertices);
				glVertexAttribPointer(ATTRIB_TEX_CO, 2, GL_FLOAT, 0, 0, texCoords);
				glEnableVertexAttribArray ( ATTRIB_VERTEX );
				glEnableVertexAttribArray ( ATTRIB_TEX_CO );
				glUniform1i ( uniforms[UNIFORM_S_TEX], 0 );
				glUniform1i ( uniforms[UNIFORM_CHANNEL], -4 );
				glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);*/
				
				[self drawText:[msg getTexture2d] AtX:[msg getX] Y:[msg getY]];
			}
				
		}
		
		
		if(showGrid)
		{
			for(int r=0;r<numRows;r++)
			{
				for(int c=0;c<numCols;c++)
				{
					
					Vertex3D vertices[] = {
						{-startX+dx*c, startY-(r)*dy, -0.0},
						{ -startX+dx*(c+1), startY-(r)*dy, -0.0},
						{ -startX+dx*(c+1), startY-dy*(1+r), -0.0},
						{-startX+dx*c, startY-dy*(1+r), -0.0},
						{-startX+dx*c, startY-(r)*dy, -0.0}
					};

					//if(intLevel == 0) glColor4f(1,0,0,0);
					//else glColor4f(0, 1, 0,0);
					//glVertexPointer(3, GL_FLOAT, 0, vertices);	
					glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, 0, 0, vertices);
					glVertexAttribPointer(ATTRIB_TEX_CO, 2, GL_FLOAT, 0, 0, texCoords);

					glEnableVertexAttribArray ( ATTRIB_VERTEX );
					glEnableVertexAttribArray ( ATTRIB_TEX_CO );
					//glEnableVertexAttribArray ( ATTRIB_CHANNEL );
					
					
					// Set the sampler texture unit to 0
					glUniform1i ( uniforms[UNIFORM_S_TEX], 0 );
					glUniform1i ( uniforms[UNIFORM_CHANNEL], -1 );
					

					glDrawArrays(GL_LINE_STRIP, 0, 4);
				}
			}
			
		}
				

		
		
		//glDisableClientState(GL_VERTEX_ARRAY);
		//glDisableClientState(GL_TEXTURE_COORD_ARRAY);
		
		[GLLock releaseGLLock];
	}
	[GLLock acquireGLLock];
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER_OES];
	glFinish();
	[GLLock releaseGLLock];
	time = [NSDate timeIntervalSinceReferenceDate]-time;
	renderTime+=time;
	tilesRendered+=tilesDrawn;
	
	
	//NSLog(@"Signaling prefetch");
	//if(semaphore_signal_all(*signalSem))
	//	NSLog(@"Semaphore failed signaling all");
	[pm performSelector:@selector(prefetch) onThread:[pm getThread] withObject:nil waitUntilDone:FALSE];
	//NSLog(@"Done rendering");
	isRendering = FALSE;

}

-(void)setPointWithX:(CGFloat)x andY:(CGFloat)y
{
//	NSLog(@"Setting on (%f, %f", x, y);

	pointX = ((float)((2*x)/glViewSize.size.width)-(width/2.0))*pow(2.0,(double)curLevel);
	pointY = -(((float)((height*y)/glViewSize.size.height)-(height/2.0))*pow(2.0,(double)curLevel));
	
//	NSLog(@"Set to (%f, %f", pointX, pointY);
	//pointX=-1;
	//pointY=-1;
	
	//ctrPos[0] -= (float)newDx*pow(2.0,(double)curLevel);
	//ctrPos[1] -= (float)newDy*pow(2.0,(double)curLevel);	
	
}

-(NSMutableArray*)getMessages
{
	return messages;
}
	

-(CGFloat)convertX:(CGFloat)x
{
	CGFloat curX = ((float)((2*x)/glViewSize.size.width)-(width/2.0))*pow(2.0,(double)curLevel)+ctrPos[0];
	CGFloat oldX=curX;
	curX += 1.0;
	curX*=(imageWidth*ceil(adjWidth))/2;
	return curX;

	//return ((float)((2*x)/glViewSize.size.width)-(width/2.0))*pow(2.0,(double)curLevel)+ctrPos[0];
	//
}

-(CGFloat)convertY:(CGFloat)y
{
	CGFloat curY = -(((float)((height*y)/glViewSize.size.height)-(height/2.0))*pow(2.0,(double)curLevel))+ctrPos[1];
	curY -= height/2;
	curY*=(imageHeight*floor(adjWidth))/2;
	
	//curY=curY*.5 -.5*((imageHeight*adjWidth)/(imageWidth*adjWidth));

	
	return curY;
	
	//return -(((float)((height*y)/glViewSize.size.height)-(height/2.0))*pow(2.0,(double)curLevel))+ctrPos[1];
}

-(CGFloat)convertX:(CGFloat)x withIW:(int)iw
{
	CGFloat curX = ((float)((2*x)/glViewSize.size.width)-(width/2.0))*pow(2.0,(double)curLevel)+ctrPos[0];
	CGFloat oldX=curX;
	curX += 1.0;
	curX*=iw/2;
	return curX;
	
	//return ((float)((2*x)/glViewSize.size.width)-(width/2.0))*pow(2.0,(double)curLevel)+ctrPos[0];
	//
}

-(CGFloat)convertY:(CGFloat)y withIH:(int)ih
{
	CGFloat curY = -(((float)((height*y)/glViewSize.size.height)-(height/2.0))*pow(2.0,(double)curLevel))+ctrPos[1];
	curY -= height/2;
	curY*=ih/2;
	return curY;
	
	//return -(((float)((height*y)/glViewSize.size.height)-(height/2.0))*pow(2.0,(double)curLevel))+ctrPos[1];
}


-(CGFloat)getImageWidth
{
	return imageWidth*ceil(adjWidth);
}
-(CGFloat)getImageHeight
{
	return imageHeight*floor(adjWidth);
}
-(CGFloat)getScreenHeight
{
	return height;
}


-(void) translateImg: (CGFloat) dx andDy: (CGFloat) dy
{
	CGFloat newDx, newDy;
	
	//translate into opengl coords
	//need negative y because of some weird inversion thing
	newDx = ((2*dx)/glViewSize.size.width);
	newDy = -((2*dy)/glViewSize.size.height);
	
	ctrPos[0] -= (float)newDx*pow(2.0,(double)curLevel);
	ctrPos[1] -= (float)newDy*pow(2.0,(double)curLevel);	
	[self sendSyncUpdate];
}

-(void)tileLoadTime:(float)i
{
	//NSLog(@"new time=%f", i);
	loadingTime += i;
	tilesLoaded++;
}

-(float)getTime
{
	NSLog(@"loading time=%f, render time=%f", (loadingTime/tilesLoaded),(renderTime/tilesRendered));
	return (loadingTime/tilesLoaded)+(renderTime/tilesRendered);
}

-(void)bandwidthUpdate:(float)rate andTime:(float)i
{
	bandwidthDataPoints+=i;
	//NSLog(@"Got a rate(%f), now %d points, int=%d", (float)rate, bandwidthDataPoints, i);
	bandwidthSum+=rate;
	//float bandwidth=bandwidthSum/bandwidthDataPoints;
	//bandwidthLabel.text = [NSString stringWithFormat:@"%f b/s", bandwidth];
}

-(float)getRate
{
	return bandwidthSum/totalTime;
	//return bandwidthSum/bandwidthDataPoints;
}

-(void) scaleImg: (CGFloat) factor
{		
	
	//NSLog(@"Scaling by %f", factor);
	CGFloat newFactor = factor;

	curLevel = -((double)newFactor)+baseScale;
}
	
-(void) endScale
{
	//NSLog(@"Setting basescale");

	baseScale = curLevel;
	[self sendSyncUpdate];

}

-(void) turnGridOnOff
{
	//NSLog(@"Setting basescale");
	
	showGrid=!showGrid;
}





- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer
{	
	[GLLock acquireGLLock];
    // Allocate color buffer backing based on the current layer size
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
    [context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:layer];
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
	
    if (glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES)
    {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
		[GLLock releaseGLLock];
        return NO;
    }
	[GLLock releaseGLLock];
    return YES;
}


void gluLookAt(ESMatrix *mat, GLfloat eyex, GLfloat eyey, GLfloat eyez,
			   GLfloat centerx, GLfloat centery, GLfloat centerz,
			   GLfloat upx, GLfloat upy, GLfloat upz)
{
    GLfloat m[16];
    GLfloat x[3], y[3], z[3];
    GLfloat mag;
    
    /* Make rotation matrix */
    
    /* Z vector */
    z[0] = eyex - centerx;
    z[1] = eyey - centery;
    z[2] = eyez - centerz;
    mag = sqrt(z[0] * z[0] + z[1] * z[1] + z[2] * z[2]);
    if (mag) {          /* mpichler, 19950515 */
        z[0] /= mag;
        z[1] /= mag;
        z[2] /= mag;
    }
    
    /* Y vector */
    y[0] = upx;
    y[1] = upy;
    y[2] = upz;
    
    /* X vector = Y cross Z */
    x[0] = y[1] * z[2] - y[2] * z[1];
    x[1] = -y[0] * z[2] + y[2] * z[0];
    x[2] = y[0] * z[1] - y[1] * z[0];
    
    /* Recompute Y = Z cross X */
    y[0] = z[1] * x[2] - z[2] * x[1];
    y[1] = -z[0] * x[2] + z[2] * x[0];
    y[2] = z[0] * x[1] - z[1] * x[0];
    
    /* mpichler, 19950515 */
    /* cross product gives area of parallelogram, which is < 1.0 for
     * non-perpendicular unit-length vectors; so normalize x, y here
     */
    
    mag = sqrt(x[0] * x[0] + x[1] * x[1] + x[2] * x[2]);
    if (mag) {
        x[0] /= mag;
        x[1] /= mag;
        x[2] /= mag;
    }
    
    mag = sqrt(y[0] * y[0] + y[1] * y[1] + y[2] * y[2]);
    if (mag) {
        y[0] /= mag;
        y[1] /= mag;
        y[2] /= mag;
    }
    
#define M(row,col)  m[col*4+row]
    M(0, 0) = x[0];
    M(0, 1) = x[1];
    M(0, 2) = x[2];
    M(0, 3) = 0.0;
    M(1, 0) = y[0];
    M(1, 1) = y[1];
    M(1, 2) = y[2];
    M(1, 3) = 0.0;
    M(2, 0) = z[0];
    M(2, 1) = z[1];
    M(2, 2) = z[2];
    M(2, 3) = 0.0;
    M(3, 0) = 0.0;
    M(3, 1) = 0.0;
    M(3, 2) = 0.0;
    M(3, 3) = 1.0;
#undef M
    //glMultMatrixf(m);
    
    /* Translate Eye to Origin */
    //glTranslatef(-eyex, -eyey, -eyez);
	esTranslate(mat, -eyex, -eyey, -eyez);

    
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;

    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source)
    {
        NSLog(@"Failed to load vertex shader");
        return FALSE;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0)
    {
        glDeleteShader(*shader);
        return FALSE;
    }
    
    return TRUE;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0)
        return FALSE;
    
    return TRUE;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0)
        return FALSE;
    
    return TRUE;
}

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    program = glCreateProgram();
    
    
    // Create and compile vertex shader.
    vertShaderPathname= [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
  
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname])
    {
        NSLog(@"Failed to compile vertex shader");
        return FALSE;
    }
    
    // Create and compile fragment shader.
	
	//CHANGE THIS IF USING ADVANCED COMPRESSION SHADING!! ("Shader" for normal, "ShaderCom" for advanced)
	//if(USING_ADV_COMP)
	//	fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"ShaderCom" ofType:@"fsh"];
	//else
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    

    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname])
    {
        NSLog(@"Failed to compile fragment shader");
        return FALSE;
    }
    
    // Attach vertex shader to program.
    glAttachShader(program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
	//glBindAttribLocation(program, ATTRIB_CHANNEL, "channel");
    glBindAttribLocation(program, ATTRIB_VERTEX, "position");
    glBindAttribLocation(program, ATTRIB_COLOR, "color");
	glBindAttribLocation(program, ATTRIB_TEX_CO, "textureCo");

    
    // Link program.
    if (![self linkProgram:program])
    {
        NSLog(@"Failed to link program: %d", program);
        
        if (vertShader)
        {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader)
        {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (program)
        {
            glDeleteProgram(program);
            program = 0;
        }
        
        return FALSE;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM_TRANSLATE] = glGetUniformLocation(program, "translate");
	uniforms[UNIFORM_S_TEX] = glGetUniformLocation(program, "s_texture");
	if(USING_ADV_COMP)
	{
		uniforms[UNIFORM_S_TEX2] = glGetUniformLocation(program, "s_texture2");
		uniforms[UNIFORM_IKLT0] = glGetUniformLocation(program, "iKLT0");
		uniforms[UNIFORM_IKLT4] = glGetUniformLocation(program, "iKLT4");
		uniforms[UNIFORM_IKLT8] = glGetUniformLocation(program, "iKLT8");
	}
	uniforms[UNIFORM_MATRIX] = glGetUniformLocation(program, "matrix");
	uniforms[UNIFORM_CHANNEL] = glGetUniformLocation(program, "channel");
	


    
    // Release vertex and fragment shaders.
    if (vertShader)
        glDeleteShader(vertShader);
    if (fragShader)
        glDeleteShader(fragShader);
    
    return TRUE;
}


-(CGFloat)convertBackX:(CGFloat) x
{
	return ((2/(imageWidth*ceil(adjWidth)))*x)-1.0;
}

-(CGFloat)convertBackY:(CGFloat) y
{
	return ((2/(imageHeight*floor(adjWidth)))*y)+(height/2.0);
}

- (BOOL)updateFromPoll:(float)posX andPosY:(float)posY andZoom:(float)zoom andSlice:(int)slice andFocal:(int)focal
{
	if(!SYNC_ON)
		return;
	
	bool isChanged=FALSE;
	focal+=1;
	if(curSlice!=focal)
	{
		NSLog(@"Cur slice=%d, slice update=%d", curSlice, focal);
		[self switchSliceTo: focal];
	}
	if(ctrPos[0]!=posX)
		isChanged=TRUE;
	ctrPos[0]=[self convertBackX:posX];
	if(ctrPos[1]!=posY)
		isChanged=TRUE;
	ctrPos[1]=[self convertBackY:posY];
	if(curLevel!=zoom)
		isChanged=TRUE;
	curLevel=zoom-initialLevel;
	
	return isChanged;
}
-(void)sendSyncUpdate
{
	//NSLog(@"init level = %d", initialLevel);
	if(syncsSent>SYNC_SENT_THRESH)
		return;
	syncsSent++;
	CGFloat curX = ctrPos[0];
	curX += 1.0;
	curX*=(imageWidth*ceil(adjWidth))/2;

	
	CGFloat curY = ctrPos[1];
	curY -= height/2;
	curY*=(floor(adjWidth) * imageHeight)/2;
	//curY=curY*.5 -.5*((imageHeight*adjWidth)/(imageWidth*adjWidth));
	NSLog(@"adjWidth=%f adjWidth=%f", ceil(adjWidth), floor(adjWidth));
	//NSLog(@"Change x:%f->%f y:%f->%f (height=%f)", ctrPos[0], curX, ctrPos[1], curY, height);
	//NSLog(@"imageHeight=%f width=%f", adjWidth * imageHeight, imageWidth*adjWidth);

	
	NSString *post = [[NSString alloc] initWithFormat:@"positionX=%f&positionY=%f&slice=0&zoom=%f&id=%d&focal=%d", curX, curY, curLevel+initialLevel, myId, curSlice-1];
	NSURL *url = [[NSURL alloc] initWithString:@"http://neurotrace.seas.harvard.edu/testDataSet/POST"];

	download = [[URLCacheConnection alloc] initWithURL:url delegate:self andPost:post];
}

- (void) connectionDidFail:(URLCacheConnection *)theConnection
{
	syncsSent--;
	//NSLog(@"Failed to send sync update");
	[theConnection release];
	//[download release];
}
- (void) connectionDidFinish:(URLCacheConnection *)theConnection andLength:(NSTimeInterval) length
{	
	syncsSent--;

	//NSString *content = [[NSString alloc]  initWithBytes:[theConnection.receivedData bytes]
	//											  length:[theConnection.receivedData length] encoding: NSUTF8StringEncoding];
	//NSLog(@"Sent sync update, got back %@", content);

	[theConnection release];
	//[download release];
}




@end
