//
//  ITKSegmentation3DController+Yang.h
//  3DROIManager
//
//  Created by Yang Yang on 4/27/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OsiriX Headers/ITKSegmentation3DController.h>
@class ViewerController;

@interface ITKSegmentation3DController (Yang)

- (void) computeWithPoint: (NSPoint) pt withInterval:(NSMutableDictionary *)interval :(NSString *)generatedname : (NSString *) selectedname;

@end
