//to do list BIG:
//-find out why graphics are so buggy, can't do anything about it.

//to do list SMALL:
//-rebuild sm2dgraphview to be 64 bit
//-make toggle ROIVolume rather than two buttons, autohide volume when masking.
//-make slider play option just like menu
//-add roi to queue

#import "ThreeDROIManagerController.h"

#import <OsiriX Headers/Notifications.h>
#import <OsiriX Headers/ViewerController.h>
#import "ViewerController+Yang.h"
#import <OsiriX Headers/VRController.h>
#import <OsiriX Headers/DCMView.h>
#import <OsiriX Headers/ROI.h>
#import <OsiriX Headers/DCMPix.h>
#import "DMCPix+Yang.h"
#import <OsiriX Headers/OrthogonalMPRController.h>
#import <OsiriX Headers/OrthogonalMPRPETCTController.h>
#import <OsiriX Headers/OrthogonalMPRPETCTViewer.h>
#import <OsiriX Headers/OrthogonalMPRView.h>
#import "SwizzleDCMView.h"
#include <OpenGL/CGLMacro.h>
#include <OpenGL/CGLCurrent.h>
#include <OpenGL/CGLContext.h>

#import "ThreeDGeometries.h"
#import "DynamicInterface.h"
#import "CLUTBar.h"
#import "FrameSlider.h" 

@class ROIVolume;
@implementation ThreeDROIManagerController
#pragma mark -
#pragma mark Init + Dealloc

@synthesize maxFrames;
@synthesize maxSlices;
@synthesize activeFrame;
@synthesize activeSlice;

@synthesize curROIlist; 
@synthesize centerList;
@synthesize deleteLaterList;



- (void) awakeFromNib { 
	
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey: @"EmptyNameForNewROIs"]; //Make sure new ROIs have names! ROI Names are used to filter out unnecessary mouseUp notifications intercepted in MoveObject:
	
	[self initSlider]; //Draw our sliders according to number of frames
	if (maxFrames == 1) [frameNavigator setEnabled:NO];

	//checks if there is a PETMinimumValue set in preferences, adjusts our lock button accordingly
	int i = [[NSUserDefaults standardUserDefaults] integerForKey: @"PETWindowingMode"];
	if (i==0){ [LockMin setState:NSOffState];
		[VisibleMin setEnabled:YES];
		[VisibleMin setIntValue:[[NSUserDefaults standardUserDefaults] integerForKey: @"PETMinimumValue"]];
	}
	else{
		[VisibleMin setEnabled:NO];
		[LockMin setState:NSOnState];
	}
	
	
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey: @"dontAutoCropScissors"]; //prevents autocrop from ruining our 3D ROI
	[[NSUserDefaults standardUserDefaults] setObject:@"Classic Mode" forKey: @"PET Clut Mode"];
	[[NSUserDefaults standardUserDefaults] setObject:@"Rainbow" forKey:@"PET Default CLUT"];
	[[NSUserDefaults standardUserDefaults] setObject:@"Rainbow" forKey:@"PET Blending CLUT"];
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey: @"ROITEXTNAMEONLY"];
	
	// grab lookup values from viewer, puts them in our textboxes
	float   iwl, iww;
	[[viewer imageView] getWLWW:&iwl :&iww];
	[VisibleMax setFloatValue:iwl+iww/2];
	[VisibleMin setFloatValue:iwl-iww/2];
	[self drawCLUTbar];
	
}



//! \brief initializes all the window stuff as well as the viewerController
//! \exp. doesn't yet output any actual windows
//! \param the viewer controller

- (id) initWithViewer:(ViewerController*) v
{
	// function sets up "sandbox" for convenient analysis, this includes hiding the original 2D ViewerController and initializing the VRView (3D)
	// orthogonal MPR (3 orthogonal planes).
	// the state of all three windows - ViewerController (hidden), VRViewer, and OrthogonalMPRViewer are kept in sync by the class.
	Class  VR			= objc_getClass("VRView");
	Class  SwizzleVR	= objc_getClass("SwizzleVRView");
	
	Method oldClick = class_getInstanceMethod(VR, @selector(mouseDown:));
	Method newClick = class_getInstanceMethod(SwizzleVR, @selector(mouseDown:));
	IMP	   newClickImp = method_getImplementation(newClick);
	oldClickImp = method_getImplementation(oldClick);
	method_setImplementation(oldClick, newClickImp);
	
	Class oldView = objc_getClass("DCMView");
	Class SwizzleView = objc_getClass("SwizzleDCMView");
	
	Method oldMouseUpMethod = class_getInstanceMethod(oldView, @selector(mouseUp:));
	Method newMouseUpMethod = class_getInstanceMethod(SwizzleView, @selector(mouseUp:));
	
	IMP newMouseUp = method_getImplementation(newMouseUpMethod);
	oldMouseUp = method_getImplementation(oldMouseUpMethod);
	method_setImplementation(oldMouseUpMethod, newMouseUp);
	
	
	self = [super initWithWindowNibName:@"3DROIManager"];
	if(!self) return nil;

	self.curROIlist = [NSMutableArray array];
	self.centerList = [NSMutableArray array];
	self.deleteLaterList = [NSMutableArray array];
	viewer = [v retain];

	if(viewer.blendingController == nil) isFusion = NO;
	else isFusion = YES;
	if(isFusion)
	{
		[viewer.blendingController setWL:1200 WW:2400]; //very good viewing window, only shows bones
		[[viewer.blendingController window] orderOut:self]; //hides other window also
		[[viewer.blendingController window] performMiniaturize:self];
	}
	
	if([[viewer modality] isEqualToString:@"PT"])
	{ 
		[viewer ApplyCLUTString:@"Rainbow"];
		[viewer ApplyConvString:@"Gaussian blur"]; //apply Gaussian blur on PET to make it look better
	}

	[[viewer window] orderOut:self]; //only removes window from screen list, effectivly hiding it
	[[viewer window] performMiniaturize:self];

	maxFrames = [v maxMovieIndex]; 	activeFrame = [v curMovieIndex];	activeSlice = [v imageIndex];	maxSlices = [[v pixList:0] count];

	[frameNavigator setFloatValue:activeFrame];
	movez = 0.f;
	if(maxFrames > 1)
	{ //grabs frame information for dynamic scans
		[playButton setEnabled:YES];
		ElapsedTime = [[NSMutableArray array] retain];
		int i, timepassed=0;
		for (i=0; i<maxFrames; i++) 
		{
			[ElapsedTime addObject:[NSNumber numberWithInt:timepassed]];
			timepassed = timepassed + [[[viewer pixList:i] objectAtIndex:0] frameDuration]/1000;
		}
	}
	
	[self.window setFrameAutosaveName:@"3DROIManagerWindow"];
	[self.window setTitle:[[[[viewer pixList] objectAtIndex:0] seriesObj] valueForKey:@"name"]];
	self.start3DViewer;  
	self.startOrthoViewer;
	
	if (isFusion) 
		ShapesController = [[ThreeDGeometries alloc] initWithViewers:viewer :D3View :isFusion :FusionOrthoView:self];
	else 
		ShapesController = [[ThreeDGeometries alloc] initWithViewers:viewer :D3View :isFusion :orthoView:self];

	
	[self tabulateAllrois];	
	[tableView setDataSource:self];
	[tableView reloadData];
	
	if ([[viewer modality] isEqualToString:@"PT"]) 
	{
		if(maxFrames > 1)
			[TimeField setStringValue: [NSString stringWithFormat:@"Frame:1\nDuration: %i s\nTime:%@ s", 
										[[[viewer pixList:0] objectAtIndex:0] frameDuration]/1000, 
										[ElapsedTime objectAtIndex:0]]];		
		else
			[TimeField setStringValue:[NSString stringWithFormat:@"Scan Duration: %i s", [[[viewer pixList:activeFrame] objectAtIndex:0] frameDuration]/1000]];
	}

	self.startObservers;
	
	return self;
}

