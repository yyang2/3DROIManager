//
//  SwizzleVRView.h
//  3DROIManager
//
//  Created by Yang Yang on 1/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OsirixAPI/VRView.h>
#import <OsirixAPI/VTKView.h>

@interface SwizzleVRView : VRView 
{

}
- (void)mouseDown:(NSEvent *)theEvent;
- (long) getTool: (NSEvent*) event;
- (void) removeSelected3DPoint;
@end
