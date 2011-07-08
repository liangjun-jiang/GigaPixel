//
//  Section.m
//  Pathology-interface
//
//  Created by Liangjun Jiang on 7/7/11.
//  Copyright 2011 Harvard University Extension School. All rights reserved.
//

#import "Section.h"



@implementation Section

@synthesize number,title,identifier;

-(void) dealloc
{
    [super dealloc];
    [number release];
    number = nil;
    [title release];
    title = nil;
    [identifier release];
    identifier = nil;
    
}

@end
