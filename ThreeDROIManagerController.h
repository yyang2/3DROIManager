/*=========================================================================
 Program:   OsiriX
 
 Copyright (c) OsiriX Team
 All rights reserved.
 Distributed under GNU - LGPL
 
 See http://www.osirix-viewer.com/copyright.html for details.
 
 This software is distributed WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 PURPOSE.
 =========================================================================*/



#import <Cocoa/Cocoa.h>
#import <OsirixAPI/DCMView.h>
#import <OsirixAPI/DCMPix.h>
#import <objc/runtime.h>
#import "ViewerController+Yang.h"
#import "VRView+Yang.h"

@class FrameSlider;
@class CLUTBar;
@class ViewerController;
@class DCMPix;
@class VRController;
@class OrthogonalMPRViewer;
@class OrthogonalMPRPETCTViewer;
@class ThreeDGeometries;
@class ColorTransferView;
/** \brief  Window Controller for ROI management */
// Main controller class for 3D ROI Analysis and Management
// Uses ThreeDGeometries to generate fake three dimensional ROIs

@interface ThreeDROIManagerController : NSWindowController
{
	BOOL						isFusion, MaxEditing, MinEditing, ignoreUpdateContrast;
	NSMutableArray				*ElapsedTime;
	ViewerController			*viewer;
	IBOutlet NSTableView		*tableView;
	IBOutlet CLUTBar			*CLUTColumn;
	IBOutlet NSPanel			*ChangeRadiusWindow;
	IBOutlet NSTextField		*ROIStatisticsField, *VisibleMin, *VisibleMax, *TimeField, *ChangeRadiusOriginal, *ChangeRadiusNew, *ChangeRadiusName;
	IBOutlet NSButton			*playButton, *ChangeRadiusButton, *ShowButton, *HideButton, *DeleteButton, *GoToButton, *StartVolumeButton, *GenerateTACButton, *ExportROIButton, *LockMin,*LockROIButton;
	float		pixelSpacingZ;
	
	IMP			oldClickImp, oldMouseUp;
	
	NSMutableArray
	*curROIlist, 
	//list of NSMutableDictionaries containing name of 3DROI, and location of each slice+frame where it exists.
	
	*centerList, 
	//list of points which are the center of 3D ROIs
	*deleteLaterList;
	//list of ROIs which have been moved and redrawn. deleted when tabulateROIs is called. this is a hack to prevent rois from being destroyed prematurely
	
	VRController				*D3View;
	ThreeDGeometries				*ShapesController;
	float						movez;
	OrthogonalMPRPETCTViewer	*FusionOrthoView;
	OrthogonalMPRViewer			*orthoView;
	int							maxFrames, maxSlices, activeFrame, activeSlice;
	IBOutlet FrameSlider		*frameNavigator;
}
@property (retain) NSMutableArray 	*curROIlist, 	*centerList, 	*deleteLaterList;
@property int maxFrames, maxSlices, activeFrame, activeSlice;

/** Default initializer */
- (id) initWithViewer:(ViewerController*) v;
//subroutines called by initializer
- (void) start3DViewer;
- (void) startOrthoViewer;
- (void) startObservers;
- (void) initSlider;
- (void) drawCLUTbar;

- (void)setSelectedTableROI:(NSString*)ROIName;

-(ROI *) ROIForSelectedIndex;
- (IBAction) exportAllROIs:(id)sender;
- (IBAction) playFrames:(id)sender;
- (IBAction)toggleWindowLock:(id)sender;
- (IBAction)updateWindows:(id)sender;
- (IBAction)deleteVolume:(id)sender;
- (IBAction)lockROI:(id)sender;
- (IBAction) openOrthView:(id)sender;
- (IBAction) gotoSlice:(id)sender;
- (IBAction) startVolume:(id)sender;
- (IBAction) gotoFrame:(id)sender;
- (IBAction) HideROI:(id)sender;
- (IBAction)generateTAC:(id)sender;
- (IBAction) ShowROI:(id)sender;
- (IBAction) openSphereDrawer:(id)sender;

// Table view data source methods
- (void) deleteThisROI: (ROI*) roi;
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;
- (void) tabulateAllrois;
- (NSMutableDictionary *) getCenterROI:(ROI *)roiofinterest;
-(void) refreshForFrame:(int)newframe;
- (int) indexforROIname:(NSString *)compared;
- (BOOL) nameInIndex: (NSString*)compared;
- (void) UpdateStatistics: (NSNotification *) notification;
- (id)tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
			row:(NSInteger)rowIndex;
-(ROI*)centerForOrthoROI:(ROI*)orth;
- (void) roiListModification :(NSNotification*) note;
- (void) fireUpdate: (NSNotification*) note;
@end
