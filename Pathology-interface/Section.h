//
//  Section.h
//  Pathology-interface
//
//  Created by Liangjun Jiang on 7/7/11.
//  Copyright 2011 Harvard University Extension School. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Section : NSObject {
    NSString *number;
    NSString *title;
    NSString *identifier;
}

@property (nonatomic, copy) NSString *number;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *identifier;


@end
