//
//  DynamicInterface.m
//  DynamicROI
//
//  Created by Yang Yang on 3/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DynamicInterface.h"
#import <OsiriX Headers/ROI.h>
#import <OsiriX Headers/DCMPix.h>
#import <OsiriX Headers/DCMView.h>
#import <OsiriX Headers/ViewerController.h>
#import <Osirix Headers/Notifications.h>
#import <SM2DGraphView/SM2DGraphView.h>
#import "DMCPix+Yang.h"
#import "viewerController+Yang.h"

@implementation DynamicInterface

#pragma mark -
#pragma mark Initializing and Deallocation

- (id) initWithViewer:(ViewerController*) v:(ROI*)selectedROI
{
	
	self = [super initWithWindowNibName:@"DynamicROI"];
	if(!self) return nil;
	
	[[self window] setFrameAutosaveName:@"DynamicROIWindow"];; // triggers nib loading
	
	
	currentYDisplay = showMean;
	currentXDisplay = showStart;
	viewer = [v retain];
	
	totalframes = [viewer maxMovieIndex];
	activeFrame = [viewer curMovieIndex];
	xValues = [NSMutableArray arrayWithCapacity:totalframes];
	yValues = [NSMutableArray arrayWithCapacity:totalframes];
	activeROI = [selectedROI retain];
	NSLog(@"Initializing active ROI: %@", activeROI);
	TACData = [[NSMutableArray array] retain];
	timeData = [[NSMutableArray arrayWithCapacity:totalframes] retain];
    

	[self calculateTAC];
	[self calculateTime];
	

	[dynamicTable reloadData];
	if(TACData.count == timeData.count)
	{
		[self changeChartDataSource:@"blah"];
		[graphTAC refreshDisplay:self];
	}
	NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];	
	[nc addObserver: self
           selector: @selector(viewerWillClose:)
               name: OsirixCloseViewerNotification
             object: nil];
	
	return self;
}


-(void) windowWillClose:(NSNotification *)notification
{
	self.release;
}
-(void) viewerWillClose:(NSNotification*) note
{	
	if ([note object] == [self window])
	{
		NSLog( @"Dynamic Close Notification");
		self.release;
	}
}

-(void)dealloc
{
	
	// NSMutableArray				*TACData, *timeData;
	[dynamicTable setDataSource:nil];
	TACData.release;
	timeData.release;
	activeROI.release;
	
	NSLog(@"Deallocating Dynamic ROI");
	
	viewer.release;
	[super dealloc];
}

#pragma mark -
#pragma mark Data and Time Calculation

-(void) calculateTime
{
	int curFrame=0;
	DCMPix *curPix;
	int duration=0;
	int last=0;
	int midpoint=0;
	unitsoftime = 1000;
	//going through all the frames
	if (TACData.count == 0) return;
	
	for (curFrame=0; (curFrame)<(totalframes); curFrame++) {
		

		[viewer setMovieIndex:(curFrame)];
		
		curPix = [[viewer pixList] objectAtIndex:0];
		NSMutableDictionary *tempDictionary = [NSMutableDictionary dictionary];
		duration = [curPix frameDuration];
		duration = duration/unitsoftime;

		[tempDictionary setObject: [NSNumber numberWithInt: (curFrame+1)] forKey:@"Frame"];
		[tempDictionary setObject: [NSNumber numberWithInt: duration] forKey:@"Duration"];
		[tempDictionary setObject: [NSNumber numberWithInt: last] forKey:@"Start"];
		midpoint = ((2*last + duration)/2);
		[tempDictionary setObject: [NSNumber numberWithInt: midpoint] forKey:@"Midpoint"];
		last = last + duration;
		[tempDictionary setObject: [NSNumber numberWithInt: last] forKey:@"End"];
		
		[timeData addObject: tempDictionary];
	}
	
	
}

- (void) calculateTAC
{ 
	int curFrame;
	
	for (curFrame=0; (curFrame)<(totalframes); curFrame++) {
		[viewer setMovieIndex:(curFrame)];
		NSLog(@"Frame Number: %i", curFrame);
		//set into temp array
		NSMutableDictionary *tempDictionary = [viewer computeTAC:activeROI onframe:activeFrame withFrame:curFrame];
		
		// test code: NSLog(@"%d", [[tempDictionary valueForKey:@"mean"] floatValue]);
		if(tempDictionary)
		[TACData addObject: tempDictionary];

	}

}

#pragma mark -
#pragma mark Table Access and Control

- (NSInteger)numberOfRowsInTableView:(NSTableView *)dynamicTable
{
	if(TACData.count != timeData.count)
		return 0;

	return (NSInteger)TACData.count;		
}

