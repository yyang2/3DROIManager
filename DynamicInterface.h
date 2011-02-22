//
//  DynamicInterface.h
//  DynamicROI
//
//  Created by Yang Yang on 3/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

enum chartDisplayYOptions {
	showMax, showMin, showMean
};
enum chartDisplayXOptions{
	showStart, showMid, showEnd
};

#import <Cocoa/Cocoa.h>
#import <OsiriX Headers/ROI.h>
#import <OsiriX Headers/DCMPix.h>
#import <OsiriX Headers/DCMView.h>
#import <OsiriX Headers/ViewerController.h>
#import <SM2DGraphView/SM2DGraphView.h>

//Simple class, including windowcontroller, which takes in the viewer + ROI in viewer, generates a Time Activity Curve.

@interface DynamicInterface : NSWindowController 
{
	ViewerController			*viewer;
	IBOutlet NSTableView		*dynamicTable;
	long						totalframes, activeFrame;
	IBAction					*buttonClicked;
	ROI							*activeROI;
	NSMutableArray				*TACData, *timeData;
	enum chartDisplayYOptions   currentYDisplay;
	enum chartDisplayXOptions	currentXDisplay;
	int							unitsoftime;
	IBOutlet SM2DGraphView *    graphTAC;
	IBOutlet NSPopUpButton		*chartYOptions, *chartXOptions;
	IBOutlet NSMenuItem			*displayMax, *displayMean, *displayMin, *displayStart, *displayEnd, *displayMid;
	NSMutableArray *xValues, *yValues;
}

- (id) initWithViewer:(ViewerController*) v:(ROI*)selectedROI;
- (void) calculateTAC;
- (void) calculateTime;
- (NSInteger)numberOfRowsInTableView:(NSTableView *)dynamicTable;
- (id)tableView:(NSTableView *)dynamicTable objectValueForTableColumn:(NSTableColumn *)aCol row:(int)aRow;
- (IBAction)buttonClicked:(id)sender;
- (IBAction)chartYOptionschanged:(id)sender;
- (IBAction)chartXOptionschanged:(id)sender;
- (void) changeChartDataSource:(NSString *)axis;

// things that need to be implemented for Chartviewer




@end
