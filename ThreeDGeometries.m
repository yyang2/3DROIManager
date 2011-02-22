//
//  ThreeDGeometries.m
//  GenerateSphere
//
//  Created by Yang Yang on 4/1/10.
//  Copyright 2010 UCLA Molecular and Medical Pharmacology. All rights reserved.
//

#import "ThreeDGeometries.h"
#import "ViewerController+Yang.h"
#import "ITKSegmentation3DController+Yang.h"
#import "ThreeDROIManagerController.h"

#import <OsiriX Headers/ROI.h>
#import "VRController+Yang.h"
#import <OsiriX Headers/VRView.h>
#import <OsiriX Headers/ViewerController.h>
#import <OsiriX Headers/Notifications.h>
#import <OsiriX Headers/DCMPix.h>
#import <OsiriX Headers/DCMView.h>
#import <OsiriX Headers/ITKSegmentation3D.h>
#import <OsiriX Headers/OrthogonalMPRController.h>
#import <OsiriX Headers/OrthogonalMPRPETCTController.h>
#import <OsiriX Headers/OrthogonalMPRPETCTViewer.h>
#import <OsiriX Headers/OrthogonalMPRView.h>
@class ROI;



@implementation ThreeDGeometries

#pragma mark Init and dealloc

- (void) awakeFromNib {

	//set up slider for diameter of spheres before displaying window
	DCMPix *firstDCMPix = [[tempViewer pixList] objectAtIndex: 1];
	float minValue = [firstDCMPix sliceInterval] +.01;
	[diameterSlider setMinValue:minValue];
	
	
}
-(id) initWithViewers:(ViewerController *) v :(VRController *) D3 :(BOOL) isfusion :(id) secondviewer:(ThreeDROIManagerController*)c {
	
	// main class that handles the drawing and movement of all 3D Geometries for 3DROIManager.

	tempViewer = [v retain];
	if (isfusion)	{ FusionOrthoView = secondviewer;}
	else			{ orthoView = secondviewer;}
	D3View = [D3 retain];
	
	controller = c;

	//initialize window with location and names
	NSRect mainscreen = [[NSScreen mainScreen] frame];
	NSPoint TopLeft = NSMakePoint(mainscreen.size.width/2-100.0, 300);
	self = [super initWithWindowNibName:@"Geometries"];
	[[self window] setFrameTopLeftPoint:TopLeft];
	[[self window] setTitle: [NSString stringWithFormat:@"%@",[[tempViewer window] title]]];

	NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];	
	
	[nc addObserver: self selector: @selector(MoveObject:) name: OsirixROIChangeNotification object: nil];
	
	//init slider+text
	[diameterSlider setFloatValue:2.f];
	[diameterText setStringValue:[NSString stringWithFormat:@"2.0"]];
	[nameText setStringValue:@"Unnamed"];

	return self;
}

-(void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
	[[self window] close];
	[tempViewer release];
	[D3View release];

	[super dealloc];
}


#pragma mark -
#pragma mark Spheres

- (IBAction) changePreviewRadius: (id)sender
{
	[diameterText takeFloatValueFrom:diameterSlider];	
	
	if([D3View.view isAny3DPointSelected]){
		//update VR Size of selected 3D Point
		[D3View.view setNeedsDisplay:YES];
		[D3View.view setSelected3DPointRadius: diameterSlider.floatValue/2.f];
	}
	
}

- (IBAction) changeDefaultRadius: (id)sender 
{
	[[NSUserDefaults standardUserDefaults] setFloat:[diameterText floatValue]/2 forKey:@"points3Dradius"];
}

