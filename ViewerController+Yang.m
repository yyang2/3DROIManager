//
//  ViewerController+Yang.m
//  3DROIManager
//
//  Created by Yang Yang on 3/25/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.

#import "ViewerController+Yang.h"
#import <OsiriX Headers/ViewerController.h>
#import <OsiriX Headers/Notifications.h>
#import <Osirix Headers/DCMPix.h>
#import <Osirix Headers/ROI.h>
#import <Osirix Headers/DCMView.h>
#import <OsiriX Headers/WaitRendering.h>
#import <OsiriX Headers/ROIVolumeController.h>
#import <Osirix Headers/ITKSegmentation3D.h>

@implementation ViewerController (Yang)
-(void) deleteAllSeriesROIwithName: (NSString*) name withSlices:(int)maxSlices{
	
	long	frames, slices, rois;
	int maxFrames = [self maxMovieIndex];
	

	//[imageView stopROIEditingForce: YES];
	[name retain];

	for( frames = 0; frames < maxFrames; frames++ ) {
		for (slices = 0; slices < maxSlices; slices++){
			for (rois = 0; rois <[[[self roiList:frames] objectAtIndex:slices] count]; rois++){
				ROI *curROI;
				curROI = [[[self roiList:frames] objectAtIndex:slices] objectAtIndex: rois];
				NSLog(@"index:%i current ROI: %@",rois, curROI);
				if( [[curROI name] isEqualToString: name]){
					[[[self roiList:frames] objectAtIndex:slices] removeObject:curROI];
					[[NSNotificationCenter defaultCenter] postNotificationName: OsirixRemoveROINotification object:curROI userInfo: nil];
					rois--;
				}
			}
		}
	}
	[name release];
}

NSInteger firstNumSort(id str1, id str2, void *context) {
    float num1 = [str1 floatValue];
    float num2 = [str2 floatValue];
	
    if (num1 < num2)
        return NSOrderedDescending;  
    else if (num1 > num2)
	    return NSOrderedAscending;
    return NSOrderedSame;
}



