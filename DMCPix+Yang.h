//
//  DMCPix+Yang.h
//  DynamicROI
//
//  Created by Yang Yang on 3/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Osirix Headers/DCMPix.h>
//Adding accessors to DCMPix to get modality names, frame duration and units
//used by 3DROIManager

@interface DCMPix (Yang)
-(int) frameDuration;
-(NSString *) modalityName;
-(NSString*) returnUnits;
@end