-(void) startObservers 
{
	NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];	
	[nc addObserver: self
           selector: @selector(CloseViewerNotification:)
               name: OsirixCloseViewerNotification
             object: nil];
	[nc addObserver: self
           selector: @selector(UpdateStatistics:)
               name: NSTableViewSelectionDidChangeNotification
             object: nil];
	[nc addObserver: self
           selector: @selector(roiListModification:)
               name: OsirixROIChangeNotification
             object: nil];
	[nc addObserver: self
           selector: @selector(fireUpdate:)
               name: OsirixRemoveROINotification
             object: nil];
	[nc addObserver: self
           selector: @selector(updateContrast:)
               name: OsirixChangeWLWWNotification
             object: nil];
	[nc addObserver: self
           selector: @selector(updateCLUT:)
               name: OsirixCLUTChangedNotification
             object: nil];
}

-(void) start3DViewer
{
	NSRect mainscreen = [[NSScreen mainScreen] frame];
	NSPoint TopLeft = NSMakePoint(0.0, mainscreen.size.height-20.0);
	NSRect  ThreeDPanel = NSMakeRect(0.0, 0.0, mainscreen.size.width*.5, mainscreen.size.height*.9);

	// default opening settings: for 3D, Rainbow for PET
	D3View = [viewer openVRViewerForMode:@"MIP"];
	[D3View retain];
	[D3View setModeIndex: 1];
	if ([[viewer modality] isEqualToString:@"PT"]) [D3View ApplyCLUTString: @"Rainbow"];
	float   iwl, iww;
	[[viewer imageView] getWLWW:&iwl :&iww];
	[D3View setWLWW:iwl :iww];
	[viewer place3DViewerWindow: D3View];
	[D3View load3DState];
	[[D3View window] setFrame:ThreeDPanel display:NO];
	[[D3View window] setFrameTopLeftPoint:TopLeft];
	[D3View showWindow:self];			
	[[D3View window] makeKeyAndOrderFront:self];
	[[D3View window] display];
	[[D3View window] setTitle: [NSString stringWithFormat:@"%@: %@", [[D3View window] title], [[viewer window] title]]];

}

-(void) startOrthoViewer {	
	NSRect mainscreen = [[NSScreen mainScreen] frame];
	NSRect  OrthoPanel = NSMakeRect(0.0, 0.0, mainscreen.size.width*.5, mainscreen.size.height*.7);
	NSPoint TopLeft = NSMakePoint(mainscreen.size.width*.5, mainscreen.size.height-20.0);
	if (isFusion) {
		FusionOrthoView = [viewer openOrthogonalMPRPETCTViewer];
		[FusionOrthoView retain];
		[[FusionOrthoView window] makeKeyAndOrderFront:self];
		[[FusionOrthoView window] setFrame:OrthoPanel display:NO];
		[[FusionOrthoView window] setFrameTopLeftPoint:TopLeft];
		[[FusionOrthoView window] setTitle: [NSString stringWithFormat:@"Orthogonal MPR"]];
		[[FusionOrthoView window] orderOut:self];
	}
	else {
		orthoView = [viewer openOrthogonalMPRViewer];
		[orthoView retain];
		[[orthoView window] makeKeyAndOrderFront:self];
		
		[[orthoView window] setFrame:OrthoPanel display:NO];
		[[orthoView window] setFrameTopLeftPoint:TopLeft];
		[orthoView showWindow:self];
	
		float   iwl, iww;
		[[viewer imageView] getWLWW:&iwl :&iww];
		[orthoView setWLWW:iwl :iww];	
		[[orthoView window] setTitle:[[viewer window] title]];

		[[orthoView window] orderOut:self];
	}
}


-(void) CloseViewerNotification:(NSNotification*) note
{	
	if( [note object] == viewer)
	{
		NSLog( @"3DROIManager CloseViewerNotification");
		[self windowWillClose:nil];
	}
}

- (void)windowWillClose:(NSNotification *)notification
{
	[self release];
}


