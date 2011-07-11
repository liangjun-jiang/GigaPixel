//
//  EAGLView.m
//  GigaPixel
//
//  Created by Axel Hansen on 2/9/10.
//  Copyright Harvard University 2010. All rights reserved.

/*
	This is the basic uiview subclass that handles native cocoa gui stuff (like multitouch)
	It is created by the table view when a dataset is picked
 */
//

#import "EAGLView.h"

#import "ES1Renderer.h"
#import "PrefetchManager.h"
#import "Tile.h"
#import "PollMsg.h"

@implementation EAGLView

@synthesize animating;
@dynamic animationFrameInterval;

//int deceleration = 2;
double deceleration = .8;

float throwThresh = 0;
float tapThresh = 5;
float endThresh = .05;

int TIMER_SECONDS = 1;
int TIMER_SLOW_SECONDS = 10;

int POLL_LIMIT = 3;

extern int maxId;


// You must implement this method
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}



//The EAGL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
//- (id)initWithCoder:(NSCoder*)coder
-(id)initWithFrame:(CGRect)frame andImg:(NSString *)img andUrl:(NSString *)url andNumSlices:(int)nS
{    
	followId = -1;
	trackId = -1;
	curSlice = 1;
	SLICE_COUNT = nS;
	myHdrId = atoi([url UTF8String]);
	
	SLICE_COUNT = 15;  //TODO: DON'T HARDCODE THIS SHIT
	
	//NSLog(@"Slice max:%d", SLICE_COUNT);
	
	NSString *idStr = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"http://neurotrace.seas.harvard.edu/testDataSet/GETID"]];
	
	myId = atoi([idStr UTF8String]);
		
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString * dataPath = [paths objectAtIndex:0];
	NSString *dirPath =  [dataPath stringByAppendingPathComponent:img];
	if([[NSFileManager defaultManager] fileExistsAtPath:dirPath] == NO)
		[[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];
	
	
	//if ((self = [super initWithCoder:coder]))
	if ((self = [super initWithFrame:frame]))
    {
        // Get the layer
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;

        eaglLayer.opaque = TRUE;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
	

		setBaseURLForAllTiles(url);
		NSLog(@"URL for tiles: %@", url);
		
		//set up prefetch manager thread
	/*	NSPort *port1;
		NSPort *port2;
		NSArray *portArray;
        port1 = [NSPort port];
        port2 = [NSPort port];
        connectionToTransferServer = [[NSConnection alloc] initWithReceivePort:port1 sendPort:port2];
		[connectionToTransferServer setRootObject:self];
        portArray = [NSArray arrayWithObjects:port2, port1, nil];*/
		
		signalSem = (semaphore_t*)malloc(sizeof(semaphore_t));
		//if(sem_init(signalSem, 0, 0)==-1)
		if(semaphore_create(mach_task_self(), signalSem, SYNC_POLICY_FIFO, 0))
		{
			NSLog(@"Semaphore init failed with %d", errno);
			if(errno==EINVAL)
				NSLog(@"Einval");
			else if(errno==ENOSYS)
				NSLog(@"Enosys");
		}
		
		pm = [[PrefetchManager alloc] initWithLock:signalSem];
		//NSLog(@"pm test before thread start");

		//[pm test];
		
		//create our render object
		renderer = [[ES1Renderer alloc] initWithBounds:self.bounds andSemaphore:signalSem andPrefetchManager:pm andImg:img andSlice:curSlice andId:myId];
		
		if (!renderer)
		{
			[self release];
			return nil;
		}
		

        animating = FALSE;
        displayLinkSupported = TRUE;
		shouldStopAnimate = FALSE;
        animationFrameInterval = 2;
        displayLink = nil;
        animationTimer = nil;

        // A system version of 3.1 or greater is required to use CADisplayLink. The NSTimer
        // class is used as fallback when it isn't available.
        NSString *reqSysVer = @"3.1";
        NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
        if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending)
            displayLinkSupported = TRUE;
		initialDistance = -1;
		touchCount = 0;
		vX = 0.0;
		vY = 0.0;
		
		
		
		
    }
	
	toolbar = [[UIToolbar alloc] init];
	toolbar.barStyle = UIBarStyleBlackTranslucent;
	[toolbar sizeToFit];
	//Caclulate the height of the toolbar
	CGFloat toolbarHeight = [toolbar frame].size.height;
	//Get the bounds of the parent view
	CGRect rootViewBounds = self.bounds;
	//Get the height of the parent view.
	CGFloat rootViewHeight = CGRectGetHeight(rootViewBounds);
	//Get the width of the parent view,
	CGFloat rootViewWidth = CGRectGetWidth(rootViewBounds);
	//Create a rectangle for the toolbar
	CGRect rectArea = CGRectMake(0, rootViewHeight - toolbarHeight, rootViewWidth, toolbarHeight);
	//Reposition and resize the receiver
	[toolbar setFrame:rectArea];
	
	downButton = [[UIBarButtonItem alloc] initWithTitle:@"Down" style:UIBarButtonItemStyleBordered target:self action:@selector(downClicked)];
	upButton = [[UIBarButtonItem alloc] initWithTitle:@"Up" style:UIBarButtonItemStyleBordered target:self action:@selector(upClicked)];
	//UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithTitle:@"Spacer" style:UIBarButtonItemStyleBordered target:self action:@selector(gridClicked)];
	//spacer.width = 10;
	//spacer.hidden = TRUE;
	gridButton = [[UIBarButtonItem alloc] initWithTitle:@"Grid" style:UIBarButtonItemStyleBordered target:self action:@selector(gridClicked)];

	UIBarButtonItem *markButton = [[UIBarButtonItem alloc] initWithTitle:@"Mark" style:UIBarButtonItemStyleBordered target:self action:@selector(markClicked)];

	UIBarButtonItem *rulerButton = [[UIBarButtonItem alloc] initWithTitle:@"Ruler" style:UIBarButtonItemStyleBordered target:self action:@selector(rulerClicked)];

	UIBarButtonItem *textButton = [[UIBarButtonItem alloc] initWithTitle:@"Text" style:UIBarButtonItemStyleBordered target:self action:@selector(textClicked)];

	UIBarButtonItem *makeSession = [[UIBarButtonItem alloc] initWithTitle:@"Make Session" style:UIBarButtonItemStyleBordered target:self action:@selector(makeSession)];

	UIBarButtonItem *quitButton = [[UIBarButtonItem alloc] initWithTitle:@"Quit" style:UIBarButtonItemStyleBordered target:self action:@selector(quitApp)];

	//UIBarButtonItem *followSession = [[UIBarButtonItem alloc] initWithTitle:@"Follow Session" style:UIBarButtonItemStyleBordered target:self action:@selector(followSession)];
	//UIBarButtonItem *trackId = [[UIBarButtonItem alloc] initWithTitle:@"Track" style:UIBarButtonItemStyleBordered target:self action:@selector(trackId)];
	
	//UIBarButtonItem *followButton = [[UIBarButtonItem alloc] initWithTitle:@"Ruler" style:UIBarButtonItemStyleBordered target:self action:@selector(rulerClicked)];

	showSessionsButton = [[UIBarButtonItem alloc] initWithTitle:@"Follow Session" style:UIBarButtonItemStyleBordered target:self action:@selector(showSessions)];
	showTracksButton = [[UIBarButtonItem alloc] initWithTitle:@"Track User" style:UIBarButtonItemStyleBordered target:self action:@selector(showTracks)];

	
	[toolbar setItems:[NSArray arrayWithObjects:downButton, upButton, gridButton, makeSession, showSessionsButton, showTracksButton, markButton, rulerButton, textButton, quitButton, nil]];
	[self addSubview:toolbar];
	toolbar.hidden = TRUE;
	toolbar.alpha = 0;
	//[[UIApplication sharedApplication] setStatusBarHidden:TRUE animated:NO];
	hasOldPoint = FALSE;
	
	sliceLabel = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_WIDTH-22, SCREEN_HEIGHT-20, 20, 15)];
	sliceLabel.backgroundColor = [UIColor blackColor];
	sliceLabel.textColor = [UIColor whiteColor];
	sliceLabel.text = [NSString stringWithFormat:@"%d", 1];
	//[self addSubview:sliceLabel];
	
	bandwidthLabel = [[UILabel alloc] initWithFrame:CGRectMake(3, SCREEN_HEIGHT-30, 150, 15)];
	bandwidthLabel.backgroundColor = [UIColor clearColor];
	bandwidthLabel.textColor = [UIColor whiteColor];
	bandwidthLabel.text = [NSString stringWithFormat:@"%d", 0];
	//[self addSubview:bandwidthLabel];
	
	timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(300, SCREEN_HEIGHT-30, 150, 15)];
	timeLabel.backgroundColor = [UIColor clearColor];
	timeLabel.textColor = [UIColor whiteColor];
	timeLabel.text = [NSString stringWithFormat:@"%d", 0];
	[self addSubview:timeLabel];
	
	
	UILabel *idLabel = [[UILabel alloc] initWithFrame:CGRectMake(3, 3, 150, 15)];
	idLabel.backgroundColor = [UIColor clearColor];
	idLabel.textColor = [UIColor whiteColor];
	idLabel.text = [NSString stringWithFormat:@"ID: %d", myId];
	[self addSubview:idLabel];
	
	sessIdLabel = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_WIDTH-100, 3, 150, 15)];
	sessIdLabel.backgroundColor = [UIColor clearColor];
	sessIdLabel.textColor = [UIColor whiteColor];
	sessIdLabel.text = [NSString stringWithFormat:@"SESS: none"];
	
	sessions = [[SessionList alloc] 
				initWithRenderer:self andType:0];
	tracks = [[SessionList alloc] 
			  initWithRenderer:self andType:1];


	
	polls = 0;
	pollTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)(TIMER_SECONDS) target:self selector:@selector(pollRequest:) userInfo:nil repeats:TRUE];
	[NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)(TIMER_SECONDS) target:self selector:@selector(pollMsgRequest:) userInfo:nil repeats:TRUE];
	
	[self listRequest:self];//get the sessions
	[self usersRequest:self];
	[NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)(TIMER_SLOW_SECONDS) target:self selector:@selector(listRequest:) userInfo:nil repeats:TRUE];
	[NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)(TIMER_SLOW_SECONDS) target:self selector:@selector(usersRequest:) userInfo:nil repeats:TRUE];

	[GLLock setEAGLVIEW:self];

	return self;
}

