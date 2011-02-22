//
//  CLUTBar.h
//  3DROIManager
//
//  Created by Yang Yang on 5/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OpenGL/gl.h>

// An object which renders the Color Look Up Table on our 3DROIManager
// given the 8-bit lookup table, it is exactly 256 pixels high

@interface CLUTBar : NSOpenGLView {
	unsigned char redTable[256], blueTable[256], greenTable[256];
}

- (void) setCLUT:( unsigned char*) r : (unsigned char*) g : (unsigned char*) b;


@end
