//
//  Message.h
//  GigaPixel
//
//  Created by Axel Hansen on 3/8/11.
//  Copyright 2011 Harvard University. All rights reserved.

//  A message is an operation by the user (arrow, measurment, text, etc)
//

#import <Foundation/Foundation.h>
#import "URLCacheConnection.h"
#import "Texture2D.h"
//message types:
enum {
	TEXT,
	ARROW,
	RULER
};



@interface Message : NSObject {
	CGFloat startX;
	CGFloat startY;
	
	CGFloat endX;
	CGFloat endY;
	
	CGFloat imageHeight;
	CGFloat imageWidth;
	CGFloat screenHeight;
	
	int messageType;
	int messageId;
	int addedBy;
	int session;
	
	int slice;
	int numberImages;
	
	NSString *textMessage;
	Texture2D* statusTexture;
}

-(CGFloat)getX;
-(CGFloat)getY;
-(void)setFirstPointX:(CGFloat)x andY:(CGFloat)y;
-(void)setEndPointX:(CGFloat)x andY:(CGFloat)y;
-(void)postMessage:(int)myId andSessId:(int)sessId;
-(NSString *)getText;
-(CGFloat)getEndX;
-(CGFloat)getEndY;
-(void)setText:(NSString *)txt;
-(Texture2D*)getTexture2d;
-(id)initWithType:(int)type andW:(CGFloat)width andH:(CGFloat)height andScreenHeight:(CGFloat)sH;
-(CGFloat)convertBackX:(CGFloat) x;
-(CGFloat)convertBackY:(CGFloat) y;



@end
