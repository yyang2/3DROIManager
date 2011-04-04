//
//  SwizzleROI.h
//  3DROIManager
//
//  Created by Yang Yang on 3/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OsirixAPI/ROI.h>

@interface SwizzleROI : ROI 
{

}
-(float) plainArea;
-(float) Area;
-(float) EllipseArea;
-(float) Area: (NSMutableArray*) pts;
-(float) AngleUncorrected:(NSPoint) p2 :(NSPoint) p1 :(NSPoint) p3;
- (void) drawROIWithScaleValue:(float)scaleValue offsetX:(float)offsetx offsetY:(float)offsety pixelSpacingX:(float)spacingX pixelSpacingY:(float)spacingY highlightIfSelected:(BOOL)highlightIfSelected thickness:(float)thick prepareTextualData:(BOOL) prepareTextualData;
@end
