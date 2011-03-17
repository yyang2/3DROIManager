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
	IBOutlet NSTextField	*nameText, *diameterText, *isocontour, *isoname, *ellpX, *ellpY, *ellpZ, *seedPercent;
	IBOutlet NSButton		*useTextField, *useTextFields;
	IBOutlet NSTabView		*tabView;
	ThreeDROIManagerController *controller;
	VRController			*D3View;
	OrthogonalMPRPETCTViewer	*FusionOrthoView;
	OrthogonalMPRViewer			*orthoView;
	ViewerController		*tempViewer;

}

- (id) initWithViewers:(ViewerController *) v :(VRController *) D3 :(BOOL) isfusion :(id) secondviewer:(ThreeDROIManagerController*)c ;

- (void)moveWindow:(NSNotification*)note;
- (IBAction) make3DObject: (id)sender;

- (ROI*)RoiInOrthoView :(NSString*)origin;
- (ROI*)makePointForOval:(ROI*)circle;
- (NSDictionary*) get2DCoordinates: (float) threeDx: (float) threeDy: (float) threeDz;
- (void) getPosition: (id) sender : (NSRect*) trueposition : (ROI*) planarPositionROI:(ROI*) threeDPositionROI : (int*) sliceZ: (int) lastoffset;
- (BOOL) validName:(NSString *) name :(BOOL) runalert;


/* sphere functions */
- (BOOL) generateSphere;
- (void) MoveSphere: (ROI *) center :(ROI *) planar;
- (NSString*) getSphereName:(NSString*)r;
- (float) getSphereDiameter: (NSString*)r;
- (NSString*) makeSphereName:(NSString *)n :(float)diameter;
- (BOOL) makeSphereWithName:(NSString*)name center:(ROI *)center atSlice:(long)currentSlice withRadius:(float)radius;
- (void) resetsphere;


/*ellipse functions*/
- (BOOL)makeEllipseWithName:(NSString*)name center:(ROI*)center atSlice:(long)currentSlice x:(double)xdiam y:(double)ydiam z:(double)zdiam;
- (NSString*)makeEllipseName:(NSString*)name:(double)x:(double)y:(double)z;
- (void)getEllipseDimensions:(NSString*)center :(double*)pos;
- (NSString*)getEllipseName:(NSString*)center;
- (BOOL)generateEllipse;
- (void)getMissingEllipseDimension:(ROI*)current: (NSString *)origin;
- (void) MoveEllipse: (ROI *) center :(ROI *) planar;

- (IBAction) changeDefaultRadius: (id)sender;
- (IBAction) changePreviewRadius: (id)sender;
@end
