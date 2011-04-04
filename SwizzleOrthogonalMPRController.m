//
//  SwizzleOrthgonalMPRController.m
//  3DROIManager
//
//  Created by Yang Yang on 1/26/11.
//  Copyright 2011 UCLA School of Medicine. All rights reserved.
//

#import "SwizzleOrthogonalMPRController.h"
#import <OsirixAPI/ROI.h>
#import <OsirixAPI/DCMView.h> //

@implementation SwizzleOrthogonalMPRController

- (void) setPixList: (NSArray*)pix :(NSArray*)files :(ViewerController*)vC
{

	if( originalDCMPixList) [originalDCMPixList removeAllObjects];
	else originalDCMPixList = [[NSMutableArray alloc] initWithCapacity: [pix count]];
	
	for( DCMPix *p in pix)
		[originalDCMPixList addObject:  [[p copy] autorelease]];
	
	[originalDCMFilesList release];
	originalDCMFilesList = [[NSMutableArray alloc] initWithArray:files];
	
	if( [vC blendingController] == nil || [[NSUserDefaults standardUserDefaults] integerForKey:@"PreclinicalAnalysis"])
	{
		[originalROIList release];
		
		// yang this adds ROIs onto fused images also
		if([[NSUserDefaults standardUserDefaults] integerForKey:@"PreclinicalAnalysis"]) originalROIList = 
			[[[[vC imageView] dcmRoiList] subarrayWithRange:NSMakeRange([[pix objectAtIndex:0] ID], [pix count])] retain];
		else originalROIList = [[[vC imageView] dcmRoiList] retain];
		
	}
	else
	{
		originalROIList = nil;
	}
		
	[reslicer release];
	reslicer = [[OrthogonalReslice alloc] initWithOriginalDCMPixList: originalDCMPixList];
}

