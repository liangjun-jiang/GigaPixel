#import <UIKit/UIKit.h>
//#import "ES1Renderer.h"


@protocol Tile;

float totalTime;
int activeDownloads;


@interface URLCacheConnection : NSObject {
	id <Tile> delegate;
	NSMutableData *receivedData;
	NSDate *lastModified;
	NSTimeInterval timeStart;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) NSMutableData *receivedData;
@property (nonatomic, retain) NSDate *lastModified;

- (id) initWithURL:(NSURL *)theURL delegate:(id<Tile>)theDelegate;
- (id) initWithURL:(NSURL *)theURL delegate:(id<Tile>)theDelegate andPost:(NSString *)postData;

@end


@protocol Tile<NSObject>

- (void) connectionDidFail:(URLCacheConnection *)theConnection;
- (void) connectionDidFinish:(URLCacheConnection *)theConnection;

@end