- (IBAction) generateSphere: (id)sender
{
	ROI		*threeDROI=nil;
	ROI		*selectedROI;
	float	sliceLocation = -1.f;
	
	if(![self validName:[nameText stringValue]:YES]) return;
	// get orthoROI
	ROI		*orthoROI = [self RoiInOrthoView];
	if(orthoROI)
	{
		//check validity of ROI
		NSArray *temparray = [tempViewer roisWithName:[orthoROI name]];
		if([[orthoROI name] hasSuffix:@"_center"] || [temparray count] > 1) orthoROI=nil;
	}
	
	// get threeDROI
	if([D3View.view isAny3DPointSelected]){
		float position[3];
		[[[D3View.view get3DPositionArray] objectAtIndex:[D3View.view selected3DPointIndex]] getValue:position];
		NSDictionary *temp = [self get2DCoordinates:position[0] :position[1] :position[2]];
		threeDROI = [temp objectForKey:@"ROI"];
		sliceLocation = [[temp objectForKey:@"SliceLocation"] floatValue];
		
		//check validity of ROI - ie make sure it's not
		if([[threeDROI name] hasSuffix:@"_center"]) {
			threeDROI = nil;
			sliceLocation = -1.f;
		}
	}
	
	NSLog(@"orthoROI: %@ threeDROI: %@", orthoROI, threeDROI);
	// if only one view has ROI, use it
	if(orthoROI && !threeDROI) selectedROI = orthoROI;
	else if(!orthoROI && threeDROI) selectedROI = threeDROI;
	else if(orthoROI && threeDROI)
	{
		NSLog(@"Two Selected ROIs,");
		// if both are selected, throw a fit unless its both ROIs have the same name, meaning they are the same thing;
		
		if (orthoROI.name == threeDROI.name)  
			selectedROI = threeDROI;
		else {
			NSAlert *myAlert = [NSAlert alertWithMessageText:@"Conflicting ROIs Selected On 3D and Orthogonal Views, deselect one and try again" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@""]; 
			[myAlert runModal];
			return; }
	}
	else //	None selected, proper error message.
	{
		
		NSAlert *myAlert = [NSAlert alertWithMessageText:@"No Valid ROIs Selected" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@""]; 
		[myAlert runModal];
		return;
	}
	
	
	
	// make it into a point if circle is selected;
	if([selectedROI type] == tOval)
	{
		if([useTextField state] != NSOnState) [diameterSlider setFloatValue:selectedROI.rect.size.width];
		selectedROI = [self makePointForOval:selectedROI];
	}
	
	if(sliceLocation <0) {
		selectedROI = [[tempViewer roisWithName:[selectedROI name]] objectAtIndex:0];
		sliceLocation = [[selectedROI pix] ID];
	}
	
	NSLog(@"selectedROI name before:%@", [selectedROI name]);
	if(!selectedROI) 
	{
		NSLog(@"Uh, you really shouldn't be here");
		return;
	}
	
	float diam = [diameterSlider floatValue];
	NSString* name = [nameText stringValue];
	
	[self makeSphereWithName:name center:selectedROI atSlice:sliceLocation  withRadius:diam/2.f];
	[D3View.view unselectAllActors];
	[self resetsphere];
	
}

-(void) resetsphere 
{
	[nameText setStringValue:@""];	
}
-(NSString*) sphereName:(NSString*)n :(float)diameter
{
	return [NSString stringWithFormat:@"%@_%2.3f_center",n,diameter];
}

- (NSString*) nameForSphere:(NSString*)r
{
	if (![r hasSuffix:@"center"]) return nil;
	else if ([r length] < 14) return nil;
	
	NSString * name =[r substringWithRange:NSMakeRange(0, [r length] - 13)];
	
	if ([name hasSuffix:@"_"])
		name =[r substringWithRange:NSMakeRange(0, [r length] - 14)];
	
	return name;
}

- (float) diameterForSphere: (NSString*)r
{
	if (![r hasSuffix:@"center"]) return -1.f;
	else if ([r length] < 14) return -1.f;
	
	NSString *diameter = [r substringWithRange:NSMakeRange([r length] - 13, 6)];
	
	if ([diameter hasPrefix:@"_"])
		return [[diameter substringWithRange:NSMakeRange(1, 4)] floatValue];
	else
		return [diameter floatValue];
}

