//
//  SwizzleOrthgonalMPRController.h
//  3DROIManager
//
//  Created by Yang Yang on 1/26/11.
//  Copyright 2011 UCLA School of Medicine. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Osirix Headers/OrthogonalMPRController.h>

@interface SwizzleOrthogonalMPRController : OrthogonalMPRController {

}
- (void) setPixList: (NSArray*)pix :(NSArray*)files :(ViewerController*)vC;
- (NSMutableArray*) pointsROIAtX: (long) x;
- (NSMutableArray*) pointsROIAtY: (long) y;
@end
