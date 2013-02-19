//
//  EAGLView.h
//  GigaPixel
//
//  Created by Axel Hansen on 2/9/10.
//  Copyright Harvard University 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "GigaPixel.h"

#import "ESRenderer.h"
#import "PrefetchManager.h"
#import "Message.h"
#import "SessionList.h"

// This class wraps the CAEAGLLayer from CoreAnimation into a convenient UIView subclass.
// The view content is basically an EAGL surface you render your OpenGL scene into.
// Note that setting the view non-opaque will only work if the EAGL surface has an alpha channel.
@interface EAGLView : UIView
{    
@private
    id <ESRenderer> renderer;
	int myHdrId;
	BOOL toolOn;
	int toolId;
	
	SessionList *sessions;
	SessionList *tracks;

	
	int currentAlert;
	
    BOOL animating;
	BOOL shouldStopAnimate;
    BOOL displayLinkSupported;
    NSInteger animationFrameInterval;
    // Use of the CADisplayLink class is the preferred method for controlling your animation timing.
    // CADisplayLink will link to the main display and fire every vsync when added to a given run-loop.
    // The NSTimer class is used only as fallback when running on a pre 3.1 device where CADisplayLink
    // isn't available.
    id displayLink;
    NSTimer *animationTimer;
	NSTimer *pollTimer;
	
	int followId;
	int trackId;
	int myId;
	
	UILabel *sessIdLabel;
	
	//AH, stuff for multi touch and pinching
	NSTimer *timer;
	CGFloat initialDistance;
	int touchCount;
	PrefetchManager *pm; //separate thread to manage prefetching
	semaphore_t *signalSem;
	
	CGFloat vX;
	CGFloat vY;
	//int time;

	UIToolbar *toolbar;
	UIBarButtonItem *upButton;
	UIBarButtonItem *downButton;
	UIBarButtonItem *gridButton;
	UIBarButtonItem *showSessionsButton;
	UIBarButtonItem *showTracksButton;

	UILabel *sliceLabel;
	UILabel *bandwidthLabel;
	UILabel *timeLabel;

	
	UITextField* myTextField;
	
    
    NSString *userName;
    
	NSString *inputText;


	CGPoint oldPoint;
	BOOL hasOldPoint;
	
	CGPoint textPoint;
	
	int curSlice;
	int SLICE_COUNT;
	
	int polls;
	UIPopoverController * pop;
	UIPopoverController * popTrack;

}

@property (readonly, nonatomic, getter=isAnimating) BOOL animating;
@property (nonatomic) NSInteger animationFrameInterval;
-(id)initWithFrame:(CGRect)frame andImg:(NSString *)img andUrl:(NSString *)url andNumSlices:(int)nS withUserName:(NSString *)username;
-(void)showSessions;
-(void)pollRequest:(id)sender;
-(void)gridClicked;
-(void)upClicked;
-(void)downClicked;
- (void)startAnimation;
- (void)stopAnimation;
- (void)drawView:(id)sender;
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)finishInit;
-(void)animateToss:(id)sender;
-(void)setRate;
-(void)listRequest:(id)sender;
-(void)setFollow:(int)who;
@end
