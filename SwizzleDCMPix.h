//
//  SwizzleDCMPix.h
//  3DROIManager
//
//  Created by Yang Yang on 1/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OsiriX Headers/DCMPix.h>

@interface SwizzleDCMPix : DCMPix {

}
- (BOOL)loadDICOMDCMFramework;
- (BOOL) loadDICOMPapyrus;
@end
