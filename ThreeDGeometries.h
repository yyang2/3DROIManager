//
//  ThreeDGeometries.h
//  GenerateSphere
//
//  Created by Yang Yang on 4/1/10.
//  Copyright 2010 UCLA Molecular and Medical Pharmacology. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ViewerController;
@class VRController;
@class OrthogonalMPRPETCTViewer;
@class OrthogonalMPRViewer;
@class ROI;
@class ThreeDROIManagerController;

//Pop up Window which gets initialized with 3DROIManager, does not dealloc when closed (see XIB).
//Handles drawing spheres - gets called a lot

@interface ThreeDGeometries : NSWindowController {
	IBOutlet NSSlider		*diameterSlider;
	IBOutlet NSWindow		*MaskWindow;
	IBOutlet NSTextField	*nameText, *diameterText, *isocontour, *isoname;
	IBOutlet NSButton		*useTextField;
	
	ThreeDROIManagerController *controller;
	VRController			*D3View;
	OrthogonalMPRPETCTViewer	*FusionOrthoView;
	OrthogonalMPRViewer			*orthoView;
	ViewerController		*tempViewer;

}

- (id) initWithViewers:(ViewerController *) v :(VRController *) D3 :(BOOL) isfusion :(id) secondviewer:(ThreeDROIManagerController*)c ;


- (void) MoveSphere: (ROI *) center :(ROI *) planar;
- (NSString*) nameForSphere:(NSString*)r;
- (float) diameterForSphere: (NSString*)r;
- (void) resetsphere;
- (ROI*)RoiInOrthoView;
- (ROI*)makePointForOval:(ROI*)circle;
- (NSDictionary*) get2DCoordinates: (float) threeDx: (float) threeDy: (float) threeDz;
- (void) getPosition: (id) sender : (NSRect*) trueposition : (ROI*) planarPositionROI:(ROI*) threeDPositionROI : (int*) sliceZ: (int) lastoffset;
-(BOOL) validName:(NSString *) name :(BOOL) runalert;

- (NSString*) sphereName:(NSString *)n :(float)diameter;

- (IBAction) changeDefaultRadius: (id)sender;
- (IBAction) changePreviewRadius: (id)sender;
- (IBAction) generateSphere: (id)sender;
- (BOOL) makeSphereWithName:(NSString*)name center:(ROI *)center atSlice:(long)currentSlice withRadius:(float)radius;
@end
