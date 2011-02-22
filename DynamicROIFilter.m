//
//  DynamicROIFilter.m
//  DynamicROI
//
//  Copyright (c) 2010 Yang. All rights reserved.
//

#import "DynamicROIFilter.h"
#import "DynamicInterface.h"

@implementation DynamicROIFilter

- (void) initPlugin
{
}

- (long) filterImage:(NSString*) menuName{
	if ([viewerController maxMovieIndex] > 1) { //is it a dynamic image?
		
		if( [viewerController selectedROI] == nil)			{ //is there a ROI selected?
			NSAlert *myAlert = [NSAlert alertWithMessageText:@"No ROI Selected" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please select an ROI for which you want to calculate the time activity curve for."];
			[myAlert runModal];
			return 0;
		}
		else {
 			[viewerController roiVolume:nil]; //pulls up ROI volume.
			[[DynamicInterface alloc] initWithViewer:viewerController];
			
		}
				
	}
	else {
		NSAlert *myAlert = [NSAlert alertWithMessageText:@"Invalid Image set" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"This plugin is only for dynamic datasets"];
		[myAlert runModal];
	}
	
	
	return 0;
}

@end