-(void)showTracks
{
    if (popTrack == nil) {
		popTrack = [[UIPopoverController alloc] 
			   initWithContentViewController:tracks];               
    }
	[tracks setPopup:popTrack];
	//[pop presentPopoverFromBarButtonItem:<#(UIBarButtonItem *)item#> permittedArrowDirections:<#(UIPopoverArrowDirection)arrowDirections#> animated:<#(BOOL)animated#>
    [popTrack presentPopoverFromBarButtonItem:showTracksButton 
				permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}


-(void)showSessions
{
    if (pop == nil) {
         pop = [[UIPopoverController alloc] 
									initWithContentViewController:sessions];               
    }
	[sessions setPopup:pop];
	//[pop presentPopoverFromBarButtonItem:<#(UIBarButtonItem *)item#> permittedArrowDirections:<#(UIPopoverArrowDirection)arrowDirections#> animated:<#(BOOL)animated#>
    [pop presentPopoverFromBarButtonItem:showSessionsButton 
									permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}


-(void)gridClicked
{
	[renderer turnGridOnOff];
	[renderer render];
}

-(void)textClicked
{
	if(toolOn && toolId!=2)
		toolId=2;
	else if(toolOn && toolId==2)
		toolOn=FALSE;
	else {
		toolId=2;
		toolOn=TRUE;
	}
	
	currentAlert=0;
	UIAlertView *myAlertView = [[UIAlertView alloc] initWithTitle:@"Enter text" message:@"this gets covered" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
	myTextField = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 45.0, 260.0, 25.0)];
	[myTextField setKeyboardType:UIKeyboardTypeURL];
	
	[myTextField setBackgroundColor:[UIColor whiteColor]];
	[myAlertView addSubview:myTextField];
	[myTextField becomeFirstResponder];
	[myAlertView show];
	
	
	//now hide the menu
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:.5];
	[UIView setAnimationCurve: UIViewAnimationCurveEaseInOut];
	//[UIView setAnimationRepeatCount:5];
	//toolbar.hidden = ! toolbar.hidden;
	if(toolbar.hidden)
		toolbar.alpha = 1;
	else 
		toolbar.alpha = 0;
	[toolbar setHidden:!toolbar.hidden];
	[[UIApplication sharedApplication] setStatusBarHidden:![UIApplication sharedApplication].statusBarHidden animated:YES];
	[UIView commitAnimations];
	
}

