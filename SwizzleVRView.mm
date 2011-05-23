//
//  SwizzleVRView.m
//  3DROIManager
//
//  Created by Yang Yang on 1/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SwizzleVRView.h"
#import "VRView+Yang.h"
#import <OsirixAPI/ROI.h>
#import <OsirixAPI/Notifications.h>
#import <OsirixAPI/DCMPix.h>
#import <OsirixAPI/DCMView.h>
#import <OsirixAPI/browserController.h>


#define BONEOPACITY 1.1

@implementation SwizzleVRView



static VRView	*snVRView = nil;
extern int dontRenderVolumeRenderingOsiriX;	// See OsiriXFixedPointVolumeRayCastMapper.cxx
static NSRecursiveLock *drawLock = nil;



- (void)mouseDown:(NSEvent *)theEvent
{
//	NSLog(@"modified dontRenderVolumeRenderingOsiriX:%i", dontRenderVolumeRenderingOsiriX);
//	NSLog(@"modified snVRView:%@", snVRView);
//	NSLog(@"modified NSRecursiveLock:%@", drawLock);
	
	if(drawLock == nil) drawLock = [[NSRecursiveLock alloc] init];
	snVRView = self;
	dontRenderVolumeRenderingOsiriX = 0;
	
	_hasChanged = YES;
	[drawLock lock];
	
	if( snCloseEventTimer)
		[snCloseEventTimer fire];
	
	snStopped = YES;
	
    NSPoint		mouseLoc, mouseLocPre;
	short		tool;
	
	[cursor set];
	
	noWaitDialog = YES;
	tool = currentTool;
	
	if ([theEvent type] == NSLeftMouseDown)
	{
		if (_mouseDownTimer)
		{
			[self deleteMouseDownTimer];
		}
		
		if( [[controller style] isEqualToString: @"noNib"] == NO)
			_mouseDownTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(startDrag:) userInfo:theEvent  repeats:NO] retain];
	}
	
	mouseLocPre = _mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView: nil];
	
	int clickCount = 1;
	
	@try
	{
		if( [theEvent type] ==	NSLeftMouseDown || [theEvent type] ==	NSRightMouseDown || [theEvent type] ==	NSLeftMouseUp || [theEvent type] == NSRightMouseUp)
			clickCount = [theEvent clickCount];
	}
	@catch (NSException * e)
	{
		clickCount = 1;
	}
	
	if( clickCount > 1 && (tool != t3Dpoint))
	{
		long	pix[ 3];
		float	pos[ 3], value;
		
		if( clipRangeActivated)
		{
			float position[ 3], sc[ 3], cos[ 9], r = [self getResolution];
			
			[self getOrigin: position];
			[self getCosMatrix: cos];
			
			position[0] = ([self frame].size.height - _mouseLocStart.y)*cos[3]*r + _mouseLocStart.x*cos[0]*r +position[0];
			position[1] = ([self frame].size.height - _mouseLocStart.y)*cos[4]*r + _mouseLocStart.x*cos[1]*r +position[1];
			position[2] = ([self frame].size.height - _mouseLocStart.y)*cos[5]*r + _mouseLocStart.x*cos[2]*r +position[2];
			
			[firstObject convertDICOMCoords: position toSliceCoords: sc pixelCenter: YES];
			
			sc[ 0] /= [firstObject pixelSpacingX];
			sc[ 1] /= [firstObject pixelSpacingY];
			sc[ 2] /= [firstObject sliceInterval];
			
			NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: sc[0]], @"x", [NSNumber numberWithInt: sc[1]], @"y", [NSNumber numberWithInt: sc[2]], @"z", nil];
			[[NSNotificationCenter defaultCenter] postNotificationName: OsirixDisplay3dPointNotification object:pixList  userInfo: dict];
		}
		else
		{
			if( [self get3DPixelUnder2DPositionX:_mouseLocStart.x Y:_mouseLocStart.y pixel:pix position:pos value:&value])
			{
				NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:	[NSNumber numberWithInt: pix[0]], @"x", [NSNumber numberWithInt: pix[1]], @"y", [NSNumber numberWithInt: pix[2]], @"z",
									  nil];
				[[NSNotificationCenter defaultCenter] postNotificationName: OsirixDisplay3dPointNotification object:pixList  userInfo: dict];
			}
		}
		[drawLock unlock];
		return;
	}
	
	if( _mouseLocStart.x < 20 && _mouseLocStart.y < 20 && isViewportResizable)
	{
		_resizeFrame = YES;
	}
	else
	{
		_resizeFrame = NO;
		tool = [self getTool: theEvent];
		_tool = tool;
		[self setCursorForView: tool];
		
		if( tool != tWL && tool != tZoom)
		{
			rotate = NO;
			
			[self resetAutorotate: self];
		}
		
		if( tool == tMesure)
		{
			if( bestRenderingWasGenerated)
			{
				bestRenderingWasGenerated = NO;
				[self display];
			}
			dontRenderVolumeRenderingOsiriX = 1;
			
			double	*pp;
			long	i;
			
			vtkPoints		*pts = Line2DData->GetPoints();
			
			if( pts->GetNumberOfPoints() >= 2)
			{
				// Delete current ROI
				pts = vtkPoints::New();
				vtkCellArray *rect = vtkCellArray::New();
				Line2DData-> SetPoints( pts);		pts->Delete();
				Line2DData-> SetLines( rect);		rect->Delete();
				
				pts = Line2DData->GetPoints();
			}
			
			// Click point 3D to 2D
			
			_mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView: nil];
			
			aRenderer->SetDisplayPoint( _mouseLocStart.x, _mouseLocStart.y, 0);
			aRenderer->DisplayToWorld();
			pp = aRenderer->GetWorldPoint();
			
			// Create the 2D Actor
			
			aRenderer->SetWorldPoint(pp[0], pp[1], pp[2], 1.0);
			aRenderer->WorldToDisplay();
			
			double *tempPoint = aRenderer->GetDisplayPoint();
			
			NSLog(@"New pt: %2.2f %2.2f", tempPoint[0] , tempPoint[ 1]);
			
			pts->InsertPoint( pts->GetNumberOfPoints(), tempPoint[0], tempPoint[ 1], 0);
			
			vtkCellArray *rect = vtkCellArray::New();
			rect->InsertNextCell( pts->GetNumberOfPoints()+1);
			for( i = 0; i < pts->GetNumberOfPoints(); i++) rect->InsertCellPoint( i);
			rect->InsertCellPoint( 0);
			
			Line2DData->SetVerts( rect);
			Line2DData->SetLines( rect);		rect->Delete();
			
			Line2DData->SetPoints( pts);
			
			[self computeLength];
			
			[self setNeedsDisplay: YES];
		}
		else if( tool == t3DCut)
		{
			double	*pp;
			
			if( bestRenderingWasGenerated)
			{
				bestRenderingWasGenerated = NO;
				[self display];
			}
			
			dontRenderVolumeRenderingOsiriX = 1;
			
			// Click point 3D to 2D
			
			_mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView: nil];
			
			aRenderer->SetDisplayPoint( _mouseLocStart.x, _mouseLocStart.y, 0);
			aRenderer->DisplayToWorld();
			pp = aRenderer->GetWorldPoint();
			
			// Create the 2D Actor
			
			aRenderer->SetWorldPoint(pp[0], pp[1], pp[2], 1.0);
			aRenderer->WorldToDisplay();
			
			double *tempPoint = aRenderer->GetDisplayPoint();
			
			NSLog(@"New pt: %2.2f %2.2f", tempPoint[0] , tempPoint[ 1]);
			
			[ROIPoints addObject: [NSValue valueWithPoint: NSMakePoint( tempPoint[0], tempPoint[ 1])]];
			[self generateROI];
			
			//			if( ROIUPDATE == NO)
			//			{
			//				ROIUPDATE = YES;
			//				[NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(timerUpdate:) userInfo:nil repeats:0]; 
			//			}
			
			[self setNeedsDisplay: YES];
		}
		else if( tool == tWL)
		{
			_startWW = ww;
			_startWL = wl;
			_startMin = wl - ww/2;
			_startMax = wl + ww/2;
			
			_mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView:nil];
			
			volumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
			
			if( blendingVolumeMapper) 
				blendingVolumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
		}
		else if( tool == tWLBlended)
		{
			_startWW = blendingWw;
			_startWL = blendingWl;
			_startMin = blendingWl - blendingWw/2;
			_startMax = blendingWl + blendingWw/2;
			
			_mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView:nil];
			
			volumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
			
			if( blendingVolumeMapper) 
				blendingVolumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
		}
		else if( tool == tRotate)
		{
			int shiftDown = 0;
			int controlDown = 1;
			
			if( volumeMapper)
				volumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
			
			if( blendingVolumeMapper)
				blendingVolumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
			
			mouseLoc = _mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView:nil];
			[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
			[self getInteractor]->InvokeEvent(vtkCommand::LeftButtonPressEvent,NULL);
		}
		else if( tool == t3DRotate || tool == tCamera3D)
		{
			if( _tool == tCamera3D || clipRangeActivated == YES)
			{
				mouseLocPre = _mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView:nil];
				
				if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
				if( blendingVolumeMapper) blendingVolumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
				
				if( clipRangeActivated)
				{
					if( keep3DRotateCentered == NO)
					{
						double xx = -(mouseLocPre.x - [self frame].size.width/2.);
						double yy = -(mouseLocPre.y - [self frame].size.height/2.);
						
						double pWC[ 2];
						aCamera->GetWindowCenter( pWC);
						pWC[ 0] *= ([self frame].size.width/2.);
						pWC[ 1] *= ([self frame].size.height/2.);
						
						if( pWC[ 0] != xx || pWC[ 1] != yy)
						{
							aCamera->SetWindowCenter( xx / ([self frame].size.width/2.), yy / ([self frame].size.height/2.));
							[self panX: ([self frame].size.width/2.) -(pWC[ 0] - xx)*10000. Y: ([self frame].size.height/2.) -(pWC[ 1] - yy) *10000.];
						}
					}
				}
			}
			else
			{
				int shiftDown = 0;//([theEvent modifierFlags] & NSShiftKeyMask);
				int controlDown = 0;//([theEvent modifierFlags] & NSControlKeyMask);
				
				if( volumeMapper)
					volumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
				
				if( blendingVolumeMapper)
					blendingVolumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
				
				mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
				
				[self getInteractor]->SetEventInformation((int)mouseLoc.x, (int)mouseLoc.y, controlDown, shiftDown);
				[self getInteractor]->InvokeEvent(vtkCommand::LeftButtonPressEvent,NULL);
				
				if( clipRangeActivated)
					aCamera->SetClippingRange( 0.0, clippingRangeThickness);
				else
					aRenderer->ResetCameraClippingRange();
			}
		}
		else if( tool == tTranslate)
		{
			int shiftDown = 1;
			int controlDown = 0;
			
			if( volumeMapper)
				volumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
			
			if( blendingVolumeMapper)
				blendingVolumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
			
			mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
			[self getInteractor]->SetEventInformation((int)mouseLoc.x, (int)mouseLoc.y, controlDown, shiftDown);
			[self getInteractor]->InvokeEvent(vtkCommand::LeftButtonPressEvent,NULL);
		}
		else if( tool == tZoom)
		{
			if( volumeMapper)
				volumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
			
			if( blendingVolumeMapper)
				blendingVolumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
			
			if( projectionMode != 2)
			{
				int shiftDown = 0;
				int controlDown = 1;
				
				mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
				[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
				[self getInteractor]->InvokeEvent(vtkCommand::RightButtonPressEvent,NULL);
			}
			else
			{
				// vtkCamera
				mouseLocPre = _mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView:nil];
				
				if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
				if( blendingVolumeMapper) blendingVolumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
			}
		}
		else if( tool == t3Dpoint)
		{
#pragma mark double click
			
			NSEvent *artificialPKeyDown = [NSEvent keyEventWithType:NSKeyDown
														   location:[theEvent locationInWindow]
													  modifierFlags:nil
														  timestamp:[theEvent timestamp]
													   windowNumber:[theEvent windowNumber]
															context:[theEvent context]
														 characters:@"p"
										charactersIgnoringModifiers:nil
														  isARepeat:NO
															keyCode:112
										   ];
  			if( blendingVolume)
				blendingVolume->SetPickable( NO);
	
			[super callSuperKeyDown: artificialPKeyDown];
			
			if (![self isAny3DPointSelected])
			{
				// add a point on the surface under the mouse click
				[self throw3DPointOnSurface: _mouseLocStart.x : _mouseLocStart.y];
				[self setNeedsDisplay:YES];
			}
			else
			{
				[point3DRadiusSlider setFloatValue: [[point3DRadiusArray objectAtIndex:[self selected3DPointIndex]] floatValue]];
				[point3DColorWell setColor: [point3DColorsArray objectAtIndex:[self selected3DPointIndex]]];
				NSPoint mouseLocationOnScreen = [[self window] convertBaseToScreen:[theEvent locationInWindow]];
				NSDictionary *pass = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:[self selected3DPointIndex]], @"index", NSStringFromPoint(mouseLocationOnScreen), @"mouse",
									  nil];
				[[NSNotificationCenter defaultCenter] postNotificationName: @"3DROIManagerShow" object:pass  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[[self controller] viewer], @"viewer",nil]];

				if (clickCount == 2)
				{
					NSPoint mouseLocationOnScreen = [[self window] convertBaseToScreen:[theEvent locationInWindow]];
					[point3DInfoPanel setAlphaValue:0.8];
					[point3DInfoPanel	setFrame:	NSMakeRect(	mouseLocationOnScreen.x - [point3DInfoPanel frame].size.width/2.0, 
															   mouseLocationOnScreen.y-[point3DInfoPanel frame].size.height-20.0,
															   [point3DInfoPanel frame].size.width,
															   [point3DInfoPanel frame].size.height)
									   display:YES animate: NO];
					NSLog(@"Short circuited point3DInfoPanel");
//					[point3DInfoPanel orderFront:self];
					
					
					float pos[3];
					[[point3DPositionsArray objectAtIndex:[self selected3DPointIndex]] getValue:pos];
					
					int pix[3];
					pix[0] = (int)[[[[[controller roi2DPointsArray] objectAtIndex:[self selected3DPointIndex]] points] objectAtIndex:0] x];
					pix[1] = (int)[[[[[controller roi2DPointsArray] objectAtIndex:[self selected3DPointIndex]] points] objectAtIndex:0] y];
					pix[2] = [[[controller sliceNumber2DPointsArray] objectAtIndex:[self selected3DPointIndex]] intValue];
					
					NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: pix[0]], @"x", [NSNumber numberWithInt: pix[1]], @"y", [NSNumber numberWithInt: pix[2]], @"z",
										  nil];
					
					[[NSNotificationCenter defaultCenter] postNotificationName: OsirixDisplay3dPointNotification object:pixList  userInfo: dict];
				}
			}
		}
		else if( tool == tBonesRemoval)
		{
			[self deleteMouseDownTimer];
			
			NSLog( @"**** Bone Removal Start");
			// enable Undo
			[controller prepareUndo];
			NSLog( @"**** Undo");
			
			// clicked point (2D coordinate)
			_mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView: nil];
			
