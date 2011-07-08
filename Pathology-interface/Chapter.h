//
//  Chapter.h
//  Actors
//
//  Created by Liangjun Jiang on 7/7/11.
//  Copyright 2011 Harvard University Extension School. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Chapter : NSObject {

    NSURL *thumbURL;
    NSURL *fullImageURL;
    UIImage *thumb;
    UIImage *fullImage;
    
    NSString *title;
    NSString *synopsis;
    
    BOOL gigaPixelAvailable;
}

@property (nonatomic, assign) BOOL gigaPixelAvailable;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *synopsis;

@property (nonatomic, retain) NSURL *thumbURL;
@property (nonatomic, retain) NSURL *fullImageURL;
@property (nonatomic, retain) UIImage *thumb;
@property (nonatomic, retain) UIImage *fullImage;



@end