- (id)tableView:(NSTableView *)dynamicTable objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	if(TACData.count != timeData.count)
		return nil;

	NSMutableDictionary *time	= [NSMutableDictionary dictionary];
    NSMutableDictionary *tac	= [NSMutableDictionary dictionary];
	
	if(TACData.count == 0)
    [tac setDictionary: [TACData objectAtIndex:row]];
	[time setDictionary: [timeData objectAtIndex:row]];
	
	if( [[tableColumn identifier] isEqualToString:@"Frame"])
		return [time valueForKey:@"Frame"];
	
	else if( [[tableColumn identifier] isEqualToString:@"Start"])
		return [time valueForKey:@"Start"];
	
	else if( [[tableColumn identifier] isEqualToString:@"End"]) 
		return [time valueForKey:@"End"];
	
	else if( [[tableColumn identifier] isEqualToString:@"Duration"])
		return [time valueForKey:@"Duration"];	

	else if( [[tableColumn identifier] isEqualToString:@"Min"])
		return [tac valueForKey:@"min"];	
	
	else if( [[tableColumn identifier] isEqualToString:@"Max"])
		return [tac valueForKey:@"max"];
	
	else if( [[tableColumn identifier] isEqualToString:@"Mean"])
		return [tac valueForKey:@"mean"];
	
	else if( [[tableColumn identifier] isEqualToString:@"StDev"])
		return [tac valueForKey:@"dev"];	
	
	else
		return nil;
}


#pragma mark -
#pragma mark Save Panel


-(IBAction)buttonClicked:(id)sender
{
	NSLog(@"Export button clicked");
	NSSavePanel* exportTAC= [NSSavePanel savePanel];
	[exportTAC setTitle:@"Export TAC as text"];
	[exportTAC setPrompt:@"Export"];
	[exportTAC setCanCreateDirectories:1];
	[exportTAC setAllowedFileTypes:[NSMutableArray arrayWithObject:@"txt"]];
	
	NSManagedObject* infoData = [[[viewer imageView] curDCM] imageObj];
	NSString* filename = [NSString stringWithFormat:@"%@-%@", [infoData valueForKeyPath:@"series.study.name"], [[viewer selectedROI] name]];
	[exportTAC beginSheetForDirectory:nil file:filename modalForWindow:[self window] 
						modalDelegate:self didEndSelector:@selector(saveAsPanelDidEnd:returnCode:contextInfo:) contextInfo: NULL];
}

-(void)saveAsPanelDidEnd:(NSSavePanel*)panel returnCode:(int)code contextInfo:(void*)format {
	if (code == NSOKButton) {
		
		NSError* error = 0;
		DCMPix *curPix = [[viewer pixList] objectAtIndex:0];
		NSLog(@"Unit Description: %@", curPix.returnUnits);
		
		NSMutableString *content = [NSMutableString string];
		
		if ( [curPix appliedFactorPET2SUV] == 1.0)
			[content appendString:[curPix returnUnits]];
		else 
			[content appendString:@"SUV"];
		
		[content appendString:@"\nFrame\tStart\tEnd\tDuration\tMin\tMax\tMean\tStDev\n"];
		
		int i;
		for(i=0; i<totalframes; i++){
			NSMutableDictionary *time	= [[NSMutableDictionary alloc] init];
			NSMutableDictionary *tac	= [[NSMutableDictionary alloc] init];
			
			[tac setDictionary: [TACData objectAtIndex:i]];
			[time setDictionary: [timeData objectAtIndex:i]];											  
			[content appendFormat: @"%i\t%i\t%i\t%i\t%f\t%f\t%f\t%f\n",
			[[time valueForKey:@"Frame"] intValue],[[time valueForKey:@"Start"] intValue],[[time valueForKey:@"End"] intValue],
			 [[time valueForKey:@"Duration"] intValue],[[tac valueForKey:@"min"] floatValue], [[tac valueForKey:@"max"] floatValue]
			 , [[tac valueForKey:@"mean"] floatValue], [[tac valueForKey:@"dev"] floatValue]];
	
		}
		[content writeToFile:[panel filename] atomically:YES encoding:NSUTF8StringEncoding error:&error];
	}
}
#pragma mark -
#pragma mark GraphView Functions

- (IBAction)chartYOptionschanged:(id)sender{
	NSMenuItem* selectedItem = [chartYOptions selectedItem];
	if([[selectedItem title] isEqualToString: [displayMax title]]){ currentYDisplay = showMax;
	NSLog(@"Max");}
	if([[selectedItem title] isEqualToString: [displayMean title]]){ currentYDisplay = showMean;
	NSLog(@"Mean");}
	if([[selectedItem title]isEqualToString: [displayMin title]]){ currentYDisplay = showMin;
	NSLog(@"Min");}
	
	[self changeChartDataSource:@"yaxis"];
	[graphTAC refreshDisplay:self];
}

