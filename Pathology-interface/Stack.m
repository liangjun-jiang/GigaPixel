//
//  Stack.m
//  GigaPixel
//
//  Created by Axel Hansen on 4/5/10.
//  Copyright 2010 Harvard University. All rights reserved.
//

/*
 Simple stack impelmentation for non-obj c objects (c struct).  uses linked list
 */

#import "Stack.h"


@implementation Stack

-(id)init
{
	head = NULL;
	numCount = 0;
	return self;
}

-(void)dealloc
{
	Entry* cur = head;
	while(cur!=NULL)
	{
		Entry * temp = cur;
		cur = cur->next;
		free(temp);
	}
	[super dealloc];
}	
-(void)print
{
	Entry* cur = head;
	while(cur!=NULL)
	{
		NSLog(@"Texture %d", cur->tex);
		
		cur = cur->next;
	}
	
}

-(GLuint) pop
{
	Entry * temp = head;
	GLuint t = 0;
	if(head!=NULL)
	{
		numCount--;
		head=head->next;
		t = temp->tex;
	}
	//temp->tex = 0;
	//temp->next = NULL;
	free(temp);
	//NSLog(@"Stack removing texture %d", t);
	return t;
}
-(void) push:(GLuint)g
{
	//NSLog(@"Stack adding texture %d", g);
	numCount++;
	Entry * newE = (Entry*)malloc(sizeof(Entry));
	newE->tex = g;
	newE->next = head;
	head = newE;
}
	
-(int) count
{
	return numCount;
}
	  


@end
