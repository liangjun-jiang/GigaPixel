//
//  GigaPixel.h
//  GigaPixel
//
//  Created by Axel Hansen on 3/2/10.
//  Copyright 2010 Harvard University. All rights reserved.
//

//#define DEBBUG
//#define DEBUG_2
//#define DEBUG_3
//#define DEBUG_4

//#define LOCK_FREE 0;
//#define TAKEN 1;
#include <pthread.h>
#include <mach/semaphore.h> 
#include <mach/task.h>



/*enum {
	LOCK_FREE, TAKEN
};*/

extern int CPU_CACHE_SIZE;
extern int SCREEN_WIDTH;
extern int SCREEN_HEIGHT;

extern bool USING_PVRTC;



#ifndef max
#define max( a, b ) ( ((a) > (b)) ? (a) : (b) )
#endif

#ifndef min
#define min( a, b ) ( ((a) < (b)) ? (a) : (b) )
#endif