-(NSMutableDictionary*) computeTAC:(ROI*)selectedRoi onframe:(long)frameofroi withFrame:(long)frame
{
	
	long				i, x, y, globalCount, imageCount, lastImageIndex;
	double				volume, prevArea, preLocation, location, sliceInterval;
	ROI					*lastROI;
	BOOL				missingSlice = NO;
	NSMutableArray		*theSlices = [NSMutableArray array];
	
	NSMutableArray *pts = [NSMutableArray array];
	NSString **error = nil;
	
	
	lastROI = nil;
	lastImageIndex = -1;
	
	NSLog( @"computeTAC started");
	
	
	lastROI = nil;
	prevArea = 0;
	globalCount = 0;
	lastImageIndex = -1;
	preLocation = 0;
	location = 0;
	volume = 0;
	sliceInterval = [[pixList[curMovieIndex] objectAtIndex: 0] sliceInterval];
	
	ROI *fROI = nil, *lROI = nil;
	int	fROIIndex, lROIIndex;
	ROI	*curROI = nil;
	
	for( x = 0; x < [pixList[curMovieIndex] count]; x++)
	{
		DCMPix	*curDCM = [pixList[curMovieIndex] objectAtIndex: x];
		imageCount = 0;
		
		location = x * sliceInterval;
		
		for( i = 0; i < [[roiList[curMovieIndex] objectAtIndex: x] count]; i++)
		{
			curROI = [[roiList[curMovieIndex] objectAtIndex: x] objectAtIndex: i];
			if( [[curROI name] isEqualToString: [selectedRoi name]] == YES)		//&& [[curROI comments] isEqualToString:@"morphing generated"] == NO)
			{
				if( fROI == nil)
				{
					fROI = curROI;
					fROIIndex = x;
				}
				lROI = curROI;
				lROIIndex = x;
				
				globalCount++;
				imageCount++;
				
				DCMPix *curPix = [pixList[ curMovieIndex] objectAtIndex: x];
				float curArea = [curROI roiArea];
				
				[curROI setPix: curPix];
				
				if( curArea == 0)
				{
					if( error) *error = [NSString stringWithString: NSLocalizedString(@"One ROI has an area equal to ZERO!", nil)];
					return 0;
				}
				
				if( preLocation != 0)
					volume += ((location - preLocation)/10.) * (curArea + prevArea)/2.;
				
				prevArea = curArea;
				preLocation = location;
				
				if( pts)
				{
					NSMutableArray	*points = nil;
					
					if( [curROI type] == tPlain)
					{
						points = [ITKSegmentation3D extractContour:[curROI textureBuffer] width:[curROI textureWidth] height:[curROI textureHeight] numPoints: 100 largestRegion: NO];
						
						float mx = [curROI textureUpLeftCornerX], my = [curROI textureUpLeftCornerY];
						
						for( i = 0; i < [points count]; i++)
						{
							MyPoint	*pt = [points objectAtIndex: i];
							[pt move: mx :my];
						}
					}
					else points = [curROI splinePoints];
					
					for( y = 0; y < [points count]; y++)
					{
						float location[ 3];
						
						[curDCM convertPixX: [[points objectAtIndex: y] x] pixY: [[points objectAtIndex: y] y] toDICOMCoords: location pixelCenter: YES];
						
						NSArray	*pt3D = [NSArray arrayWithObjects: [NSNumber numberWithFloat: location[0]], [NSNumber numberWithFloat:location[1]], [NSNumber numberWithFloat:location[2]], nil];
						
						[pts addObject: pt3D];
					}
				}
				
				if( lastROI && (lastImageIndex+1) < x)
					missingSlice = YES;
				
				[theSlices addObject: [NSDictionary dictionaryWithObjectsAndKeys: curROI, @"roi", curPix, @"dcmPix", nil]];
				
				lastImageIndex = x;
				lastROI = curROI;
			}
		}
		
		if( imageCount > 1)
		{
			if( [imageView flippedData])
			{
				if( error) *error = [NSString stringWithFormat: NSLocalizedString(@"Only ONE ROI per image, please! (im: %d)", nil), pixList[curMovieIndex] -x];
			}
			else
			{
				if( error) *error = [NSString stringWithFormat: NSLocalizedString(@"Only ONE ROI per image, please! (im: %d)", nil), x+1];
			}
			return 0;
		}
	}
	
	NSLog( @"********");
	
	if( pts)
	{
		if( fROI && lROI)
		{
			// Close the floor and the ceil of the volume
			
			//			float *data;
			//			float *locations;
			//			long dataSize;
			//			
			//			data = [[fROI pix] getROIValue:&dataSize :fROI :&locations];
			//			
			//			for( i = 0 ; i < dataSize; i +=4)
			//			{
			//				float location[ 3];
			//				NSArray	*pt3D;
			//				
			//				[[fROI pix] convertPixX: locations[i*2] pixY: locations[i*2+1] toDICOMCoords: location];
			//				
			//				pt3D = [NSArray arrayWithObjects: [NSNumber numberWithFloat: location[0]], [NSNumber numberWithFloat:location[1]], [NSNumber numberWithFloat:location[2]], nil];
			//				NSLog( [pt3D description]);
			//				[*pts addObject: pt3D];
			//			}
			//			
			//			free( data);
			//			free( locations);
			//			
			//			data = [[lROI pix] getROIValue:&dataSize :lROI :&locations];
			//			
			//			for( i = 0 ; i < dataSize; i +=4)
			//			{
			//				float location[ 3];
			//				NSArray	*pt3D;
			//				
			//				[[lROI pix] convertPixX: locations[i*2] pixY: locations[i*2+1] toDICOMCoords: location];
			//				
			//				pt3D = [NSArray arrayWithObjects: [NSNumber numberWithFloat: location[0]], [NSNumber numberWithFloat:location[1]], [NSNumber numberWithFloat:location[2]], nil];
			//				NSLog( [pt3D description]);
			//				[*pts addObject: pt3D];
			//			}
			//			
			//			free( data);
			//			free( locations);
			
			float location[ 3];
			NSArray	*pt3D;
			NSPoint centroid;
			DCMPix	*curDCM;
			
			if( fROIIndex > 0) fROIIndex--;
			if( lROIIndex < [pixList[curMovieIndex] count]-1) lROIIndex++;
			
			curDCM = [pixList[curMovieIndex] objectAtIndex: fROIIndex];
			centroid = [fROI centroid];
			[curDCM  convertPixX: centroid.x pixY: centroid.y toDICOMCoords: location pixelCenter: YES];
			pt3D = [NSArray arrayWithObjects: [NSNumber numberWithFloat: location[0]-1], [NSNumber numberWithFloat:location[1]-1], [NSNumber numberWithFloat:location[2]], nil];
			[pts addObject: pt3D];
			pt3D = [NSArray arrayWithObjects: [NSNumber numberWithFloat: location[0]-1], [NSNumber numberWithFloat:location[1]+1], [NSNumber numberWithFloat:location[2]], nil];
			[pts addObject: pt3D];
			pt3D = [NSArray arrayWithObjects: [NSNumber numberWithFloat: location[0]], [NSNumber numberWithFloat:location[1]], [NSNumber numberWithFloat:location[2]], nil];
			[pts addObject: pt3D];
			
			curDCM = [pixList[curMovieIndex] objectAtIndex: lROIIndex];
			centroid = [lROI centroid];
			[curDCM  convertPixX: centroid.x pixY: centroid.y toDICOMCoords: location pixelCenter: YES];
			pt3D = [NSArray arrayWithObjects: [NSNumber numberWithFloat: location[0]-1], [NSNumber numberWithFloat:location[1]-1], [NSNumber numberWithFloat:location[2]], nil];
			[pts addObject: pt3D];
			pt3D = [NSArray arrayWithObjects: [NSNumber numberWithFloat: location[0]-1], [NSNumber numberWithFloat:location[1]+1], [NSNumber numberWithFloat:location[2]], nil];
			[pts addObject: pt3D];
			pt3D = [NSArray arrayWithObjects: [NSNumber numberWithFloat: location[0]], [NSNumber numberWithFloat:location[1]], [NSNumber numberWithFloat:location[2]], nil];
			[pts addObject: pt3D];
		}
	}
	
	NSLog( @"volume computation done");
	
	if( [pts count] > 0)
	{
		NSLog( @"number of points: %d", [pts count]);
		
#define MAXPOINTS 7000
		
		if( [pts count] > MAXPOINTS*2)
		{
			NSMutableArray *newpts = [NSMutableArray arrayWithCapacity: MAXPOINTS*2];
			
			int i, add = [pts count] / MAXPOINTS;
			
			if( add > 1)
			{
				for( i = 0; i < [pts count]; i += add)
				{
					[newpts addObject: [pts objectAtIndex: i]];
				}
				
				NSLog( @"too much points, reducing from: %d, to: %d", [pts count], [newpts count]);
				
				[pts removeAllObjects];
				[pts addObjectsFromArray: newpts];
			}
		}
	}
	
	NSMutableDictionary *data = [NSMutableDictionary dictionary];
	if( missingSlice) NSLog( @"**** Warning cannot compute data on a ROI with missing slices. Turn generateMissingROIs to TRUE to solve this.");
		else
		{
			double gmean = 0, gtotal = 0, gmin = 0, gmax = 0, gdev = 0;
			
			//			for( i = 0 ; i < [theSlices count]; i++)
			//			{
			//				DCMPix	*curPix = [[theSlices objectAtIndex: i] objectForKey:@"dcmPix"];
			//				ROI		*curROI = [[theSlices objectAtIndex: i] objectForKey:@"roi"];
			//				
			//				float mean = 0, total = 0, dev = 0, min = 0, max = 0;
			//				[curPix computeROIInt: curROI :&mean :&total :&dev :&min :&max];
			//				
			//				gmean  = ((gmean * gtotal) + (mean*total)) / (gtotal+total);
			//				gdev  = ((gdev * gtotal) + (dev*total)) / (gtotal+total);
			//				
			//				gtotal += total;
			//
			//				if( i == 0)
			//				{
			//					gmin = min;
			//					gmax = max;
			//				}
			//				else
			//				{
			//					if( min < gmin) gmin = min;
			//					if( max > gmax) gmax = max;
			//				}
			//			}
			//			
			//			NSLog( @"%f\r%f\r%f\r%f\r%f", gtotal, gmean, gdev, gmin, gmax);
			
			long				memSize = 0;
			float				*totalPtr = nil;
			NSMutableArray		*rois = [NSMutableArray array];
			
			for( i = 0 ; i < [theSlices count]; i++)
			{
				DCMPix	*curPix = [[theSlices objectAtIndex: i] objectForKey:@"dcmPix"];
				ROI		*curROI = [[theSlices objectAtIndex: i] objectForKey:@"roi"];
				
				[rois addObject: curROI];
				
				long numberOfValues;
				
				float *tempPtr = [curPix getROIValue: &numberOfValues :curROI :nil];
				if( tempPtr)
				{
					float *newPtr = malloc( (memSize + numberOfValues)*sizeof( float));
					if( newPtr)
					{
						if( totalPtr)
							memcpy( newPtr, totalPtr, memSize * sizeof(float));
						
						free( totalPtr);
						totalPtr = newPtr;
						
						memcpy( newPtr + memSize, tempPtr, numberOfValues * sizeof(float));
						
						memSize += numberOfValues;
					}
					
					free( tempPtr);
				}
			}
			
			gtotal = 0;
			for( i = 0; i < memSize; i++)
			{
				gtotal += totalPtr[ i];
			}
			
			gmean = gtotal / memSize;
			
			gdev = 0;
			gmin = totalPtr[ 0];
			gmin = totalPtr[ 0];
			for( i = 0; i < memSize; i++)
			{
				float	val = totalPtr[ i];
				
				float temp = gmean - val;
				temp *= temp;
				gdev += temp;
				
				if( val < gmin) gmin = val;
				if( val > gmax) gmax = val;
			}
			gdev = gdev / (double) (memSize-1);
			gdev = sqrt( gdev);
			
			free( totalPtr);
			
			[data setObject: [NSNumber numberWithDouble: gmin] forKey:@"min"];
			[data setObject: [NSNumber numberWithDouble: gmax] forKey:@"max"];
			[data setObject: [NSNumber numberWithDouble: gmean] forKey:@"mean"];
			[data setObject: [NSNumber numberWithDouble: gtotal] forKey:@"total"];
			[data setObject: [NSNumber numberWithDouble: gdev] forKey:@"dev"];
			[data setObject: rois forKey:@"rois"];
		}
	

	return data;
}

