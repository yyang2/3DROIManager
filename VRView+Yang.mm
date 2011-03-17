//
//  VRView+Yang.m
//  3DROIManager
//
//  Created by Yang Yang on 2/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "VRView+Yang.h"


@implementation VRView (Yang)

-(NSMutableArray*) get3DPositionArray
{
	return point3DPositionsArray; 
}

-(void) callSuperKeyDown: (NSEvent*)keyDown 
{
	//implementing this because VTKView keyDown:(char p) selects point in VRView,
	// needed for Swizzle VRView to work correctly
	[super keyDown:keyDown];
}

@end
