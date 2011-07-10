//
//  Message.m
//  GigaPixel
//
//  Created by Axel Hansen on 3/8/11.
//  Copyright 2011 Harvard University. All rights reserved.
//

#import "Message.h"


@implementation Message

-(id)initWithType:(int)type andW:(CGFloat)width andH:(CGFloat)height andScreenHeight:(CGFloat)sH
{
	imageWidth = width;
	imageHeight = height;
	screenHeight = sH;
	numberImages = 1;

	messageType = type;
	messageId=-1; //-1 means message still local...
	
	slice=0;
	
	return self;
}

-(void)setFirstPointX:(CGFloat)x andY:(CGFloat)y
{
	startX = x;
	startY = y;
}

-(void)setEndPointX:(CGFloat)x andY:(CGFloat)y
{
	endX = x;
	endY = y;
}

-(int)getType
{
	return messageType;
}

-(int)getMessageId
{
	return messageId;
}

-(CGFloat)convertBackX:(CGFloat) x
{
	//NSLog(@"imgWidth=%f", imageWidth);
	return ((2/(imageWidth*numberImages))*x)-1.0;
}

-(CGFloat)convertBackY:(CGFloat) y
{
	//NSLog(@"screen height=%f imgH=%f", screenHeight, imageHeight);
	return ((2/(imageHeight*numberImages))*y)+(screenHeight/2.0);
}


-(CGFloat)getX
{
	return [self convertBackX:startX];
}

-(CGFloat)getY
{
	return [self convertBackY:startY];
}

-(CGFloat)getEndX
{
	return [self convertBackX:endX];
}

-(CGFloat)getEndY
{
	return [self convertBackY:endY];
}

-(void)setText:(NSString*)txt
{
	textMessage = txt;
	statusTexture = [[Texture2D alloc] initWithString:textMessage dimensions:CGSizeMake(60, 40) alignment:UITextAlignmentLeft fontName:@"Helvetica" fontSize:10];

}

-(NSString*)getText
{
	return textMessage;
}

-(Texture2D*)getTexture2d
{
	return statusTexture;
}

//sends the message to the server
-(void)postMessage:(int)myId andSessId:(int)sessId
{
	NSString *msg=@"0";
	//NSLog
	if(messageType==0)
		msg = [[NSString alloc] initWithFormat:@"0,3,%d,0,1,%f,%f,0,0,128,255,0,255,0,", slice, startX, startY];
		//msg = [[NSString alloc] initWithFormat:@"%f,%f", startX, startY];
	else if(messageType==1)
		msg = [[NSString alloc] initWithFormat:@"0,2,%d,0,2,%f,%f,0,%f,%f,0,0,128,255,0,255,0,", slice, startX, startY, endX, endY];
		//msg = [[NSString alloc] initWithFormat:@"%f,%f,%f,%f", startX, startY, endX, endY];
	else if(messageType==2)
		msg = [[NSString alloc] initWithFormat:@"0,1,%d,0,1,%f,%f,0,0,128,255,0,255,%d,%@", slice, startX, startY, [textMessage length]+1, textMessage];
		//msg = [[NSString alloc] initWithFormat:@"%f,%f,%@", startX, startY, textMessage];

	NSString *post = [[NSString alloc] initWithFormat:@"sessionid=%d&id=%d&message=%@&type=%d", sessId, myId, msg, 5];
	NSURL *url = [[NSURL alloc] initWithString:@"http://neurotrace.seas.harvard.edu/testDataSet/POSTMSG"];
	
	[[URLCacheConnection alloc] initWithURL:url delegate:self andPost:post];
}

- (void) connectionDidFail:(URLCacheConnection *)theConnection
{
	//NSLog(@"Failed to send sync update");
	[theConnection release];
	//[download release];
}
- (void) connectionDidFinish:(URLCacheConnection *)theConnection andLength:(NSTimeInterval) length
{	
	
	NSString *content = [[NSString alloc]  initWithBytes:[theConnection.receivedData bytes]
												  length:[theConnection.receivedData length] encoding: NSUTF8StringEncoding];
	messageId = atoi([content UTF8String]);
	NSLog(@"Set message id to %d", messageId);
	
	[theConnection release];
	//[download release];
}



@end
