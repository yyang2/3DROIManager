//
//  SwizzleDCMView.m
//  3DROIManager
//
//  Created by Yang Yang on 3/15/11.
//  Copyright 2011 UCLA School of Medicine. All rights reserved.
//

#import "SwizzleDCMView.h"
#import <Osirix Headers/DCMView.h>
#import <Osirix Headers/ROI.h>
#import <Osirix Headers/browserController.h>
#import <Osirix Headers/Notifications.h>

short						syncro = syncroLOC;
static		BOOL						pluginOverridesMouse = NO;  // Allows plugins to override mouse click actions.
BOOL						FULL32BITPIPELINE = NO;
int							CLUTBARS, ANNOTATIONS = -999, SOFTWAREINTERPOLATION_MAX, DISPLAYCROSSREFERENCELINES = YES;
static		NSRecursiveLock				*drawLock = nil;

NSString *pasteBoardOsiriX = @"OsiriX pasteboard";
NSString *pasteBoardOsiriXPlugin = @"OsiriXPluginDataType";


@implementation SwizzleDCMView

- (void)mouseUp:(NSEvent *)event
{
	if ([self eventToPlugins:event]) return;
	
	mouseDragging = NO;
	
	// get rid of timer
	[self deleteMouseDownTimer];
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:curImage], @"curImage", event, @"event", nil];
	
	if( [[self window] isVisible] == NO) return;
	
	if( [self is2DViewer] == YES)
	{
		if( [[self windowController] windowWillClose]) return;
	}
	
	// If caplock is on changes to scale, rotation, zoom, ww/wl will apply only to the current image
	BOOL modifyImageOnly = NO;
	if ([event modifierFlags] & NSAlphaShiftKeyMask)
		modifyImageOnly = YES;
	
    if( dcmPixList)
    {
		if ( pluginOverridesMouse && ( [event modifierFlags] & NSControlKeyMask ) )
		{  // Simulate Right Mouse Button action
			[nc postNotificationName: OsirixRightMouseUpNotification object: self userInfo: userInfo];
			return;
		}
		
		[drawLock lock];
		
		@try 
		{
			[self mouseMoved: event];	// Update some variables...
			
			if( curImage != startImage && (matrix && [BrowserController currentBrowser]))
			{
				NSButtonCell *cell = [matrix cellAtRow:curImage/[[BrowserController currentBrowser] COLUMN] column:curImage%[[BrowserController currentBrowser] COLUMN]];
				[cell performClick:nil];
				[matrix selectCellAtRow :curImage/[[BrowserController currentBrowser] COLUMN] column:curImage%[[BrowserController currentBrowser] COLUMN]];
			}
			
			long tool = currentMouseEventTool;
			
			if( crossMove >= 0) tool = tCross;
			
			if( tool == tWL || tool == tWLBlended)
			{
				if( [self is2DViewer] == YES)
				{
					[[[self windowController] thickSlabController] setLowQuality: NO];
					[self reapplyWindowLevel];
					[self loadTextures];
					[self setNeedsDisplay:YES];
				}
			}
			
			if( [self roiTool: tool] )
			{
				NSPoint     eventLocation = [event locationInWindow];
				NSPoint		tempPt = [self convertPoint:eventLocation fromView: nil];
				
				tempPt = [self ConvertFromNSView2GL:tempPt];
				
				for( long i = 0; i < [curRoiList count]; i++)
				{
					[[curRoiList objectAtIndex:i] mouseRoiUp: tempPt];
					
					if( [[curRoiList objectAtIndex:i] ROImode] == ROI_selected)
					{
						if ([[self className] hasPrefix:@"Orthogonal"]) {
							NSDictionary *pass = [NSDictionary dictionaryWithObjectsAndKeys:[curRoiList objectAtIndex:i], @"roi", NSStringFromPoint([NSEvent mouseLocation]), @"mouse", nil];
							
							[nc postNotificationName:@"3DROIManagerShow" object:pass userInfo:nil];
							
						}
						
						[nc postNotificationName: OsirixROISelectedNotification object: [curRoiList objectAtIndex:i] userInfo: nil];
						break;
					}
				}
				
				for( long i = 0; i < [curRoiList count]; i++)
				{
					if( [[curRoiList objectAtIndex: i] valid] == NO)
					{
						[[NSNotificationCenter defaultCenter] postNotificationName: OsirixRemoveROINotification object: [curRoiList objectAtIndex:i] userInfo: nil];
						[curRoiList removeObjectAtIndex: i];
						i--;
					}
				}
				
				[self setNeedsDisplay:YES];
			}
			
			if(repulsorROIEdition)
			{
				currentTool = tRepulsor;
				tool = tRepulsor;
				repulsorROIEdition = NO;
			}
			
			if(tool == tRepulsor)
			{
				repulsorRadius = 0;
				if(repulsorColorTimer)
				{
					[repulsorColorTimer invalidate];
					[repulsorColorTimer release];
					repulsorColorTimer = nil;
				}
				[self setNeedsDisplay:YES];
			}
			
			if(selectorROIEdition)
			{
				currentTool = tROISelector;
				tool = tROISelector;
				selectorROIEdition = NO;
			}
			
			if(tool == tROISelector)
			{
				[ROISelectorSelectedROIList release];
				ROISelectorSelectedROIList = nil;
				
				NSRect rect = NSMakeRect(ROISelectorStartPoint.x-1, ROISelectorStartPoint.y-1, fabsf(ROISelectorEndPoint.x-ROISelectorStartPoint.x)+2, fabsf(ROISelectorEndPoint.y-ROISelectorStartPoint.y)+2);
				ROISelectorStartPoint = NSMakePoint(0.0, 0.0);
				ROISelectorEndPoint = NSMakePoint(0.0, 0.0);
				[self drawRect:rect];
			}
		}
		@catch (NSException * e) 
		{
			NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
		}
		
		
		[drawLock unlock];
    }
}

@end
