//
//  VRView+Yang.h
//  3DROIManager
//
//  Created by Yang Yang on 2/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OsirixAPI/VRView.h>

@interface VRView (Yang)
-(NSMutableArray*) get3DPositionArray;
-(void) callSuperKeyDown: (NSEvent*)keyDown;
@end
