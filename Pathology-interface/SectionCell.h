//
//  SectionCell.h
//  Pathology-interface
//
//  Created by Liangjun Jiang on 7/7/11.
//  Copyright 2011 Harvard University Extension School. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AQGridViewCell.h"

@interface SectionCell : AQGridViewCell {
    UILabel *numberLabel;
    UILabel *titleLabel;
    UIImageView *imageView;
    
}

@property (nonatomic, retain) IBOutlet UILabel *numberLabel;
@property (nonatomic, retain) IBOutlet UILabel *titleLabel;
@property (nonatomic, copy) NSString *reuseIdentifier;

+(SectionCell *)cellFromNib;

@end
