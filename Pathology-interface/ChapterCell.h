//
//  ChapterCell.h
//  Pathology-interface
//
//  Created by Liangjun Jiang on 7/7/11.
//  Copyright 2011 Harvard University Extension School. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AQGridViewCell.h"

@interface ChapterCell : AQGridViewCell {
    IBOutlet UIImageView *thumbnailImageView;
    IBOutlet UILabel *chapterNameLabel;
    IBOutlet UIView *gigaPixelAvailable;
    
}
@property (nonatomic, retain) IBOutlet UIImageView *thumbnailImageView;
@property (nonatomic, retain) IBOutlet UILabel *chapterNameLabel;
@property (nonatomic, retain) IBOutlet UIView *gigaPixelAvailable;


@property (nonatomic, copy) NSString *reuseIdentifier;

+(ChapterCell *)cellFromNib;
@end