- (NSMutableArray*) pointsROIAtX: (long) x
{
	NSMutableArray *rois = [originalView dcmRoiList];
	NSMutableArray *roisAtX = [NSMutableArray array];
	
	int i, j;
	for(i=0; i<[rois count]; i++)
	{
		for(j=0; j<[[rois objectAtIndex:i] count]; j++)
		{
			ROI *aROI = [[rois objectAtIndex:i] objectAtIndex:j];
			if([aROI type]==t2DPoint)
			{
				if([aROI.name hasSuffix:@"_center"] && [[NSUserDefaults standardUserDefaults] integerForKey:@"PreclinicalAnalysis"])
				{
					double radius = .5*[[[aROI.name componentsSeparatedByString:@"_"] objectAtIndex:1] doubleValue];
					NSString *name = [[aROI.name componentsSeparatedByString:@"_"] objectAtIndex:0]; 

					float change = fabs([[[aROI points] objectAtIndex:0] x]-x);
					if(change < radius) {
						ROI *newCircle = [[[ROI alloc] initWithType: tOval :[yReslicedView pixelSpacingX] :[yReslicedView pixelSpacingY] :NSMakePoint( [yReslicedView origin].x, [yReslicedView origin].y)] autorelease];
						float cutradius = sqrt(radius*radius-change*change);
						NSRect irect;
						irect.size.height = cutradius/[yReslicedView pixelSpacingY]; 
						irect.size.width = cutradius/[yReslicedView pixelSpacingX];
						irect.origin.x = [[[aROI points] objectAtIndex:0] y];
						long sliceIndex = (sign>0)? [[originalView dcmPixList] count]-1 -i : i;
						irect.origin.y = sliceIndex;
						
						ROI *border = [[[viewer viewerController] roisWithName:name in4D:YES] objectAtIndex:0];
						
						newCircle.locked = border.locked;
						[newCircle setROIRect:irect]; 
						[newCircle setName:name];
						[roisAtX addObject:newCircle];
					}
				}
				if([aROI.name hasSuffix:@"_ellipse"] && [[NSUserDefaults standardUserDefaults] integerForKey:@"PreclinicalAnalysis"])
				{
					NSString *xyz = [[aROI.name componentsSeparatedByString:@"_"] objectAtIndex:1];
					NSArray  *dimensions = [xyz componentsSeparatedByString:@","];
					double xrad = .5*[[dimensions objectAtIndex:0] doubleValue];
					double yrad = .5*[[dimensions objectAtIndex:1] doubleValue];
					double zrad = .5*[[dimensions objectAtIndex:2] doubleValue];

					//this is in yrescliced view: x,y,z -> y,z,x
					
 					float change = fabs([[[aROI points] objectAtIndex:0] x]-x);
					if(change < xrad) {
						ROI *newCircle = [[[ROI alloc] initWithType: tOval :[yReslicedView pixelSpacingX] :[yReslicedView pixelSpacingY] :NSMakePoint( [yReslicedView origin].x, [yReslicedView origin].y)] autorelease];
						double t = asin(change/xrad);
						double newyradius = yrad*cos(t);
						double newzradius = zrad*cos(t);
						NSRect irect;
						irect.size.height = newzradius/[yReslicedView pixelSpacingY]; 
						irect.size.width = newyradius/[yReslicedView pixelSpacingX];
						irect.origin.x = [[[aROI points] objectAtIndex:0] y];
						long sliceIndex = (sign>0)? [[originalView dcmPixList] count]-1 -i : i;
						irect.origin.y = sliceIndex;
						
						
						NSString * name =[[aROI.name componentsSeparatedByString:@"_"] objectAtIndex:0];
						ROI *border = [[[viewer viewerController] roisWithName:name in4D:YES] objectAtIndex:0];
						
						newCircle.locked = border.locked;
						[newCircle setROIRect:irect]; 
						[newCircle setName:name];
						[roisAtX addObject:newCircle];
					}
				}
				
				if((long)([[[aROI points] objectAtIndex:0] x])==x)
				{
					ROI *new2DPointROI = [[[ROI alloc] initWithType: t2DPoint :[yReslicedView pixelSpacingX] :[yReslicedView pixelSpacingY] :NSMakePoint( [yReslicedView origin].x, [yReslicedView origin].y)] autorelease];
					NSRect irect;
					irect.origin.x = [[[aROI points] objectAtIndex:0] y];
					long sliceIndex = (sign>0)? [[originalView dcmPixList] count]-1 -i : i; // i is slice number
					irect.origin.y = sliceIndex; // i is slice number
					irect.size.width = irect.size.height = 0;
					[new2DPointROI setROIRect:irect];
					[new2DPointROI setParentROI:aROI];
					// copy the name
					[new2DPointROI setName:[aROI name]];
					// add the 2D Point ROI to the ROI list
					[roisAtX addObject:new2DPointROI];
				}
			}
			if([aROI type]==tPlain && [[NSUserDefaults standardUserDefaults] integerForKey:@"PreclinicalAnalysis"])
			{	
				BOOL existing = NO;
				int k=0;
				while(k<[roisAtX count] && !existing){
					ROI *tplain = [roisAtX objectAtIndex:k];
					if ([[aROI name] isEqualToString: [tplain name]]){//does this roi name already exist in stack?
						existing = YES;
						int m;
						NSMutableArray *allthepoints = [aROI points];
						
						for(m=0;m<[allthepoints count];m++){ //find points in X
							if((long)([[allthepoints objectAtIndex:m] x])==x){
								[tplain setROIMode:ROI_selectedModify];
								long sliceIndex = (sign>0)? [[originalView dcmPixList] count]-1 -i : i; // i is slice number
								NSPoint addpoint = {[[allthepoints objectAtIndex:m] y], sliceIndex};
								//add point to tplain
								[tplain mouseRoiDragged:addpoint :256 :[originalView pixelSpacingX]];
							}
						}
					}
					else k++;
				}
				if(!existing){
					int m; BOOL first = YES;
					NSMutableArray *allthepoints = [aROI points];
					ROI *newtplain = [[[ROI alloc] initWithType: tPlain :[yReslicedView pixelSpacingX] :[yReslicedView pixelSpacingY] :NSMakePoint( [yReslicedView origin].x, [yReslicedView origin].y)] autorelease];
					for(m=0;m<[allthepoints count];m++){						
						NSLog(@"X:%f",[[allthepoints objectAtIndex:m] x]);
						if((long)([[allthepoints objectAtIndex:m] x])==x){ //is point in x?
							if (first) { //first point found needs to create new tplain
								first = NO;
								long sliceIndex = (sign>0)? [[originalView dcmPixList] count]-1 -i : i; // i is slice number
								NSPoint firstpoint = {[[allthepoints objectAtIndex:m] y], sliceIndex};
								[newtplain mouseRoiDown:firstpoint :[originalView pixelSpacingX]];
								[newtplain setName:[aROI name]];
							}
							else { //other points found will be added to newly created tplain
								[newtplain setROIMode:ROI_selectedModify];
								long sliceIndex = (sign>0)? [[originalView dcmPixList] count]-1 -i : i; // i is slice number
								NSPoint addpoint = {[[allthepoints objectAtIndex:m] y], sliceIndex};
								[newtplain mouseRoiDragged:addpoint :256 :[originalView pixelSpacingX]];
							}
						}
					}
					if(!first) [roisAtX addObject:newtplain]; //if at least one point, add roi to stack.
					
				}
			}			
		}
	}
	
	return roisAtX;
}

