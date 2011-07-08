//
//  ChapterCell.m
//  Pathology-interface
//
//  Created by Liangjun Jiang on 7/7/11.
//  Copyright 2011 Harvard University Extension School. All rights reserved.
//

#import "ChapterCell.h"


@implementation ChapterCell
@synthesize reuseIdentifier;
@synthesize thumbnailImageView, chapterNameLabel, gigaPixelAvailable;

+(ChapterCell *)cellFromNib;
{
    UINib *nib = [UINib nibWithNibName:NSStringFromClass(self) bundle:[NSBundle bundleForClass:self]];
	
    NSArray *objects = [nib instantiateWithOwner:nil options:nil];
	
    ChapterCell *returnedCell = (ChapterCell *)[objects objectAtIndex:0];
	
	return returnedCell;
}

@end