-(void)quitApp
{
	exit(1);
    
}

-(void)followSession
{
	currentAlert=1;
	UIAlertView *myAlertView = [[UIAlertView alloc] initWithTitle:@"Enter session id" message:@"this gets covered" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
	myTextField = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 45.0, 260.0, 25.0)];
	[myTextField setKeyboardType:UIKeyboardTypeURL];
	
	[myTextField setBackgroundColor:[UIColor whiteColor]];
	[myAlertView addSubview:myTextField];
	[myTextField becomeFirstResponder];
	[myAlertView show];
	
	//now hide the menu
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:.5];
	[UIView setAnimationCurve: UIViewAnimationCurveEaseInOut];
	//[UIView setAnimationRepeatCount:5];
	//toolbar.hidden = ! toolbar.hidden;
	if(toolbar.hidden)
		toolbar.alpha = 1;
	else 
		toolbar.alpha = 0;
	[toolbar setHidden:!toolbar.hidden];
	[[UIApplication sharedApplication] setStatusBarHidden:![UIApplication sharedApplication].statusBarHidden animated:YES];
	[UIView commitAnimations];
	
}

-(void)trackId
{
	currentAlert=2;
	UIAlertView *myAlertView = [[UIAlertView alloc] initWithTitle:@"Enter user id" message:@"this gets covered" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
	myTextField = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 45.0, 260.0, 25.0)];
	[myTextField setKeyboardType:UIKeyboardTypeURL];
	
	[myTextField setBackgroundColor:[UIColor whiteColor]];
	[myAlertView addSubview:myTextField];
	[myTextField becomeFirstResponder];
	[myAlertView show];
	
	//now hide the menu
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:.5];
	[UIView setAnimationCurve: UIViewAnimationCurveEaseInOut];
	//[UIView setAnimationRepeatCount:5];
	//toolbar.hidden = ! toolbar.hidden;
	if(toolbar.hidden)
		toolbar.alpha = 1;
	else 
		toolbar.alpha = 0;
	[toolbar setHidden:!toolbar.hidden];
	[[UIApplication sharedApplication] setStatusBarHidden:![UIApplication sharedApplication].statusBarHidden animated:YES];
	[UIView commitAnimations];
	
}