- (NSMutableArray*) pointsROIAtY: (long) y
{
//	NSLog(@"Swizzling OrthoMPRController pointsAtY:");
	NSMutableArray *rois = [originalView dcmRoiList];
	NSMutableArray *roisAtY = [NSMutableArray array];
	
	int i, j;
	for(i=0; i<[rois count]; i++)
	{
		for(j=0; j<[[rois objectAtIndex:i] count]; j++)
		{
			ROI *aROI = [[rois objectAtIndex:i] objectAtIndex:j];
			if([aROI type]==t2DPoint)
			{
			
				if([[aROI name] hasSuffix:@"_center"]){
					
					double radius = .5*[[[aROI.name componentsSeparatedByString:@"_"] objectAtIndex:1] doubleValue];
					NSString *name = [[aROI.name componentsSeparatedByString:@"_"] objectAtIndex:0]; 

 					float change = [[[aROI points] objectAtIndex:0] y]-y;
 					
 					if(fabs(change) < radius) {
	 					ROI *newCircle = [[[ROI alloc] initWithType: tOval :[xReslicedView pixelSpacingX] :[xReslicedView pixelSpacingY] :NSMakePoint( [xReslicedView origin].x, [xReslicedView origin].y)] autorelease];
						float cutradius = sqrt(radius*radius-change*change);
						NSRect irect;
						irect.size.height = cutradius/[xReslicedView pixelSpacingY]; irect.size.width = cutradius/[xReslicedView pixelSpacingX];
						irect.origin.x = [[[aROI points] objectAtIndex:0] x];
						long sliceIndex = (sign>0)? [[originalView dcmPixList] count]-1 -i : i; // i is slice number
						irect.origin.y = sliceIndex;
						
						ROI *border = [[[viewer viewerController] roisWithName:name in4D:YES] objectAtIndex:0];
					 	
						newCircle.locked = border.locked;
						[newCircle setROIRect:irect]; 
						[newCircle setName:name];
						[roisAtY addObject:newCircle];
						
					}
 				}
				else if([aROI.name hasSuffix:@"_ellipse"])
				{
					NSString *xyz = [[aROI.name componentsSeparatedByString:@"_"] objectAtIndex:1];
					NSArray  *dimensions = [xyz componentsSeparatedByString:@","];
					double xrad = .5*[[dimensions objectAtIndex:0] doubleValue];
					double yrad = .5*[[dimensions objectAtIndex:1] doubleValue];
					double zrad = .5*[[dimensions objectAtIndex:2] doubleValue];
					
					//this is in xrescliced view: x,y,z -> x,z,y
					
					float change = fabs([[[aROI points] objectAtIndex:0] y]-y);
					if(change < yrad) {
						ROI *newCircle = [[[ROI alloc] initWithType: tOval :[yReslicedView pixelSpacingX] :[yReslicedView pixelSpacingY] :NSMakePoint( [yReslicedView origin].x, [yReslicedView origin].y)] autorelease];
						double t = asin(change/yrad);
						double newxradius = xrad*cos(t);
						double newzradius = zrad*cos(t);
						NSRect irect;
						irect.size.height = newzradius/[xReslicedView pixelSpacingY]; 
						irect.size.width = newxradius/[xReslicedView pixelSpacingX];
						irect.origin.x = [[[aROI points] objectAtIndex:0] x];
						long sliceIndex = (sign>0)? [[originalView dcmPixList] count]-1 -i : i;
						irect.origin.y = sliceIndex;
						

						NSString *name = [[aROI.name componentsSeparatedByString:@"_"] objectAtIndex:0];
						ROI *border = [[[viewer viewerController] roisWithName:name in4D:YES] objectAtIndex:0];
						
						newCircle.locked = border.locked;
						[newCircle setROIRect:irect]; 
						[newCircle setName:name];
						[roisAtY addObject:newCircle];
					}
				}
				
				if((long)([[[aROI points] objectAtIndex:0] y])==y)
				{
					ROI *new2DPointROI = [[[ROI alloc] initWithType: t2DPoint :[xReslicedView pixelSpacingX] :[xReslicedView pixelSpacingY] :NSMakePoint( [xReslicedView origin].x, [xReslicedView origin].y)] autorelease];
					NSRect irect;
					irect.origin.x = [[[aROI points] objectAtIndex:0] x];
					long sliceIndex = (sign>0)? [[originalView dcmPixList] count]-1 -i : i; // i is slice number
					irect.origin.y = sliceIndex;
					irect.size.width = irect.size.height = 0;
					[new2DPointROI setROIRect:irect];
					[new2DPointROI setParentROI:aROI];
					// copy the name
					[new2DPointROI setName:[aROI name]];
					// add the 2D Point ROI to the ROI list
					[roisAtY addObject:new2DPointROI];
				}
			}
			if([aROI type]==tPlain && [[NSUserDefaults standardUserDefaults] integerForKey:@"PreclinicalAnalysis"])
			{	
 				[[NSUserDefaults standardUserDefaults] setFloat:1.0 forKey:@"ROIRegionThickness"]; //sets so only draws in single point
 				BOOL existing = NO;
 				int k=0;
 				while(k<[roisAtY count] && !existing){//does the tplain roi already exist?
					ROI *tplain = [roisAtY objectAtIndex:k];
					if ([[aROI name] isEqualToString: [tplain name]]){
						existing = YES;
						int m;
						NSMutableArray *allthepoints = [aROI points];
						
						for(m=0;m<[allthepoints count];m++){ //check if any points in roi are at y
							if((long)([[allthepoints objectAtIndex:m] y])==y){
								[tplain setROIMode:ROI_selectedModify];
								long sliceIndex = (sign>0)? [[originalView dcmPixList] count]-1 -i : i; // i is slice number
								NSPoint addpoint = {[[allthepoints objectAtIndex:m] x], sliceIndex};
								//if so, add point to newly created tplain 
								[tplain mouseRoiDragged:addpoint :256 :[originalView pixelSpacingY]];
								//modifier:256, scale: 4.058474
							}
						}
					}
					else k++;
 				}
 				if(!existing){
					int m; BOOL first = YES;
					NSMutableArray *allthepoints = [aROI points];
					ROI *newtplain = [[[ROI alloc] initWithType: tPlain :[yReslicedView pixelSpacingX] :[yReslicedView pixelSpacingY] :NSMakePoint( [yReslicedView origin].x, [yReslicedView origin].y)] autorelease];
					for(m=0;m<[allthepoints count];m++){						
						NSLog(@"Y:%f",[[allthepoints objectAtIndex:m] y]); //is point at Y?
						if((long)([[allthepoints objectAtIndex:m] y])==y){
							if (first) { //first point found, needs to create new tplain
								first = NO;
								long sliceIndex = (sign>0)? [[originalView dcmPixList] count]-1 -i : i; // i is slice number
								NSPoint firstpoint = {[[allthepoints objectAtIndex:m] x], sliceIndex};
								[newtplain mouseRoiDown:firstpoint :[originalView pixelSpacingY]];
								[newtplain setName:[aROI name]];
							}
							else { //other points, add to newly createdtplain
								[newtplain setROIMode:ROI_selectedModify];
								long sliceIndex = (sign>0)? [[originalView dcmPixList] count]-1 -i : i; // i is slice number
								NSPoint addpoint = {[[allthepoints objectAtIndex:m] x], sliceIndex};
								[newtplain mouseRoiDragged:addpoint :256 :[originalView pixelSpacingY]];
 								
							}
						}
					}
 					if(!first) [roisAtY addObject:newtplain]; //if there is one point, add to stack.
					
 				}
 			}
		}
	}
	
	return roisAtY;
}
@end
