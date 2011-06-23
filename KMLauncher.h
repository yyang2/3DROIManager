//
//  KMLauncher.h
//  3DROIManager
//
//  Created by Yang Yang on 6/22/11.
//  Copyright 2011 UCLA School of Medicine. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OsirixAPI/DCMPix.h>
#import <OsirixAPI/DCMView.h>
#import <OsirixAPI/ViewerController.h>
#import <SM2DGraphView/SM2DGraphView.h>


@interface KMLauncher :  NSWindowController 
{
    ViewerController            *viewer;
    IBOutlet SM2DGraphView      *inputGraph, *tissueGraph;
    IBOutlet NSPopUpButton		*inputSelection; 
    IBOutlet NSPopUpButton      *tissueSelection;
    NSMutableArray              *input, *tissue, *timepoints;             //each one is an array of NSNumbers in sequential order
}

- (id)initWithViewer:(ViewerController*)v;
- (void)calculateTime;
- (IBAction) updateGraph:(id)sender;
- (IBAction) runModel:(id)sender;

@end