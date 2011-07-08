//
//  ButtonGroup.m
//  Pathology-interface
//
//  Created by Liangjun Jiang on 7/7/11.
//  Copyright 2011 Harvard University Extension School. All rights reserved.
//

#import "ButtonGroup.h"


@implementation ButtonGroup

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)removeAllSubviews;
{
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
}

-(void)layoutSubviews
{
    CGRect frame = self.frame;
    CGFloat rowHeight = 30.f;
    if (self.subviews.count > 0) {
        rowHeight = 40;
    }
    
    CGPoint offset = CGPointZero;
    
    for (UIView *subview in self.subviews) {
        CGSize size = [subview sizeThatFits:CGSizeZero];
        
        if (offset.x + size.width > frame.size.width) {
            offset.x = 0;
            offset.y += rowHeight;
        }
        
        CGRect subviewFrame;
        subviewFrame.origin = offset;
        subviewFrame.size = size;
        subview.frame = subviewFrame;
        
        offset.x += size.width;
    }
    
    frame.size.height = offset.y + rowHeight;
    self.frame = frame;
}

- (void)dealloc
{
    [super dealloc];
}

@end
