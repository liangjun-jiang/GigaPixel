//
//  Stack.h
//  GigaPixel
//
//  Created by Axel Hansen on 4/5/10.
//  Copyright 2010 Harvard University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <Foundation/Foundation.h>
#import "GigaPixel.h"

struct entryStruct {
	struct entryStruct *next;
	GLuint tex;
};
typedef struct entryStruct Entry;


@interface Stack : NSObject {
	Entry* head;
	int numCount;
}


-(GLuint) pop;
-(void) push:(GLuint)g;
-(int) count;
-(void)print;

@end
