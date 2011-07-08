//
//  SectionCell.m
//  Pathology-interface
//
//  Created by Liangjun Jiang on 7/7/11.
//  Copyright 2011 Harvard University Extension School. All rights reserved.
//

#import "SectionCell.h"


@implementation SectionCell
@synthesize numberLabel, titleLabel, reuseIdentifier;

+(SectionCell *)cellFromNib;
{
    UINib *nib = [UINib nibWithNibName:NSStringFromClass(self) bundle:[NSBundle bundleForClass:self]];
	
    NSArray *objects = [nib instantiateWithOwner:nil options:nil];
	
    SectionCell *returnedCell = (SectionCell *)[objects objectAtIndex:0];
	
	return returnedCell;
}

-(void)dealloc
{
    [numberLabel release];
    [titleLabel release];
    [super dealloc];
}

@end
