//
//  SwizzleVRView.m
//  3DROIManager
//
//  Created by Yang Yang on 1/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SwizzleVRView.h"
#import <OsiriX Headers/ROI.h>

@implementation SwizzleVRView

- (void) removeSelected3DPoint
{
	if([self isAny3DPointSelected])
	{
		// remove 2D Point
		float position[3];
		ROI* something = [[self.controller roi2DPointsArray] objectAtIndex:[self selected3DPointIndex]];

		//yangyang added this so center of points don't get deleted from VRView
		if([something.name hasSuffix:@"_center"]) return;
		
		[[point3DPositionsArray objectAtIndex:[self selected3DPointIndex]] getValue:position];
		
		[controller remove2DPoint: position[0] : position[1] : position[2]];
		// remove 3D Point
		// the 3D Point is removed through notification (sent in [controller remove2DPoint..)
		//[self remove3DPointAtIndex:[self selected3DPointIndex]];
	}
}

@end
