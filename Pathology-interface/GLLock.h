//
//  GLLock.h
//  GigaPixel
//
//  Created by Axel Hansen on 3/23/10.
//  Copyright 2010 Harvard University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GLLock : NSObject {

}
+(void)acquireGLLock;
+(void)releaseGLLock;

@end
