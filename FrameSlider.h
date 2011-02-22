//
//  FrameSlider.h
//  3DROIManager
//
//  Created by Yang Yang on 5/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//modified version of NSSlider which responds to mouse wheel,convenient way to advance in frames


@interface FrameSlider : NSSlider {

}

- (void) scrollWheel:(NSEvent*) event;

@end
