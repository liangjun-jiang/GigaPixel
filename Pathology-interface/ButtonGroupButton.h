//
//  ButtonGroupButton.h
//  Pathology-interface
//
//  Created by Liangjun Jiang on 7/7/11.
//  Copyright 2011 Harvard University Extension School. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Section.h"

@interface ButtonGroupButton : UIButton {
    Section *section;
    NSString *keyword;
    
}

@property (nonatomic, retain) Section *section;
@property (nonatomic, retain) NSString *keyword;

@end
