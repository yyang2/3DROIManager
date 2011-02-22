//
//  SwizzleROIVolume.m
//  3DROIManager
//
//  Created by Yang Yang on 1/26/11.
//  Copyright 2011 UCLA School of Medicine. All rights reserved.
//

#import "SwizzleROIVolume.h"


@implementation SwizzleROIVolume
- (void) setROIList: (NSArray*) newRoiList
{
	float prevArea, preLocation;
	prevArea = 0.;
	preLocation = 0.;
	volume = 0.;
	
	for(unsigned int i = 0; i < [newRoiList count]; i++)
	{
		ROI *curROI = [newRoiList objectAtIndex:i];
		if([curROI type]==tPencil || [curROI type]==tCPolygon || [curROI type]==tPlain || ([[NSUserDefaults standardUserDefaults] integerForKey:@"PreclinicalAnalysis"] && [curROI type] == tOval))
		{
//			NSLog(@"Swizzling ROIVolume setROIList");
			[roiList addObject:curROI];
			// volume
			DCMPix *curDCM = [curROI pix];
			float curArea = [curROI roiArea];
			if( preLocation != 0)
				volume += (([curDCM sliceLocation] - preLocation)/10.) * (curArea + prevArea)/2.;
			prevArea = curArea;
			preLocation = [curDCM sliceLocation];
		}
	}
	
	if([roiList count])
	{
		ROI *curROI = [roiList objectAtIndex:0];
		[name release];
		name = [[curROI name] retain];
		[properties setValue:name forKey:@"name"];
		[properties setValue:[NSNumber numberWithFloat:volume] forKey:@"volume"];
	}
}

@end
