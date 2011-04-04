//
//  SwizzleROI.m
//  3DROIManager
//
//  Created by Yang Yang on 3/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SwizzleROI.h"
#import <OsirixAPI/DCMView.h>
#import <OsirixAPI/DCMPix.h>
#import <OsirixAPI/BrowserController.h>

#define CIRCLERESOLUTION 200
#define ROIVERSION 11

static		float					deg2rad = M_PI / 180.0f; 
static		float					fontHeight = 0;
static		NSString				*defaultName;
static		int						gUID = 0;
static BOOL displayCobbAngle = NO;

static BOOL ROITEXTIFSELECTED, ROITEXTNAMEONLY;


@implementation SwizzleROI

- (void) drawROIWithScaleValue:(float)scaleValue offsetX:(float)offsetx offsetY:(float)offsety pixelSpacingX:(float)spacingX pixelSpacingY:(float)spacingY highlightIfSelected:(BOOL)highlightIfSelected thickness:(float)thick prepareTextualData:(BOOL) prepareTextualData 
{
	float thicknessCopy = thickness;
	thickness = thick;
	
	if( roiLock == nil) roiLock = [[NSLock alloc] init];
	
	if( fontListGL == -1 && prepareTextualData == YES) {NSLog(@"fontListGL == -1! We will not draw this ROI..."); return;}
	if( curView == nil && prepareTextualData == YES) {NSLog(@"curView == nil! We will not draw this ROI..."); return;}
	
	[roiLock lock];
	
	@try
	{
		if( selectable == NO)
			mode = ROI_sleep;
		
		pixelSpacingX = spacingX;
		pixelSpacingY = spacingY;
		
		float screenXUpL,screenYUpL,screenXDr,screenYDr; // for tPlain ROI
		
		NSOpenGLContext *currentContext = [NSOpenGLContext currentContext];
		CGLContextObj cgl_ctx = [currentContext CGLContextObj];
		
		glColor3f ( 1.0f, 1.0f, 1.0f);
		
		glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST);
		glHint(GL_LINE_SMOOTH_HINT, GL_NICEST);
		glEnable(GL_POINT_SMOOTH);
		glEnable(GL_LINE_SMOOTH);
		glEnable(GL_POLYGON_SMOOTH);
		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		
		switch( type)
		{
			case tLayerROI:
			{
				if(layerImage)
				{
					NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
					NSSize imageSize = [layerImage size];
					float imageWidth = imageSize.width;
					float imageHeight = imageSize.height;
                    
					glDisable(GL_POLYGON_SMOOTH);
					glEnable(GL_TEXTURE_RECTANGLE_EXT);
					
                    //				if(needsLoadTexture)
                    //				{
                    //					[self loadLayerImageTexture];
                    //					if(layerImageWhenSelected)
                    //						[self loadLayerImageWhenSelectedTexture];
                    //					needsLoadTexture = NO;
                    //				}
					
                    //				if(layerImageWhenSelected && mode==ROI_selected)
                    //				{
                    //					if(needsLoadTexture2) [self loadLayerImageWhenSelectedTexture];
                    //					needsLoadTexture2 = NO;
                    //					glBindTexture(GL_TEXTURE_RECTANGLE_EXT, textureName2);
                    //				}
                    //				else
					{
						GLuint texName = 0;
						NSUInteger index = [ctxArray indexOfObjectIdenticalTo: currentContext];
						if( index != NSNotFound)
							texName = [[textArray objectAtIndex: index] intValue];
						
						if (!texName)
							texName = [self loadLayerImageTexture];
                        
						glBindTexture(GL_TEXTURE_RECTANGLE_EXT, texName);
					}
					
					
					glBlendEquation(GL_FUNC_ADD);
					glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
					
					NSPoint p1, p2, p3, p4;
					p1 = [[points objectAtIndex:0] point];
					p2 = [[points objectAtIndex:1] point];
					p3 = [[points objectAtIndex:2] point];
					p4 = [[points objectAtIndex:3] point];
					
					p1.x = (p1.x-offsetx)*scaleValue;
					p1.y = (p1.y-offsety)*scaleValue;
					p2.x = (p2.x-offsetx)*scaleValue;
					p2.y = (p2.y-offsety)*scaleValue;
					p3.x = (p3.x-offsetx)*scaleValue;
					p3.y = (p3.y-offsety)*scaleValue;
					p4.x = (p4.x-offsetx)*scaleValue;
					p4.y = (p4.y-offsety)*scaleValue;
                    
					glBegin(GL_QUAD_STRIP); // draw either tri strips of line strips (so this will draw either two tris or 3 lines)
                    glTexCoord2f(0, 0); // draw upper left corner
                    glVertex3d(p1.x, p1.y, 0.0);
                    
                    glTexCoord2f(imageWidth, 0); // draw upper left corner
                    glVertex3d(p2.x, p2.y, 0.0);
                    
                    glTexCoord2f(0, imageHeight); // draw lower left corner
                    glVertex3d(p4.x, p4.y, 0.0);
                    
                    glTexCoord2f(imageWidth, imageHeight); // draw lower right corner
                    glVertex3d(p3.x, p3.y, 0.0);
                    
					glEnd();
					glDisable( GL_BLEND);
					
					glDisable(GL_TEXTURE_RECTANGLE_EXT);
					glEnable(GL_POLYGON_SMOOTH);
					
					// draw the 4 points defining the bounding box
					if(mode==ROI_selected && highlightIfSelected)
					{
						glColor3f (0.5f, 0.5f, 1.0f);
						glPointSize( 8.0);
						glBegin(GL_POINTS);
						glVertex3f(p1.x, p1.y, 0.0);
						glVertex3f(p2.x, p2.y, 0.0);
						glVertex3f(p3.x, p3.y, 0.0);
						glVertex3f(p4.x, p4.y, 0.0);
						glEnd();
						glColor3f (1.0f, 1.0f, 1.0f);
					}
					
					if( [self isTextualDataDisplayed] && prepareTextualData)
					{
						// TEXT
						line1[0] = 0; line2[0] = 0; line3[0] = 0; line4[0] = 0; line5[0] = 0; line6[0] = 0;
						NSPoint tPt = self.lowerRightPoint;
                        
						if(![name isEqualToString:@"Unnamed"]) strcpy(line1, [name UTF8String]);
						if(textualBoxLine1 && ![textualBoxLine1 isEqualToString:@""]) strcpy(line1, [textualBoxLine1 UTF8String]);
						if(textualBoxLine2 && ![textualBoxLine2 isEqualToString:@""]) strcpy(line2, [textualBoxLine2 UTF8String]);
						if(textualBoxLine3 && ![textualBoxLine3 isEqualToString:@""]) strcpy(line3, [textualBoxLine3 UTF8String]);
						if(textualBoxLine4 && ![textualBoxLine4 isEqualToString:@""]) strcpy(line4, [textualBoxLine4 UTF8String]);
						if(textualBoxLine5 && ![textualBoxLine5 isEqualToString:@""]) strcpy(line5, [textualBoxLine5 UTF8String]);
						if(textualBoxLine6 && ![textualBoxLine6 isEqualToString:@""]) strcpy(line6, [textualBoxLine5 UTF8String]);
						
						[self prepareTextualData:line1 :line2 :line3 :line4 :line5 :line6 location:tPt];
					}
					[pool release];
				}
			}
                break;
                
			case tPlain:
                //	if( mode == ROI_selected | mode == ROI_selectedModify | mode == ROI_drawing)
			{
				//	NSLog(@"drawROI - tPlain, mode=%i, (ROI_sleep = 0,ROI_drawing = 1,ROI_selected = 2,	ROI_selectedModify = 3)",mode);
				// test to display something !
				// init
				screenXUpL = (textureUpLeftCornerX-offsetx)*scaleValue;
				screenYUpL = (textureUpLeftCornerY-offsety)*scaleValue;
				screenXDr = screenXUpL + textureWidth*scaleValue;
				screenYDr = screenYUpL + textureHeight*scaleValue;
                
                //	screenXDr = (textureDownRightCornerX-offsetx)*scaleValue;
                //	screenYDr = (textureDownRightCornerY-offsety)*scaleValue;
				
				glDisable(GL_POLYGON_SMOOTH);
				glEnable(GL_TEXTURE_RECTANGLE_EXT);
				
				[self deleteTexture: currentContext];
				
				GLuint textureName = 0;
				
				glTextureRangeAPPLE(GL_TEXTURE_RECTANGLE_EXT, textureWidth * textureHeight, textureBuffer);
				glGenTextures (1, &textureName);
				glBindTexture(GL_TEXTURE_RECTANGLE_EXT, textureName);
				glPixelStorei (GL_UNPACK_ROW_LENGTH, textureWidth);
				glPixelStorei (GL_UNPACK_CLIENT_STORAGE_APPLE, 1);
				glTexParameteri (GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_CACHED_APPLE);
				
				[ctxArray addObject: currentContext];
				[textArray addObject: [NSNumber numberWithInt: textureName]];
				
				glBlendEquation(GL_FUNC_ADD);
				glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
				
				glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
				
				glTexImage2D (GL_TEXTURE_RECTANGLE_EXT, 0, GL_INTENSITY8, textureWidth, textureHeight, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, textureBuffer);
				
				glBegin (GL_QUAD_STRIP); // draw either tri strips of line strips (so this will drw either two tris or 3 lines)
				glTexCoord2f (0, 0); // draw upper left in world coordinates
				glVertex3d (screenXUpL, screenYUpL, 0.0);
				
				glTexCoord2f (textureWidth, 0); // draw lower left in world coordinates
				glVertex3d (screenXDr, screenYUpL, 0.0);
				
				glTexCoord2f (0, textureHeight); // draw upper right in world coordinates
				glVertex3d (screenXUpL, screenYDr, 0.0);
				
				glTexCoord2f (textureWidth, textureHeight); // draw lower right in world coordinates
				glVertex3d (screenXDr, screenYDr, 0.0);
				glEnd();
				
				glDisable(GL_TEXTURE_RECTANGLE_EXT);
				glEnable(GL_POLYGON_SMOOTH);
				
				switch( mode)
				{
					case 	ROI_drawing:
					case 	ROI_selected:
					case 	ROI_selectedModify:
						if(highlightIfSelected)
						{
							glColor3f (0.5f, 0.5f, 1.0f);
							//smaller points for calcium scoring
							if (_displayCalciumScoring)
								glPointSize( 3.0);
							else
								glPointSize( 8.0);
							glBegin(GL_POINTS);
							glVertex3f(screenXUpL, screenYUpL, 0.0);
							glVertex3f(screenXDr, screenYUpL, 0.0);
							glVertex3f(screenXUpL, screenYDr, 0.0);
							glVertex3f(screenXDr, screenYDr, 0.0);
							glEnd();
						}
                        break;
				}
				
				glLineWidth(1.0);
				glColor3f (1.0f, 1.0f, 1.0f);
				
				// TEXT
				line1[ 0] = 0;		line2[ 0] = 0;	line3[ 0] = 0;		line4[ 0] = 0;	line5[ 0] = 0; line6[0] = 0;
				if( [self isTextualDataDisplayed] && prepareTextualData)
				{
					NSPoint tPt = [self lowerRightPoint];
					
					if( [name isEqualToString:@"Unnamed"] == NO) strcpy(line1, [name UTF8String]);
					
					if ( ROITEXTNAMEONLY == NO )
					{
						if( rtotal == -1) [[curView curDCM] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax];
						
						float area = [self plainArea];
                        
						if (!_displayCalciumScoring)
						{
							if( pixelSpacingX != 0 && pixelSpacingY != 0 )
							{
								if( area*pixelSpacingX*pixelSpacingY < 1.)
									sprintf (line2, "Area: %0.1f %cm2", area*pixelSpacingX*pixelSpacingY* 1000000.0, 0xB5);
								else
									sprintf (line2, "Area: %0.3f cm2", area*pixelSpacingX*pixelSpacingY/100.);
							}
							else
								sprintf (line2, "Area: %0.3f pix2", area);
							
							sprintf (line3, "Mean: %0.3f SDev: %0.3f Sum: %0.0f", rmean, rdev, rtotal);
							sprintf (line4, "Min: %0.3f Max: %0.3f", rmin, rmax);
						}
						else
						{
							sprintf (line2, "Calcium Score: %0.1f", [self calciumScore]);
							sprintf (line3, "Calcium Volume: %0.1f", [self calciumVolume]);
							sprintf (line4, "Calcium Mass: %0.1f", [self calciumMass]);
						}
						
						if( [curView blendingView])
						{
							DCMPix	*blendedPix = [[curView blendingView] curDCM];
							
							ROI *blendedROI = [self copy];
							blendedROI.pix = blendedPix;
							[blendedROI setOriginAndSpacing: blendedPix.pixelSpacingX: blendedPix.pixelSpacingY :[DCMPix originCorrectedAccordingToOrientation: blendedPix]];
							[blendedPix computeROI: blendedROI :&Brmean :&Brtotal :&Brdev :&Brmin :&Brmax];
							[blendedROI release];
							
							sprintf (line5, "Fused Image Mean: %0.3f SDev: %0.3f Sum: %0.0f", Brmean, Brdev, Brtotal);
							sprintf (line6, "Fused Image Min: %0.3f Max: %0.3f", Brmin, Brmax);
						}
					}
					//if (!_displayCalciumScoring)
					[self prepareTextualData:line1 :line2 :line3 :line4 :line5 :line6 location:tPt];
				}
			}
                break;
                
			case t2DPoint:
			{
				float angle;
				
				glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
                
//				glBegin(GL_LINE_LOOP);
//				for( int i = 0; i < CIRCLERESOLUTION ; i++ )
//				{
//                    angle = i * 2 * M_PI /CIRCLERESOLUTION;
//                    
//                    if( pixelSpacingX != 0 && pixelSpacingY != 0 )
//                        glVertex2f( (rect.origin.x - offsetx)*scaleValue + 8*cos(angle), (rect.origin.y - offsety)*scaleValue + 8*sin(angle)*pixelSpacingX/pixelSpacingY);
//                    else
//                        glVertex2f( (rect.origin.x - offsetx)*scaleValue + 8*cos(angle), (rect.origin.y - offsety)*scaleValue + 8*sin(angle));
//				}
//				glEnd();
				
				if((mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing) && highlightIfSelected) glColor4f (0.5f, 0.5f, 1.0f, opacity);
				else glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
				//else glColor4f (1.0f, 0.0f, 0.0f, opacity);
				
				glPointSize( (1 + sqrt( thickness))*3.5);
				glBegin( GL_POINTS);
				glVertex2f(  (rect.origin.x  - offsetx)*scaleValue, (rect.origin.y  - offsety)*scaleValue);
				glEnd();
				
				glLineWidth(1.0);
				glColor3f (1.0f, 1.0f, 1.0f);
				
				// TEXT
				line1[ 0] = 0;		line2[ 0] = 0;	line3[ 0] = 0;		line4[ 0] = 0;	line5[ 0] = 0; line6[0] = 0;
				if( [self isTextualDataDisplayed] && prepareTextualData)
				{
					NSPoint tPt = self.lowerRightPoint;
					
					if( [name isEqualToString:@"Unnamed"] == NO) strcpy(line1, [name UTF8String]);
					
					if( ROITEXTNAMEONLY == NO )
					{
						if( rtotal == -1) [[curView curDCM] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax];
						
						if( [curView blendingView])
						{
							DCMPix	*blendedPix = [[curView blendingView] curDCM];
							
							ROI *blendedROI = [[[ROI alloc] initWithType: type :[blendedPix pixelSpacingX] :[blendedPix pixelSpacingY] :[DCMPix originCorrectedAccordingToOrientation: blendedPix]] autorelease];
							
							NSRect blendedRect = [self rect];
							blendedRect.origin = [curView ConvertFromGL2GL: blendedRect.origin toView:[curView blendingView]];
							[blendedROI setROIRect: blendedRect];
							
							[blendedPix computeROI: blendedROI :&Brmean :&Brtotal :&Brdev :&Brmin :&Brmax];
						}
						
						sprintf (line2, "Val: %0.3f", rmean);
						if( Brtotal != -1) sprintf (line3, "Fused Image Val: %0.3f", Brmean);
						
						sprintf (line4, "2D Pos: X:%0.3f px Y:%0.3f px", rect.origin.x, rect.origin.y);
						
						float location[ 3 ];
						[[curView curDCM] convertPixX: rect.origin.x pixY: rect.origin.y toDICOMCoords: location pixelCenter: YES];
						if(fabs(location[0]) < 1.0 && location[0] != 0.0)
							sprintf (line5, "3D Pos: X:%0.1f %cm Y:%0.1f %cm Z:%0.1f %cm", location[0] * 1000.0, 0xB5, location[1] * 1000.0, 0xB5, location[2] * 1000.0, 0xB5);
						else
							sprintf (line5, "3D Pos: X:%0.3f mm Y:%0.3f mm Z:%0.3f mm", location[0], location[1], location[2]);
					}
					[self prepareTextualData:line1 :line2 :line3 :line4 :line5 :line6 location:tPt];
				}
			}
                break;
                
			case tText:
			{
				glPushMatrix();
				
				float ratio = 1;
				
				if( pixelSpacingX != 0 && pixelSpacingY != 0)
					ratio = pixelSpacingX / pixelSpacingY;
				
				glLoadIdentity (); // reset model view matrix to identity (eliminates rotation basically)
				glScalef (2.0f /([curView xFlipped] ? -([curView drawingFrameRect].size.width) : [curView drawingFrameRect].size.width), -2.0f / ([curView yFlipped] ? -([curView drawingFrameRect].size.height) : [curView drawingFrameRect].size.height), 1.0f); // scale to port per pixel scale
				glTranslatef( [curView origin].x, -[curView origin].y, 0.0f);
                
				NSRect centeredRect = rect;
				NSRect unrotatedRect = rect;
				
				centeredRect.origin.y -= offsety + [curView origin].y*ratio/scaleValue;
				centeredRect.origin.x -= offsetx - [curView origin].x/scaleValue;
				
				unrotatedRect.origin.x = centeredRect.origin.x*cos( -curView.rotation*deg2rad) + centeredRect.origin.y*sin( -curView.rotation*deg2rad)/ratio;
				unrotatedRect.origin.y = -centeredRect.origin.x*sin( -curView.rotation*deg2rad) + centeredRect.origin.y*cos( -curView.rotation*deg2rad)/ratio;
				
				unrotatedRect.origin.y *= ratio;
				
				unrotatedRect.origin.y += offsety + [curView origin].y*ratio/scaleValue;
				unrotatedRect.origin.x += offsetx - [curView origin].x/scaleValue;
				
				if((mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing) && highlightIfSelected)
				{
					glColor3f (0.5f, 0.5f, 1.0f);
					glPointSize( 2.0 * 3);
					glBegin( GL_POINTS);
					glVertex2f(  (unrotatedRect.origin.x - offsetx)*scaleValue - unrotatedRect.size.width/2, (unrotatedRect.origin.y - offsety)/ratio*scaleValue - unrotatedRect.size.height/2/ratio);
					glVertex2f(  (unrotatedRect.origin.x - offsetx)*scaleValue - unrotatedRect.size.width/2, (unrotatedRect.origin.y - offsety)/ratio*scaleValue + unrotatedRect.size.height/2/ratio);
					glVertex2f(  (unrotatedRect.origin.x- offsetx)*scaleValue + unrotatedRect.size.width/2, (unrotatedRect.origin.y - offsety)/ratio*scaleValue + unrotatedRect.size.height/2/ratio);
					glVertex2f(  (unrotatedRect.origin.x - offsetx)*scaleValue + unrotatedRect.size.width/2, (unrotatedRect.origin.y - offsety)/ratio*scaleValue - unrotatedRect.size.height/2/ratio);
					glEnd();
				}
				
				glLineWidth(1.0);
				
				NSPoint tPt = NSMakePoint( unrotatedRect.origin.x, unrotatedRect.origin.y);
				tPt.x = (tPt.x - offsetx)*scaleValue - unrotatedRect.size.width/2;
				tPt.y = (tPt.y - offsety)/ratio*scaleValue - unrotatedRect.size.height/2/ratio;
				
				glEnable (GL_TEXTURE_RECTANGLE_EXT);
				
				glEnable(GL_BLEND);
				if( opacity == 1.0) glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
				else glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
				
				if( stringTex == nil ) self.name = name;
				
				[stringTex setFlippedX: [curView xFlipped] Y:[curView yFlipped]];
				
				glColor4f (0, 0, 0, opacity);
				[stringTex drawAtPoint:NSMakePoint(tPt.x+1, tPt.y+ 1.0) ratio: 1];
                
				glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
				
				[stringTex drawAtPoint:tPt ratio: 1];
                
				glDisable (GL_TEXTURE_RECTANGLE_EXT);
				
				glColor3f (1.0f, 1.0f, 1.0f);
				
				glPopMatrix();
			}
                break;
                
			case tMesure:
			case tArrow:
			{
				glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
				glLineWidth(thickness);
				
				if( type == tArrow)
				{
					NSPoint a, b;
					float   slide, adj, op, angle;
					
					a.x = ([[points objectAtIndex: 0] x]- offsetx) * scaleValue;
					a.y = ([[points objectAtIndex: 0] y]- offsety) * scaleValue;
					
					b.x = ([[points objectAtIndex: 1] x]- offsetx) * scaleValue;
					b.y = ([[points objectAtIndex: 1] y]- offsety) * scaleValue;
					
					if( (b.y-a.y) == 0) slide = (b.x-a.x)/-0.001;
					else
					{
						if( pixelSpacingX != 0 && pixelSpacingY != 0 )
							slide = (b.x-a.x)/((b.y-a.y) * (pixelSpacingY / pixelSpacingX));
						else
							slide = (b.x-a.x)/((b.y-a.y));
					}
#define ARROWSIZEConstant 25.0
					
					float ARROWSIZE = ARROWSIZEConstant * (thickness / 3.0);
					
					// LINE
					glLineWidth(thickness*2);
					
					angle = 90 - atan( slide)/deg2rad;
					adj = (ARROWSIZE + thickness * 13)  * cos( angle*deg2rad);
					op = (ARROWSIZE + thickness * 13) * sin( angle*deg2rad);
					
					glBegin(GL_LINE_STRIP);
                    if(b.y-a.y > 0)
                    {	
                        if( pixelSpacingX != 0 && pixelSpacingY != 0 )
                            glVertex2f( a.x + adj, a.y + (op*pixelSpacingX / pixelSpacingY));
                        else
                            glVertex2f( a.x + adj, a.y + (op));
                    }
                    else
                    {
                        if( pixelSpacingX != 0 && pixelSpacingY != 0 )
                            glVertex2f( a.x - adj, a.y - (op*pixelSpacingX / pixelSpacingY));
                        else
                            glVertex2f( a.x - adj, a.y - (op));
                    }
                    glVertex2f( b.x, b.y);
					glEnd();
					
					glPointSize( thickness*2);
                    
					glBegin( GL_POINTS);
					if(b.y-a.y > 0)
					{	
						if( pixelSpacingX != 0 && pixelSpacingY != 0 )
							glVertex2f( a.x + adj, a.y + (op*pixelSpacingX / pixelSpacingY));
						else
							glVertex2f( a.x + adj, a.y + (op));
					}
					else
					{
						if( pixelSpacingX != 0 && pixelSpacingY != 0 )
							glVertex2f( a.x - adj, a.y - (op*pixelSpacingX / pixelSpacingY));
						else
							glVertex2f( a.x - adj, a.y - (op));
					}
					glVertex2f( b.x, b.y);
					glEnd();
					
					// ARROW
					NSPoint aa1, aa2, aa3;
					
					if(b.y-a.y > 0) 
					{
						angle = atan( slide)/deg2rad;
						
						angle = 80 - angle - thickness;
						adj = (ARROWSIZE + thickness * 15)  * cos( angle*deg2rad);
						op = (ARROWSIZE + thickness * 15) * sin( angle*deg2rad);
						
						if( pixelSpacingX != 0 && pixelSpacingY != 0 )
							aa1 = NSMakePoint( a.x + adj, a.y + (op*pixelSpacingX / pixelSpacingY));
						else
							aa1 = NSMakePoint( a.x + adj, a.y + (op));
                        
						angle = atan( slide)/deg2rad;
						angle = 100 - angle + thickness;
						adj = (ARROWSIZE + thickness * 15) * cos( angle*deg2rad);
						op = (ARROWSIZE + thickness * 15) * sin( angle*deg2rad);
						
						if( pixelSpacingX != 0 && pixelSpacingY != 0 )
							aa2 = NSMakePoint( a.x + adj, a.y + (op*pixelSpacingX / pixelSpacingY));
						else
							aa2 = NSMakePoint( a.x + adj, a.y + (op));
					}
					else
					{
						angle = atan( slide)/deg2rad;
						
						angle = 180 + 80 - angle - thickness;
						adj = (ARROWSIZE + thickness * 15) * cos( angle*deg2rad);
						op = (ARROWSIZE + thickness * 15) * sin( angle*deg2rad);
						
						if( pixelSpacingX != 0 && pixelSpacingY != 0 )
							aa1 = NSMakePoint( a.x + adj, a.y + (op*pixelSpacingX / pixelSpacingY));
						else
							aa1 = NSMakePoint( a.x + adj, a.y + (op));
                        
						angle = atan( slide)/deg2rad;
						angle = 180 + 100 - angle + thickness;
						adj = (ARROWSIZE + thickness * 15) * cos( angle*deg2rad);
						op = (ARROWSIZE + thickness * 15) * sin( angle*deg2rad);
						
						if( pixelSpacingX != 0 && pixelSpacingY != 0 )
							aa2 = NSMakePoint( a.x + adj, a.y + (op*pixelSpacingX / pixelSpacingY));
						else
							aa2 = NSMakePoint( a.x + adj, a.y + (op));
					}
					aa3 = NSMakePoint( a.x , a.y );
					
					glLineWidth( 1.0);
					glBegin(GL_TRIANGLES);
					
					glColor4f(color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
					
					glVertex2f( aa1.x, aa1.y);
					glVertex2f( aa2.x, aa2.y);
					glVertex2f( aa3.x, aa3.y);
					
					glEnd();
					
					glBegin(GL_LINE_LOOP);
					glBlendFunc(GL_ONE_MINUS_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
					glColor4f(color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
					
					glVertex2f( aa1.x, aa1.y);
					glVertex2f( aa2.x, aa2.y);
					glVertex2f( aa3.x, aa3.y);
					
					glEnd();
				}
				else
				{
					// If there is another line, compute cobb's angle
					if( curView && displayCobbAngle && displayCMOrPixels == NO)
					{
						NSArray *roiList = curView.curRoiList;
						
						NSUInteger index = [roiList indexOfObject: self];
						if( index != NSNotFound)
						{
							if( index >= 0)
							{
								int no = 0;
								for( ROI *r  in roiList)
								{
									if( [r type] == tMesure)
									{
										no++;
										if( no >= 2)
											break;
									}
								}
								
								if( no >= 2)
								{
									BOOL f = NO;
									for( int i = 0; i < index; i++)
									{
										ROI *r = [roiList objectAtIndex: i];
										
										if( [r type] == tMesure)
										{
											f = YES;
											break;
										}
									}
									
									if( f == NO)
									{
										glColor4f ( 1.0, 1.0, 0.0, 0.5);
										glLineWidth( thickness * 3.);
										
										glBegin(GL_LINE_STRIP);
										for( id pt in points)
										{
											glVertex2f( ([pt x]- offsetx) * scaleValue , ([pt y]- offsety) * scaleValue );
										}
										glEnd();
										
										glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
										glLineWidth(thickness);
									}
								}
							}
						}
					}
					
					glBegin(GL_LINE_STRIP);
					for( id pt in points)
					{
						glVertex2f( ([pt x]- offsetx) * scaleValue , ([pt y]- offsety) * scaleValue );
					}
					glEnd();
					
					glPointSize( thickness);
                    
					glBegin( GL_POINTS);
					for( id pt in points)
					{
						glVertex2f( ([pt x]- offsetx) * scaleValue , ([pt y]- offsety) * scaleValue );
					}
					glEnd();
				}
				
				if( highlightIfSelected)
				{
					glColor3f (0.5f, 0.5f, 1.0f);
					
					if( tArrow)
						glPointSize( sqrt( thickness)*3.);
					else
						glPointSize( thickness*2);
					
					glBegin( GL_POINTS);
					for( long i = 0; i < [points count]; i++)
					{
						if(i == selectedModifyPoint || i == PointUnderMouse)
						{
							glColor3f (1.0f, 0.2f, 0.2f);
							glVertex2f( ([[points objectAtIndex: i] x]- offsetx) * scaleValue , ([[points objectAtIndex: i] y]- offsety) * scaleValue );
						}
						else if( mode >= ROI_selected)
						{
							glColor3f (0.5f, 0.5f, 1.0f);
							glVertex2f( ([[points objectAtIndex: i] x]- offsetx) * scaleValue , ([[points objectAtIndex: i] y]- offsety) * scaleValue );
						}
					}
					glEnd();
				}
				
				if( mousePosMeasure != -1)
				{
					NSPoint	pt = NSMakePoint( [[points objectAtIndex: 0] x], [[points objectAtIndex: 0] y]);
					float	theta, pyth;
					
					theta = atan( ([[points objectAtIndex: 1] y] - [[points objectAtIndex: 0] y]) / ([[points objectAtIndex: 1] x] - [[points objectAtIndex: 0] x]));
					
					pyth =	([[points objectAtIndex: 1] y] - [[points objectAtIndex: 0] y]) * ([[points objectAtIndex: 1] y] - [[points objectAtIndex: 0] y]) +
                    ([[points objectAtIndex: 1] x] - [[points objectAtIndex: 0] x]) * ([[points objectAtIndex: 1] x] - [[points objectAtIndex: 0] x]);
					pyth = sqrt( pyth);
					
					if( ([[points objectAtIndex: 1] x] - [[points objectAtIndex: 0] x]) < 0)
					{
						pt.x -= (mousePosMeasure * ( pyth)) * cos( theta);
						pt.y -= (mousePosMeasure * ( pyth)) * sin( theta);
					}
					else
					{
						pt.x += (mousePosMeasure * ( pyth)) * cos( theta);
						pt.y += (mousePosMeasure * ( pyth)) * sin( theta);
					}
					
					glColor3f (1.0f, 0.0f, 0.0f);
					glPointSize( (1 + sqrt( thickness))*3.5);
					glBegin( GL_POINTS);
                    glVertex2f( (pt.x - offsetx) * scaleValue , (pt.y - offsety) * scaleValue );
					glEnd();
				}
				
				glLineWidth(1.0);
				glColor3f (1.0f, 1.0f, 1.0f);
				
				// TEXT
				line1[ 0] = 0;		line2[ 0] = 0;	line3[ 0] = 0;		line4[ 0] = 0;	line5[ 0] = 0; line6[0] = 0;
				if( [self isTextualDataDisplayed] && prepareTextualData)
				{
					NSPoint tPt = self.lowerRightPoint;
					
					if( [name isEqualToString:@"Unnamed"] == NO) strcpy(line1, [name UTF8String]);
					if( type == tMesure && ROITEXTNAMEONLY == NO)
					{
						if( pixelSpacingX != 0 && pixelSpacingY != 0)
						{
							float lPix, lMm = [self MesureLength: &lPix];
							
							if( displayCMOrPixels)
							{
								if ( lMm < .1)
									sprintf (line2, "%0.1f %cm", lMm * 10000.0, 0xb5);
								else
									sprintf (line2, "%0.2f cm", lMm);
							}
							else
							{
								if ( lMm < .1)
									sprintf (line2, "Length: %0.1f %cm (%0.3f pix)", lMm * 10000.0, 0xb5, lPix);
								else
									sprintf (line2, "Length: %0.3f cm (%0.3f pix)", lMm, lPix);
							}
						}
						else
							sprintf (line2, "Length: %0.3f pix", [self Length:[[points objectAtIndex:0] point] :[[points objectAtIndex:1] point]]);
						
						// If there is another line, compute cobb's angle
						if( curView && displayCobbAngle && displayCMOrPixels == NO)
						{
							NSArray *roiList = curView.curRoiList;
							
							NSUInteger index = [roiList indexOfObject: self];
							if( index != NSNotFound)
							{
								if( index > 0)
								{
									for( int i = 0 ; i < index; i++)
									{
										ROI *r = [roiList objectAtIndex: i];
										
										if( [r type] == tMesure)
										{
											NSArray *B = [r points];
											NSPoint	u1 = [[[self points] objectAtIndex: 0] point], u2 = [[[self points] objectAtIndex: 1] point], v1 = [[B objectAtIndex: 0] point], v2 = [[B objectAtIndex: 1] point];
											
											float pX = [curView.curDCM pixelSpacingX];
											float pY = [curView.curDCM pixelSpacingY];
											
											if( pX == 0 || pY == 0)
											{
												pX = 1;
												pY = 1;
											}
											
											NSPoint a1, a2, b1, b2;
											a1 = NSMakePoint(u1.x * pX, u1.y * pY);
											a2 = NSMakePoint(u2.x * pX, u2.y * pY);
											b1 = NSMakePoint(v1.x * pX, v1.y * pY);
											b2 = NSMakePoint(v2.x * pX, v2.y * pY);
											
											if( (a2.x - a1.x) != 0 && (b2.x - b1.x) != 0)
											{
												NSPoint a = NSMakePoint( a1.x + (a2.x - a1.x)/2, a1.y + (a2.y - a1.y)/2);
												
												float slope1 = (a2.y - a1.y) / (a2.x - a1.x);
												slope1 = -1./slope1;
												float or1 = a.y - slope1*a.x;
												
												float slope2 = (b2.y - b1.y) / (b2.x - b1.x);
												float or2 = b1.y - slope2*b1.x;
												
												float xx = (or2 - or1) / (slope1 - slope2);
												
												NSPoint d = NSMakePoint( xx, or1 + xx*slope1);
												
												NSPoint b = [self ProjectionPointLine: a :b1 :b2];
												
												b.x = b.x + (d.x - b.x)/2.;
												b.y = b.y + (d.y - b.y)/2.;
												
												slope2 = -1./slope2;
												or2 = b.y - slope2*b.x;
												
												xx = (or2 - or1) / (slope1 - slope2);
												
												NSPoint c = NSMakePoint( xx, or1 + xx*slope1);
												float angle = [self AngleUncorrected :b :c :d];
												
												NSString *rName = r.name;
												
												if( [rName isEqualToString: @"Unnamed"] || [rName isEqualToString: NSLocalizedString( @"Unnamed", nil)])
													rName = nil;
												
												if( rName)
													sprintf (line3, "Cobb's Angle: %0.3f with: %s", angle, [rName UTF8String]);
												else
													sprintf (line3, "Cobb's Angle: %0.3f", angle);
												
												break;
											}
										}
									}
								}
							}
						}
					}
					[self prepareTextualData:line1 :line2 :line3 :line4 :line5 :line6 location:tPt];
				}
			}
                break;
                
			case tROI:
			{
				glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
				glLineWidth(thickness);
				glBegin(GL_LINE_LOOP);
                glVertex2f(  (rect.origin.x - offsetx)*scaleValue, (rect.origin.y - offsety)*scaleValue);
                glVertex2f(  (rect.origin.x - offsetx)*scaleValue, (rect.origin.y + rect.size.height- offsety)*scaleValue);
                glVertex2f(  (rect.origin.x+ rect.size.width- offsetx)*scaleValue, (rect.origin.y + rect.size.height- offsety)*scaleValue);
                glVertex2f(  (rect.origin.x+ rect.size.width - offsetx)*scaleValue, (rect.origin.y - offsety)*scaleValue);
				glEnd();
				
				glPointSize( thickness);
				glBegin( GL_POINTS);
                glVertex2f(  (rect.origin.x - offsetx)*scaleValue, (rect.origin.y - offsety)*scaleValue);
                glVertex2f(  (rect.origin.x - offsetx)*scaleValue, (rect.origin.y + rect.size.height- offsety)*scaleValue);
                glVertex2f(  (rect.origin.x+ rect.size.width- offsetx)*scaleValue, (rect.origin.y + rect.size.height- offsety)*scaleValue);
                glVertex2f(  (rect.origin.x+ rect.size.width - offsetx)*scaleValue, (rect.origin.y - offsety)*scaleValue);
				glEnd();
				
				if((mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing) && highlightIfSelected)
				{
					glColor3f (0.5f, 0.5f, 1.0f);
					glPointSize( (1 + sqrt( thickness))*3.5);
					glBegin( GL_POINTS);
					glVertex2f(  (rect.origin.x - offsetx)*scaleValue, (rect.origin.y - offsety)*scaleValue);
					glVertex2f(  (rect.origin.x - offsetx)*scaleValue, (rect.origin.y + rect.size.height- offsety)*scaleValue);
					glVertex2f(  (rect.origin.x+ rect.size.width- offsetx)*scaleValue, (rect.origin.y + rect.size.height- offsety)*scaleValue);
					glVertex2f(  (rect.origin.x+ rect.size.width - offsetx)*scaleValue, (rect.origin.y - offsety)*scaleValue);
					glEnd();
				}
				
				glLineWidth(1.0);
				glColor3f (1.0f, 1.0f, 1.0f);
				
				// TEXT
				{
					line1[ 0] = 0;		line2[ 0] = 0;	line3[ 0] = 0;		line4[ 0] = 0;	line5[ 0] = 0; line6[0] = 0;
					if( [self isTextualDataDisplayed] && prepareTextualData) {
						NSPoint			tPt = self.lowerRightPoint;
						
						if( [name isEqualToString:@"Unnamed"] == NO) strcpy(line1, [name UTF8String]);
						else line1[ 0] = 0;
						
						if( ROITEXTNAMEONLY == NO )
						{
							if( rtotal == -1) [[curView curDCM] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax];
							
							if( pixelSpacingX != 0 && pixelSpacingY != 0 ) {
								if ( fabs( NSWidth(rect)*pixelSpacingX*NSHeight(rect)*pixelSpacingY) < 1.)
									sprintf (line2, "Area: %0.1f %cm2", fabs( NSWidth(rect)*pixelSpacingX*NSHeight(rect)*pixelSpacingY * 1000000.0), 0xB5);
								else
									sprintf (line2, "Area: %0.3f cm2 (W:%0.1fmm H:%0.1fmm)", fabs( NSWidth(rect)*pixelSpacingX*NSHeight(rect)*pixelSpacingY/100.), fabs(NSWidth(rect)*pixelSpacingX), fabs(NSHeight(rect)*pixelSpacingY));
							}
							else
								sprintf (line2, "Area: %0.3f pix2", fabs( NSWidth(rect)*NSHeight(rect)));
							sprintf (line3, "Mean: %0.3f SDev: %0.3f Sum: %0.0f", rmean, rdev, rtotal);
							sprintf (line4, "Min: %0.3f Max: %0.3f", rmin, rmax);
							
							if( [curView blendingView])
							{
								DCMPix	*blendedPix = [[curView blendingView] curDCM];
								
								ROI *blendedROI = [[[ROI alloc] initWithType: type :[blendedPix pixelSpacingX] :[blendedPix pixelSpacingY] :[DCMPix originCorrectedAccordingToOrientation: blendedPix]] autorelease];
								
								NSRect blendedRect = [self rect];
								NSPoint downRight = NSMakePoint( blendedRect.origin.x + blendedRect.size.width, blendedRect.origin.y + blendedRect.size.height);
								
								blendedRect.origin = [curView ConvertFromGL2GL: blendedRect.origin toView:[curView blendingView]];
								
								downRight = [curView ConvertFromGL2GL: downRight toView:[curView blendingView]];
								
								blendedRect.size.width = downRight.x - blendedRect.origin.x;
								blendedRect.size.height = downRight.y - blendedRect.origin.y;
								
								[blendedROI setROIRect: blendedRect];
								
								[blendedPix computeROI: blendedROI :&Brmean :&Brtotal :&Brdev :&Brmin :&Brmax];
								
								sprintf (line5, "Fused Image Mean: %0.3f SDev: %0.3f Sum: %0.0f", Brmean, Brdev, Brtotal);
								sprintf (line6, "Fused Image Min: %0.3f Max: %0.3f", Brmin, Brmax);
							}
						}
						
						[self prepareTextualData:line1 :line2 :line3 :line4 :line5 :line6 location:tPt];
					}
				}
			}
                break;
                
			case tOval:
			{
				float angle;
				
				glColor4f( color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
				glLineWidth( thickness);
				
				NSRect rrect = rect;
				
				if( rrect.size.height < 0)
					rrect.size.height = -rrect.size.height;
				
				if( rrect.size.width < 0)
					rrect.size.width = -rrect.size.width;
				
				int resol = (rrect.size.height + rrect.size.width) * 1.5 * scaleValue;
				
				glBegin(GL_LINE_LOOP);
				for( int i = 0; i < resol ; i++ )
				{
					angle = i * 2 * M_PI /resol;
                    
                    glVertex2f( (rrect.origin.x + rrect.size.width*cos(angle) - offsetx)*scaleValue, (rrect.origin.y + rrect.size.height*sin(angle)- offsety)*scaleValue);
				}
				glEnd();
				
				glPointSize( thickness);
				glBegin( GL_POINTS);
				for( int i = 0; i < resol ; i++ )
				{
					angle = i * 2 * M_PI /resol;
                    
                    glVertex2f( (rrect.origin.x + rrect.size.width*cos(angle) - offsetx)*scaleValue, (rrect.origin.y + rrect.size.height*sin(angle)- offsety)*scaleValue);
				}
				glEnd();
				
				if((mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing) && highlightIfSelected)
				{
					glColor3f (0.5f, 0.5f, 1.0f);
					glPointSize( (1 + sqrt( thickness))*3.5);
					glBegin( GL_POINTS);
					glVertex2f( (rrect.origin.x - offsetx - rrect.size.width) * scaleValue, (rrect.origin.y - rrect.size.height - offsety) * scaleValue);
					glVertex2f( (rrect.origin.x - offsetx - rrect.size.width) * scaleValue, (rrect.origin.y + rrect.size.height - offsety) * scaleValue);
					glVertex2f( (rrect.origin.x + rrect.size.width - offsetx) * scaleValue, (rrect.origin.y + rrect.size.height - offsety) * scaleValue);
					glVertex2f( (rrect.origin.x + rrect.size.width - offsetx) * scaleValue, (rrect.origin.y - rrect.size.height - offsety) * scaleValue);
					
					//Center
					glVertex2f( (rrect.origin.x - offsetx) * scaleValue, (rrect.origin.y - offsety) * scaleValue);
					glEnd();
				}
				
				glLineWidth(1.0);
				glColor3f (1.0f, 1.0f, 1.0f);
				
				// TEXT
				
				line1[ 0] = 0;		line2[ 0] = 0;	line3[ 0] = 0;		line4[ 0] = 0;	line5[ 0] = 0;	line6[ 0] = 0;
				if( [self isTextualDataDisplayed] && prepareTextualData)
				{
					NSPoint tPt = self.lowerRightPoint;
					
					if( [name isEqualToString:@"Unnamed"] == NO) strcpy(line1, [name UTF8String]);
					
					if( ROITEXTNAMEONLY == NO )
					{
						if( rtotal == -1) [[curView curDCM] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax];
						
						if( pixelSpacingX != 0 && pixelSpacingY != 0)
						{
							if( [self EllipseArea]*pixelSpacingX*pixelSpacingY < 1.)
								sprintf (line2, "Area: %0.1f %cm2", [self EllipseArea]*pixelSpacingX*pixelSpacingY* 1000000.0, 0xB5);
							else
								sprintf (line2, "Area: %0.3f cm2", [self EllipseArea]*pixelSpacingX*pixelSpacingY/100.);
						}
						else
							sprintf (line2, "Area: %0.3f pix2", [self EllipseArea]);
						
						sprintf (line3, "Mean: %0.3f SDev: %0.3f Sum: %0.0f", rmean, rdev, rtotal);
						sprintf (line4, "Min: %0.3f Max: %0.3f", rmin, rmax);
						
						if( [curView blendingView])
						{
							DCMPix	*blendedPix = [[curView blendingView] curDCM];
							
							ROI *blendedROI = [[[ROI alloc] initWithType: tCPolygon :[blendedPix pixelSpacingX] :[blendedPix pixelSpacingY] :[DCMPix originCorrectedAccordingToOrientation: blendedPix]] autorelease];
							
							NSMutableArray *pts = [[[NSMutableArray alloc] initWithArray: [self points] copyItems:YES] autorelease];
							
							for( MyPoint *p in pts)
								[p setPoint: [curView ConvertFromGL2GL: [p point] toView:[curView blendingView]]];
							
							[blendedROI setPoints: pts];
							[blendedPix computeROI: blendedROI :&Brmean :&Brtotal :&Brdev :&Brmin :&Brmax];
							
							sprintf (line5, "Fused Image Mean: %0.3f SDev: %0.3f Sum: %0.0f", Brmean, Brdev, Brtotal);
							sprintf (line6, "Fused Image Min: %0.3f Max: %0.3f", Brmin, Brmax);
						}
					}
					
					[self prepareTextualData:line1 :line2 :line3 :line4 :line5 :line6 location:tPt];
				}
			}
                break;
                
			case tAxis:
			{
				glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
				
				if( mode == ROI_drawing) 
					glLineWidth(thickness * 2);
				else 
					glLineWidth(thickness);
				
				glBegin(GL_LINE_LOOP);
				
				for( long i = 0; i < [points count]; i++)
				{				
					//NSLog(@"JJCP--	tAxis- New point: %f x, %f y",[[points objectAtIndex:i] x],[[points objectAtIndex:i] y]);
					glVertex2f( ([[points objectAtIndex: i] x]- offsetx) * scaleValue , ([[points objectAtIndex: i] y]- offsety) * scaleValue );
					if(i>2)
					{
						//glEnd();
						break;
					}
				}
				glEnd();
				if( [points count]>3 )
				{
					for( long i=4;i<[points count];i++ ) [points removeObjectAtIndex: i];
				}
				//TEXTO
				line1[ 0] = 0;		line2[ 0] = 0;	line3[ 0] = 0;		line4[ 0] = 0;	line5[ 0] = 0; line6[0] = 0;
				if( [self isTextualDataDisplayed] && prepareTextualData)
				{
					NSPoint tPt = self.lowerRightPoint;
					float   length;
					
					if( [name isEqualToString:@"Unnamed"] == NO) strcpy(line1, [name UTF8String]);
					
					if( ROITEXTNAMEONLY == NO ) {
						if( rtotal == -1) [[curView curDCM] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax];
						
						if( pixelSpacingX != 0 && pixelSpacingY != 0 ) {
							if([self Area] *pixelSpacingX*pixelSpacingY < 1.)
								sprintf (line2, "Area: %0.1f %cm2", [self Area] *pixelSpacingX*pixelSpacingY * 1000000.0, 0xB5);
							else
								sprintf (line2, "Area: %0.3f cm2", [self Area] *pixelSpacingX*pixelSpacingY / 100.);
						}
						else
							sprintf (line2, "Area: %0.3f pix2", [self Area]);
						sprintf (line3, "Mean: %0.3f SDev: %0.3f Sum: %0.0f", rmean, rdev, rtotal);
						sprintf (line4, "Min: %0.3f Max: %0.3f", rmin, rmax);
						
						length = 0;
						long i;
						for( i = 0; i < [points count]-1; i++ ) {
							length += [self Length:[[points objectAtIndex:i] point] :[[points objectAtIndex:i+1] point]];
						}
						length += [self Length:[[points objectAtIndex:i] point] :[[points objectAtIndex:0] point]];
						
						if (length < .1)
							sprintf (line5, "L: %0.1f %cm", length * 10000.0, 0xB5);
						else
							sprintf (line5, "Length: %0.3f cm", length);
					}
					
					[self prepareTextualData:line1 :line2 :line3 :line4 :line5 :line6 location:tPt];
				}
                if((mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing) && highlightIfSelected)
                {
                    NSPoint tempPt = [curView convertPoint: [[curView window] mouseLocationOutsideOfEventStream] fromView: nil];
                    tempPt = [curView ConvertFromNSView2GL:tempPt];
                    
                    glColor3f (0.5f, 0.5f, 1.0f);
                    glPointSize( (1 + sqrt( thickness))*3.5);
                    glBegin( GL_POINTS);
                    for( long i = 0; i < [points count]; i++) {
                        if( mode >= ROI_selected && (i == selectedModifyPoint || i == PointUnderMouse)) glColor3f (1.0f, 0.2f, 0.2f);
                        else if( mode == ROI_drawing && [[points objectAtIndex: i] isNearToPoint: tempPt : scaleValue/thickness :[[curView curDCM] pixelRatio]] == YES) glColor3f (1.0f, 0.0f, 1.0f);
                        else glColor3f (0.5f, 0.5f, 1.0f);
                        
                        glVertex2f( ([[points objectAtIndex: i] x]- offsetx) * scaleValue , ([[points objectAtIndex: i] y]- offsety) * scaleValue);
                    }
                    glEnd();
                }
                if(1)
                {	
                    BOOL plot=NO;
                    BOOL plot2=NO;
                    NSPoint tPt0, tPt1, tPt01, tPt2, tPt3, tPt23, tPt03, tPt21;
                    if([points count]>3)
                    {
                        //Calculus of middle point between 0 and 1.
                        tPt0.x = ([[points objectAtIndex: 0] x]- offsetx) * scaleValue;
                        tPt0.y = ([[points objectAtIndex: 0] y]- offsety) * scaleValue;
                        tPt1.x = ([[points objectAtIndex: 1] x]- offsetx) * scaleValue;
                        tPt1.y = ([[points objectAtIndex: 1] y]- offsety) * scaleValue;
                        //Calculus of middle point between 2 and 3.
                        tPt2.x = ([[points objectAtIndex: 2] x]- offsetx) * scaleValue;
                        tPt2.y = ([[points objectAtIndex: 2] y]- offsety) * scaleValue;
                        tPt3.x = ([[points objectAtIndex: 3] x]- offsetx) * scaleValue;
                        tPt3.y = ([[points objectAtIndex: 3] y]- offsety) * scaleValue;
                        plot=YES;
                        plot2=YES;
                    }
                    //else
                    /*
                     {
                     tPt0.x=0-offsetx*scaleValue;
                     tPt0.y=0-offsety*scaleValue;
                     tPt1.x=0-offsetx*scaleValue;
                     tPt1.y=0-offsety*scaleValue;
                     tPt2.x=0-offsetx*scaleValue;
                     tPt2.y=0-offsety*scaleValue;
                     tPt3.x=0-offsetx*scaleValue;
                     tPt3.y=0-offsety*scaleValue;
                     
                     }*/
                    //Calcular punto medio entre el punto 0 y 1.
                    tPt01.x  = (tPt1.x+tPt0.x)/2;
                    tPt01.y  = (tPt1.y+tPt0.y)/2;
                    //Calcular punto medio entre el punto 2 y 3.
                    tPt23.x  = (tPt3.x+tPt2.x)/2;
                    tPt23.y  = (tPt3.y+tPt2.y)/2;
                    
                    
                    /*****Line equation p1-p2
                     *
                     * 	// line between p1 and p2
                     *	float a, b; // y = ax+b
                     *	a = (p2.y-p1.y) / (p2.x-p1.x);
                     *	b = p1.y - a * p1.x;
                     *	float y1 = a * point.x + b;
                     *   point.x=(y1-b)/a;
                     *
                     ******/
                    //Line 1. Equation
                    float a1,b1,a2,b2;
                    a1=(tPt23.y-tPt01.y)/(tPt23.x-tPt01.x);
                    b1=tPt01.y-a1*tPt01.x;
                    float x1,x2,x3,x4,y1,y2,y3,y4;
                    y1=tPt01.y-125;
                    y2=tPt23.y+125;					
                    x1=(y1-b1)/a1;
                    x2=(y2-b1)/a1;
                    //Line 2. Equation
                    tPt03.x  = (tPt3.x+tPt0.x)/2;
                    tPt03.y  = (tPt3.y+tPt0.y)/2;
                    tPt21.x  = (tPt1.x+tPt2.x)/2;
                    tPt21.y  = (tPt1.y+tPt2.y)/2;
                    a2=(tPt21.y-tPt03.y)/(tPt21.x-tPt03.x);
                    b2=tPt03.y-a2*tPt03.x;
                    x3=tPt03.x-125;
                    x4=tPt21.x+125;
                    y3=a2*x3+b2;
                    y4=a2*x4+b2;
                    if(plot)
                    {
                        glBegin(GL_LINE_STRIP);
                        glColor3f (0.0f, 0.0f, 1.0f);
                        glVertex2f(x1,y1);
                        glVertex2f(x2,y2);
                        //glVertex2f(tPt01.x, tPt01.y);
                        //glVertex2f(tPt23.x, tPt23.y);
                        glEnd();
                        glBegin(GL_LINE_STRIP);
                        glColor3f (1.0f, 0.0f, 0.0f);
                        glVertex2f(x3,y3);
                        glVertex2f(x4,y4);
                        //glVertex2f(tPt03.x, tPt03.y);
                        //glVertex2f(tPt21.x, tPt21.y);
                        glEnd();
                    }
                    if(plot2)
                    {
                        NSPoint p1, p2, p3, p4;
                        p1 = [[points objectAtIndex:0] point];
                        p2 = [[points objectAtIndex:1] point];
                        p3 = [[points objectAtIndex:2] point];
                        p4 = [[points objectAtIndex:3] point];
                        
                        p1.x = (p1.x-offsetx)*scaleValue;
                        p1.y = (p1.y-offsety)*scaleValue;
                        p2.x = (p2.x-offsetx)*scaleValue;
                        p2.y = (p2.y-offsety)*scaleValue;
                        p3.x = (p3.x-offsetx)*scaleValue;
                        p3.y = (p3.y-offsety)*scaleValue;
                        p4.x = (p4.x-offsetx)*scaleValue;
                        p4.y = (p4.y-offsety)*scaleValue;
                        //if(1)
                        {	
                            glEnable(GL_BLEND);
                            glDisable(GL_POLYGON_SMOOTH);
                            glDisable(GL_POINT_SMOOTH);
                            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                            // inside: fill							
                            glColor4f(color.red / 65535., color.green / 65535., color.blue / 65535., 0.25);
                            glBegin(GL_POLYGON);		
                            glVertex2f(p1.x, p1.y);
                            glVertex2f(p2.x, p2.y);
                            glVertex2f(p3.x, p3.y);
                            glVertex2f(p4.x, p4.y);
                            glEnd();
                            
                            // no border
                            
                            /*	glColor4f(color.red / 65535., color.green / 65535., color.blue / 65535., 0.2);						
                             glBegin(GL_LINE_LOOP);
                             glVertex2f(p1.x, p1.y);
                             glVertex2f(p2.x, p2.y);
                             glVertex2f(p3.x, p3.y);
                             glVertex2f(p4.x, p4.y);
                             glEnd();
                             */	
                            glDisable(GL_BLEND);
                        }											
                    }
				}			
				glLineWidth(1.0);
				glColor3f (1.0f, 1.0f, 1.0f);			
			}
                break;
                
			case tDynAngle:
			{
				glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
				
				if( mode == ROI_drawing) 
					glLineWidth(thickness * 2);
				else 
					glLineWidth(thickness);
				
				glBegin(GL_LINE_STRIP);
				
				for( long i = 0; i < [points count]; i++) {				
					if(i==1||i==2)
					{
						glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., 0.1);
					}
					else
					{
						glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
					}
					glVertex2f( ([[points objectAtIndex: i] x]- offsetx) * scaleValue , ([[points objectAtIndex: i] y]- offsety) * scaleValue );
					if(i>2)
					{
						//glEnd();
						break;
					}
				}
				glEnd();
				if( [points count]>3 )
				{
					for( long i=4; i<[points count]; i++ ) [points removeObjectAtIndex: i];
				}
				NSPoint a1,a2,b1,b2;
				NSPoint a,b,c,d;
				float angle=0;
				if([points count]>3)
				{
					a1 = [[points objectAtIndex: 0] point];
					a2 = [[points objectAtIndex: 1] point];
					b1 = [[points objectAtIndex: 2] point];
					b2 = [[points objectAtIndex: 3] point];
					
					if( pixelSpacingX != 0 && pixelSpacingY != 0)
					{
						a1 = NSMakePoint(a1.x * pixelSpacingX, a1.y * pixelSpacingY);
						a2 = NSMakePoint(a2.x * pixelSpacingX, a2.y * pixelSpacingY);
						b1 = NSMakePoint(b1.x * pixelSpacingX, b1.y * pixelSpacingY);
						b2 = NSMakePoint(b2.x * pixelSpacingX, b2.y * pixelSpacingY);
					}
					
					//plot=YES;
					//plot2=YES;
					
					//Code from Cobb's angle plugin.
					a = NSMakePoint( a1.x + (a2.x - a1.x)/2, a1.y + (a2.y - a1.y)/2);
					
					float slope1 = (a2.y - a1.y) / (a2.x - a1.x);
					slope1 = -1./slope1;
					float or1 = a.y - slope1*a.x;
					
					float slope2 = (b2.y - b1.y) / (b2.x - b1.x);
					float or2 = b1.y - slope2*b1.x;
					
					float xx = (or2 - or1) / (slope1 - slope2);
					
					d = NSMakePoint( xx, or1 + xx*slope1);
					
					b = [self ProjectionPointLine: a :b1 :b2];
					
					b.x = b.x + (d.x - b.x)/2.;
					b.y = b.y + (d.y - b.y)/2.;
					
					slope2 = -1./slope2;
					or2 = b.y - slope2*b.x;
					
					xx = (or2 - or1) / (slope1 - slope2);
					
					c = NSMakePoint( xx, or1 + xx*slope1);
					
					//Angle given by b,c,d points
					angle = [self AngleUncorrected:b :c :d];
				}
				//TEXTO
				line1[ 0] = 0;		line2[ 0] = 0;	line3[ 0] = 0;		line4[ 0] = 0;	line5[ 0] = 0; line6[0] = 0;
				if( [self isTextualDataDisplayed] && prepareTextualData)
				{
                    NSPoint tPt = self.lowerRightPoint;
                    float   length;
                    
                    if( [name isEqualToString:@"Unnamed"] == NO) strcpy(line1, [name UTF8String]);
                    
                    if( ROITEXTNAMEONLY == NO ) {
                        
                        if( rtotal == -1) [[curView curDCM] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax];
                        
                        if( pixelSpacingX != 0 && pixelSpacingY != 0 ) {
                            if ([self Area] *pixelSpacingX*pixelSpacingY < 1.)
                                sprintf (line2, "Area: %0.1f %cm2", [self Area] *pixelSpacingX*pixelSpacingY * 1000000.0, 0xB5);
                            else
                                sprintf (line2, "Area: %0.3f cm2", [self Area] *pixelSpacingX*pixelSpacingY / 100.);
                        }
                        else
                            sprintf (line2, "Area: %0.3f pix2", [self Area]);
                        
                        sprintf (line3, "Mean: %0.3f SDev: %0.3f Sum: %0.0f", rmean, rdev, rtotal);
                        sprintf (line4, "Min: %0.3f Max: %0.3f", rmin, rmax);
                        
                        length = 0;
                        for( long i = 0; i < [points count]-1; i++ ) {
                            length += [self Length:[[points objectAtIndex:i] point] :[[points objectAtIndex:i+1] point]];
                        }
                        
                        if (length < .1)
                            sprintf (line5, "L: %0.1f %cm", length * 10000.0, 0xB5);
                        else
                            sprintf (line5, "Length: %0.3f cm", length);
                    }
                    sprintf (line2, "Angle: %0.2f", angle);
                    sprintf (line3, "Angle 2: %0.2f",360 - angle);
                    line4[ 0] = 0;
                    //sprintf (line5,"");
                    [self prepareTextualData:line1 :line2 :line3 :line4 :line5 :line6 location:tPt];
				}
				//ROI MODE
				if((mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing) && highlightIfSelected)
				{
					NSPoint tempPt = [curView convertPoint: [[curView window] mouseLocationOutsideOfEventStream] fromView: nil];
					tempPt = [curView ConvertFromNSView2GL:tempPt];
					
					glColor3f (0.5f, 0.5f, 1.0f);
					glPointSize( (1 + sqrt( thickness))*3.5);
					glBegin( GL_POINTS);
					for( long i = 0; i < [points count]; i++) {
						if( mode >= ROI_selected && (i == selectedModifyPoint || i == PointUnderMouse)) glColor3f (1.0f, 0.2f, 0.2f);
						else if( mode == ROI_drawing && [[points objectAtIndex: i] isNearToPoint: tempPt : scaleValue/thickness :[[curView curDCM] pixelRatio]] == YES) glColor3f (1.0f, 0.0f, 1.0f);
						else glColor3f (0.5f, 0.5f, 1.0f);
						
						glVertex2f( ([[points objectAtIndex: i] x]- offsetx) * scaleValue , ([[points objectAtIndex: i] y]- offsety) * scaleValue);
					}
					glEnd();
				}
				
				glLineWidth(1.0);
				glColor3f (1.0f, 1.0f, 1.0f);
			}
                break;
				
			case tCPolygon:
			case tOPolygon:
			case tAngle:
			case tPencil:
			{
				glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
				
				if( mode == ROI_drawing) glLineWidth(thickness * 2);
				else glLineWidth(thickness);
				
				NSMutableArray *splinePoints = [self splinePoints: scaleValue];
				
				if( [splinePoints count] >= 1)
				{
					if( (type == tCPolygon || type == tPencil) && mode != ROI_drawing ) glBegin(GL_LINE_LOOP);
					else glBegin(GL_LINE_STRIP);
					
					for(long i=0; i<[splinePoints count]; i++)
					{
						glVertex2d( ((double) [[splinePoints objectAtIndex:i] x]- (double) offsetx)*(double) scaleValue , ((double) [[splinePoints objectAtIndex:i] y]-(double) offsety)*(double) scaleValue);
					}
					glEnd();
					
					if( mode == ROI_drawing) glPointSize( thickness * 2);
					else glPointSize( thickness);
					
					glBegin( GL_POINTS);
					for(long i=0; i<[splinePoints count]; i++)
					{
						glVertex2d( ((double) [[splinePoints objectAtIndex:i] x]- (double) offsetx)*(double) scaleValue , ((double) [[splinePoints objectAtIndex:i] y]-(double) offsety)*(double) scaleValue);
					}
					glEnd();
					
					// TEXT
					if( type == tCPolygon || type == tPencil)
					{
						line1[ 0] = 0;		line2[ 0] = 0;	line3[ 0] = 0;		line4[ 0] = 0;	line5[ 0] = 0; line6[0] = 0;
						if( [self isTextualDataDisplayed] && prepareTextualData)
						{
							NSPoint tPt = self.lowerRightPoint;
							float   length;
							
							if( [name isEqualToString:@"Unnamed"] == NO) strcpy(line1, [name UTF8String]);
							
							if( ROITEXTNAMEONLY == NO )
							{
								if( rtotal == -1) [[curView curDCM] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax];
								
								if( pixelSpacingX != 0 && pixelSpacingY != 0 )
								{
									if([self Area] *pixelSpacingX*pixelSpacingY < 1.)
										sprintf (line2, "Area: %0.1f %cm2", [self Area] *pixelSpacingX*pixelSpacingY * 1000000.0, 0xB5);
									else
										sprintf (line2, "Area: %0.3f cm2", [self Area] *pixelSpacingX*pixelSpacingY / 100.);
								}
								else
									sprintf (line2, "Area: %0.3f pix2", [self Area]);
								sprintf (line3, "Mean: %0.3f SDev: %0.3f Sum: %0.0f", rmean, rdev, rtotal);
								sprintf (line4, "Min: %0.3f Max: %0.3f", rmin, rmax);
								
								length = 0;
								
								if( [splinePoints count] < 2)
								{
									sprintf (line5, "Length: %0.3f cm", length);
								}
								else
								{
									if( [curView blendingView])
									{
										DCMPix	*blendedPix = [[curView blendingView] curDCM];
										
										ROI *blendedROI = [[[ROI alloc] initWithType: tCPolygon :[blendedPix pixelSpacingX] :[blendedPix pixelSpacingY] :[DCMPix originCorrectedAccordingToOrientation: blendedPix]] autorelease];
										
										NSMutableArray *pts = [[[NSMutableArray alloc] initWithArray: [self points] copyItems:YES] autorelease];
										
										for( MyPoint *p in pts)
											[p setPoint: [curView ConvertFromGL2GL: [p point] toView:[curView blendingView]]];
										
										[blendedROI setPoints: pts];
										[blendedPix computeROI: blendedROI :&Brmean :&Brtotal :&Brdev :&Brmin :&Brmax];
										
										sprintf (line5, "Fused Image Mean: %0.3f SDev: %0.3f Sum: %0.0f", Brmean, Brdev, Brtotal);
										sprintf (line6, "Fused Image Min: %0.3f Max: %0.3f", Brmin, Brmax);
									}
									else
									{
										int i = 0;
										for( i = 0; i < [splinePoints count]-1; i++ )
										{
											length += [self Length:[[splinePoints objectAtIndex:i] point] :[[splinePoints objectAtIndex:i+1] point]];
										}
										length += [self Length:[[splinePoints objectAtIndex:i] point] :[[splinePoints objectAtIndex:0] point]];
										
										if (length < .1)
											sprintf (line5, "L: %0.1f %cm", length * 10000.0, 0xB5);
										else
											sprintf (line5, "Length: %0.3f cm", length);
									}
								}
							}
							
							[self prepareTextualData:line1 :line2 :line3 :line4 :line5 :line6 location:tPt];
						}
					}
					else if( type == tOPolygon)
					{
						line1[ 0] = 0;		line2[ 0] = 0;	line3[ 0] = 0;		line4[ 0] = 0;	line5[ 0] = 0; line6[0] = 0;
						if( [self isTextualDataDisplayed] && prepareTextualData)
						{
							NSPoint tPt = self.lowerRightPoint;
							float   length;
							
							if( [name isEqualToString:@"Unnamed"] == NO) strcpy(line1, [name UTF8String]);
							
							if( ROITEXTNAMEONLY == NO )
							{
								if( rtotal == -1) [[curView curDCM] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax];
								
								if( pixelSpacingX != 0 && pixelSpacingY != 0 )
								{
									if ([self Area] *pixelSpacingX*pixelSpacingY < 1.)
										sprintf (line2, "Area: %0.1f %cm2", [self Area] *pixelSpacingX*pixelSpacingY * 1000000.0, 0xB5);
									else
										sprintf (line2, "Area: %0.3f cm2", [self Area] *pixelSpacingX*pixelSpacingY / 100.);
								}
								else
									sprintf (line2, "Area: %0.3f pix2", [self Area]);
								
								sprintf (line3, "Mean: %0.3f SDev: %0.3f Sum: %0.0f", rmean, rdev, rtotal);
								sprintf (line4, "Min: %0.3f Max: %0.3f", rmin, rmax);
								
								if( [curView blendingView])
								{
									DCMPix	*blendedPix = [[curView blendingView] curDCM];
									
									ROI *blendedROI = [[[ROI alloc] initWithType: tCPolygon :[blendedPix pixelSpacingX] :[blendedPix pixelSpacingY] :[DCMPix originCorrectedAccordingToOrientation: blendedPix]] autorelease];
									
									NSMutableArray *pts = [[[NSMutableArray alloc] initWithArray: [self points] copyItems:YES] autorelease];
									
									for( MyPoint *p in pts)
										[p setPoint: [curView ConvertFromGL2GL: [p point] toView:[curView blendingView]]];
									
									[blendedROI setPoints: pts];
									[blendedPix computeROI: blendedROI :&Brmean :&Brtotal :&Brdev :&Brmin :&Brmax];
									
									sprintf (line5, "Fused Image Mean: %0.3f SDev: %0.3f Sum: %0.0f", Brmean, Brdev, Brtotal);
									sprintf (line6, "Fused Image Min: %0.3f Max: %0.3f", Brmin, Brmax);
								}
								else
								{
									length = 0;
									for( long i = 0; i < [splinePoints count]-1; i++ )
									{
										length += [self Length:[[splinePoints objectAtIndex:i] point] :[[splinePoints objectAtIndex:i+1] point]];
									}
									
									if( length > 0.0 && length < .1)
										sprintf (line5, "L: %0.1f %cm", length * 10000.0, 0xB5);
									else
										sprintf (line5, "Length: %0.3f cm", length);
									
									
									// 3D Length
									if( curView && pixelSpacingX != 0 && pixelSpacingY != 0)
									{
										NSArray *zPosArray = [self zPositions];
                                        
										if( [zPosArray count])
										{
											int zPos = [[zPosArray objectAtIndex:0] intValue];
											for( int i = 1; i < [zPosArray count]; i++)
											{
												if( zPos != [[zPosArray objectAtIndex:i] intValue])
												{
													if( [zPosArray count] != [points count])
														NSLog( @"***** [zPosArray count] != [points count]");
													
													double sliceInterval = [[self pix] sliceInterval];
													
													// Compute 3D distance between each points
													double distance3d = 0;
													for( i = 1; i < [points count]-1; i++)
													{
														double x[ 3];
														double y[ 3];
														
														
														x[ 0] = [[points objectAtIndex:i] point].x * pixelSpacingX;
														x[ 1] = [[points objectAtIndex:i] point].y * pixelSpacingY;
														x[ 2] = [[zPosArray objectAtIndex:i] intValue] * sliceInterval;
														
														y[ 0] = [[points objectAtIndex:i-1] point].x * pixelSpacingX;
														y[ 1] = [[points objectAtIndex:i-1] point].y * pixelSpacingY;
														y[ 2] = [[zPosArray objectAtIndex:i-1] intValue] * sliceInterval;
														
														distance3d += sqrt((x[0]-y[0])*(x[0]-y[0]) + (x[1]-y[1])*(x[1]-y[1]) +  (x[2]-y[2])*(x[2]-y[2]));
													}
													
													if (length < .1)
														sprintf (line6, "3D L: %0.1f %cm", distance3d * 10000.0, 0xB5);
													else
														sprintf (line6, "3D Length: %0.3f cm", distance3d / 10.);
													break;
												}
											}
										}
									}
								}
							}
							
							[self prepareTextualData:line1 :line2 :line3 :line4 :line5 :line6 location:tPt];
						}
					}
					else if( type == tAngle)
					{
						if( [points count] == 3)
						{
							displayTextualData = YES;
							line1[ 0] = 0;		line2[ 0] = 0;	line3[ 0] = 0;		line4[ 0] = 0;	line5[ 0] = 0; line6[0] = 0;
							if( [self isTextualDataDisplayed] && prepareTextualData)
							{
								NSPoint tPt = self.lowerRightPoint;
								float   angle;
								
								if( [name isEqualToString:@"Unnamed"] == NO) strcpy(line1, [name UTF8String]);
								
								angle = [self Angle:[[points objectAtIndex: 0] point] :[[points objectAtIndex: 1] point] : [[points objectAtIndex: 2] point]];
								
								sprintf (line2, "Angle: %0.3f / %0.3f", angle, 360 - angle);
								
								[self prepareTextualData:line1 :line2 :line3 :line4 :line5 :line6 location:tPt];
							}
						}
						else displayTextualData = NO;
					}
					
					if((mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing) && highlightIfSelected)
					{
						[curView window];
						
						NSPoint tempPt = [curView convertPoint: [[curView window] mouseLocationOutsideOfEventStream] fromView: nil];
						tempPt = [curView ConvertFromNSView2GL:tempPt];
						
						glColor3f (0.5f, 0.5f, 1.0f);
						glPointSize( (1 + sqrt( thickness))*3.5);
						glBegin( GL_POINTS);
						for( long i = 0; i < [points count]; i++)
						{
							if( mode >= ROI_selected && (i == selectedModifyPoint || i == PointUnderMouse)) glColor3f (1.0f, 0.2f, 0.2f);
							else if( mode == ROI_drawing && [[points objectAtIndex: i] isNearToPoint: tempPt : scaleValue/thickness :[[curView curDCM] pixelRatio]] == YES) glColor3f (1.0f, 0.0f, 1.0f);
							else glColor3f (0.5f, 0.5f, 1.0f);
							
							glVertex2f( ([[points objectAtIndex: i] x]- offsetx) * scaleValue , ([[points objectAtIndex: i] y]- offsety) * scaleValue);
						}
						glEnd();
					}
					
					if( PointUnderMouse != -1)
					{
						if( PointUnderMouse < [points count])
						{
							glColor3f (1.0f, 0.0f, 1.0f);
							glPointSize( (1 + sqrt( thickness))*3.5);
							glBegin( GL_POINTS);
							
							glVertex2f( ([[points objectAtIndex: PointUnderMouse] x]- offsetx) * scaleValue , ([[points objectAtIndex: PointUnderMouse] y]- offsety) * scaleValue);
							
							glEnd();
						}
					}
					
					glLineWidth(1.0);
					glColor3f (1.0f, 1.0f, 1.0f);
				}
			}
                break;
		}
		
		glPointSize( 1.0);
		
		glDisable(GL_LINE_SMOOTH);
		glDisable(GL_POLYGON_SMOOTH);
		glDisable(GL_POINT_SMOOTH);
		glDisable(GL_BLEND);
	}
	@catch (NSException *e)
	{
		NSLog( @"drawROIWithScaleValue exception : %@", e);
	}
	[roiLock unlock];
	
	thickness = thicknessCopy;
}

- (BOOL) isTextualDataDisplayed
{
	if(!displayTextualData) return NO;
	
	// NO text for Calcium Score
	if (_displayCalciumScoring)
		return NO;
    
	BOOL drawTextBox = NO;
	
	if( ROITEXTIFSELECTED == NO || mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing)
	{
		drawTextBox = YES;
	}
	
	if( mode == ROI_selectedModify || mode == ROI_drawing)
	{
		if(	type == tOPolygon ||
           type == tCPolygon ||
           type == tPencil ||
           type == tPlain) drawTextBox = NO;
        
	}
	
	return drawTextBox;
}

-(float) AngleUncorrected:(NSPoint) p2 :(NSPoint) p1 :(NSPoint) p3
{
    float 		ax,ay,bx,by;
    float			val, angle;
    
    ax = p2.x - p1.x;
    ay = p2.y - p1.y;
    bx = p3.x - p1.x;
    by = p3.y - p1.y;
    
    if (ax == 0 && ay == 0) return 0;
    val = ((ax * bx) + (ay * by)) / (sqrt(ax*ax + ay*ay) * sqrt(bx*bx + by*by));
    angle = acos (val) / deg2rad;
    return angle;
}

-(float) plainArea
{
	long x = 0;
	for( long i = 0; i < textureWidth*textureHeight ; i++ )
	{
		if( textureBuffer[i] != 0) x++;
	}
	
	return x;
}

-(float) Area
{
	if( type == tPlain)
	{
		return [self plainArea];
	}
	
	return [self Area: [self splinePoints]];
}

-(float) Area: (NSMutableArray*) pts
{
	float area = 0;
    
    for( long i = 0 ; i < [pts count] ; i++ )
    {
        long j = (i + 1) % [pts count];
        
        area += [[pts objectAtIndex:i] x] * [[pts objectAtIndex:j] y];
        area -= [[pts objectAtIndex:i] y] * [[pts objectAtIndex:j] x];
    }
    
    area *= 0.5f;
    
    return fabs( area );
}

-(float) EllipseArea
{
	return fabs (3.14159265358979 * rect.size.width*2. * rect.size.height*2.) / 4.;
}


@end
