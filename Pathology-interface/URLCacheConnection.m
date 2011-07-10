/*
 the downloader class.  spawns a thread which uses the callbacks in this class as data is downloaded.
 */

#import "URLCacheConnection.h"

@implementation URLCacheConnection

@synthesize delegate;
@synthesize receivedData;
@synthesize lastModified;


/* This method initiates the load request. The connection is asynchronous, 
 and we implement a set of delegate methods that act as callbacks during 
 the load. */

- (id) initWithURL:(NSURL *)theURL delegate:(id<Tile>)theDelegate
{

	if (self = [super init]) {

		self.delegate = theDelegate;
		[theDelegate retain];

		/* Create the request. This application does not use a NSURLCache 
		 disk or memory cache, so our cache policy is to satisfy the request
		 by loading the data from its source. */
		
		NSURLRequest *theRequest = [NSURLRequest requestWithURL:theURL
													cachePolicy:NSURLRequestReloadIgnoringLocalCacheData 
												timeoutInterval:60];
		
		/* create the NSMutableData instance that will hold the received data */
		receivedData = [[NSMutableData alloc] initWithLength:0];

		/* Create the connection with the request and start loading the
		 data. The connection object is owned both by the creator and the
		 loading system. */
			
		NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:theRequest 
																	  delegate:self 
															  startImmediately:YES];
		if (connection == nil) {
			/* inform the user that the connection failed */
			NSString *message = NSLocalizedString (@"Unable to initiate request.", 
												   @"NSURLConnection initialization method failed.");
			NSLog(message);
		}
		timeStart = [NSDate timeIntervalSinceReferenceDate];
		[connection start];
		activeDownloads++;
		//[connection retain];
	}
//	NSLog(@"Download begun for %d %d id=%d", [theDelegate getX], [theDelegate getY], [theDelegate getID]);
	//NSLog([theURL absoluteString]);
	return self;
}


- (id) initWithURL:(NSURL *)theURL delegate:(id<Tile>)theDelegate andPost:(NSString *)postData
{
	
	if (self = [super init]) {
		
		self.delegate = theDelegate;
		[theDelegate retain];
		
		/* Create the request. This application does not use a NSURLCache 
		 disk or memory cache, so our cache policy is to satisfy the request
		 by loading the data from its source. */
		
		NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:theURL
													cachePolicy:NSURLRequestReloadIgnoringLocalCacheData 
												timeoutInterval:60];
		NSData *myRequestData = [NSData dataWithBytes: [postData UTF8String] length: [postData length]];
		[theRequest setHTTPMethod: @"POST"];
		[theRequest setHTTPBody: myRequestData];
		
		/* create the NSMutableData instance that will hold the received data */
		receivedData = [[NSMutableData alloc] initWithLength:0];
		
		/* Create the connection with the request and start loading the
		 data. The connection object is owned both by the creator and the
		 loading system. */
		
		NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:theRequest 
																	  delegate:self 
															  startImmediately:YES];
		if (connection == nil) {
			/* inform the user that the connection failed */
			NSString *message = NSLocalizedString (@"Unable to initiate request.", 
												   @"NSURLConnection initialization method failed.");
			NSLog(message);
		}
		timeStart = [NSDate timeIntervalSinceReferenceDate];
		[connection start];
		activeDownloads++;

		//[connection retain];
	}
	//	NSLog(@"Download begun for %d %d id=%d", [theDelegate getX], [theDelegate getY], [theDelegate getID]);
	//NSLog([theURL absoluteString]);
	return self;
}


- (void)dealloc
{
	[receivedData release];
	[lastModified release];
	[super dealloc];
}


#pragma mark NSURLConnection delegate methods

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    /* This method is called when the server has determined that it has
	 enough information to create the NSURLResponse. It can be called
	 multiple times, for example in the case of a redirect, so each time
	 we reset the data. */
//	NSLog(@"Got response for %d %d id=%d", [self.delegate getX], [self.delegate getY], [self.delegate getID]);

    [self.receivedData setLength:0];

	
	/* Try to retrieve last modified date from HTTP header. If found, format  
	 date so it matches format of cached image file modification date. */
	
	if ([response isKindOfClass:[NSHTTPURLResponse self]]) {
		NSDictionary *headers = [(NSHTTPURLResponse *)response allHeaderFields];
		NSString *modified = [headers objectForKey:@"Last-Modified"];
		if (modified) {
			NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
			[dateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss zzz"];
			self.lastModified = [dateFormatter dateFromString:modified];
			[dateFormatter release];
		}
		else {
			/* default if last modified date doesn't exist (not an error) */
			self.lastModified = [NSDate dateWithTimeIntervalSinceReferenceDate:0];
		}
	}
}


- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{

    /* Append the new data to the received data. */
	//NSLog(@"Got Data for %d %d id=%d", [self.delegate getX], [self.delegate getY], [self.delegate getID]);

    [self.receivedData appendData:data];
}


- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	NSLog(@"Connection error on url");
	if(error)
		NSLog([error localizedDescription]);
	activeDownloads--;
	[self.delegate connectionDidFail:self];
	[connection release];
}


- (NSCachedURLResponse *) connection:(NSURLConnection *)connection 
				   willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
//	NSLog(@"Some cahcing thing %d %d id=%d", [self.delegate getX], [self.delegate getY], [self.delegate getID]);

	/* this application does not use a NSURLCache disk or memory cache */
    return nil;
}


- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
	//NSLog(@"Finished loading for %d %d id=%d", [self.delegate getX], [self.delegate getY], [self.delegate getID]);
	
	NSTimeInterval length = [NSDate timeIntervalSinceReferenceDate]-timeStart;
	activeDownloads--;
	if(activeDownloads==0)
	{
		totalTime+=length;
	}
	if([self.delegate retainCount]>1)
		[self.delegate connectionDidFinish:self andLength:length];

	[connection release];
	[self.delegate release];
}

-(void)stopDownload
{
	//[connection cancel];
	self.delegate = NULL;
}

@end
