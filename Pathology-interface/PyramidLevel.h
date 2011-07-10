//
//  PyramidLevel.h
//  GigaPixel
//
//  Created by Axel Hansen on 2/19/10.
//  Copyright 2010 Harvard University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Tile.h"
#import "GigaPixel.h"

@interface PyramidLevel : NSObject {
	Tile*** tiles;
	int cols;
	int rows;
	int width;
	int height;
	int imageBase; //start of image indices for this level
	float **matrix;
}

- (Tile*)getTileWithX:(int)x andY: (int) y;
- (int)getCols;
- (int)getRows;
- (int)getWidth;
- (int)getHeight;



@end
