//
//  ViewerController+Yang.h
//  3DROIManager
//
//  Created by Yang Yang on 3/25/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OsiriX Headers/ViewerController.h>

@class ROI;
@interface ViewerController (Yang) 
//Extension of viewerController class, adds functions to compute TACS for ROIs
//Called by Dynamic interface to generate Time Acitivity Curves

-(void) deleteAllSeriesROIwithName: (NSString*)name withSlices:(int)maxSlices;
-(NSMutableDictionary*) computeTAC:(ROI*)selectedROI onframe:(long)frameofroi withFrame:(long)frame;
-(NSMutableDictionary*) maxValueForROI: (ROI*)selectedROI withFrame:(long) frame threshold:(float)percent;
- (void) GenVolumefor: (ROI *)something;
@end
