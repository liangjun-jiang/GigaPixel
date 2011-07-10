//
//  SessionList.m
//  GigaPixel
//
//  Created by Axel Hansen on 3/23/11.
//  Copyright 2011 Harvard University. All rights reserved.
//

#import "SessionList.h"
#import "EAGLView.h"


@implementation SessionList

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


-(id)initWithRenderer:(EAGLView*)r andType:(int)t
{
	self = [super initWithStyle:UITableViewStylePlain];
	glview = r;
	sessions = [[NSMutableDictionary alloc] init];
	sessionArray = [[NSMutableArray alloc] init];
	//[sessions setObject:[[NSNumber alloc] initWithInt:154] forKey:[[NSNumber alloc] initWithInt:0]];
	//[sessions setObject:[[NSNumber alloc] initWithInt:155] forKey:[[NSNumber alloc] initWithInt:1]];
	data = (struct Messages*)malloc(sizeof(struct Messages));
	type=t;
	return self;

}

-(void)setPopup:(UIPopoverController*)p
{
	popup = p;
}

// Add viewDidLoad like the following:
- (void)viewDidLoad {
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = YES;
    //self.contentSizeForViewInPopover = CGSizeMake(150.0, 140.0);
    //[sessions addObject:@"one"];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

// in numberOfRowsInSection:
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [sessionArray count];
}

// In cellForRowAtIndexPath, under configure the cell:
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
	
	NSString *session = [[sessionArray objectAtIndex:indexPath.row] stringValue];//[[sessions objectForKey:[[NSNumber alloc] initWithInt:indexPath.row]] stringValue];//[sessions objectAtIndex:indexPath.row];
	cell.textLabel.text = session;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	//NSLog(@"Got %d for %d", [[sessionArray objectAtIndex:indexPath.row] intValue], indexPath.row);
	//[glview setFollow:[[sessions objectForKey:[[NSNumber alloc] initWithInt:indexPath.row]] intValue]];
	if(type==0)
		[glview setFollow:[[sessionArray objectAtIndex:indexPath.row] intValue]];
	else if(type==1)
		[glview setTrack:[[sessionArray objectAtIndex:indexPath.row] intValue]];
	[popup dismissPopoverAnimated:YES];
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
		
		BOOL found=FALSE;
		for(int i=0;i<[sessionArray count];i++)
		{
			if(type==0)
			{
				if([[sessionArray objectAtIndex:i] intValue]==msg->id)
					found=TRUE;
			}
			else if(type==1)
			{
				if([[sessionArray objectAtIndex:i] intValue]==atoi(msg->message))
					found=TRUE;
			}
			
		}
		if(!found)
		{		
			if(type==0)
				[sessionArray addObject:[[NSNumber alloc] initWithInt:msg->id]];
			else if(type==1)
				[sessionArray addObject:[[NSNumber alloc] initWithInt:atoi(msg->message)]];

		}
	}	
}


// In dealloc
//self.colors = nil;
//self.delegate = nil;


@end
