//
//  CLUTBar.m
//  3DROIManager
//
//  Created by Yang Yang on 5/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CLUTBar.h"
#import <OpenGL/gl.h>

@implementation CLUTBar

-(void) drawRect: (NSRect) bounds
{
//	CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
//	
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);
	
	int i;

	glBegin(GL_LINES);
	glLineWidth(1.0);

	{
	for(i = 0; i < 256; i++)
	{
		float temp = i/128.f + (1/128.f);
		glColor3ub ( redTable[ i], greenTable[ i], blueTable[ i]);


		glVertex2f(  -1.f, temp-1);
		glVertex2f(  1.f, temp-1);
	}
	
	//	glColor3ub ( 128, 128, 128);
	//	glVertex2f(  widthhalf - BARPOSX1, heighthalf - -128.f);		glVertex2f(  widthhalf - BARPOSX2 , heighthalf - -128.f);
	//	glVertex2f(  widthhalf - BARPOSX1, heighthalf - 127.f);			glVertex2f(  widthhalf - BARPOSX2 , heighthalf - 127.f);
	//	glVertex2f(  widthhalf - BARPOSX1, heighthalf - -128.f);		glVertex2f(  widthhalf - BARPOSX1, heighthalf - 127.f);
	//	glVertex2f(  widthhalf - BARPOSX2 ,heighthalf -  -128.f);		glVertex2f(  widthhalf - BARPOSX2, heighthalf - 127.f);
	}
	glEnd();
	glFlush();
}
- (void) setCLUT:( unsigned char*) r : (unsigned char*) g : (unsigned char*) b
{
	if( memcmp( redTable, r, 256) == 0 && memcmp( greenTable, g, 256) == 0 && memcmp( blueTable, b, 256) == 0) {return;}
	int i;
	for(i = 0; i < 256; i++)
	{
		//				NSLog(@"Red: %u, Green: %u, Blue: %u", redTable[ i], greenTable[ i], blueTable[ i]);				
		redTable[i] = r[i];
		greenTable[i] = g[i];
		blueTable[i] = b[i];
	}
}
@end