-(ROI*)makePointForOval:(ROI*)circle

{	
	int cur = [[FusionOrthoView CTController] currentTool];
	if(FusionOrthoView)
	{
		//changing tool to point ROI, making a new ROI, and then simulating a mouseclick to add point ROI at center of circle
		[(OrthogonalMPRController *)[FusionOrthoView CTController] setCurrentTool:19];
		ROI *newPtROI = [[[ROI alloc] initWithType: t2DPoint : [[[FusionOrthoView keyView] curDCM] pixelSpacingX] :
						  [[[FusionOrthoView keyView] curDCM] pixelSpacingY]: [circle imageOrigin]] autorelease];
		[newPtROI setName: [nameText stringValue]];
		[newPtROI setROIMode:ROI_selected];
		[newPtROI mouseRoiDown:NSMakePoint(circle.rect.origin.x, circle.rect.origin.y) :[[orthoView keyView] curImage] :1.0];
		
		
		//proper notification for adding ROI, so every view gets updated
		[[[FusionOrthoView keyView] curRoiList] addObject:newPtROI];
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:	newPtROI, @"ROI",
								  [NSNumber numberWithInt:[[FusionOrthoView keyView] curImage]],	@"sliceNumber", 
								  nil];
		
		[[NSNotificationCenter defaultCenter] postNotificationName: OsirixAddROINotification object: [FusionOrthoView keyView] userInfo:userInfo];
		
		//remove old circle
		[[[FusionOrthoView keyView] curRoiList] removeObject:circle];
		
		//restore original tool
		[[FusionOrthoView CTController] setCurrentTool:cur];
		return newPtROI;
	}
	else
	{
		//changing tool to point ROI, making a new ROI, and then simulating a mouseclick to add point ROI at center of circle
		[[orthoView controller] setCurrentTool:19];
		[(OrthogonalMPRController *)[orthoView controller] setCurrentTool:19];
		ROI *newPtROI = [[[ROI alloc] initWithType: t2DPoint : [[[orthoView keyView] curDCM] pixelSpacingX] :
						  [[[orthoView keyView] curDCM] pixelSpacingY]: [circle imageOrigin]] autorelease];
		[newPtROI setName: [nameText stringValue]];
		[newPtROI setROIMode:ROI_selected];
		[newPtROI mouseRoiDown:NSMakePoint(circle.rect.origin.x, circle.rect.origin.y) :[[orthoView keyView] curImage] :1.0];
		
		//proper notification for adding ROI, so every view gets updated
		[[[orthoView keyView] curRoiList] addObject:newPtROI];
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:	newPtROI, @"ROI",
								  [NSNumber numberWithInt:[[orthoView keyView] curImage]],	@"sliceNumber", 
								  //xx, @"x", yy, @"y", zz, @"z",
								  nil];
		[[NSNotificationCenter defaultCenter] postNotificationName: OsirixAddROINotification object: [orthoView keyView] userInfo:userInfo];
		
		//remove old circle
		[[[orthoView keyView] curRoiList] removeObject:circle];
		
		//restore original tool
		[[orthoView controller] setCurrentTool:cur];
		return newPtROI;
	}
}


