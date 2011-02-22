//
//  FrameSlider.m
//  3DROIManager
//
//  Created by Yang Yang on 5/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "FrameSlider.h"


@implementation FrameSlider
-(void) scrollWheel:(NSEvent *) event{
	int change;
	if ([event deltaY] >0) change = -ceil([event deltaY]);	
	else change = -floor([event deltaY]);
	
	[self setIntValue: [self intValue] + change];
	[self sendAction:[self action] to:[self target]];
}

@end
