//
//  ESRenderer.h
//  GigaPixel
//
//  Created by Axel Hansen on 2/9/10.
//  Copyright Harvard University 2010. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>
#import "GigaPixel.h"


@protocol ESRenderer <NSObject>

- (void)render;
- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer;

@end
