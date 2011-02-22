//
//  ITKSegmentation3DController+Yang.m
//  3DROIManager
//
//  Created by Yang Yang on 4/27/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ITKSegmentation3DController+Yang.h"
#import <OsiriX Headers/ViewerController.h>
#import <OsiriX Headers/DCMPix.h>
#import <OsiriX Headers/ITKSegmentation3D.h>
#import <OsiriX Headers/Notifications.h>

@implementation ITKSegmentation3DController (Yang)
- (void) computeWithPoint: (NSPoint) pt :(NSMutableDictionary *)interval :(NSString *)generatedname : (NSString *) selectedname
{
	float min = [[interval objectForKey:@"min"] floatValue];
	float max = [[interval objectForKey:@"max"] floatValue];
	
	[viewer roiDeleteWithName: selectedname];
	
	long slice=-1;
	int previousMovieIndex = [viewer curMovieIndex];
	
	int i;
	for(i = 0; i < [viewer maxMovieIndex]; i++)
	{
		if( i == [viewer curMovieIndex])
		{
			ITKSegmentation3D	*itk = [[ITKSegmentation3D alloc] initWith:[viewer pixList] :[viewer volumePtr] :slice];
			if( itk)
			{			
				// an array for the parameters
				int algo = 1;
				NSMutableArray *parametersArray = [NSMutableArray arrayWithCapacity:2] ;
				[parametersArray addObject:[NSNumber numberWithFloat:0.0]];
				[parametersArray addObject:[NSNumber numberWithFloat:8000.0]];				
				[itk regionGrowing3D	: viewer
									 : nil
									 : -1
									 : pt
									 : algo
									 : parametersArray //[[params cellAtIndex: 2] floatValue]
									 : NO
									 : 1000.0
									 : NO
									 : 0.0
									 : 0
									 : 6
									 : generatedname
									 : NO
				 ];
								
				[itk release];
			}
		}
	}
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"growingRegionPropagateIn4D"])
		[viewer setMovieIndex: previousMovieIndex];
}


@end