- (void) dealloc
{
	Class  VR			= objc_getClass("VRView");
	Method oldClick = class_getInstanceMethod(VR, @selector(mouseDown:));
	method_setImplementation(oldClick, oldClickImp);
	
	Class oldView = objc_getClass("DCMView");
	Method oldMouseUpMethod = class_getInstanceMethod(oldView, @selector(mouseUp:));
	method_setImplementation(oldMouseUpMethod, oldMouseUp);

	
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
	[ShapesController release];
	if (ElapsedTime) [ElapsedTime release];
	
	[[D3View window] orderOut:self];
	[D3View release];
	[[NSNotificationCenter defaultCenter] postNotificationName: NSWindowWillCloseNotification object: [D3View window] userInfo: 0]; //dumb thing we must include to fully dealloc everything in VRController
	
	[tableView setDataSource: nil];
	
	self.curROIlist =nil;
	self.deleteLaterList = nil;
	self.centerList = nil;
	
	if(isFusion)
	{
		[FusionOrthoView release];
		[[[viewer blendingController] window] makeKeyAndOrderFront:self];
	}
	else 
	{
		[orthoView release];
		[[orthoView window] performClose: self];			
	}
	
	[[viewer window] makeKeyAndOrderFront:self];
	[viewer release];
	[super dealloc];
}


#pragma mark -
#pragma mark UI
- (void) drawCLUTbar {
	
	//allocates space for the CLUT Table, grabs it from the viewer, and send it to our CLUTBar
	unsigned char redTable[256], greenTable[256],blueTable[256];
	unsigned char *red, *green, *blue;
	red = (unsigned char *)&redTable[0]; green = (unsigned char *)&greenTable[0]; blue = (unsigned char *)&blueTable[0];
	[viewer.imageView getCLUT:&red:&green:&blue];
	
	[CLUTColumn setCLUT:red :green :blue];
	[[CLUTColumn openGLContext] makeCurrentContext];
	[CLUTColumn update];
}


-(void) updateCLUT:(NSNotification*) note
{	//grabs OsiriCLUTChangedNotification from viewerController about CLUT change, updates our view
	if(ignoreUpdateContrast) return;
	[self drawCLUTbar];
}

- (IBAction)toggleWindowLock:(id)sender
{	
	//makes sure our lock button state changing the preferences
	if(LockMin.state != NSOnState){
		[VisibleMin setEnabled:YES];
		[[NSUserDefaults standardUserDefaults] setInteger:0 forKey: @"PETWindowingMode"];
	}
	else{
		[[NSUserDefaults standardUserDefaults] setInteger:1 forKey: @"PETWindowingMode"];
		[[NSUserDefaults standardUserDefaults] setInteger:[VisibleMin intValue] forKey: @"PETMinimumValue"];
		[VisibleMin setEnabled:NO];
	}
}
- (IBAction) updateWindows:(id)sender
{
	
	if (([VisibleMax floatValue] - [VisibleMin floatValue])>0){
		//		NSLog(@"Updating wlww");
		float wl = ([VisibleMax floatValue] + [VisibleMin floatValue])/2.;
		float ww = ([VisibleMax floatValue] - [VisibleMin floatValue]);
		[viewer.imageView setWLWW:wl :ww];
		[D3View setWLWW:wl :ww];
		if(isFusion) [FusionOrthoView setWLWW: wl :ww :nil];
		else [orthoView setWLWW: wl :ww];
	}
}
-(void) updateContrast:(NSNotification*) note
{
	//responds to OsirixChangeWLWWNotification, which is sent from a DCMPIX 
	//updates WLWW on textboxes, 3D View.
	if(ignoreUpdateContrast) return;
	DCMPix	*otherPix = [note object];
	NSString *modality = [otherPix modalityName];
	
	if ([modality isEqualToString:@"PT"]) {		
		float iwl, iww;
		iww = [otherPix ww];
		iwl = [otherPix wl];
		[VisibleMax setFloatValue:iwl+iww/2];
		[VisibleMin setFloatValue:iwl-iww/2];
		[D3View setWLWW:iwl :iww];
	
		if(isFusion){
			//ignoreUpdateContrast in our CT, or else will go into infinite loop
			ignoreUpdateContrast=YES;
			[FusionOrthoView setWLWW: iwl: iww:[FusionOrthoView CTController]];
			ignoreUpdateContrast=NO;
		}
		[[D3View view] setNeedsDisplay:YES];
		
	}
	else if([modality isEqualToString:@"CT"]){
		float iwl, iww;
		iww = [otherPix ww];
		iwl = [otherPix wl];
		if(viewer.blendingController){
			[viewer.blendingController setWL:iwl WW:iww];
			[D3View updateBlendingImage];
		}
		else
			[D3View setWLWW:iwl :iww];
		
	
	}
}



#pragma mark -
#pragma mark Handling ROI Lists


- (void) deleteThisROI: (ROI*) roi
{	//need to implement for dynamic sets, or else delete only works on one frame
	//scrolls through EVERY image, looking for ROI with the same name as input.
	int x,i,k;
	[viewer.imageView stopROIEditingForce: YES];
	for(k=0; k<maxFrames;k++){
		
	for(x = 0; x < [[viewer pixList:k] count]; x++)
	{
		for(i = 0; i < [[[viewer roiList:k] objectAtIndex: x] count]; i++)
		{
			ROI	*curROI = [[[viewer roiList:k] objectAtIndex: x] objectAtIndex: i];
			if( curROI == roi)
			{
				[[NSNotificationCenter defaultCenter] postNotificationName: OsirixRemoveROINotification object:curROI userInfo: nil];
				[[[viewer roiList:k] objectAtIndex: x] removeObject:curROI];
				i--;
			}
		}
	}
	}
}
NSInteger sortbyroiname(NSMutableDictionary *obj1, NSMutableDictionary *obj2, void *reverse){
	//function to sort ROIs by name
	return [[obj1 objectForKey:@"name"] localizedCaseInsensitiveCompare:[obj2 objectForKey:@"name"]];
}

