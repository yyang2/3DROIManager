//
//  KMLauncher.m
//  3DROIManager
//
//  Created by Yang Yang on 6/22/11.
//  Copyright 2011 UCLA School of Medicine. All rights reserved.
//

#import "KMLauncher.h"
#import "ViewerController+Yang.h"
#import "DMCPix+Yang.h"
#import <OsirixAPI/Notifications.h>

@implementation KMLauncher

- (void) awakeFromNib 
{ 
    //populate both options
    NSMutableArray *names = [NSMutableArray arrayWithArray:[viewer roiNames]];
    int k=0;
    
    while(k<names.count){
        //removes center and ellipses
        if([[names objectAtIndex:k] hasSuffix:@"center"] || [[names objectAtIndex:k] hasSuffix:@"ellipse"])
        {
            [names removeObjectAtIndex:k];
        }
        else
            k++;
    }
    
    for (int i=0; i<names.count; i++)
    {
        [inputSelection addItemWithTitle:[names objectAtIndex:i]];
        [tissueSelection addItemWithTitle:[names objectAtIndex:i]];
    }
}

- (id)initWithViewer:(ViewerController*)v
{
	self = [super initWithWindowNibName:@"KMLauncher"];
	if(!self) return nil;
	viewer = [v retain];
    
    
    [self calculateTime];

    NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];	
	[nc addObserver: self
           selector: @selector(CloseViewerNotification:)
               name: OsirixCloseViewerNotification
             object: nil];

    
    [[self window] setFrameAutosaveName:@"KMLauncher"];; // triggers nib loading
    return self;
}

-(void) calculateTime
{
    timepoints = [NSMutableArray array];
	int curFrame=0;
	DCMPix *curPix;
	int duration=0;
	int last=0;
//	int midpoint=0;
	int unitsoftime = 1000;
	//going through all the frames
	
	for (curFrame=0; curFrame<[viewer maxMovieIndex]; curFrame++) {

		[viewer setMovieIndex:curFrame];
		
		curPix = [[viewer pixList] objectAtIndex:0];

		duration = [curPix frameDuration];
		duration = duration/unitsoftime;
        
//		NSMutableDictionary *tempDictionary = [NSMutableDictionary dictionary];        
//		[tempDictionary setObject: [NSNumber numberWithInt: (curFrame+1)] forKey:@"Frame"];
//		[tempDictionary setObject: [NSNumber numberWithInt: duration] forKey:@"Duration"];
//		[tempDictionary setObject: [NSNumber numberWithInt: last] forKey:@"Start"];
//		midpoint = ((2*last + duration)/2);
//		[tempDictionary setObject: [NSNumber numberWithInt: midpoint] forKey:@"Midpoint"];
		last = last + duration;
//		[tempDictionary setObject: [NSNumber numberWithInt: last] forKey:@"End"];
		
		[timepoints addObject: [NSNumber numberWithInt: last]];
	}
    [timepoints retain];
}

-(void) CloseViewerNotification:(NSNotification*) note
{	
	if( [note object] == viewer)
	{
		[self windowWillClose:nil];
	}
}


-(void) windowWillClose:(NSNotification *)notification
{
    [self release];
}

- (void)dealloc
{
    NSLog(@"KMLauncher deallocing");
    [viewer release];
    if(input) [input release];
    if(tissue) [tissue release];
    [timepoints release];
    [super dealloc];
}


- (IBAction) updateGraph:(id)sender
{
    
    NSMutableArray *TACData = [NSMutableArray arrayWithCapacity:timepoints.count];
    ROI *current = [[viewer roisWithName:[[sender selectedItem] title] ] objectAtIndex:0];
    for (int curFrame=0; curFrame<[viewer maxMovieIndex]; curFrame++){
		[viewer setMovieIndex:(curFrame)];
		//set into temp array
		NSMutableDictionary *tempDictionary = [viewer computeTAC:current onframe:curFrame withFrame:curFrame];		
		// test code: NSLog(@"%d", [[tempDictionary valueForKey:@"mean"] floatValue]);
		if(tempDictionary)
        {    
            [TACData addObject: [tempDictionary valueForKey:@"mean"]];
        }
    }    
	
    NSLog(@"timepoints:%@ data: %@", timepoints, TACData);
    
    if(sender == inputSelection){
        if(input) [input release];
        input = [TACData retain];
        [inputGraph refreshDisplay:self];
        
    }
    else if(sender == tissueSelection){
        if(tissue) [tissue release];
        tissue = [TACData retain];
        [tissueGraph refreshDisplay:self];
    }

}

#pragma mark -
#pragma mark GraphView 
- (NSUInteger)numberOfLinesInTwoDGraphView:(SM2DGraphView *)inGraphView 
{
	return 1;
}

- (NSArray *)twoDGraphView:(SM2DGraphView *)inGraphView dataForLineIndex:(NSUInteger)inLineIndex 
{
    NSMutableArray *values = nil;
    if( inGraphView == inputGraph){
        if(input)
            values = [NSMutableArray arrayWithArray:input];
    }
    else if(inGraphView == tissueGraph){
        if (tissue)
            values = [NSMutableArray arrayWithArray:tissue];
    }
    if(values == nil) return nil;
    
    NSMutableArray *points = [NSMutableArray arrayWithCapacity:values.count];
    for(int i=0; i< values.count; i++)
    {
        NSPoint newpt = NSMakePoint([[timepoints objectAtIndex:i]floatValue],[[values objectAtIndex:i] floatValue]);
        [points addObject:NSStringFromPoint(newpt)];
    }

	return points;
}

- (CGFloat)twoDGraphView:(SM2DGraphView *)inGraphView maximumValueForLineIndex:(NSUInteger)inLineIndex forAxis:(SM2DGraphAxisEnum)inAxis {
    
    NSMutableArray *values = nil;
    if( inGraphView == inputGraph){
        if(input)
            values = [NSMutableArray arrayWithArray:input];
    }
    else if(inGraphView == tissueGraph){
        if (tissue)
            values = [NSMutableArray arrayWithArray:tissue];
    }
    if(values == nil) return -1;

    
    
	if (inAxis == kSM2DGraph_Axis_Y) {
        
		NSNumber *maxValue = [[values sortedArrayUsingSelector:@selector(compare:)] lastObject];
		return [maxValue doubleValue];
	}
	else {
		NSNumber *maxValue = [timepoints lastObject];
		
		return [maxValue doubleValue];
	}
}

- (CGFloat)twoDGraphView:(SM2DGraphView *)inGraphView minimumValueForLineIndex:(NSUInteger)inLineIndex forAxis:(SM2DGraphAxisEnum)inAxis {

    NSMutableArray *values = nil;
    if( inGraphView == inputGraph){
        if(input)
            values = [NSMutableArray arrayWithArray:input];
    }
    else if(inGraphView == tissueGraph){
        if (tissue)
            values = [NSMutableArray arrayWithArray:tissue];
    }
    if(values == nil) return -1;
    
	if ( inAxis == kSM2DGraph_Axis_X) {
		return 0.f;
	}
	else {
		NSNumber *minValue = [[values sortedArrayUsingSelector:@selector(compare:)] objectAtIndex:0];
		return [minValue doubleValue];
	}
    return 0.f;
}

@end