-(NSMutableDictionary *) maxValueForROI: (ROI*)selectedROI withFrame:(long) frame threshold:(float)percent
{
	NSMutableDictionary *returnvalues = [NSMutableDictionary dictionaryWithCapacity:2];
	if ( (percent < 0.0) || (percent >100.)) return nil;
	long				i, x, globalCount, imageCount, lastImageIndex;
	double				volume, prevArea, preLocation, location, sliceInterval;
	ROI					*lastROI, *generatedROIs;
	
	BOOL				missingSlice = NO;
	NSMutableArray		*theSlices = [NSMutableArray array];
	NSMutableArray      *allpoints = [NSMutableArray array];
	BOOL				generateMissingROIs;
	generateMissingROIs = NO;
	generatedROIs = nil;
	NSString			**error;
	error = nil;
	
	
	lastROI = nil;
	lastImageIndex = -1;
	
	lastROI = nil;
	prevArea = 0;
	globalCount = 0;
	lastImageIndex = -1;
	preLocation = 0;
	location = 0;
	volume = 0;
	sliceInterval = [[pixList[frame] objectAtIndex: 0] sliceInterval];
	
	ROI *fROI = nil, *lROI = nil;
	int	fROIIndex, lROIIndex;
	ROI	*curROI = nil;
	
	for( x = 0; x < [pixList[frame] count]; x++)
	{
		imageCount = 0;
		
		location = x * sliceInterval;
		
		for( i = 0; i < [[roiList[frame] objectAtIndex: x] count]; i++)
		{   //yangyang determines ROI with same name
			curROI = [[roiList[frame] objectAtIndex: x] objectAtIndex: i];
			
			if( [[curROI name] isEqualToString: [selectedROI name]] == YES)		//&& [[curROI comments] isEqualToString:@"morphing generated"] == NO)
			{
				if( fROI == nil)
				{
					fROI = curROI;
					fROIIndex = x;
				}
				lROI = curROI;
				lROIIndex = x;
				
				globalCount++;
				imageCount++;
				
				DCMPix *curPix = [pixList[ frame] objectAtIndex: x];
				
				[curROI setPix: curPix];
				
				[theSlices addObject: [NSDictionary dictionaryWithObjectsAndKeys: curROI, @"roi", curPix, @"dcmPix", nil]];
				
				lastImageIndex = x;
				lastROI = curROI;
			}
		}
	}
	
	if( missingSlice) NSLog( @"**** Warning cannot compute data on a ROI with missing slices. Turn generateMissingROIs to TRUE to solve this.");
	else
	{
		long				memSize = 0;
		float				*totalPtr = nil;
		NSMutableArray		*rois = [NSMutableArray array];
		
		for( i = 0 ; i < [theSlices count]; i++)
		{
			DCMPix	*curPix = [[theSlices objectAtIndex: i] objectForKey:@"dcmPix"];
			ROI		*curROI = [[theSlices objectAtIndex: i] objectForKey:@"roi"];
			
			[rois addObject: curROI];
			
			long numberOfValues;
			
			float *tempPtr = [curPix getROIValue: &numberOfValues :curROI :nil];
			if( tempPtr)
			{
				float *newPtr = malloc( (memSize + numberOfValues)*sizeof( float));
				if( newPtr)
				{
					if( totalPtr)
						memcpy( newPtr, totalPtr, memSize * sizeof(float));
					
					free( totalPtr);
					totalPtr = newPtr;
					
					memcpy( newPtr + memSize, tempPtr, numberOfValues * sizeof(float));
					
					memSize += numberOfValues;
				}
				
				free( tempPtr);
			}
		}
		
		for( i = 0; i < memSize; i++) [allpoints addObject:[NSNumber numberWithFloat:totalPtr[i]]];
		[allpoints sortUsingFunction:firstNumSort context:NULL];
		NSLog(@"This is the array after sort: %@", allpoints);
		int count = [allpoints count];
		int arraynumber = ceil(count*percent/100);
		NSLog(@"this is the number for the %i min: %@", arraynumber, [allpoints objectAtIndex:arraynumber]);
		[returnvalues setObject:[allpoints objectAtIndex:arraynumber] forKey:@"low"];
		[returnvalues setObject:[allpoints objectAtIndex:0] forKey:@"high"];
		[returnvalues setObject:[allpoints objectAtIndex:[allpoints count]-1] forKey:@"min"];
		return returnvalues;
		free( totalPtr);		
	}
	return nil;
}