-(void)makeSession
{
	NSString *idStr = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"http://neurotrace.seas.harvard.edu/testDataSet/GETSESSIONID"]];
	followId = atoi([idStr UTF8String]);
	NSString*makeUrl = [NSString stringWithFormat:@"http://neurotrace.seas.harvard.edu/%d=%d/POSTSESSIONFILE", myHdrId, followId];
	NSLog(makeUrl);
	[NSString stringWithContentsOfURL:[NSURL URLWithString:makeUrl]];
	
	sessIdLabel.text = [NSString stringWithFormat:@"SESS: %d", followId];
	[self addSubview:sessIdLabel];
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:.5];
	[UIView setAnimationCurve: UIViewAnimationCurveEaseInOut];
	//[UIView setAnimationRepeatCount:5];
	//toolbar.hidden = ! toolbar.hidden;
	if(toolbar.hidden)
		toolbar.alpha = 1;
	else 
		toolbar.alpha = 0;
	[toolbar setHidden:!toolbar.hidden];
	[[UIApplication sharedApplication] setStatusBarHidden:![UIApplication sharedApplication].statusBarHidden animated:YES];
	[UIView commitAnimations];
	
}

-(void)markClicked
{
	if(toolOn && toolId!=0)
		toolId=0;
	else if(toolOn && toolId==0)
		toolOn=FALSE;
	else {
		toolId=0;
		toolOn=TRUE;
	}
	//now hide the menu
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:.5];
	[UIView setAnimationCurve: UIViewAnimationCurveEaseInOut];
	//[UIView setAnimationRepeatCount:5];
	//toolbar.hidden = ! toolbar.hidden;
	if(toolbar.hidden)
		toolbar.alpha = 1;
	else 
		toolbar.alpha = 0;
	[toolbar setHidden:!toolbar.hidden];
	[[UIApplication sharedApplication] setStatusBarHidden:![UIApplication sharedApplication].statusBarHidden animated:YES];
	[UIView commitAnimations];
		
}

-(void)rulerClicked
{
	if(toolOn && toolId!=1)
		toolId=1;
	else if(toolOn && toolId==1)
		toolOn=FALSE;
	else {
		toolId=1;
		toolOn=TRUE;
	}
	//now hide the menu
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:.5];
	[UIView setAnimationCurve: UIViewAnimationCurveEaseInOut];
	//[UIView setAnimationRepeatCount:5];
	//toolbar.hidden = ! toolbar.hidden;
	if(toolbar.hidden)
		toolbar.alpha = 1;
	else 
		toolbar.alpha = 0;
	[toolbar setHidden:!toolbar.hidden];
	[[UIApplication sharedApplication] setStatusBarHidden:![UIApplication sharedApplication].statusBarHidden animated:YES];
	[UIView commitAnimations];
	
}


