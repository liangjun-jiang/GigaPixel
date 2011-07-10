//
//  ES1Renderer.h
//  GigaPixel
//
//  Created by Axel Hansen on 2/9/10.
//  Copyright Harvard University 2010. All rights reserved.
//

#import "ESRenderer.h"

//#import "URLCacheConnection.h"

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <Foundation/Foundation.h>

#import "TileManager.h"
#import "PrefetchManager.h"
#import "GigaPixel.h"
#import "GLLock.h"
#import "Message.h"
#import "Texture2D.h"

#include "esUtil.h"  //some matrix functions from opengles book

@interface ES1Renderer : NSObject <ESRenderer>
{
@private
	int numberImages;
	int myId;
	int syncsSent;
    EAGLContext *context;
    EAGLContext *contextB;
	
	GLuint program;

	
	NSString *gigaImage;


    // The pixel dimensions of the CAEAGLLayer
    GLint backingWidth;
    GLint backingHeight;

    // The OpenGL ES names for the framebuffer and renderbuffer used to render to this view
    GLuint defaultFramebuffer, colorRenderbuffer;
	
	GLuint texture[1];//AH, TEMP, since only one tile, stores the single texture
	CGRect glViewSize; //AH, give us size of glviewport
	
	//AH, sum of deltas for translation
	CGFloat sumDeltaX;
	CGFloat sumDeltaY;
	//two scale factors to let subsequent zoom levels begin from the previous zoom level
	CGFloat baseScale;
	
	double viewFrustum[4]; 
	float curLevel;
	float ctrPos[2];
	CGRect windowBounds;
	
	BOOL showGrid;
	
	CGFloat imageWidth;
	CGFloat imageHeight;
	
	
	URLCacheConnection *download;

	TileManager *tm;
	
	int finishedInit;
	
	semaphore_t *signalSem;
	PrefetchManager *pm;

	GLuint loadingTexture[1];
	
	NSMutableArray *messages;
	

	NSString *CONFIG_SOURCE_URL_STRING;
	
	int curSlice;
	//int cu
	float width;
	float height; 
	float startY;
	
	BOOL isRendering;
	
	int bandwidthDataPoints;
	float bandwidthSum;
	
	float loadingTime;
	int tilesLoaded;
	
	float renderTime;
	int tilesRendered;

	
	//int maxId;
	
	CGFloat pointX;
	CGFloat pointY;
	
	int initialLevel;
	//int overlap;
	float adjWidth;

}


//FIXME == get rid of these
#define DEGREES_TO_RADIANS(__ANGLE__) ((__ANGLE__) / 180.0 * M_PI)
typedef struct {
	GLfloat	red;
	GLfloat	green;
	GLfloat	blue;
	GLfloat alpha;
} Color3D;
typedef struct {
	GLfloat	x;
	GLfloat y;
	GLfloat z;
} Vertex3D;
typedef Vertex3D Vector3D;
typedef struct {
	Vertex3D v1;
	Vertex3D v2;
	Vertex3D v3;
} Triangle3D;

-(CGFloat)getImageWidth;
-(CGFloat)getImageHeight;
-(CGFloat)getScreenHeight;

-(NSMutableArray*)getMessages;
-(NSString*)getImage;
- (void)render;
- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer;
-(void) translateImg: (CGFloat) dx andDy: (CGFloat) dy;
-(void) scaleImg: (CGFloat) factor;
- (void) endScale;
- (void) updateCurrentViewFrustum;
-(void) turnGridOnOff;
- (void) createTileManager;
-(EAGLContext*)getContextA;
-(EAGLContext*)getContextB;
-(CGRect)getWinBounds;
-(void)switchSliceTo:(int)newS;
-(void)testIdle;
- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;
-(float)getRate;
-(void)bandwidthUpdate:(float)rate andTime:(float)i;
-(void)sendSyncUpdate;
- (void) connectionDidFail:(URLCacheConnection *)theConnection;
- (void) connectionDidFinish:(URLCacheConnection *)theConnection andLength:(NSTimeInterval) length;
-(float)getTime;
-(void)tileLoadTime:(float)i;

- (BOOL)updateFromPoll:(float)posX andPosY:(float)posY andZoom:(float)zoom andSlice:(int)slice andFocal:(int)focal;

-(void)setPointWithX:(CGFloat)x andY:(CGFloat)y;

-(void)addMessage:(Message *)msg;

-(CGFloat)convertX:(CGFloat)x;
-(CGFloat)convertY:(CGFloat)y;
-(CGFloat)convertX:(CGFloat)x withIW:(int)iw;
-(CGFloat)convertY:(CGFloat)y withIH:(int)ih;

int loadPyramidFile(struct FileInfo ** fis, NSString *img, int curSlice, ES1Renderer *rend);

void gluLookAt(ESMatrix *mat, GLfloat eyex, GLfloat eyey, GLfloat eyez,
			   GLfloat centerx, GLfloat centery, GLfloat centerz,
			   GLfloat upx, GLfloat upy, GLfloat upz);

extern int TILE_SIZE;

enum {
    ATTRIB_VERTEX,
    ATTRIB_COLOR,
	ATTRIB_TEX_CO,
	//ATTRIB_CHANNEL,
    NUM_ATTRIBUTES
};
enum {
    UNIFORM_TRANSLATE,
	UNIFORM_S_TEX,
	UNIFORM_S_TEX2,
	UNIFORM_MATRIX,
	UNIFORM_CHANNEL,
	UNIFORM_IKLT0,
	UNIFORM_IKLT4,
	UNIFORM_IKLT8,
    NUM_UNIFORMS
};

GLint uniforms[NUM_UNIFORMS];




@end