- (void) GenVolumefor: (ROI *) something
{
	long				i, x;
	float				volume = 0, preLocation, interval;
	ROI					*selectedROI = nil;
	NSMutableArray		*pts;
	
	[self computeInterval];
	
	[self displayAWarningIfNonTrueVolumicData];
	
	for( i = 0; i < maxMovieIndex; i++)
		[self saveROI: i];
	
	selectedROI = something;
	
	if( selectedROI == nil)
	{
		NSRunCriticalAlertPanel(NSLocalizedString(@"ROIs Volume Error", nil), NSLocalizedString(@"Select a ROI to compute volume of all ROIs with the same name.", nil) , NSLocalizedString(@"OK", nil), nil, nil);
		return;
	}
	
	// Check that sliceLocation is available and identical for all images
	preLocation = 0;
	interval = 0;
	
	for( x = 0; x < [pixList[curMovieIndex] count]; x++)
	{
		DCMPix *curPix = [pixList[ curMovieIndex] objectAtIndex: x];
		
		if( preLocation != 0)
		{
			if( interval)
			{
				if( fabs( [curPix sliceLocation] - preLocation - interval) > 1.0)
				{
					NSRunCriticalAlertPanel(NSLocalizedString(@"ROIs Volume Error", nil), NSLocalizedString(@"Slice Interval is not constant!", nil) , NSLocalizedString(@"OK", nil), nil, nil);
					return;
				}
			}
			interval = [curPix sliceLocation] - preLocation;
		}
		preLocation = [curPix sliceLocation];
	}
	
	NSLog(@"Slice Interval : %f", interval);
	
	if( interval == 0)
	{
		NSRunCriticalAlertPanel(NSLocalizedString(@"ROIs Volume Error", nil), NSLocalizedString(@"Slice Locations not available to compute a volume.", nil) , NSLocalizedString(@"OK", nil), nil, nil);
		return;
	}
	
	NSString	*error;
	int			numberOfGeneratedROI = [[self roisWithComment: @"morphing generated"] count];
	
	[self addToUndoQueue: @"roi"];
	NSLog(@"Error here?");
	WaitRendering *splash = [[WaitRendering alloc] init:NSLocalizedString(@"Preparing data...", nil)];
	[splash showWindow:self];
	
	// First generate the missing ROIs
	NSMutableArray *generatedROIs = [NSMutableArray array];
	NSMutableDictionary	*data = nil;
	
	data = [NSMutableDictionary dictionary];
	
	volume = [self computeVolume: selectedROI points:&pts generateMissingROIs: YES generatedROIs: generatedROIs computeData:data error: &error];
	
	// Show Volume Window
	if(error == nil)
	{
		ROIVolumeController	*viewer = [[ROIVolumeController alloc] initWithPoints:pts :volume :self roi: selectedROI];
		//yangyang volume and data output string
		[viewer showWindow: self];
		
		NSMutableString	*s = [NSMutableString string];
		
		if( [selectedROI name] && [[selectedROI name] isEqualToString:@""] == NO)
			[s appendString: [NSString stringWithFormat:NSLocalizedString(@"%@\r", nil), [selectedROI name]]];
		
		NSString *volumeString;
		
		if( volume < 0.01)
			volumeString = [NSString stringWithFormat:NSLocalizedString(@"Volume : %2.4f mm3", nil), volume*1000.];
		else
			volumeString = [NSString stringWithFormat:NSLocalizedString(@"Volume : %2.4f cm3", nil), volume];
		
		[s appendString: volumeString];
		
		[s appendString: [NSString stringWithFormat:NSLocalizedString(@"\rMean : %2.4f SDev: %2.4f Total : %2.4f", nil), [[data valueForKey:@"mean"] floatValue], [[data valueForKey:@"dev"] floatValue], [[data valueForKey:@"total"] floatValue]]];
		[s appendString: [NSString stringWithFormat:NSLocalizedString(@"\rMin : %2.4f Max : %2.4f ", nil), [[data valueForKey:@"min"] floatValue], [[data valueForKey:@"max"] floatValue]]];
		
		[viewer setDataString: s volume: volumeString];
		
		[[viewer window] center];
		
		//Delete the generated ROIs - There was no generated ROIs previously
		if( numberOfGeneratedROI == 0)
		{
			for( ROI *c in generatedROIs)
			{
				
				NSInteger index = [self imageIndexOfROI: c];
				
				if( index >= 0)
				{
					[[NSNotificationCenter defaultCenter] postNotificationName: OsirixRemoveROINotification object: c userInfo: nil];
					[[roiList[curMovieIndex] objectAtIndex: index] removeObject: c];
				}
			}
		}
	}
	else if(!error)
	{
		int	numberOfGeneratedROIafter = [[self roisWithComment:@"morphing generated"] count];
		if(!numberOfGeneratedROIafter)
			NSRunCriticalAlertPanel(NSLocalizedString(@"ROIs Volume Error", nil), NSLocalizedString(@"The missing ROIs were not created (this feature does not work with ROIs of types: Rectangles, Elipses and Axis).", nil), NSLocalizedString(@"OK", nil), nil, nil);
	}
	
	[splash close];
	[splash release];
	
	if( error)
	{
		NSRunCriticalAlertPanel(NSLocalizedString(@"ROIs Volume Error", nil), error , NSLocalizedString(@"OK", nil), nil, nil);
		return;
	}
}
	
@end
