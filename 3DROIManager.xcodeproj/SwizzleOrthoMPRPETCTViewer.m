//
//  SwizzleOrthoMPRPETCTViewer.m
//  3DROIManager
//
//  Created by Yang Yang on 6/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SwizzleOrthoMPRPETCTViewer.h"
@implementation SwizzleOrthoMPRPETCTViewer

- (void) setMovieIndex: (short) i
{
	int index = [[CTController originalView] curImage];
	
	[self initPixList: nil];
	
	curMovieIndex = i;
	if( curMovieIndex < 0) curMovieIndex = maxMovieIndex-1;
        if( curMovieIndex >= maxMovieIndex) curMovieIndex = 0;
            
            [moviePosSlider setIntValue:curMovieIndex];
	
	NSMutableArray	*cPix = [viewer pixList:i];
	NSMutableArray	*subPix = [NSMutableArray arrayWithArray: [cPix subarrayWithRange:NSMakeRange(fistCTSlice,sliceRangeCT)]];
	
	[[CTController reslicer] setOriginalDCMPixList: subPix];
	[[CTController reslicer] setUseYcache:NO];

    //yang changed here
	[[CTController originalView] setPixels:subPix files:[[viewer fileList:i] subarrayWithRange:NSMakeRange(fistCTSlice,sliceRangeCT)] rois:[[viewer roiList:i] subarrayWithRange:NSMakeRange(fistCTSlice,sliceRangeCT)] firstImage:0 level:'i' reset:NO];
	
    //	if( wasDataFlipped) [self flipDataSeries: self];
	[[CTController originalView] setIndex:index];
	//[[CTController originalView] sendSyncMessage:0];
	
	cPix = [blendingViewerController pixList:i];
	subPix = [NSMutableArray arrayWithArray: [cPix subarrayWithRange:NSMakeRange(fistPETSlice,sliceRangePET)]];
    
	index = [[PETController originalView] curImage];
	[[PETController reslicer] setOriginalDCMPixList:subPix];
	[[PETController reslicer] setUseYcache:NO];
    
    //yang changed here
	[[PETController originalView] setPixels:subPix files:[[blendingViewerController fileList:i] subarrayWithRange:NSMakeRange(fistPETSlice,sliceRangePET)] rois:[[blendingViewerController roiList:i] subarrayWithRange:NSMakeRange(fistPETSlice,sliceRangePET)] firstImage:0 level:'i' reset:NO];
    //	if( wasDataFlipped) [self flipDataSeries: self];
	[[PETController originalView] setIndex:index];
	//[[CTController originalView] sendSyncMessage:0];
    //	
    //	[CTController setFusion];
    //	[PETController setFusion];
    //	[PETCTController setFusion];
    //	
	[CTController refreshViews];
	[PETController refreshViews];
	[PETCTController refreshViews];
}

@end