- (void) MoveSphere: (ROI *) center :(ROI *) planar
{
	
	ROI *newCenter;
	center.locked = FALSE;
	int sliceZ = -1; int lastoffset=0; id view;
	
	NSRect trueposition;
	
	//creates new point with right pixelspacing, based on either fusion or regular MPR
	if(FusionOrthoView){		
		view = [FusionOrthoView keyView];
		newCenter = [[ROI alloc] initWithType: t2DPoint :[[[FusionOrthoView CTController] originalView] pixelSpacingX] :
					 [[[FusionOrthoView CTController] originalView] pixelSpacingY] :
					 NSMakePoint( [[[FusionOrthoView CTController] originalView] origin].x, 
								 [[[FusionOrthoView CTController] originalView] origin].y)];
		lastoffset = controller.maxSlices - (int)[[[[FusionOrthoView PETCTController] originalDCMPixList] lastObject] ID];
		NSLog(@"last %i, first %i", (int)[[[[FusionOrthoView PETCTController] originalDCMPixList] lastObject] ID], (int)[[[[FusionOrthoView PETCTController] originalDCMPixList] objectAtIndex:0] ID]);
	}
	else
	{
		view = [orthoView keyView];
		newCenter = [[ROI alloc] initWithType: t2DPoint :[[[orthoView controller] originalView] pixelSpacingX] :
					 [[[orthoView controller] originalView] pixelSpacingY] :
					 NSMakePoint( [[[orthoView controller] originalView] origin].x, 
								 [[[orthoView controller] originalView] origin].y)];
		
		
	}
	
	//adds all centers and circles for deletion later on
	NSMutableArray *deletestack = [NSMutableArray arrayWithArray:[tempViewer roisWithName:planar.name in4D:YES]];
	[deletestack addObjectsFromArray:[tempViewer roisWithName:center.name in4D:YES]];
	
	[newCenter setName:center.name];
	[self getPosition:view : &trueposition : planar :center : &sliceZ : lastoffset];
	
	// if not enough changes, do not draw another sphere
	NSLog(@"xchange: %f, ychange: %f, zchange %f", fabs(center.rect.origin.x - trueposition.origin.x), fabs(center.rect.origin.y - trueposition.origin.y), fabs((float)[[center pix] ID] - (float)sliceZ));
	if (fabs(center.rect.origin.x - trueposition.origin.x) < .35 && fabs(center.rect.origin.y - trueposition.origin.y) < .35 && fabs((float)[[center pix] ID] - (float)sliceZ) < 1)
	{
		[newCenter release];
		return;
	}
	
	
	if(sliceZ)
	{
		[newCenter setROIRect:trueposition];
		
		[[[tempViewer roiList:controller.activeFrame] objectAtIndex:sliceZ] addObject:newCenter];
		
		float diam = [self diameterForSphere:newCenter.name];
		
		[self makeSphereWithName:planar.name center:newCenter atSlice:sliceZ withRadius:diam/2.f];
		
		//adds old ROIs to the deletelaterlist, will be deleted by -controller tabulateallROIs on next refresh.
		int i;

		for(i=0; i< [deletestack count]; i++)
			[controller.deleteLaterList addObject:[deletestack objectAtIndex:i]];
	}
	
	newCenter.release;
}