-(void)upClicked
{
	if(curSlice>=SLICE_COUNT)
		return;
	curSlice++;
	sliceLabel.text = [NSString stringWithFormat:@"%d", curSlice];
	[renderer switchSliceTo:curSlice];
}

-(void)downClicked
{
	if(curSlice<=1)
		return;
	curSlice--;
	sliceLabel.text = [NSString stringWithFormat:@"%d", curSlice];
	[renderer switchSliceTo:curSlice];
}

- (void)finishInit
{
	//[renderer createTileManager];
}

-(void)listRequest:(id)sender
{
	NSURL *url = [[NSURL alloc] initWithString:@"http://neurotrace.seas.harvard.edu/testDataSet/GETSESSIONLIST"];
	
	//NSLog(@"Sending poll msg request");
	[[URLCacheConnection alloc] initWithURL:url delegate:sessions];	
}

-(void)usersRequest:(id)sender
{
	NSURL *url = [[NSURL alloc] initWithString:@"http://neurotrace.seas.harvard.edu/testDataSet/GETUSERS"];
	
	//NSLog(@"Sending poll msg request");
	[[URLCacheConnection alloc] initWithURL:url delegate:tracks];	
}


-(void)pollMsgRequest:(id)sender
{
	//if(polls>POLL_LIMIT)
	//{
	//	return;
	//}
	//polls++;
	if(followId==-1)
		return;

	NSString *post = [[NSString alloc] initWithFormat:@"id=%d&time=%d", followId, maxId];
	NSURL *url = [[NSURL alloc] initWithString:@"http://neurotrace.seas.harvard.edu/testDataSet/POLLMSG"];
	
	//NSLog(@"Sending poll msg request");
	[[URLCacheConnection alloc] initWithURL:url delegate:[[PollMsg alloc] initWithRenderer:renderer] andPost:post];	
}


-(void)pollRequest:(id)sender
{
	if(trackId==-1)
		return;

	if(polls>POLL_LIMIT)
	{
		return;
	}
	polls++;
	NSString *post = [[NSString alloc] initWithFormat:@"id=%d", trackId];
	NSURL *url = [[NSURL alloc] initWithString:@"http://neurotrace.seas.harvard.edu/testDataSet/POLL"];
	
	[[URLCacheConnection alloc] initWithURL:url delegate:self andPost:post];	
}

- (void) connectionDidFail:(URLCacheConnection *)theConnection
{
	polls--;
	NSLog(@"Failed to send sync update");
	[theConnection release];
	//[download release];
}

- (void) connectionDidFinish:(URLCacheConnection *)theConnection andLength:(NSTimeInterval) length
{	
	polls--;
	//NSLog(@"Sent sync update");
	[theConnection release];
	
	NSString *content = [[NSString alloc]  initWithBytes:[theConnection.receivedData bytes]
												length:[theConnection.receivedData length] encoding: NSUTF8StringEncoding];
	
	float posX, posY, zoom;
	int msgId, slice, focal;
	if([content isEqualToString:@"ERROR"])
	{
		NSLog(@"Error in poll request");
		return;
	}
	//NSLog(@"Got content:%@", content);
	sscanf([content UTF8String], "x=%f,y=%f,z=%f,i=%d,s=%d,f=%d", &posX, &posY, &zoom, &msgId, &slice, &focal);
	sliceLabel.text = [NSString stringWithFormat:@"%d", focal+1];
	if([renderer updateFromPoll:posX andPosY:posY andZoom:zoom andSlice:slice andFocal:focal])
		[self drawView:nil];

	
			//theConnection.receivedData
	//[download release];
}


-(void)animateToss:(id)sender
{
	//NSLog(@"Throwing, vX=%f vY=%f", vX, vY);
	[renderer translateImg: vX andDy: vY];
	float oX = vX;
	float oY = vY;
	//vX+=-(abs(vX)/vX)*deceleration;
	//vY+=-(abs(vY)/vY)*deceleration;
	vX*=deceleration;
	vY*=deceleration;
	
	//if(abs(vX)/vX != abs(oX)/oX)
	if(abs(vX)<endThresh)
	{
		//NSLog(@"Done throwing");
		[self stopAnimation];
	}
	if(abs(vY)<endThresh)
	//if(abs(vY)/vY != abs(oY)/oY)
	{
		[self stopAnimation];
		//NSLog(@"Done throwing");
	}
	[self drawView:sender];
}