-(void) tabulateAllrois{
	
	[curROIlist removeAllObjects];
	[centerList removeAllObjects];
	int j;
	if(deleteLaterList.count > 0) {
		NSLog(@"Deleting Now");
		for(j=0; j< [deleteLaterList count]; j++) 
			[self deleteThisROI:[deleteLaterList objectAtIndex:j]];
		
		[deleteLaterList removeAllObjects];
		
		if(isFusion)
			[[FusionOrthoView CTController] refreshViews];
		else
			[[orthoView controller] refreshViews];
		
	}	
	
	if(deleteLaterList.count == 0)
	{
	}
	int frameNo, sliceNo, roiNo;
	//going through each frame, slice and then down the roilist, looking at each individual ROI.
	for (frameNo = 0; frameNo < maxFrames; frameNo++){
		for( sliceNo = 0; sliceNo < maxSlices; sliceNo++){
			int maxROIs = [[[viewer roiList:frameNo] objectAtIndex:sliceNo] count];
			for (roiNo = 0; roiNo < maxROIs; roiNo++)
			{
				ROI *curROI = [[[viewer roiList:frameNo] objectAtIndex:sliceNo] objectAtIndex: roiNo];
				[curROI setPix: [[viewer pixList:frameNo] objectAtIndex:sliceNo]];
			
				// if the name is in the index, add to slice array (active frame only), and frame array;
				if ([self nameInIndex: [curROI name]]){
					int index = [self indexforROIname:[curROI name]];
					
					NSMutableArray *frames = [[curROIlist objectAtIndex:index] objectForKey: @"frames"];			
					if (frameNo == activeFrame){ //if in active frame, add current slices
						[[[curROIlist objectAtIndex:index] objectForKey: @"slices"] addObject: [NSNumber numberWithInt:sliceNo]];}
					
					if (![frames containsObject:[NSNumber numberWithInt:frameNo]]) { //if framenumber is not added, add it to the array
						[[[curROIlist objectAtIndex:index] objectForKey: @"frames"] addObject:[NSNumber numberWithInt:frameNo]]; }
				}
				else if([[curROI name] hasSuffix:@"center"] || [[curROI name] hasSuffix:@"ellipse"]){ 
					[centerList addObject: curROI];
				}
				else if([[curROI name] hasSuffix:@"about to be deleted"]){ 
					//ignore
				}
				else { // if name is new, initialize new NSMutableDictionary for this value	
					NSMutableDictionary *newLine = [NSMutableDictionary dictionary];
					NSMutableArray *frames = [NSMutableArray array];
					NSMutableArray *slices = [NSMutableArray array];
					
					if (frameNo == activeFrame) {
						[slices addObject:[NSNumber numberWithInt:sliceNo]];
					}
					
					[frames addObject:[NSNumber numberWithInt:frameNo]];
					[newLine setObject:curROI forKey:@"roi"];
					[newLine setObject:curROI.name forKey:@"name"];
					[newLine setObject:frames forKey:@"frames"];
					[newLine setObject:slices forKey:@"slices"];
					[curROIlist addObject:newLine];
				}
			}
		}
	}
	
	//now sort the list, because we want the table to be displayed alphabetically
	[curROIlist sortUsingFunction:sortbyroiname context:NULL];
}


- (BOOL) nameInIndex: (NSString*)compared
{	//utility function used by tabulateROIs to check if the ROI is new or is already in the array
	int i;
	for (i=0; i < [curROIlist count]; i++) { 
		ROI *tempROI = [[curROIlist objectAtIndex:i] objectForKey:@"roi"];
		if ([[tempROI name] isEqualToString: compared]) return YES;
	}
	return NO;
}

- (int) indexforROIname:(NSString *)compared;
{	//utility function used by tabulateROIs to return index for an ROI, returns 0 for empty curROIlist
	int i;
	if ([curROIlist count] == 0) return 0;
	else {
		for (i=0; i < curROIlist.count; i++) { 
			ROI *tempROI = [[curROIlist objectAtIndex:i] objectForKey:@"roi"];
			if ([[tempROI name] isEqualToString: compared]){
				return i;
			}
		}
	}
	return 0;
}

#pragma mark -
#pragma mark Handling TableView
-(void) refreshForFrame:(int)newframe {
	//changes the slider to indicate the new frame number, updates active frame
	[frameNavigator setIntValue:newframe];
	activeFrame= newframe;
}

- (void)tableView:(NSTableView *)aTableView   setObjectValue:(id)anObject   forTableColumn:(NSTableColumn *)aTableColumn		  row:(NSInteger)rowIndex
{
	//Method called when we change ROI name in table
	if( [[aTableColumn identifier] isEqualToString:@"roiName"] && anObject)	{
		ROI				*editedROI = [[curROIlist objectAtIndex: rowIndex] objectForKey:@"roi"];
		if (editedROI.locked) {
			//error message
			NSAlert *myAlert = [NSAlert alertWithMessageText:@"ROI is Locked" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@""]; [myAlert runModal];
			[self tabulateAllrois]; 
			return;
			
		}
		
		//rename center point
		int i;
		for(i=0;i<[centerList count];i++){
			if([[[centerList objectAtIndex:i] name] hasPrefix:[editedROI name]]){
				ROI *point = [centerList objectAtIndex:i];
				NSString *newName = [anObject stringByAppendingString:[[[centerList objectAtIndex:i] name] substringFromIndex: [editedROI.name length]]];
				point.locked = NO;
				point.name = newName;
			}
		}
		
		//rename all on all other slices
		NSArray *stackofROIs = [NSArray array];
		stackofROIs = [viewer roisWithName: [editedROI name] in4D:YES];
		for(i=0;i<[stackofROIs count];i++){
			ROI *current = [stackofROIs objectAtIndex:i];
			current.name = anObject;
		}

		[self tabulateAllrois];
		
		}
}

- (void) roiListModification: (NSNotification*) note
{	
	
	if ((maxFrames > 1) || (viewer.curMovieIndex != activeFrame)) [self refreshForFrame:viewer.curMovieIndex];
	else [self refreshForFrame:0];

	if([[[note userInfo] objectForKey:@"action"] isEqualToString:@"mouseUp"]) return;
	[self tabulateAllrois];
	[tableView reloadData];

}