//			long pix[ 3];
//			float pos[ 3], value;
//			float minValue = [[NSUserDefaults standardUserDefaults] floatForKey: @"VRGrowingRegionValue"]-[[NSUserDefaults standardUserDefaults] floatForKey: @"VRGrowingRegionInterval"]/3.;
			
//			if( [self get3DPixelUnder2DPositionX:_mouseLocStart.x Y:_mouseLocStart.y pixel:pix position:pos value:&value maxOpacity: BONEOPACITY minValue: minValue])
//			{
//				WaitRendering	*waiting = [[WaitRendering alloc] init:NSLocalizedString(@"Applying Bone Removal...", nil)];
//				[waiting showWindow:self];
//				
//				NSArray	*roiList = nil;
//				
//				NSLog( @"ITKSegmentation3D");
//				
//				int savedMovieIndex = [[controller viewer2D] curMovieIndex];
//				
//				for ( int m = 0; m < [[controller viewer2D] maxMovieIndex] ; m++)
//				{
//					[[controller viewer2D] setMovieIndex: m];
//					[[[controller viewer2D] imageView] setIndex: pix[ 2]]; //set the DCMview on the good slice
//					
//					NSPoint seedPoint;
//					seedPoint.x = pix[ 0];
//					seedPoint.y = pix[ 1];
//					
//					ITKSegmentation3D *itkSegmentation = [[ITKSegmentation3D alloc] initWith:[[controller viewer2D] pixList] :[[controller viewer2D] volumePtr] :-1];
//					
//					[itkSegmentation regionGrowing3D	:[controller viewer2D]	// source viewer
//													 :nil					// destination viewer = nil means we don't want a new serie
//													 :-1						// slice = -1 means 3D region growing
//													 :seedPoint				// startingPoint
//													 :1						// algorithmNumber, 1 = threshold connected with low & up threshold
//													 :[NSArray arrayWithObjects:	[NSNumber numberWithFloat: [[NSUserDefaults standardUserDefaults] floatForKey: @"VRGrowingRegionValue"] -[[NSUserDefaults standardUserDefaults] floatForKey: @"VRGrowingRegionInterval"]/2.],
//													   [NSNumber numberWithFloat: [[NSUserDefaults standardUserDefaults] floatForKey: @"VRGrowingRegionValue"] +[[NSUserDefaults standardUserDefaults] floatForKey: @"VRGrowingRegionInterval"]/2.],
//													   nil]// algo parameters
//													 :0						// setIn
//													 :0.0					// inValue
//													 :0						// setOut
//													 :0.0					// outValue
//													 :0						// roiType
//													 :0						// roiResolution
//													 :@"BoneRemovalAlgorithmROIUniqueName" // newname (I tried to make it unique ;o)
//													 :NO];					// merge with existing ROIs?
//					
//					// find all ROIs with name = BoneRemoval
//					NSArray *rois = [[controller viewer2D] roisWithName:@"BoneRemovalAlgorithmROIUniqueName"];
//					
//					NSMutableArray *d = [NSMutableArray array];
//					for( ROI *r in rois)
//					{
//						[d addObject: [NSDictionary dictionaryWithObjectsAndKeys: r, @"roi", [r pix], @"curPix", nil]];
//					}
//					
//					roiList = d;
//					
//					[itkSegmentation release];
//					
//					// Dilatation
//					
//					[[controller viewer2D] applyMorphology: [roiList valueForKey:@"roi"] action:@"dilate" radius: 10 sendNotification:NO];
//					[[controller viewer2D] applyMorphology: [roiList valueForKey:@"roi"] action:@"erode" radius: 6 sendNotification:NO];
//					
//					BOOL addition = NO;
//					
//					// Bone Removal
//					NSNumber		*nsnewValue	= [NSNumber numberWithFloat: -1000];		//-1000
//					NSNumber		*nsminValue	= [NSNumber numberWithFloat: -FLT_MAX];		//-99999
//					NSNumber		*nsmaxValue	= [NSNumber numberWithFloat: FLT_MAX];
//					NSNumber		*nsoutside	= [NSNumber numberWithBool: NO];
//					NSNumber		*nsaddition	= [NSNumber numberWithBool: addition];
//					NSMutableArray	*roiToProceed = [NSMutableArray array];
//					
//					for( NSDictionary *rr in roiList)
//					{
//						[roiToProceed addObject: [NSDictionary dictionaryWithObjectsAndKeys:  [rr objectForKey:@"roi"], @"roi", [rr objectForKey:@"curPix"], @"curPix", @"setPixelRoi", @"action", nsnewValue, @"newValue", nsminValue, @"minValue", nsmaxValue, @"maxValue", nsoutside, @"outside", nsaddition, @"addition", nil]];
//					}
//					
//					[[controller viewer2D] roiSetStartScheduler: roiToProceed];
//					
//					NSLog( @"**** Set Pixels");
//					
//					// Update 3D image
//					if( textureMapper) 
//					{
//						// Force min/max recomputing
//						[self movieChangeSource: data];
//						//reader->Modified();
//					}
//					else
//					{
//						if( isRGB == NO)
//							//							vImageConvert_FTo16U( &srcf, &dst8, -OFFSET16, 1./valueFactor, 0);
//							[BrowserController multiThreadedImageConvert: @"FTo16U" :&srcf :&dst8 :-OFFSET16 :1./valueFactor];
//					}
//				}
//				
//				[[controller viewer2D] setMovieIndex: savedMovieIndex];
//				
//				[self setNeedsDisplay:YES];
//				
//				[waiting close];
//				[waiting release];
//				
//				[[controller viewer2D] roiIntDeleteAllROIsWithSameName:@"BoneRemovalAlgorithmROIUniqueName"];
//				
//				[[controller viewer2D] needsDisplayUpdate];
//			}
//			else NSRunAlertPanel(NSLocalizedString(@"Bone Removing", nil), NSLocalizedString(@"Failed to detect a high density voxel to start growing region.", nil), NSLocalizedString(@"OK", nil), nil, nil);
			
			NSLog( @"**** Bone Removal End");
		}
		else [super mouseDown:theEvent];
		
		if( croppingBox)
			croppingBox->SetHandleSize( 0.005);
	}
	
	if (![self isAny3DPointSelected]) 
	{
		//updates if nothing is selected
		NSDictionary *pass = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:-1], @"index", nil];
		[[NSNotificationCenter defaultCenter] postNotificationName: @"3DROIManagerShow" object:pass  userInfo: [NSDictionary dictionary]];
	}
	bestRenderingWasGenerated = NO;
	noWaitDialog = NO;
	[drawLock unlock];
}


- (void) removeSelected3DPoint
{
	if([self isAny3DPointSelected])
	{
		// remove 2D Point
		float position[3];
		ROI* something = [[self.controller roi2DPointsArray] objectAtIndex:[self selected3DPointIndex]];

		//yangyang added this so center of points don't get deleted from VRView
		if([something.name hasSuffix:@"_center"] || [something.name hasSuffix:@"_ellipse"]) 
		{
			[[NSNotificationCenter defaultCenter] postNotificationName: @"3DROIManagerVRDelete" object:something  userInfo: nil];
			return;
		}
		
		
		[[point3DPositionsArray objectAtIndex:[self selected3DPointIndex]] getValue:position];
		
		[controller remove2DPoint: position[0] : position[1] : position[2]];

		//updates so with negative index so sphere window is hidden
		NSDictionary *pass = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:-1], @"index", nil];
		[[NSNotificationCenter defaultCenter] postNotificationName: @"3DROIManagerShow" object:pass  userInfo: nil];

		// remove 3D Point
		// the 3D Point is removed through notification (sent in [controller remove2DPoint..)
		//[self remove3DPointAtIndex:[self selected3DPointIndex]];
	}
}

@end