-(BOOL) makeSphereWithName:(NSString*)name center:(ROI *)center atSlice:(long)currentSlice withRadius:(float)radius
{
	center.locked = NO;

	//checks center name
	NSRange  empty = {NSNotFound, 0};
	if (NSEqualRanges([center.name rangeOfString:@"_"],empty) || NSEqualRanges([center.name rangeOfString:@","],empty))
		center.name = [self sphereName:name :radius*2];
	
	float sliceInterval = [[[tempViewer pixList:0] objectAtIndex: 1] sliceInterval];
	int totalmovement = ceil(radius/sliceInterval);
	
	if (currentSlice + totalmovement > controller.maxSlices || currentSlice - totalmovement < 1){
		NSAlert *Error = [NSAlert alertWithMessageText:@"ROI goes outside image bounds!" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Sphere goes outside image bounds"]; [Error runModal];
		return NO;
	}
	
	NSPoint origin = [center imageOrigin];
	float xSpacing = [[[tempViewer pixList:0] objectAtIndex:0] pixelSpacingX];
	float ySpacing = [[[tempViewer pixList:0] objectAtIndex:0] pixelSpacingY];
	float xpos = center.rect.origin.x; float ypos = center.rect.origin.y;
	NSRect newrect = NSMakeRect(xpos, ypos, radius/xSpacing, radius/ySpacing);
	
	//create and set temporary ROI location + width
	ROI *tempROI= [[[ROI alloc]  initWithType:tOval : xSpacing: ySpacing: origin] autorelease];
	[tempROI setROIRect:newrect];
	[tempROI setName:name];
	
	int j;
	for(j=0; j<[tempViewer maxMovieIndex]; j++) //needs to do this for all time frames
	{ 
		if(![[[tempViewer roiList:j] objectAtIndex:currentSlice] containsObject:center]) 
			[[[tempViewer roiList:j] objectAtIndex:currentSlice] addObject:center];	
		
		[tempROI setPix: [[tempViewer pixList:j] objectAtIndex:currentSlice]];
		[[[tempViewer roiList:j] objectAtIndex:currentSlice] addObject:tempROI];
		[[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:tempROI userInfo: nil];
		
		int delta;
		for(delta=1; delta <totalmovement; delta++){																				
			//this is the actual loop for each individual ROI drawn
			double deltaz = delta*sliceInterval;                                                                                           
			double newradius = sqrt(radius*radius-deltaz*deltaz);                                                                          
			ROI *upperROI =[[[ROI alloc]  initWithType:tOval : xSpacing: ySpacing: origin] autorelease];                                         
			ROI *lowerROI =[[[ROI alloc]  initWithType:tOval : xSpacing: ySpacing: origin] autorelease];
			NSRect newrect = NSMakeRect(xpos, ypos, newradius/xSpacing, newradius/ySpacing);
			
			[upperROI setROIRect:newrect]; [upperROI setName:name];
			[lowerROI setROIRect:newrect]; [lowerROI setName:name];
			upperROI.locked = NO; lowerROI.locked = NO;
			DCMPix	*upperpix, *lowerpix;
			
			upperpix = [[tempViewer pixList:j] objectAtIndex:currentSlice+delta];
			lowerpix = [[tempViewer pixList:j] objectAtIndex:currentSlice-delta];
			
			[upperROI setPix: upperpix];
			[lowerROI setPix: lowerpix];
			
			[[[tempViewer roiList:j] objectAtIndex:(currentSlice + delta)] addObject:upperROI];                                      
			[[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:upperROI userInfo: nil];			
			
			[[[tempViewer roiList:j] objectAtIndex:(currentSlice - delta)] addObject:lowerROI];                                      
			[[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:lowerROI userInfo: nil];
		}
	}
	[D3View computeROIVolumes]; //include this to update ROI volumes in VRController. or else the ROI manager won't recognize the newly added ones
	center.locked = YES;
	return YES;
}

#pragma mark -
#pragma mark Mask
//
//- (IBAction) generateMask: (id)sender{
//	
//	//	set tool to closed polygon
//	[tempViewer setROIToolTag:25];
//	[[tempViewer imageView] setCurrentTool: 25];
//	[[tempViewer window] makeKeyAndOrderFront:nil];
//	
//	NSRect mainscreen = [[NSScreen mainScreen] frame];
//	
//	NSRect  RightPanel = NSMakeRect(0.0, 0.0, mainscreen.size.width*.5, mainscreen.size.height*.7);
//	NSPoint TopLeft = NSMakePoint(mainscreen.size.width*.5, mainscreen.size.height-20.0);
//	
//	[[tempViewer window] setFrame:RightPanel display:NO];
//	[[tempViewer window] setFrameTopLeftPoint:TopLeft];
//	
//	[MaskWindow setFrameTopLeftPoint:TopLeft];
//	[MaskWindow makeKeyAndOrderFront:self];
//	
//}
//
//- (IBAction) cancelMask: (id)sender
//{	
//	[[tempViewer window] performMiniaturize:self];
//	[MaskWindow close];
//}
//
//- (IBAction) applyMask: (id)sender{
//	if ([isocontour floatValue] > 0.0 && [isocontour floatValue] < 100.0) {
//		short allrois = 0;
//		BOOL propagatein4D = NO; BOOL outside = YES;
//		int curindex = [tempViewer curMovieIndex];
//		NSPoint pt = [[tempViewer selectedROI] centroid];
//		
//		//get intervals for isocontour
//		NSMutableDictionary *interval = [NSMutableDictionary dictionaryWithCapacity:2];
//		interval = [tempViewer maxValueForROI:[tempViewer selectedROI] withFrame:curindex threshold:[isocontour floatValue]];
//		float min = [[interval objectForKey:@"min"] floatValue];
//		
//		[tempViewer roiSetPixels:[tempViewer selectedROI] :allrois :propagatein4D :outside :FLT_MIN :FLT_MAX :min -.1 :NO];
//		[[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateVolumeDataNotification object: [tempViewer pixList] userInfo: nil];		
//		
//		
//		float low = [[interval objectForKey:@"low"] floatValue];
//		float high = [[interval objectForKey:@"high"] floatValue];
//		NSString *maskname = [[tempViewer selectedROI] name];
//		long slice=-1;
//		
//		
//		int i;
//		[tempViewer roiIntDeleteAllROIsWithSameName: maskname];
//		
//		for(i = 0; i < [tempViewer maxMovieIndex]; i++)
//		{
//			if( i == [tempViewer curMovieIndex])
//			{
//				ITKSegmentation3D	*itk = [[ITKSegmentation3D alloc] initWith:[tempViewer pixList] :[tempViewer volumePtr] :slice];
//				if( itk)
//				{			
//					// an array for the parameters
//					int algo = 1;
//					NSMutableArray *parametersArray = [NSMutableArray arrayWithCapacity:2] ;
//					[parametersArray addObject:[NSNumber numberWithFloat:low]];
//					[parametersArray addObject:[NSNumber numberWithFloat:high]];				
//					[itk regionGrowing3D	: tempViewer
//										 : nil
//										 : -1
//										 : pt
//										 : algo
//										 : parametersArray //[[params cellAtIndex: 2] floatValue]
//										 : NO
//										 : 1000.0
//										 : NO
//										 : 0.0
//										 : 0
//										 : 6
//										 : [isoname stringValue]
//										 : NO
//					 ];
//					
//					[itk release];
//				}
//			}
//		}
//		//Undo all that masking!
//		[tempViewer executeRevert];
//		//update ROIVolumes!
//		[D3View computeROIVolumes];
//		[self cancelMask:self];
//	}
//	else {
//		NSAlert *myAlert = [NSAlert alertWithMessageText:@"Error" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please enter valid isocontour percentage"];
//		[myAlert runModal];
//	}
//}

#pragma mark -
#pragma mark Shape Movement


- (void) MoveObject:(NSNotification *)note 
{
	ROI *planarObject	= [note object];
	ROI *centerObject	= nil;
	if(planarObject.locked || planarObject.ROImode != ROI_selected || ![[[note userInfo] objectForKey:@"action"] isEqualToString:@"mouseUp"] || [planarObject.name hasPrefix:@"Oval"])
			return;
	
	int i=0;
	
	while (!centerObject)
	{
		if (i>[controller.centerList count]) return;
	
		if ([[[controller.centerList objectAtIndex:i] name] hasPrefix:planarObject.name]) 
			centerObject = [controller.centerList objectAtIndex:i];
		i++;
		
	}

	
	if ([centerObject.name hasSuffix:@"center"]) 
	{
		[self MoveSphere:centerObject :planarObject];
	}
	else if ([centerObject.name hasSuffix:@"ellips"])
	{
		// do ellipsoid
	}
	
	return;
	
}



#pragma mark -
#pragma mark Utilities

-(BOOL) validName:(NSString *) name :(BOOL) runalert
{
	//checks the input name
	NSRange  empty = {NSNotFound, 0};
	NSAlert *myAlert = nil;
	
	if (!NSEqualRanges([name rangeOfString:@","],empty))
		myAlert = [NSAlert alertWithMessageText:@"Invalid Name" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"ROI names cannot have commas"];
	else if (!NSEqualRanges([name rangeOfString:@"_"],empty))
		myAlert = [NSAlert alertWithMessageText:@"Invalid Name" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"ROI names cannot have '_' "];
	else if ([name isEqualToString:@"Unnamed"] || [name isEqualToString:@""])
		myAlert = [NSAlert alertWithMessageText:@"Invalid Name" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"ROIs must be named"];
	else if ([name isEqualToString:@"Oval"] || [name isEqualToString:@"Point"])
		myAlert = [NSAlert alertWithMessageText:@"Invalid Name" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"ROIs cannot start with the name 'Oval' or 'Point'"];
	else if ([self nameForSphere:name] != nil || [self diameterForSphere:name] > 0)
		myAlert = [NSAlert alertWithMessageText:@"Invalid Name" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Violates naming convention for spheres"];

	if(myAlert != nil)	
	{	
		if(runalert)
			[myAlert runModal];
		return FALSE;
	}
	return TRUE;
}

- (void) getPosition: (id) sender : (NSRect*) trueposition : (ROI*) plane:(ROI*) threeDPositionROI : (int*) sliceZ
					 : (int) lastoffset
{
	
	if(sender == [[orthoView controller] originalView] || sender == [[FusionOrthoView CTController] originalView])
	{
		trueposition->origin.x = plane.centroid.x;
		trueposition->origin.y = plane.centroid.y;
		*sliceZ = [[threeDPositionROI pix] ID];
		NSLog(@"x:%f y:%f z:%i ", plane.centroid.x, plane.centroid.y, (int)[[threeDPositionROI pix] ID]);
	}	
	else if(sender == [[orthoView controller] xReslicedView] || sender == [[FusionOrthoView CTController] xReslicedView])
	{
		trueposition->origin.x = plane.centroid.x;
		trueposition->origin.y = threeDPositionROI.centroid.y;
		*sliceZ = controller.maxSlices - (long)plane.centroid.y -lastoffset;
		NSLog(@"x:%f y:%f z:%i ", plane.centroid.x, plane.centroid.y, (int)[[threeDPositionROI pix] ID]);
		NSLog(@"controllerMax: %i -  plane centroid %f - last offset: %i", controller.maxSlices, plane.centroid.y, lastoffset);
	}
	else if(sender == [[orthoView controller] yReslicedView] || sender == [[FusionOrthoView CTController] yReslicedView])
	{
		trueposition->origin.x = threeDPositionROI.centroid.x;
		trueposition->origin.y = plane.centroid.x;
		*sliceZ = controller.maxSlices - (long)plane.centroid.y -lastoffset;
		NSLog(@"x:%f y:%f z:%i ", plane.centroid.x, plane.centroid.y, (int)[[threeDPositionROI pix] ID]);
		NSLog(@"controllerMax: %i - plane centroid %f - last offset: %i", controller.maxSlices, plane.centroid.y, lastoffset);
	}	
}


-(ROI*)RoiInOrthoView{

	NSMutableArray *roiarray = [NSMutableArray array];;
	if(FusionOrthoView != nil){
		
		//scroll through different views, in fusionview
	
		if([[[[FusionOrthoView CTController] originalView] selectedROIs] count] > 0){
			roiarray = [[[FusionOrthoView CTController] originalView] selectedROIs];
		}
		else if([[[[FusionOrthoView CTController] xReslicedView] selectedROIs] count] > 0){
			roiarray = [[[FusionOrthoView CTController] xReslicedView] selectedROIs];
		}
		else if([[[[FusionOrthoView CTController] yReslicedView] selectedROIs] count] > 0){
			roiarray = [[[FusionOrthoView CTController] yReslicedView] selectedROIs];
		}
	}
	else{
		//scroll through regular view
		if ([[[(OrthogonalMPRController *)[orthoView controller] xReslicedView] selectedROIs] count] > 0){
			roiarray = [[(OrthogonalMPRController *)[orthoView controller] xReslicedView] selectedROIs];
		}
		else if ([[[(OrthogonalMPRController *)[orthoView controller] yReslicedView] selectedROIs] count] >0){
			roiarray = [[(OrthogonalMPRController *)[orthoView controller] yReslicedView] selectedROIs];
		}
		else if([[[(OrthogonalMPRController *)[orthoView controller] originalView] selectedROIs] count]>0){
			roiarray = [[(OrthogonalMPRController *)[orthoView controller] originalView] selectedROIs];
		}
	}		
	
	//if there are selected ROIs, find first valid selected.
	if ([roiarray count] != 0) {
		int k;
		//loop through selected ROIs, until we find one.
		for(k=0;k<[roiarray count]; k++){
			
			ROI *firstroi = [roiarray objectAtIndex:k];
			if(![firstroi.name hasPrefix:@"Oval"] && ![firstroi.name hasPrefix:@"Point"] && ![firstroi.name hasPrefix:@"Unnamed"])
			{ // do nothing
			}
			else return firstroi;
		}
		
	}
	return nil;
}	
		

-(NSDictionary*) get2DCoordinates: (float) threeDx: (float) threeDy: (float) threeDz {
	
	//Finds the actual point ROI in roiList from VRController x,y,z locations
	//if found, sets that roi as class variable pointROI + sets class varaible sliceLocation, probably needs to get rewritten
	long cur2DPointIndex = 0;
	BOOL found = NO;
	DCMPix *firstDCMPix = [[tempViewer pixList] objectAtIndex: 0];
		
	threeDx /= [D3View factor];
	threeDy /= [D3View factor];
	threeDz /= [D3View factor];
	
	NSLog(@"ThreeD X Y Z: %f %f %f", threeDx, threeDy, threeDz);
	
	// find 2D point from 3D position, mostly copy and pasted from [VRController ]
	while(!found && cur2DPointIndex<[[D3View roi2DPointsArray] count])
	{
		NSMutableArray *x = [NSMutableArray array];
		NSMutableArray *y = [NSMutableArray array];
		NSMutableArray *z = [NSMutableArray array];
		
		x = [D3View Getx2DPointsArray];
		y = [D3View Gety2DPointsArray];
		z = [D3View Getz2DPointsArray];
		
		float sx = [[x objectAtIndex:cur2DPointIndex] floatValue];
		float sy = [[y objectAtIndex:cur2DPointIndex] floatValue];
		float sz = [[z objectAtIndex:cur2DPointIndex] floatValue];

//		NSLog( @"SXYZ, %f %f %f", sx, sy, sz);
		
		if(	(threeDx < sx + [firstDCMPix pixelSpacingX] && threeDx > sx - [firstDCMPix pixelSpacingX])		&&
		   (threeDy < sy + [firstDCMPix pixelSpacingY] && threeDy > sy - [firstDCMPix pixelSpacingY])		&&
		   (threeDz < sz + [firstDCMPix sliceInterval] && threeDz > sz - [firstDCMPix sliceInterval]))
		{
			found = YES;
//			NSLog(@"FOUND!");
		}
		else cur2DPointIndex++;
	}
	if (found && cur2DPointIndex<[[D3View roi2DPointsArray] count])
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:
				[D3View.roi2DPointsArray objectAtIndex:cur2DPointIndex], @"ROI",
				[D3View.sliceNumber2DPointsArray objectAtIndex:cur2DPointIndex], @"SliceLocation", nil];
	}
	
	return nil;
	
}

	
@end
