//
//  PollMsg.m
//  GigaPixel
//
//  Created by Axel Hansen on 3/1/11.
//  Copyright 2011 Harvard University. All rights reserved.
//

#import "PollMsg.h"


@implementation PollMsg

struct MessageS
{
    int id;
    int type;
    char *message;
};
struct Messages
{
    struct MessageS** messages;
    int num;
};


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict 
{
	int i;
	
	
	//printf("%s", el);
	//NSLog(@"Got element %@", elementName);
	
	if([elementName isEqualToString:@"messages"])
	{
		int numMes;
		NSString *attr = [attributeDict valueForKey:@"num"];
		numMes = atoi([attr UTF8String]);
		((struct Messages*)data)->num = 0;
		((struct Messages*)data)->messages = (struct MessageS**)malloc(sizeof(struct MessageS*)*numMes);
	}
	else if([elementName isEqualToString:@"message"])
	{
		struct MessageS *msg = (struct MessageS*)malloc(sizeof(struct MessageS));
		msg->id=atoi([[attributeDict valueForKey:@"id"] UTF8String]);            
		msg->type=atoi([[attributeDict valueForKey:@"type"] UTF8String]);            
		char* str = [[attributeDict valueForKey:@"message"] UTF8String];
		int len = strlen(str);
		msg->message = (char*)malloc(len);
		strncpy(msg->message, str, len);
		
		int cur = ((struct Messages*)data)->num;
		((struct Messages*)data)->messages[cur]=msg;
		((struct Messages*)data)->num+=1;
	}
	
}


-(id)initWithRenderer:(ES1Renderer *)r
{
	renderer = r;
	data = (struct Messages*)malloc(sizeof(struct Messages));

	return self;
}

- (void) connectionDidFail:(URLCacheConnection *)theConnection
{
	NSLog(@"Failed to send sync update");
	[theConnection release];
	//[download release];
}

- (void) connectionDidFinish:(URLCacheConnection *)theConnection andLength:(NSTimeInterval) length
{	
	
	NSString *content = [[NSString alloc]  initWithBytes:[theConnection.receivedData bytes]
												  length:[theConnection.receivedData length] encoding: NSUTF8StringEncoding];

	[theConnection release];
	
	//NSLog(@"Got %@", content);
	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:[content dataUsingEncoding:NSASCIIStringEncoding]];

	[parser setDelegate:self];

	// Do the parse
	[parser parse];

	[parser release];
	
	//if(data->num>0)
	//	NSLog(@"Messages: (max=%d, num=%d)", maxId, data->num);
	BOOL gotMessage = FALSE;
	for(int i=0;i<data->num;i++)
	{
		gotMessage=TRUE;
		struct MessageS *msg = data->messages[i];
		
		//FORMAT: operator id(ignore), operatorType, sliceIndex, focalPlaneIndex, num_points, [x,y,z]*n, flag_for_closed, r,g,b,a, length_of_text, chars\0
		sscanf(msg->message, "%*d,%d", &msg->type);
		//NSLog(@"\tMessage: id=%d type=%d message=%s", msg->id, msg->type, msg->message);
		if (msg->type==3)
		{
			CGFloat xPos, yPos;
			//sscanf(msg->message, "%f,%f", &xPos, &yPos);
			sscanf(msg->message, "%*d,%*d,%*d,%*d,%*d,%f,%f,%*f,%*d,%*d,%*d,%*d,%*d,%*d,%*s", &xPos, &yPos);

			Message *msg = [[Message alloc] initWithType:0 andW:[renderer getImageWidth] andH:[renderer getImageHeight] andScreenHeight:[renderer getScreenHeight]];
			[msg setFirstPointX:xPos andY:yPos];
			[renderer addMessage:msg];
			
		}
		else if(msg->type==2)
		{
			CGFloat xPos1, yPos1, xPos2, yPos2;
			sscanf(msg->message, "%*d,%*d,%*d,%*d,%*d,%f,%f,%*f,%f,%f,%*f,%*d,%*d,%*d,%*d,%*d,%*d,%*s", &xPos1, &yPos1, &xPos2, &yPos2);

			Message *msg = [[Message alloc] initWithType:1 andW:[renderer getImageWidth] andH:[renderer getImageHeight] andScreenHeight:[renderer getScreenHeight]];
			[msg setEndPointX:xPos2 andY:yPos2];
			[msg setFirstPointX:xPos1 andY:yPos1];
			[renderer addMessage:msg];
			
		}
		else if(msg->type==1)
		{
			CGFloat xPos1, yPos1;
			char str[10000];
			char str2[10000];

			int len;
			sscanf(msg->message, "%*d,%*d,%*d,%*d,%*d,%f,%f,%*f,%*d,%*d,%*d,%*d,%*d,%d,%s", &xPos1, &yPos1, &len, str);
			strncpy(str2, str, len);
			Message *msg = [[Message alloc] initWithType:2 andW:[renderer getImageWidth] andH:[renderer getImageHeight] andScreenHeight:[renderer getScreenHeight]];
			[msg setFirstPointX:xPos1 andY:yPos1];
			[msg setText:[NSString stringWithCString:str]];
			[renderer addMessage:msg];
		}
		
		if(msg->id>maxId)
			maxId=msg->id;
	}
	
	if(gotMessage)
		[renderer render];


}


@end