- (void) fireUpdate: (NSNotification*) note
{
	[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(roiListModification:) userInfo:nil repeats:NO];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{    return [curROIlist count];}

- (id)tableView:(NSTableView *)tableView
objectValueForTableColumn:(NSTableColumn *)tableColumn
            row:(NSInteger)row
{	//method that is called to fill out table
	//depending on tableColumn identifier (set in XIB file), gives appropriate output
	
	if( [[tableColumn identifier] isEqualToString:@"roiName"]) return [[curROIlist objectAtIndex:(row)] objectForKey: @"name"];
	if( [[tableColumn identifier] isEqualToString:@"roiType"])
	{ 
		ROI *selectedROI = [[curROIlist objectAtIndex:(row)] objectForKey: @"roi"];
		
		if([selectedROI type] == t2DPoint) return @"Point";
		if([selectedROI type] == tOval) return @"3DObject";
		if([selectedROI type] == tPlain) return @"Growing Region";		
	}
	
	if( [[tableColumn identifier] isEqualToString:@"roiIsLocked"])
	{
		ROI *selected =  [[curROIlist objectAtIndex:(row)] objectForKey: @"roi"];
		if (selected.locked) return @"Yes";
		else return @"No";
	}
	
	if( [[tableColumn identifier] isEqualToString:@"framesExist"])
	{
		if (maxFrames == 1) return @"N/A";
		else {
			NSMutableArray *frames =  [[curROIlist objectAtIndex:(row)] objectForKey: @"frames"];
			if (frames.count == maxFrames) return @"All";
			else if (frames.count > 1) return @"Partial"; 
			else return @"No";
		}
	}
	return nil;
}

-(ROI*)centerForOrthoROI:(ROI*)orth
{
	ROI *centerObject = nil;
	unsigned int i = 0;
	while (!centerObject)
	{
		if (i==[centerList count]) return nil;
		
		if ([[[centerList objectAtIndex:i] name] hasPrefix:orth.name]) 
			centerObject = [centerList objectAtIndex:i];
		i++;
		
	}
	return centerObject;
	
}

- (NSMutableDictionary *) getCenterROI:(ROI *)roiofinterest {
	//gets called by moveSphere, identifies the middle slice of a 3D ROI and returns it
	int					i;
	ROI					*selectedROI;
	NSMutableArray		*slices = [NSMutableArray array];
	NSMutableDictionary *returnvalues = [NSMutableDictionary dictionary];
	
	//get the correct array
	for (i=0; i<[curROIlist count]; i++){		
		if ([roiofinterest.name isEqualToString: [[[curROIlist objectAtIndex:i] objectForKey: @"roi"] name]]) {
			
			selectedROI = [[curROIlist objectAtIndex:i] objectForKey: @"roi"];
			slices =  [[curROIlist objectAtIndex:i] objectForKey: @"slices"];
			int middleofArray, arraysize,slicePosition; arraysize = [slices count]; middleofArray = floor(arraysize/2.0);
	
			if (arraysize == 1) middleofArray = 0;
			if ([[viewer imageView] flippedData]) slicePosition = maxSlices - 1 - [[slices objectAtIndex:middleofArray] intValue];
			else slicePosition = [[slices objectAtIndex:middleofArray] intValue];
						
			[returnvalues setObject:[NSNumber numberWithInt:slicePosition] forKey:@"middleslice"];			
			[returnvalues setObject:selectedROI forKey:@"roi"];
		}
	}
	return returnvalues;
}

- (void) UpdateStatistics: (NSNotification *) notification
{
    int row;
	if([notification object] != tableView) return;
    row = [tableView selectedRow];
	
	NSLog(@"Calling update");
    if (row == -1){
		
		[ROIStatisticsField setStringValue:@"\n\n\n\nNo ROI Selected"];
		[ShowButton setEnabled:NO];
		[HideButton setEnabled:NO];
		[DeleteButton setEnabled:NO];
		[GoToButton setEnabled:NO];
		[ChangeRadiusButton setEnabled:NO];
		[StartVolumeButton setEnabled:NO];
		[GenerateTACButton setEnabled:NO];
		[LockROIButton setEnabled:NO];
	}
	else {
		

		if (maxFrames >1){
			[GenerateTACButton setEnabled:YES];
			if(![[[curROIlist objectAtIndex:row] objectForKey:@"frames"] containsObject:[NSNumber numberWithInt:activeFrame]]) {
				int i;
				
				NSMutableString *output = [NSMutableString stringWithFormat:@"ROI does not exist on current frame, only on: "];
				for(i=0; i< [[[curROIlist objectAtIndex:row] objectForKey:@"frames"] count]; i++) [output appendFormat:@"%i,", [[[[curROIlist objectAtIndex:row] objectForKey:@"frames"] objectAtIndex:i] intValue] + 1];
				[output deleteCharactersInRange:NSMakeRange([output length]-1, 1)];
				[ROIStatisticsField setStringValue:output];
				
				//disable all buttons
				[ShowButton setEnabled:NO];
				[HideButton setEnabled:NO];
				[DeleteButton setEnabled:NO];
				[StartVolumeButton setEnabled:NO];
				[GenerateTACButton setEnabled:NO];
				[LockROIButton setEnabled:NO];
				
				return;
			}	
		}
		
		[LockROIButton setEnabled:YES];

		ROI *selectedROI = [[curROIlist objectAtIndex:row] objectForKey: @"roi"];
		
		// changes the color in 3DView for selected ROI
		int k=0;
		for(;k<[D3View.roi2DPointsArray count]; k++){
			ROI *current = [D3View.roi2DPointsArray objectAtIndex:k];
			if([current.name hasPrefix: selectedROI.name]){
				[D3View.view set3DPointAtIndex:k Color:[NSColor colorWithCalibratedRed:.5 green:0.5 blue:0.5 alpha:1.0]];
				
			}
			else {
				[D3View.view set3DPointAtIndex:k Color:[NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.0 alpha:1.0]];
			}

		}
		[D3View.view setNeedsDisplay:YES];
		
		//locked status changes deletebutton
		if(selectedROI.locked){
			[LockROIButton setTitle:@"Unlock"];
			[DeleteButton setEnabled:NO];
		}
		else{
			[LockROIButton setTitle:@"Lock"];
			[DeleteButton setEnabled:YES];
		}
		if([selectedROI type] == t2DPoint) {
		[ShowButton setEnabled:NO];
		[HideButton setEnabled:NO];
		[StartVolumeButton setEnabled:NO];
		[GenerateTACButton setEnabled:NO];
		[GoToButton setEnabled:YES];

			
		[ROIStatisticsField setStringValue:@"Point"];
		}
		else if(([selectedROI type] == tOval) || ([selectedROI type] == tPlain) ) {
			[ShowButton setEnabled:YES];
			[HideButton setEnabled:YES];
			[GoToButton setEnabled:YES];
			
			if(([selectedROI type] == tOval)) [ChangeRadiusButton setEnabled:YES];
			else [ChangeRadiusButton setEnabled:NO];
			
			[StartVolumeButton setEnabled:YES];

			
			
			
			NSMutableString *output = [[NSMutableString stringWithFormat:@"%@\n",selectedROI.name] retain];
			NSMutableDictionary *stats = [NSMutableDictionary dictionaryWithDictionary:[viewer computeTAC:selectedROI onframe:activeFrame withFrame:activeFrame]];

			[output appendFormat:@"Max: %2.3f\nMean: %2.3f\nMin: %2.3f\nStandard Dev: %2.3f\nTotal: %2.3f", [[stats valueForKey:@"max"] doubleValue], [[stats valueForKey:@"mean"] doubleValue]
			 , [[stats valueForKey:@"min"] doubleValue], [[stats valueForKey:@"dev"] doubleValue],[[stats valueForKey:@"total"] doubleValue]];
			
			[ROIStatisticsField setStringValue:output];
			
			[output release];
		}

		else if([selectedROI type] == tCPolygon) {
			[ChangeRadiusButton setEnabled:NO];
			[ShowButton setEnabled:NO];
			[HideButton setEnabled:NO];
			[LockROIButton setEnabled:YES];
			[GoToButton setEnabled:YES];
			[StartVolumeButton setEnabled:NO];
			if (maxFrames >1) [GenerateTACButton setEnabled:YES];
			[ROIStatisticsField setStringValue:@"Mask Region"];
		}
		else {
			[ChangeRadiusButton setEnabled:NO];
			[ShowButton setEnabled:NO];
			[HideButton setEnabled:NO];
			[GoToButton setEnabled:NO];
			[StartVolumeButton setEnabled:NO];
			[GenerateTACButton setEnabled:NO];
			[ROIStatisticsField setStringValue:@"*******\nNot a Recognizable Volume\n********"];
		}	
	}
	
}

// delegate method setROIMode

#pragma mark -
#pragma mark Slider

- (void) initSlider {
	[frameNavigator setTitle:@"Frame Navigator"];
	[frameNavigator setMinValue:0];
	[frameNavigator setMaxValue:(maxFrames-1)];
	[frameNavigator setAllowsTickMarkValuesOnly:YES];
	
	[frameNavigator setNumberOfTickMarks:maxFrames];
	[frameNavigator setTickMarkPosition:NSTickMarkBelow];
	[frameNavigator setIntValue:0];	
}

- (IBAction) gotoFrame:(id)sender{
	// called on changing frameslider, updates all windows to the correct time frame

//	NSLog(@"Max:%f, Min,%f", [D3View maximumValue], [D3View maximumValue]);
	if (maxFrames == 1) return;
	int newframe = [frameNavigator integerValue];
	[D3View setMovieFrame:newframe];
	
	if (isFusion) [FusionOrthoView setMovieIndex:newframe];
	else [orthoView setMovieIndex:newframe];
	[viewer setMovieIndex:newframe];
	[self refreshForFrame:newframe];
	[self UpdateStatistics:nil];

	[TimeField setStringValue: [NSString stringWithFormat:@"Frame:%i\nDuration: %i s\nTime:%@ s", newframe+1, 
								[[[viewer pixList:activeFrame] objectAtIndex:0] frameDuration]/1000, 
								[ElapsedTime objectAtIndex:activeFrame]]];
}

-(ROI *) ROIForSelectedIndex {
	//utility function returns ROI object for a selected index in the table
	NSInteger index;
	NSIndexSet* indexSet = [tableView selectedRowIndexes];
	index = [indexSet lastIndex];
	if ((index == NSNotFound) || index < 0) return nil;
	ROI *selectedROI = [ROI alloc];
	selectedROI = [[curROIlist objectAtIndex:index] objectForKey:@"roi"];
	return selectedROI;
}

#pragma mark -
#pragma mark Buttons and actions

-(void)keyDown:(NSEvent *)theEvent
{
	
	unichar c = [[theEvent characters] characterAtIndex:0];
	
	if (tableView.selectedRow == -1) 
		return;
	
    if( c == NSDeleteFunctionKey || c == NSDeleteCharacter || c == NSBackspaceCharacter || c == NSDeleteCharFunctionKey)
		[self deleteVolume:self];
	
}


- (IBAction) playFrames:(id)sender {
	//yet to be implemented, supposed to respond to play button, so we could play through all the frames of a dynamic image like a movie
	[NSTimer scheduledTimerWithTimeInterval:1.0
									 target:self
								   selector:@selector(nextframe:)
								   userInfo:nil
									repeats:YES];
}

- (void)nextframe:(NSNotification *) note {
	if (activeFrame < maxFrames) [self refreshForFrame:activeFrame+1];
}

- (IBAction) openOrthView:(id)sender 
{
	//button to show orthoview, which is auto hidden
	if(isFusion)
	{
		if(!FusionOrthoView) [self startOrthoViewer];
		else if(![[FusionOrthoView window] isVisible]) [[FusionOrthoView window] makeKeyAndOrderFront:self];
	}
	else 
	{
		if (!orthoView) [self startOrthoViewer];
		else if(![[orthoView window] isVisible]) 	[[orthoView window] makeKeyAndOrderFront:self];
	}
	
}
- (IBAction) openSphereDrawer:(id)sender 
{
	//makes ThreeDGeometries window visible again.
	[ShapesController showWindow:self];
	
}

- (IBAction) exportAllROIs:(id)sender 
{
	//Allows all roi values to be saved in a text file
	
	//opens up save panel, where to place our file
	NSSavePanel* exportTAC= [NSSavePanel savePanel];
	[exportTAC setTitle:@"Export All TACs as text"];
	[exportTAC setPrompt:@"Export"];
	[exportTAC setCanCreateDirectories:1];
	[exportTAC setAllowedFileTypes:[NSMutableArray arrayWithObject:@"txt"]];
	NSString* filename = [[viewer window] title];

	[exportTAC beginSheetForDirectory:nil file: filename modalForWindow:[self window] 
						modalDelegate:self didEndSelector:@selector(saveAsPanelDidEnd:returnCode:contextInfo:) contextInfo: NULL];
}

-(void)saveAsPanelDidEnd:(NSSavePanel*)panel returnCode:(int)code contextInfo:(void*)format 
{
	//gets called if save panel is OK
	//seriesDescription
	if(code == NSOKButton){
		int i;
		NSError* error = 0;
		NSString *header = [NSString string];
		
		DCMPix *curPix = [[viewer pixList] objectAtIndex:0];
		
		NSMutableString *content = [[NSMutableString alloc] init];
		[content appendFormat:@"%@\n",[[viewer window] title]];
		if ( [curPix appliedFactorPET2SUV] == 1.0){
			[content appendString:[curPix returnUnits]];}
		else {
			[content appendString:@"%ID/g"];
		}

		[content appendString:@"\n"];
		if (maxFrames>1) {
			header = @"Frame\tDuration\tStart Time\tMax\tMean\tMin\tStDev\tTotal\n";
		}
		else{
			header = @"Name\tMax\tMean\tMin\tStDev\tTotal\n";
			[content appendString:header];
		}
		
			
		for(i=0;i<[curROIlist count];i++){
			ROI *selectedROI = [ROI alloc];
			//header string
			
			selectedROI = [[curROIlist objectAtIndex:i] objectForKey:@"roi"];
			
			if([selectedROI type] == tOval || [selectedROI type] == tPlain || [selectedROI type] == cPolygon)
			{
				NSString *name = [selectedROI name];
				NSMutableDictionary *stats = [NSMutableDictionary dictionary];
				
				if (maxFrames >1){
					int k, frameduration;
					[content appendFormat: @"%@\n", name];
					[content appendString:header];
					
					for (k=0;k<[[[curROIlist objectAtIndex:i] objectForKey:@"frames"] count];k++){
						
						int framenumber = [[[[curROIlist objectAtIndex:i] objectForKey:@"frames"] objectAtIndex:k] intValue];
						frameduration = [[[viewer pixList:framenumber] objectAtIndex:0] frameDuration]/1000;
						
					stats = [viewer computeTAC:selectedROI onframe:framenumber withFrame:framenumber];
						
					[content appendFormat:@"%i\t%i\t%i\t%3.3f\t%3.3f\t%3.3f\t%2.3f\t%2.3f\n", k+1, frameduration, [[ElapsedTime objectAtIndex:framenumber] intValue], [[stats valueForKey:@"max"] floatValue], [[stats valueForKey:@"mean"] floatValue]
				 , [[stats valueForKey:@"min"] floatValue], [[stats valueForKey:@"dev"] floatValue],[[stats valueForKey:@"total"] floatValue]];

					}
					
				}
				else{
					[content appendFormat: @"%@\t", name];
					stats = [viewer computeTAC:selectedROI onframe:activeFrame withFrame:activeFrame];
					[content appendFormat:@"%3.3f\t%3.3f\t%3.3f\t%2.3f\t%2.3f\n", [[stats valueForKey:@"max"] floatValue], [[stats valueForKey:@"mean"] floatValue]
					 , [[stats valueForKey:@"min"] floatValue], [[stats valueForKey:@"dev"] floatValue],[[stats valueForKey:@"total"] floatValue]];
			
				}
			}
		}
		[content writeToFile:[panel filename] atomically:YES encoding:NSUTF8StringEncoding error:&error];
	}
}

- (IBAction) ShowROI:(id)sender
{
	// makes the contour visible in 3D
	
	
	NSMutableArray *ar = [D3View roiVolumes];
	int i;
	
//	NSLog(@"ROIVOLUMES ARRAY: %@", this);
//	[D3View displayROIVolumes];

	ROI *selectedROI = [self ROIForSelectedIndex];
	if(!selectedROI) return;
	
	float slicePosition;
	NSMutableDictionary *roiandposition = [NSMutableDictionary dictionary];
	
	roiandposition = [self getCenterROI:selectedROI];
	
	selectedROI = [roiandposition objectForKey:@"roi"];
	slicePosition = [[roiandposition objectForKey:@"middleslice"] floatValue];
	
	for(i=0; i<[ar count]; i++){
		ROIVolume *current;
		current = [ar objectAtIndex:i];
		if ([[selectedROI name] isEqualToString: [current name]]) {
			id ar = [[current properties] valueForKey:@"visible"];
			NSLog(@"visible? %@", ar);
			NSLog(@"MY name is : %@", [current name]);
			[D3View displayROIVolume:current];
			break;
//			[D3View hideROIVolume:current];
		}
	}
	[[D3View view] setNeedsDisplay:YES];
	
}	
- (IBAction) HideROI:(id)sender {
	//makes the contour invisible in 3D
	NSMutableArray *ar = [D3View roiVolumes];
	int i;
	
//	NSLog(@"ROIVOLUMES ARRAY: %@", this);
//	[D3View displayROIVolumes];
	
	ROI *selectedROI = [self ROIForSelectedIndex];
	if(!selectedROI) return;
	float slicePosition;
	NSMutableDictionary *roiandposition = [NSMutableDictionary dictionary];
	
	roiandposition = [self getCenterROI:selectedROI];
	
	selectedROI = [roiandposition objectForKey:@"roi"];
	slicePosition = [[roiandposition objectForKey:@"middleslice"] floatValue];
	
	for(i=0; i<[ar count]; i++){
		ROIVolume *current;
		current = [ar objectAtIndex:i];
		if ([[selectedROI name] isEqualToString: [current name]]) {
			
//			NSLog(@"MY name is : %@", [current name]);
			[D3View hideROIVolume:current];
			break;
		}
	}
	[[D3View view] setNeedsDisplay:YES];

}

- (IBAction) gotoSlice:(id)sender
{
	NSInteger index;
	NSIndexSet* indexSet = [tableView selectedRowIndexes];
	index = [indexSet lastIndex];
	if ((index == NSNotFound) || index < 0) return;
	
	NSMutableArray *frames = [[curROIlist objectAtIndex:index] objectForKey:@"frames"];
	
	if(![frames containsObject:[NSNumber numberWithInt:viewer.curMovieIndex]])
	{ 
		[viewer setMovieIndex:[frames.lastObject intValue]];
		[self refreshForFrame:[frames.lastObject intValue]];
	}
	
	ROI *selectedROI;
	float slicePosition;
	NSMutableDictionary *roiandposition = [[self getCenterROI:[[curROIlist objectAtIndex:index] objectForKey:@"roi"]] retain];
	
	selectedROI = [[roiandposition objectForKey:@"roi"] retain];
	slicePosition = [[roiandposition objectForKey:@"middleslice"] floatValue];
	[roiandposition release];
//	if I->S, positive
//	if S->I, negative
		
	int x = selectedROI.centroid.x; int y = selectedROI.centroid.y;
	[viewer setImageIndex:slicePosition];

	NSLog(@"");
	if(isFusion) {
		[[[FusionOrthoView PETCTController] originalView] setCrossPosition:x:y];
		int MPRoffset = [[[[FusionOrthoView PETCTController] originalDCMPixList] objectAtIndex:0] ID];
		int MPRslicemax = [[[FusionOrthoView PETCTController] originalDCMPixList] count] +MPRoffset;
		[[[FusionOrthoView PETCTController] yReslicedView] setCrossPosition:y: MPRslicemax - slicePosition-.5];
	}
	else {
	[[[orthoView controller] originalView] setCrossPosition:x:y];
	[[[orthoView controller] xReslicedView] setCrossPosition:x:maxSlices - slicePosition-.5];}
	
	[selectedROI release];

}

//not finished
- (IBAction) startVolume:(id)sender
{
	[viewer GenVolumefor:[self ROIForSelectedIndex]];
}

- (IBAction)generateTAC:(id)sender 
{
	NSInteger index;
	NSIndexSet* indexSet = [tableView selectedRowIndexes];
	index = [indexSet lastIndex];
	if ((index == NSNotFound) || index < 0) return;
	ROI	*selectedROI = [[curROIlist objectAtIndex:index] objectForKey:@"roi"];
	[selectedROI setROIMode: ROI_selected];

	[[DynamicInterface alloc] initWithViewer:viewer:selectedROI];
}

- (IBAction)lockROI:(id)sender {
	ROI *selectedROI = [self ROIForSelectedIndex];
	
	NSArray *rois = [NSArray array]; rois = [viewer roisWithName:[selectedROI name] in4D:YES];
	int j;
	for(j=0; j< [rois count]; j++) {
		ROI *temp = [rois objectAtIndex:j];
		temp.locked = !temp.locked;
	}
	
	//refresh view so roi status is updated.
	// i force a redraw by changing position x+1 and then moving it back
	float x,y;
	if(isFusion){
		x = [[[FusionOrthoView PETCTController] originalView] crossPositionX];
		y = [[[FusionOrthoView PETCTController] originalView] crossPositionY];
		[[[FusionOrthoView PETCTController] originalView] setCrossPosition:x+1:y];
		[[[FusionOrthoView PETCTController] originalView] setCrossPosition:x:y];
	}
	else {
		x = [[[orthoView controller] originalView] crossPositionX];
		y = [[[orthoView controller] originalView] crossPositionY];
		[[[orthoView controller] originalView] setCrossPosition:x+1:y];
		[[[orthoView controller] originalView] setCrossPosition:x:y];
	}

	//Change locked for point also
	for(j=0; j<[centerList count]; j++){
		if ([[[centerList objectAtIndex:j] name] hasPrefix:[selectedROI name]]) {
			ROI *temp = [centerList objectAtIndex:j];
			temp.locked = selectedROI.locked;
		}
	}
	
	//update what button says
	
//	[LockROIButton setImage:];
	[LockROIButton setTitle:@"Lock"];
	[DeleteButton setEnabled:YES];
	if (selectedROI.locked){
		[LockROIButton setTitle:@"Unlock"];
		[DeleteButton setEnabled:NO];
	}
	[tableView reloadData];

}

- (IBAction)deleteVolume:(id)sender
{
	
	NSInteger index;
	NSIndexSet* indexSet = [tableView selectedRowIndexes];
	index = [indexSet lastIndex];
	if ((index == NSNotFound) || index < 0) return;
	NSString *centername =nil;
	ROI	*selectedROI = [[curROIlist objectAtIndex:index] objectForKey:@"roi"];
		
	//post this notification so 3D object is removed from VRView
	[self HideROI:nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixRemoveROINotification object:selectedROI userInfo: nil];
	int i;
	for(i=0;i<[centerList count]; i++){//find corresponding sphere center
		if([[[centerList objectAtIndex:i]name] hasPrefix:[selectedROI name]]){
			centername = [NSString stringWithString:[[centerList objectAtIndex:i]name]];			
			break;
		}
	}
	
	NSArray *allrois = [NSMutableArray array];
	allrois = [viewer roisWithName:selectedROI.name in4D:YES];
	
	[tableView deselectAll:nil];

	if([selectedROI type] == tOval && ![selectedROI.name hasPrefix:@"Oval"]) {
		[viewer deleteAllSeriesROIwithName: centername withSlices:maxSlices];
	}

	[viewer deleteAllSeriesROIwithName: selectedROI.name withSlices:maxSlices];
	
	[self tabulateAllrois];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateViewNotification object:nil userInfo: nil];
}






@end
