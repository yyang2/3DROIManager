//
//  VRController+Yang.h
//  3DROIManager
//
//  Created by Yang Yang on 6/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OsirixAPI/VRController.h>
// adds accesors for getting x,y,z position from VRController
// used by ThreeDGeometries when adding spheres using 3D View

@interface VRController (Yang)
-(NSMutableArray *) Getx2DPointsArray;
-(NSMutableArray *) Gety2DPointsArray;
-(NSMutableArray *) Getz2DPointsArray;
@end
