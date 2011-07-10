//
//  GLLock.m
//  GigaPixel
//
//  Created by Axel Hansen on 3/23/10.
//  Copyright 2010 Harvard University. All rights reserved.
//

/*
 static method to get ref to es1renderer (for convenience) and access to the opengl lock
 */

#import "GLLock.h"
#import "ES1Renderer.h"
#import "EAGLView.h"


@implementation GLLock
static NSLock *glLock=nil;
static ES1Renderer *es1Renderer = nil;
static EAGLView *eaglView = nil;

+(void)setEAGLVIEW:(EAGLView *)e
{
	eaglView = e;
}

+(EAGLView*)getEAGLVIEW
{
	return eaglView;
}


+(void)setES1Renderer:(ES1Renderer *)e
{
	es1Renderer = e;
}

+(ES1Renderer*)getES1Renderer
{
	return es1Renderer;
}

+(void)acquireGLLock
{
	if(glLock == nil)
	{
		glLock = [[NSLock alloc] init];
	}
	[glLock lock];
	//NSLog(@"+++++Acquring GLLock");

}

+(void)releaseGLLock
{
	//NSLog(@"-----Releasing GLLock");

	[glLock unlock];
}

@end