- (void)drawView:(id)sender
{
	//NSLog(@"drawing");
    [renderer render];
}

-(void)setRate
{
	float rate = [renderer getRate];
	bandwidthLabel.text = [NSString stringWithFormat:@"%f b/s", rate];
	
	float timeLen = [renderer getTime];
	timeLabel.text = [NSString stringWithFormat:@"%f b/s", timeLen];


}


- (void)layoutSubviews
{
    [renderer resizeFromLayer:(CAEAGLLayer*)self.layer];
    [self drawView:nil];
}

- (NSInteger)animationFrameInterval
{
    return animationFrameInterval;
}

- (void)setAnimationFrameInterval:(NSInteger)frameInterval
{
    // Frame interval defines how many display frames must pass between each time the
    // display link fires. The display link will only fire 30 times a second when the
    // frame internal is two on a display that refreshes 60 times a second. The default
    // frame interval setting of one will fire 60 times a second when the display refreshes
    // at 60 times a second. A frame interval setting of less than one results in undefined
    // behavior.
    if (frameInterval >= 1)
    {
        animationFrameInterval = frameInterval;

        if (animating)
        {
            [self stopAnimation];
            [self startAnimation];
        }
    }
}

- (void)startAnimation
{
	//NSLog(@"Animating");
    if (!animating)
    {
        if (displayLinkSupported)
        {
            // CADisplayLink is API new to iPhone SDK 3.1. Compiling against earlier versions will result in a warning, but can be dismissed
            // if the system version runtime check for CADisplayLink exists in -initWithCoder:. The runtime check ensures this code will
            // not be called in system versions earlier than 3.1.

            displayLink = [NSClassFromString(@"CADisplayLink") displayLinkWithTarget:self selector:@selector(animateToss:)];
            [displayLink setFrameInterval:animationFrameInterval];
            [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        }
        else
            animationTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)((1.0 / 60.0) * animationFrameInterval) target:self selector:@selector(animateToss:) userInfo:nil repeats:TRUE];

        animating = TRUE;
    }
	//[self stopAnimation];
	 
}

- (void)stopAnimation
{
//	NSLog(@"Stop animating");

    if (animating)
    {
        if (displayLinkSupported)
        {
            [displayLink invalidate];
            displayLink = nil;
        }
        else
        {
            [animationTimer invalidate];
            animationTimer = nil;
        }

        animating = FALSE;
    }
}

