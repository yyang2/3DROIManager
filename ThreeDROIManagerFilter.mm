//
//  3DROIManagerFilter.m
//  3DROIManager
//
//  Copyright (c) 2010 UCLA. All rights reserved.
//
#import <objc/runtime.h>
#import "ThreeDROIManagerFilter.h"
#import "ThreeDROIManagerController.h"
#import "SwizzleViewerController.h"
#import "SwizzleAppController.h"
#import "SwizzleROIVolume.h"
#import "SwizzleOrthogonalMPRController.h"
#import "SwizzleDCMPix.h"
#import "SwizzleROI.h"

@implementation ThreeDROIManagerFilter

- (void) initPlugin
{
	//sets this flag to be positive if the plugin is loaded.
	//Several classes in OsiriX source code have been modified to be activated for this flag
	if (![[NSUserDefaults standardUserDefaults] integerForKey:@"PreclinicalAnalysis"]) { 
		[[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"PreclinicalAnalysis"];
	}
	
	
	//swizzle ViewerController
	Class ViewerControllerClass = objc_getClass("ViewerController");
	Class SwizzleView			= objc_getClass("SwizzleViewerController");
	

	Method originalBlendViews = class_getInstanceMethod(ViewerControllerClass, @selector( blendWindows:));
	Method modifiedBlendViews = class_getInstanceMethod(SwizzleView, @selector( blendWindows:));
	IMP blendView = method_getImplementation(modifiedBlendViews);
	method_setImplementation(originalBlendViews, blendView);

	//swizzle AppController
	Class AppController = objc_getClass("AppController");
	Class SwizzleApp	= objc_getClass("SwizzleAppController");
	Method originalWarning = class_getClassMethod(AppController, @selector(displayImportantNotice:));
	Method newWarning	   = class_getClassMethod(SwizzleApp, @selector(displayImportantNotice:));
	IMP	newWarn			   = method_getImplementation(newWarning);
	method_setImplementation(originalWarning, newWarn);
	
	//swizzle DCMPix
	
//	Class DCMPictures	=objc_getClass("DCMPix");
//	Class SwizzleDCM	=objc_getClass("SwizzleDCMPix");
//
//	
//	Method OtheroriginalLoad =class_getInstanceMethod(DCMPictures, @selector(loadDICOMPapyrus));
//	Method OthernewLoad		=class_getInstanceMethod(SwizzleDCM, @selector(loadDICOMPapyrus));
//	IMP OthernewLoadingImp	=method_getImplementation(OthernewLoad);
//	method_setImplementation(OtheroriginalLoad,OthernewLoadingImp);

    //Swizzle ROI
    
    Class ROI = objc_getClass("ROI");
    Class SwizzROI = objc_getClass("SwizzleROI");

    Method oldDraw = class_getInstanceMethod(ROI, @selector(drawROIWithScaleValue: offsetX:offsetY: pixelSpacingX: pixelSpacingY: highlightIfSelected: thickness: prepareTextualData:));
    Method newDraw = class_getInstanceMethod(SwizzROI, @selector(drawROIWithScaleValue: offsetX:offsetY: pixelSpacingX: pixelSpacingY: highlightIfSelected: thickness: prepareTextualData:));
    IMP NewDrawIMP =  method_getImplementation(newDraw);
    method_setImplementation(oldDraw, NewDrawIMP);
    
	//Swizzle OrthogonalMPRController
	Class Ortho			=	objc_getClass("OrthogonalMPRController");
	Class SwizzleOrtho	=	objc_getClass("SwizzleOrthogonalMPRController");
	
	Method setPix		=	class_getInstanceMethod(Ortho, @selector(setPixList:::));
	Method pointAtX		=	class_getInstanceMethod(Ortho, @selector(pointsROIAtX:));
	Method pointAtY		=	class_getInstanceMethod(Ortho, @selector(pointsROIAtY:));
	
	Method NewsetPix		=	class_getInstanceMethod(SwizzleOrtho, @selector(setPixList:::));
	Method NewpointAtX		=	class_getInstanceMethod(SwizzleOrtho, @selector(pointsROIAtX:));
	Method NewpointAtY		=	class_getInstanceMethod(SwizzleOrtho, @selector(pointsROIAtY:));
	
	IMP impsetPix	= method_getImplementation(NewsetPix);
	IMP	imppointAtX = method_getImplementation(NewpointAtX);
	IMP imppointAtY = method_getImplementation(NewpointAtY);
	
	method_setImplementation(setPix, impsetPix);
	method_setImplementation(pointAtX, imppointAtX);
	method_setImplementation(pointAtY, imppointAtY);

	//Swizzle ROI Volume
	Class ROIVol		=	objc_getClass("ROIVolume");
	Class SwizzleROIVol	=	objc_getClass("SwizzleROIVolume");
	Method setROI		=	class_getInstanceMethod(ROIVol, @selector(setROIList:));
	Method newsetROI	=	class_getInstanceMethod(SwizzleROIVol, @selector(setROIList:));
	IMP impsetROI		=	method_getImplementation(newsetROI);
	method_setImplementation(setROI, impsetROI);
	
	//Swizzle VRView
	
	Class  VR			= objc_getClass("VRView");
	Class  SwizzleVR	= objc_getClass("SwizzleVRView");
	Method removePoint	= class_getInstanceMethod(VR, @selector(removeSelected3DPoint));
	Method newremovePoint = class_getInstanceMethod(SwizzleVR, @selector(removeSelected3DPoint));
	IMP		impremovePoint = method_getImplementation(newremovePoint);
	method_setImplementation(removePoint, impremovePoint);
	
	Method point3DArray = class_getInstanceMethod(SwizzleVR, @selector(get3DPositionArray));
	IMP		imppoint3DArray = method_getImplementation(point3DArray);
	class_addMethod(VR, @selector(get3DPositionArray), imppoint3DArray, "v@:");

	
	Class BonjourBrowser		= objc_getClass("BonjourBrowser");
	Class SwizBonjourBrowser		= objc_getClass("SwizzleBonjourBrowser");
	Method oldGetList = class_getInstanceMethod(BonjourBrowser, @selector(buildDICOMDestinationsList));
	Method newGetList = class_getInstanceMethod(SwizBonjourBrowser, @selector(buildDICOMDestinationsList));
	IMP	   getListImp = method_getImplementation(newGetList);
	method_setImplementation(oldGetList, getListImp);
}

- (long) filterImage:(NSString*) menuName
{
	//starts our main controller
	[[ThreeDROIManagerController alloc] initWithViewer: viewerController];
	return 0;
}

@end