- (IBAction)chartXOptionschanged:(id)sender {
	NSMenuItem* selectedItem = [chartXOptions selectedItem];
	if( [[selectedItem title] isEqualToString:[displayStart title]]){ currentXDisplay = showStart;
	NSLog(@"Start");}
	if([[selectedItem title] isEqualToString: [displayMid title] ]){ currentXDisplay = showMid;
	NSLog(@"Mid");}
	if([[selectedItem title]isEqualToString:[displayEnd title]]){ currentXDisplay = showEnd;
	NSLog(@"End");}
	[self changeChartDataSource:@"xaxis"];

	[graphTAC refreshDisplay:self];
}

- (void) changeChartDataSource:(NSString *)axis {
	int pointsInChart;
	NSString *timeKey, *tacKey;

	
	if ([axis isEqualToString:@"xaxis"]){
		[xValues removeAllObjects];
		
		switch (currentXDisplay) {
			case showStart: timeKey = @"Start";
				break;
			case showMid: timeKey = @"Midpoint";
				break;
			case showEnd: timeKey = @"End";
				break;			
			default: timeKey = @"Start";
				break;
		}
		
		for ( pointsInChart = 0; pointsInChart<totalframes; pointsInChart++) 
		{
			[xValues addObject: [[timeData objectAtIndex:pointsInChart] objectForKey:timeKey]];
			[xValues retain];
		}
		
	}
	else if([axis isEqualToString:@"yaxis"]){
		[yValues removeAllObjects];
		switch (currentYDisplay) {
			case showMax: tacKey = @"max";
				break;
			case showMean: tacKey = @"mean";
				break;
			case showMin: tacKey = @"min";
				break;			
			default: tacKey = @"mean";
				break;
		}
	
		for ( pointsInChart = 0; pointsInChart<totalframes; pointsInChart++) {
			NSLog(@"%@", [[TACData objectAtIndex:pointsInChart] objectForKey:tacKey]);
			[yValues addObject:[[TACData objectAtIndex:pointsInChart] objectForKey:tacKey]];
			[yValues retain];
		}
	}
	else if ([axis isEqualToString:@"blah"]) 
	{
		[self changeChartDataSource:@"yaxis"];
		[self changeChartDataSource:@"xaxis"];
	}
}


- (NSUInteger)numberOfLinesInTwoDGraphView:(SM2DGraphView *)inGraphView 
{
	return 1;
}

- (NSArray *)twoDGraphView:(SM2DGraphView *)inGraphView dataForLineIndex:(NSUInteger)inLineIndex 
{
	NSMutableArray *values = [NSMutableArray arrayWithCapacity:[xValues count]];
	
	int i;
	for(i=0; i<[xValues count]; i++){
		NSPoint currentpoint = NSMakePoint([[xValues objectAtIndex:i] floatValue], [[yValues objectAtIndex:i] floatValue]);
		[values addObject:NSStringFromPoint(currentpoint)];
	}

	return values;
}

- (CGFloat)twoDGraphView:(SM2DGraphView *)inGraphView maximumValueForLineIndex:(NSUInteger)inLineIndex forAxis:(SM2DGraphAxisEnum)inAxis {
	NSMutableArray *tempArray = [[NSMutableArray alloc] init];
	if (inAxis == kSM2DGraph_Axis_X) {
		tempArray = xValues;
		NSNumber *maxValue = [[tempArray sortedArrayUsingSelector:@selector(compare:)] lastObject];
		return [maxValue doubleValue];
	}
	else {
		tempArray = yValues;
		NSNumber *maxValue = [[tempArray sortedArrayUsingSelector:@selector(compare:)] lastObject];
		
		return [maxValue doubleValue];
	}
}

- (CGFloat)twoDGraphView:(SM2DGraphView *)inGraphView minimumValueForLineIndex:(NSUInteger)inLineIndex forAxis:(SM2DGraphAxisEnum)inAxis {
	double mintime = 0;
	if ( inAxis == kSM2DGraph_Axis_X) {
		return mintime;
	}
	else {
		NSMutableArray *tempArray = [[NSMutableArray alloc] init];
		tempArray = yValues;
		NSNumber *minValue = [[tempArray sortedArrayUsingSelector:@selector(compare:)] objectAtIndex:0];
		return [minValue doubleValue];
	}
}


@end