//calculate the distance between two points
- (CGFloat)distance:(CGPoint) first withSecond:(CGPoint)second
{
	return sqrt(pow(first.x-second.x,2)+pow(first.y-second.y,2));
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[self stopAnimation];
//	NSLog(@"Got a touch %d", [touches count]);
	touchCount+=[touches count];
	if([touches count]==3)
	{
		[renderer turnGridOnOff];
	}
	
	if(touchCount==1)
	{
		oldPoint = [[touches anyObject] locationInView:self];
		hasOldPoint = TRUE;
	}
	else {
		hasOldPoint = FALSE;
	}

	
	
	//2 fingers down, begin a pinch
	/*if([touches count] == 2)
	{
#ifdef DEBUG	
		NSLog(@"Pinching starting");
#endif
		NSSet *allTouches = [event allTouches];
		pinching = TRUE;
		UITouch *touch1 = [[allTouches allObjects] objectAtIndex:0];
		UITouch *touch2 = [[allTouches allObjects] objectAtIndex:1];
		CGPoint first = [touch1 locationInView:self];
		CGPoint second = [touch2 locationInView:self];

		initialDistance = [self distance:first withSecond:second];
	}*/
	
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	//NSLog(@"Moved %d touches, count at %d", [touches count], touchCount);
	
	if(toolOn)
		return;

	if(touchCount==1 && [touches count]==1)
	{
		UITouch *aTouch = [touches anyObject];
		CGPoint loc = [aTouch locationInView:self];
		CGPoint prevloc = [aTouch previousLocationInView:self];

		CGFloat deltaX = loc.x-prevloc.x;
		CGFloat deltaY = loc.y-prevloc.y;
		//sumDX = deltaX;
		//sumDY = deltaY;
		//time++;

		[renderer translateImg: deltaX andDy: deltaY]; 
	}
	else if(touchCount==2 && [touches count]==2)
	{
		NSSet *allTouches = [event allTouches];
		UITouch *touch1 = [[allTouches allObjects] objectAtIndex:0];
		UITouch *touch2 = [[allTouches allObjects] objectAtIndex:1];
		CGPoint first = [touch1 locationInView:self];
		CGPoint second = [touch2 locationInView:self];
		
		
		CGFloat dist = [self distance:first withSecond:second];
		if(initialDistance == -1)
			initialDistance = dist;
		else {
			CGFloat scale = log2(dist/initialDistance);
			//NSLog(@"(x1,y1):(%f, %f) (x2,y2):(%f, %f)", first.x, first.y, second.x, second.y);

			[renderer scaleImg:scale];
		}
	}
	
	
    [renderer render];
		
		
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {		
	touchCount-=[touches count];
	
	//deal with 3-finger swipe, and return to make sure no movement
	if([touches count]==3 || touchCount==2)
	{
		UITouch *aTouch = [touches anyObject];
		CGPoint loc = [aTouch locationInView:self];
		CGPoint prevloc = [aTouch previousLocationInView:self];
		
		CGFloat deltaY = loc.y-prevloc.y;
		//NSLog(@"Got 3 touches with delta y=%f", deltaY);
		if(deltaY>0)
		{
			[self downClicked];
		}
		else 
		{
			[self upClicked];
		}		
		return;
	}
	
	
	//NSLog(@"Dropped a touch, down to %d with %d removed", touchCount, [touches count]);
	if(touchCount != 2)
	{
		initialDistance = -1;
		[renderer endScale];
#ifdef DEBUG
	NSLog(@"Done pinching");
#endif
	}
	if([touches count]==1)
	{
		UITouch *aTouch = [touches anyObject];
		CGPoint loc = [aTouch locationInView:self];
		CGPoint prevloc = [aTouch previousLocationInView:self];
		
		CGFloat deltaX = loc.x-prevloc.x;
		CGFloat deltaY = loc.y-prevloc.y;
		CGFloat dist = [self distance:loc withSecond:prevloc];
		//NSLog(@"Done translating with dx=%f dy=%f dist=%f", deltaX, deltaY, dist);
		//double time = [aTouch timestamp];
		//NSLog(@"sumDX=%f sumDY=%f vX=%f vY=%f time=%d", sumDX, sumDY, sumDX/time, sumDY/time, time);
		vX = deltaX;
		vY = deltaY;
		//NSLog(@"Dist=%f",dist);
		if(hasOldPoint)
		{
			float dist2 = [self distance:loc withSecond:oldPoint];
		//	NSLog(@"Dist2=%f",dist2);
			if(dist2<=tapThresh)
			{
				//NSLog(@"Click with tool=%d and on=%d", toolId, toolOn);
				//[renderer setPointWithX:loc.x andY:loc.y];
				if(toolOn && toolId==0)
				{//Mark pressed
					CGFloat rW = [renderer getImageWidth];
					CGFloat rH = [renderer getImageHeight];
					CGFloat sH = [renderer getScreenHeight];

					Message *msg = [[Message alloc] initWithType:0 andW:rW andH:rH andScreenHeight:sH];
					[msg setFirstPointX:[renderer convertX:loc.x] andY:[renderer convertY:loc.y]];
					[msg postMessage:myId andSessId:followId];
					[renderer addMessage:msg];
					toolOn = FALSE;
					[renderer render];

				}
				else if(toolOn && toolId==2)
				{
					NSLog(@"text click");
					textPoint = loc;
					toolOn = FALSE;
					Message *msg = [[Message alloc] initWithType:2 andW:[renderer getImageWidth] andH:[renderer getImageHeight] andScreenHeight:[renderer getScreenHeight]];
					[msg setFirstPointX:[renderer convertX:textPoint.x] andY:[renderer convertY:textPoint.y]];
					[msg setText:inputText];
					[msg postMessage:myId andSessId:followId];
					[renderer addMessage:msg];
					
					[renderer render];
				}
				else {
					//check if pressed on text message
					BOOL hitMsg=FALSE;
					/*NSMutableArray * messages = [renderer getMessages];
					for(int i=0;i<[messages count];i++)
					{
						Message* msg = (Message*)[messages objectAtIndex:i];
						if([msg getType]==2)
						{
							CGFloat mX = [msg getX];
							CGFloat mY = [msg getY];
							
							CGFloat curX = [msg convertBackX:(CGFloat)[renderer convertX:loc.x]];
							CGFloat curY = [msg convertBackY:(CGFloat)[renderer convertY:loc.y]];
							CGFloat dist = [self distance:CGPointMake(mX, mY) withSecond:CGPointMake(curX, curY)];
							//NSLog(@"Disance to message=%f [(%f, %f)->(%f,%f)]", dist, mX, mY, curX, curY);
							if(dist<.05)
							{
								hitMsg = TRUE;
								//UIAlertView *myAlertView = [[UIAlertView alloc] initWithTitle:[msg getText] message:@"this gets covered" delegate:self cancelButtonTitle:@"OK" , nil];

							}
						}
							
					}*/
						
					if(!hitMsg)
					{
						[UIView beginAnimations:nil context:nil];
						[UIView setAnimationDuration:.5];
						[UIView setAnimationCurve: UIViewAnimationCurveEaseInOut];
						//[UIView setAnimationRepeatCount:5];
						//toolbar.hidden = ! toolbar.hidden;
						if(toolbar.hidden)
							toolbar.alpha = 1;
						else 
							toolbar.alpha = 0;
						[toolbar setHidden:!toolbar.hidden];
						[[UIApplication sharedApplication] setStatusBarHidden:![UIApplication sharedApplication].statusBarHidden animated:YES];
						[UIView commitAnimations];
					}
				}
			}
			
			if(toolOn && toolId==1)
			{
				Message *msg = [[Message alloc] initWithType:1 andW:[renderer getImageWidth] andH:[renderer getImageHeight] andScreenHeight:[renderer getScreenHeight]];
				[msg setEndPointX:[renderer convertX:loc.x] andY:[renderer convertY:loc.y]];
				[msg setFirstPointX:[renderer convertX:oldPoint.x] andY:[renderer convertY:oldPoint.y]];
				NSLog(@"Making line from (%f, %f) -> (%f, %f)", oldPoint.x, oldPoint.y, loc.x, loc.y);
				[msg postMessage:myId andSessId:followId];
				[renderer addMessage:msg];
				toolOn = FALSE;
			}
			
			hasOldPoint = FALSE;
		}
		if(dist>throwThresh)
		{
		//	NSLog(@"Starting throw");
			[self startAnimation];
		}
	}
	[self setRate];
		
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	NSLog(@"Cancelled a touch, down to %d", [touches count]);
	touchCount-=[touches count];
	if(touchCount != 2)
	{
		initialDistance = -1;
		[renderer endScale];
#ifdef DEBUG
		NSLog(@"Done pinching");
#endif
	}

	
}

-(void)setFollow:(int)who
{
	[renderer resetMessages];
	followId=who;
	sessIdLabel.text = [NSString stringWithFormat:@"SESS: %d", who];
	[self addSubview:sessIdLabel];

}

-(void)setTrack:(int)who
{
	trackId=who;
	if(trackId==myId)
		[renderer turnOffSync];
	else
		[renderer turnOnSync];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex

{
	if(currentAlert==0)
	{ //making a text message
		//NSLog(@"Clicked %d", buttonIndex);
		if(buttonIndex==1)
		{
			NSString *text = [myTextField text];
			[text retain];
			inputText = text;
			//toolOn = TRUE;
			//toolId=2;
		}
		//toolOn = FALSE;
	}
	else if(currentAlert==1)
	{ //following a session
		NSString *text = [myTextField text];
		int f=atoi([text UTF8String]);
		//sessIdLabel.text = [NSString stringWithFormat:@"SESS: %d", followId];
		[self setFollow:f];
	}
	else if(currentAlert==2)
	{  //tracking a user
		NSString *text = [myTextField text];
		trackId=atoi([text UTF8String]);
		if(trackId==myId)
			[renderer turnOffSync];
		else
			[renderer turnOnSync];
	}

	[myTextField resignFirstResponder];
	[myTextField release];
	
}
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	//toolOn = FALSE;

	[alertView release];
	
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
}

- (void)alertViewCancel:(UIAlertView *)alertView
{
	//NSLog(@"Cancel");
	//toolOn = FALSE;

//	[myTextField resignFirstResponder];
//	[myTextField release];

}

- (void)didPresentAlertView:(UIAlertView *)alertView
{
	
}

- (void)willPresentAlertView:(UIAlertView *)alertView
{
}



- (void)dealloc
{
    [renderer release];

    [super dealloc];
}

@end
