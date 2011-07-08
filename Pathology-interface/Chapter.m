//
//  Chapter.m
//  Actors
//
//  Created by Liangjun Jiang on 7/7/11.
//  Copyright 2011 Harvard University Extension School. All rights reserved.
//

#import "Chapter.h"


@implementation Chapter
@synthesize fullImage, fullImageURL, thumb, thumbURL,title, synopsis,gigaPixelAvailable;

-(id)init;
{
    self = [super init];
    if(!self) return nil;
    
    self.title = @"Chapter Title";
    self.synopsis = @"Chapter Synopsis";
    
    return self;
    
}

-(void)dealloc
{
    [fullImage release];
    fullImage = nil;
    
    [fullImageURL release];
    fullImageURL = nil;
    
    [thumb release];
    thumb = nil;
    
    [thumbURL release];
    thumbURL = nil;
    [super dealloc];
    
}

@end
