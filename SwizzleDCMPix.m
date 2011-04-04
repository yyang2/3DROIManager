//
//  SwizzleDCMPix.m
//  3DROIManager
//
//  Created by Yang Yang on 1/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SwizzleDCMPix.h"
#import <OsiriX/DCMAbstractSyntaxUID.h>
#import <OsiriX/DCM.h>

#import "math.h"
#import "Papyrus3/Papyrus3.h"

#ifdef STATIC_DICOM_LIB
#define PREVIEWSIZE 512
#else
#define PREVIEWSIZE 70.0
#endif


static NSConditionLock *purgeCacheLock = nil;
BOOL gUseShutter = NO;
BOOL gDisplayDICOMOverlays = YES;
extern NSRecursiveLock *PapyrusLock;
static NSMutableDictionary *cachedPapyGroups = nil;
BOOL gUseJPEGColorSpace = NO;

extern short Altivec;

void PapyrusLockFunction( int lock)
{
	if( lock)
		[PapyrusLock lock];
	else
		[PapyrusLock unlock];
}


@implementation SwizzleDCMPix
- (BOOL) loadDICOMPapyrus
{
	int				elemType;
	PapyShort		imageNb,  err = 0;
	PapyULong		nbVal, i, pos;
	SElement		*theGroupP;
	UValue_T		*val, *tmp;
	BOOL			returnValue = NO;
	
	clutRed = nil;
	clutGreen = nil;
	clutBlue = nil;
	
	fSetClut = NO;
	fSetClut16 = NO;
	
	fPlanarConf = 0;
	pixelRatio = 1.0;
	
	orientation[ 0] = 0;	orientation[ 1] = 0;	orientation[ 2] = 0;
	orientation[ 3] = 0;	orientation[ 4] = 0;	orientation[ 5] = 0;
	
	frameOfReferenceUID = 0;
	sliceThickness = 0;
	spacingBetweenSlices = 0;
	repetitiontime = 0;
	echotime = 0;
	flipAngle = 0;
	viewPosition = 0;
	patientPosition = 0;
	width = height = 0;
    
	originX = 0;
	originY = 0;
	originZ = 0;
	
	if( purgeCacheLock == nil)
		purgeCacheLock = [[NSConditionLock alloc] initWithCondition: 0];

	[purgeCacheLock lock];
	[purgeCacheLock unlockWithCondition: [purgeCacheLock condition]+1];
	
	@try
	{
		if( [self getPapyGroup: 0])	// This group is mandatory...
		{
			UValue_T *val3, *tmpVal3;
			
			modalityString = nil;
			
			imageNb = 1 + frameNo; 
			
			pixelSpacingX = 0;
			pixelSpacingY = 0;
			
			offset = 0.0;
			slope = 1.0;
			
			theGroupP = (SElement*) [self getPapyGroup: 0x0008];
			if( theGroupP)
			{
				val = Papy3GetElement (theGroupP, papRecommendedDisplayFrameRateGr, &nbVal, &elemType);
				if ( val) cineRate = atof( val->a);	//[[NSString stringWithFormat:@"%0.1f", ] floatValue];
				
				acquisitionTime = nil;
				
				
				if( acquisitionTime == nil)
				{
					val = Papy3GetElement (theGroupP, papAcquisitionDateGr, &nbVal, &elemType);	
					if (val != NULL)
					{
						NSString	*studyDate = [NSString stringWithCString:val->a encoding: NSASCIIStringEncoding];
						if( [studyDate length] != 6) studyDate = [studyDate stringByReplacingOccurrencesOfString:@"." withString:@""];
						
						val = Papy3GetElement (theGroupP, papAcquisitionTimeGr, &nbVal, &elemType);
						if (val != NULL)
						{
							NSString*   completeDate;
							NSString*   studyTime = [NSString stringWithCString:val->a encoding: NSASCIIStringEncoding];
							
							completeDate = [studyDate stringByAppendingString:studyTime];
							
							if( [studyTime length] >= 6)
								acquisitionTime = [[NSCalendarDate alloc] initWithString:completeDate calendarFormat:@"%Y%m%d%H%M%S"];
							else
								acquisitionTime = [[NSCalendarDate alloc] initWithString:completeDate calendarFormat:@"%Y%m%d%H%M"];
							
							if( acquisitionTime)
								acquisitionDate = [studyDate copy];
						}
					}
				}
				if( acquisitionTime == nil)
				{
					val = Papy3GetElement (theGroupP, papSeriesDateGr, &nbVal, &elemType);
					if (val != NULL)
					{
						NSString	*studyDate = [NSString stringWithCString:val->a encoding: NSASCIIStringEncoding];
						if( [studyDate length] != 6) studyDate = [studyDate stringByReplacingOccurrencesOfString:@"." withString:@""];
						
						val = Papy3GetElement (theGroupP, papSeriesTimeGr, &nbVal, &elemType);
						if (val != NULL)
						{
							NSString*   completeDate;
							NSString*   studyTime = [NSString stringWithCString:val->a encoding: NSASCIIStringEncoding];
							
							completeDate = [studyDate stringByAppendingString:studyTime];
							
							if( [studyTime length] >= 6)
								acquisitionTime = [[NSCalendarDate alloc] initWithString:completeDate calendarFormat:@"%Y%m%d%H%M%S"];
							else
								acquisitionTime = [[NSCalendarDate alloc] initWithString:completeDate calendarFormat:@"%Y%m%d%H%M"];
							
							if( acquisitionTime)
								acquisitionDate = [studyDate copy];
						}
					}
				}
				
				val = Papy3GetElement (theGroupP, papModalityGr, &nbVal, &elemType);
				if (val != NULL) modalityString = [NSString stringWithCString:val->a encoding: NSASCIIStringEncoding];
				
				val = Papy3GetElement (theGroupP, papSOPClassUIDGr, &nbVal, &elemType);
				if (val != NULL) self.SOPClassUID = [NSString stringWithCString:val->a encoding: NSASCIIStringEncoding];
			}
			
			theGroupP = (SElement*) [self getPapyGroup: 0x0010];
			if( theGroupP)
			{
				val = Papy3GetElement (theGroupP, papPatientsWeightGr, &nbVal, &elemType);
				if ( val) patientsWeight = atof( val->a);
				else patientsWeight = 0;
			}
			
			theGroupP = (SElement*) [self getPapyGroup: 0x0018];
			if( theGroupP)
				[self papyLoadGroup0x0018: theGroupP];
            
			theGroupP = (SElement*) [self getPapyGroup: 0x0020];
			if( theGroupP)
				[self papyLoadGroup0x0020: theGroupP];
			
			theGroupP = (SElement*) [self getPapyGroup: 0x0028];
			if( theGroupP || [SOPClassUID hasPrefix: @"1.2.840.10008.5.1.4.1.1.104.1"] || [SOPClassUID hasPrefix: @"1.2.840.10008.5.1.4.1.1.88"]) // This group is MANDATORY... or DICOM SR / PDF / Spectro
			{
				if( theGroupP)
                    [self papyLoadGroup0x0028: theGroupP];
				
#pragma mark SUV
				
				// Get values needed for SUV calcs:
				theGroupP = (SElement*) [self getPapyGroup: 0x0054];
				if( theGroupP)
				{
					val = Papy3GetElement (theGroupP, papUnitsGr, &pos, &elemType);
					if( val) units = [[NSString stringWithCString:val->a encoding: NSISOLatin1StringEncoding] retain];
					else units = nil;
					
					val = Papy3GetElement (theGroupP, papDecayCorrectionGr, &pos, &elemType);
					if( val) decayCorrection = [[NSString stringWithCString:val->a encoding: NSISOLatin1StringEncoding] retain];
					else decayCorrection = nil;
					
                    //				val = Papy3GetElement (theGroupP, papDecayFactorGr, &pos, &elemType);
                    //				if( val) decayFactor = atof( val->a);
                    //				else decayFactor = 1.0;
					decayFactor = 1.0;
					
					val = Papy3GetElement (theGroupP, papFrameReferenceTimeGr, &pos, &elemType);
					if( val) frameReferenceTime = atof( val->a);
					else frameReferenceTime = 0.0;
					
					val = Papy3GetElement (theGroupP, papRadiopharmaceuticalInformationSequenceGr, &pos, &elemType);
					
					// Loop over sequence to find injected dose
					
					if ( val)
					{
						if( val->sq)
						{
							Papy_List	*dcmList = val->sq;
							while (dcmList != NULL)
							{
								if( dcmList->object->item)
								{
									SElement *gr = (SElement *)dcmList->object->item->object->group;
									if ( gr->group == 0x0018)
									{
										val = Papy3GetElement (gr, papRadionuclideTotalDoseGr, &pos, &elemType);
										radionuclideTotalDose = val? atof( val->a) : 0.0;
										
										val = Papy3GetElement (gr, papRadiopharmaceuticalStartTimeGr, &pos, &elemType);
										if( val && acquisitionDate)
										{
											NSString *pharmaTime = [NSString stringWithCString:val->a encoding: NSASCIIStringEncoding];
											NSString *completeDate = [acquisitionDate stringByAppendingString: pharmaTime];
											
											if( [pharmaTime length] >= 6)
												radiopharmaceuticalStartTime = [[NSCalendarDate alloc] initWithString: completeDate calendarFormat:@"%Y%m%d%H%M%S"];
											else
												radiopharmaceuticalStartTime = [[NSCalendarDate alloc] initWithString: completeDate calendarFormat:@"%Y%m%d%H%M"];
										}
										
										val = Papy3GetElement (gr, papRadionuclideHalfLifeGr, &pos, &elemType);
										halflife = val? atof( val->a) : 0.0;
										
										break;
									}
								}
								dcmList = dcmList->next;
							}
						}
						
						[self computeTotalDoseCorrected];
						
						// End of SUV required values
					}
					
					val = Papy3GetElement (theGroupP, papDetectorInformationSequenceGr, &pos, &elemType);
					if( val)
					{
						if( val->sq)
						{
							Papy_List *dcmList = val->sq->object->item;
							while (dcmList != NULL)
							{
								SElement * gr = (SElement *) dcmList->object->group;
                                
								if( gr)
								{
									if( gr->group == 0x0020)
									{
										val = Papy3GetElement (gr, papImagePositionPatientGr, &nbVal, &elemType);
										if ( val)
										{
											tmp = val;
											
											originX = atof( tmp->a);
											
											if( nbVal > 1)
											{
												tmp++;
												originY = atof( tmp->a);
											}
											
											if( nbVal > 2)
											{
												tmp++;
												originZ = atof( tmp->a);
											}
											
											isOriginDefined = YES;
										}
										
										if( spacingBetweenSlices)
											originZ += frameNo * spacingBetweenSlices;
										else
											originZ += frameNo * sliceThickness;
										
										val = Papy3GetElement (gr, papImageOrientationPatientGr, &nbVal, &elemType);
										if ( val)
										{
											if( nbVal != 6)
											{
												NSLog(@"Orientation is NOT 6 !!!");
												if( nbVal > 6) nbVal = 6;
											}
											
											BOOL equalZero = YES;
											
											tmpVal3 = val;
											for ( int j = 0; j < nbVal; j++)
											{
												if( atof( tmpVal3->a) != 0) equalZero = NO;
												tmpVal3++;
											}
											
											if( equalZero == NO)
											{
												orientation[ 0] = 0;	orientation[ 1] = 0;	orientation[ 2] = 0;
												orientation[ 3] = 0;	orientation[ 4] = 0;	orientation[ 5] = 0;
												
												tmpVal3 = val;
												for ( int j = 0; j < nbVal; j++)
												{
													orientation[ j]  = atof( tmpVal3->a);
													tmpVal3++;
												}
												
												for (int j = nbVal; j < 6; j++)
													orientation[ j] = 0;
                                                
                                                //												orientation[ 0] = 1;	orientation[ 1] = 0;	orientation[ 2] = 0; tests, force axial matrix
                                                //												orientation[ 3] = 0;	orientation[ 4] = 1;	orientation[ 5] = 0;
											}
											else // doesnt the root Image Orientation contains valid data? if not use the normal vector
											{
												equalZero = YES;
												for ( int j = 0; j < 6; j++)
												{
													if( orientation[ j] != 0) equalZero = NO;
												}
												
												if( equalZero)
												{
													orientation[ 0] = 1;	orientation[ 1] = 0;	orientation[ 2] = 0;
													orientation[ 3] = 0;	orientation[ 4] = 1;	orientation[ 5] = 0;
												}
											}
										}
										break;
									}
								}
								dcmList = dcmList->next;
							}
						}
						
						[self computeTotalDoseCorrected];
						
						// End of SUV required values
					}
				}
				
				// End SUV			
				
#pragma mark MR/CT multiframe		
				// Is it a new MR/CT multi-frame exam?
				
				SElement *groupOverlay = (SElement*) [self getPapyGroup: 0x5200];
				if( groupOverlay)
				{
					// ****** ****** ****** ************************************************************************
					// SHARED FRAME
					// ****** ****** ****** ************************************************************************
					
					val = Papy3GetElement (groupOverlay, papSharedFunctionalGroupsSequence, &nbVal, &elemType);
					
					// there is an element
					if ( val)
					{
						// there is a sequence
						if (val->sq)
						{
							// get a pointer to the first element of the list
							Papy_List *dcmList = val->sq->object->item;
							
							// loop through the elements of the sequence
							while (dcmList != NULL)
							{
								SElement * gr = (SElement *) dcmList->object->group;
								
								switch( gr->group)
								{
									case 0x0018:
										val3 = Papy3GetElement (gr, papMRTimingAndRelatedParametersSequence, &nbVal, &elemType);
										if (val3 != NULL && nbVal >= 1)
										{
											if (val3->sq)
											{
												Papy_List *PixelMatrixSeq = val3->sq->object->item;
												
												while (PixelMatrixSeq)
												{
													SElement * gr = (SElement *) PixelMatrixSeq->object->group;
													
													switch( gr->group)
													{
														case 0x0018: [self papyLoadGroup0x0018: gr]; break;
													}
													PixelMatrixSeq = PixelMatrixSeq->next;
												}
											}
										}
                                        break;
                                        
									case 0x0020:
										val3 = Papy3GetElement (gr, papPlaneOrientationSequence, &nbVal, &elemType);
										if (val3 != NULL && nbVal >= 1)
										{
											// there is a sequence
											if (val3->sq)
											{
												Papy_List *PixelMatrixSeq = val3->sq->object->item;
												
												// loop through the elements of the sequence
												while (PixelMatrixSeq)
												{
													SElement * gr = (SElement *) PixelMatrixSeq->object->group;
													
													switch( gr->group)
													{
														case 0x0020: [self papyLoadGroup0x0020: gr]; break;
													}
													
													// get the next element of the list
													PixelMatrixSeq = PixelMatrixSeq->next;
												}
											}
										}
                                        break;
										
									case 0x0028:
										val3 = Papy3GetElement (gr, papPixelMatrixSequence, &nbVal, &elemType);
										if (val3 != NULL && nbVal >= 1)
										{
											// there is a sequence
											if (val3->sq != NULL)
											{
												Papy_List	  *PixelMatrixSeq = val3->sq->object->item;
												
												// loop through the elements of the sequence
												while (PixelMatrixSeq != NULL)
												{
													SElement * gr = (SElement *) PixelMatrixSeq->object->group;
													
													switch( gr->group)
													{
														case 0x0018: [self papyLoadGroup0x0018: gr]; break;
														case 0x0028: [self papyLoadGroup0x0028: gr]; break;
													}
													
													// get the next element of the list
													PixelMatrixSeq = PixelMatrixSeq->next;
												}
											}
										}
										
										val3 = Papy3GetElement (gr, papPixelValueTransformationSequence, &nbVal, &elemType);
										if (val3 != NULL && nbVal >= 1)
										{
											// there is a sequence
											if (val3->sq)
											{
												// get a pointer to the first element of the list
												Papy_List *PixelMatrixSeq = val3->sq->object->item;
												
												// loop through the elements of the sequence
												while (PixelMatrixSeq)
												{
													SElement * gr = (SElement *) PixelMatrixSeq->object->group;
													
													switch( gr->group)
													{
														case 0x0028: [self papyLoadGroup0x0028: gr]; break;
													}
													
													// get the next element of the list
													PixelMatrixSeq = PixelMatrixSeq->next;
												}
											}
										}
										
                                        break;
								}
								
								// get the next element of the list
								dcmList = dcmList->next;
							} // while ...loop through the sequence
						} // if ...there is a sequence of groups
					} // if ...val is not NULL
					
#pragma mark code for each frame				
					// ****** ****** ****** ************************************************************************
					// PER FRAME
					// ****** ****** ****** ************************************************************************
					
					long frameCount = 0;
					
					val = Papy3GetElement (groupOverlay, papPerFrameFunctionalGroupsSequence, &nbVal, &elemType);
					
					// there is an element
					if ( val)
					{
						// there is a sequence
						if (val->sq)
						{
							// get a pointer to the first element of the list
							Papy_List *dcmList = val->sq;
							
							// loop through the elements of the sequence
							while (dcmList)
							{
								if( dcmList->object->item)
								{
									if( frameCount == imageNb-1)
									{
										Papy_List *groupsForFrame = dcmList->object->item;
										
										while( groupsForFrame)
										{
											if( groupsForFrame->object->group)
											{
												SElement * gr = (SElement *) groupsForFrame->object->group;
												
												switch( gr->group)
												{
													case 0x0018:
														val = Papy3GetElement (gr, papMREchoSequence, &nbVal, &elemType);
														if (val != NULL && nbVal >= 1)
														{
															// there is a sequence
															if (val->sq)
															{
																// get a pointer to the first element of the list
																Papy_List *seq = val->sq->object->item;
																
																// loop through the elements of the sequence
																while (seq)
																{
																	SElement * gr20 = (SElement *) seq->object->group;
																	
																	switch( gr20->group)
																	{
																		case 0x0018: [self papyLoadGroup0x0018: gr20]; break;
																	}
																	
																	// get the next element of the list
																	seq = seq->next;
																}
															}
														}
                                                        break;
                                                        
													case 0x0028:
														val = Papy3GetElement (gr, papPixelMatrixSequence, &nbVal, &elemType);
														if (val != NULL && nbVal >= 1)
														{
															// there is a sequence
															if (val->sq)
															{
																// get a pointer to the first element of the list
																Papy_List *seq = val->sq->object->item;
																
																// loop through the elements of the sequence
																while (seq)
																{
																	SElement * gr20 = (SElement *) seq->object->group;
																	
																	switch( gr20->group)
																	{
																		case 0x0018: [self papyLoadGroup0x0018: gr20]; break;
																		case 0x0028: [self papyLoadGroup0x0028: gr20]; break;
																	}
																	
																	// get the next element of the list
																	seq = seq->next;
																}
															}
														}
                                                        break;
                                                        
													case 0x0020:
														val = Papy3GetElement (gr, papPlanePositionSequence, &nbVal, &elemType);
														if (val != NULL && nbVal >= 1)
														{
															// there is a sequence
															if (val->sq)
															{
																// get a pointer to the first element of the list
																Papy_List *seq = val->sq->object->item;
																
																// loop through the elements of the sequence
																while (seq)
																{
																	SElement * gr = (SElement *) seq->object->group;
																	
																	switch( gr->group)
																	{
																		case 0x0020: [self papyLoadGroup0x0020: gr]; break;
																		case 0x0028: [self papyLoadGroup0x0028: gr]; break;
																	}
																	
																	// get the next element of the list
																	seq = seq->next;
																}
															}
														}
														
														val = Papy3GetElement (gr, papPlaneOrientationSequence, &nbVal, &elemType);
														if (val != NULL && nbVal >= 1)
														{
															// there is a sequence
															if (val->sq)
															{
																// get a pointer to the first element of the list
																Papy_List *seq = val->sq->object->item;
																
																// loop through the elements of the sequence
																while (seq)
																{
																	SElement * gr = (SElement *) seq->object->group;
																	
																	switch( gr->group)
																	{
																		case 0x0020: [self papyLoadGroup0x0020: gr]; break;
																	}
																	
																	// get the next element of the list
																	seq = seq->next;
																}
															}
														}
                                                        break;
												} // switch( gr->group)
											} // if( groupsForFrame->object->item)
											
											if( groupsForFrame)
											{
												// get the next element of the list
												groupsForFrame = groupsForFrame->next;
											}
										} // while groupsForFrame
										
										// STOP the loop
										dcmList = nil;
									} // right frame?
								}
								
								if( dcmList)
								{
									// get the next element of the list
									dcmList = dcmList->next;
									
									frameCount++;
								}
							} // while ...loop through the sequence
						} // if ...there is a sequence of groups
					} // if ...val is not NULL
				}
				
#pragma mark tag group 6000		
				
				theGroupP = (SElement*) [self getPapyGroup: 0x6000];
				if( theGroupP)
				{
					val = Papy3GetElement (theGroupP, papOverlayRows6000Gr, &nbVal, &elemType);
					if ( val) oRows	= val->us;
					
					val = Papy3GetElement (theGroupP, papOverlayColumns6000Gr, &nbVal, &elemType);
					if ( val) oColumns	= val->us;
					
					//			val = Papy3GetElement (theGroupP, papNumberofFramesinOverlayGr, &nbVal, &elemType);
					//			if ( val) oRows	= val->us;
					
					val = Papy3GetElement (theGroupP, papOverlayTypeGr, &nbVal, &elemType);
					if ( val) oType	= val->a[ 0];
					
					val = Papy3GetElement (theGroupP, papOriginGr, &nbVal, &elemType);
					if ( val)
					{
						oOrigin[ 0]	= val->us;
						val++;
						oOrigin[ 1]	= val->us;
					}
					
					val = Papy3GetElement (theGroupP, papOverlayBitsAllocatedGr, &nbVal, &elemType);
					if ( val) oBits	= val->us;
					
					val = Papy3GetElement (theGroupP, papBitPositionGr, &nbVal, &elemType);
					if ( val) oBitPosition	= val->us;
					
					val = Papy3GetElement (theGroupP, papOverlayDataGr, &nbVal, &elemType);
					if (val != NULL && oBits == 1 && oRows == height && oColumns == width && oType == 'G' && oBitPosition == 0 && oOrigin[ 0] == 1 && oOrigin[ 1] == 1)
					{
						if( oData) free( oData);
						oData = calloc( oRows*oColumns, 1);
						if( oData)
						{
							register unsigned short *pixels = val->ow;
							register unsigned char *oD = oData;
							register char mask = 1;
							register long t = oColumns*oRows/16;
							
							while( t-->0)
							{
								register unsigned short	octet = *pixels++;
								register int x = 16;
								while( x-->0)
								{
									char v = octet & mask ? 1 : 0;
									octet = octet >> 1;
									
									if( v)
										*oD = 0xFF;
									
									oD++;
								}
							}
						}
					}
				}
				
#pragma mark PhilipsFactor		
				theGroupP = (SElement*) [self getPapyGroup: 0x7053];
				if( theGroupP)
				{
					val = Papy3GetElement (theGroupP, papSUVFactor7053Gr, &nbVal, &elemType);
					
					if( nbVal > 0)
					{
						if( val->a)
							philipsFactor = atof( val->a);
					}
				}
				
#pragma mark compute normal vector
				
				orientation[6] = orientation[1]*orientation[5] - orientation[2]*orientation[4];
				orientation[7] = orientation[2]*orientation[3] - orientation[0]*orientation[5];
				orientation[8] = orientation[0]*orientation[4] - orientation[1]*orientation[3];
				
				if( fabs( orientation[6]) > fabs(orientation[7]) && fabs( orientation[6]) > fabs(orientation[8]))
					sliceLocation = originX;
				
				if( fabs( orientation[7]) > fabs(orientation[6]) && fabs( orientation[7]) > fabs(orientation[8]))
					sliceLocation = originY;
				
				if( fabs( orientation[8]) > fabs(orientation[6]) && fabs( orientation[8]) > fabs(orientation[7]))
					sliceLocation = originZ;
				
#pragma mark read pixel data
				
				BOOL toBeUnlocked = YES;
				[PapyrusLock lock];
				
				int fileNb = -1;
				NSDictionary *dict = [cachedPapyGroups valueForKey: srcFile];
				
				if( [dict valueForKey: @"fileNb"] == nil)
					[self getPapyGroup: 0];
				
				if( dict != nil && [dict valueForKey: @"fileNb"] == nil)
					NSLog( @"******** dict != nil && [dict valueForKey: @fileNb] == nil");
				
				fileNb = [[dict valueForKey: @"fileNb"] intValue];
				
				if( fileNb >= 0)
				{
					short *oImage = nil;
					
					if( SOPClassUID != nil && [SOPClassUID hasPrefix: @"1.2.840.10008.5.1.4.1.1.104.1"]) // EncapsulatedPDFStorage
					{
						if (gIsPapyFile[ fileNb] == DICOM10)
							err = Papy3FSeek (gPapyFile [fileNb], SEEK_SET, 132L);
						
						if ((err = Papy3GotoGroupNb (fileNb, 0x0042)) == 0)
						{
							if ((err = Papy3GroupRead (fileNb, &theGroupP)) > 0) 
							{
								SElement *element = theGroupP + papEncapsulatedDocumentGr;
								
								if( element->nb_val > 0)
								{
									NSPDFImageRep *rep = [NSPDFImageRep imageRepWithData: [NSData dataWithBytes: element->value->a length: element->length]];
									
									[rep setCurrentPage: frameNo];	
									
									NSImage *pdfImage = [[[NSImage alloc] init] autorelease];
									[pdfImage addRepresentation: rep];
									
									NSSize newSize;
									
									newSize.width = ceil( [rep bounds].size.width * 1.5);		// Increase PDF resolution to 72 * X DPI !
									newSize.height = ceil( [rep bounds].size.height * 1.5);		// KEEP THIS VALUE IN SYNC WITH DICOMFILE.M
                                    
									[pdfImage setScalesWhenResized:YES];
									[pdfImage setSize: newSize];
									
									[self getDataFromNSImage: pdfImage];
								}
								
								err = Papy3GroupFree (&theGroupP, TRUE);
							}
						}
					}
					else if( SOPClassUID != nil && [SOPClassUID hasPrefix: @"1.2.840.10008.5.1.4.1.1.4.2"]) // Spectroscopy
					{
						if( fExternalOwnedImage)
							fImage = fExternalOwnedImage;
						else
							fImage = malloc( 128 * 128 * 4);
						
						height = 128;
						width = 128;
						oImage = nil;
						isRGB = NO;
						
						for( int i = 0; i < 128*128; i++)
							fImage[ i ] = i%2;
					} 
					else if( SOPClassUID != nil && [SOPClassUID hasPrefix: @"1.2.840.10008.5.1.4.1.1.88"]) // DICOM SR
					{
#ifdef OSIRIX_VIEWER
#ifndef OSIRIX_LIGHT
                        
						@try
						{
							if( [[NSFileManager defaultManager] fileExistsAtPath: @"/tmp/dicomsr_osirix/"] == NO)
								[[NSFileManager defaultManager] createDirectoryAtPath: @"/tmp/dicomsr_osirix/" attributes: nil];
							
							NSString *htmlpath = [[@"/tmp/dicomsr_osirix/" stringByAppendingPathComponent: [srcFile lastPathComponent]] stringByAppendingPathExtension: @"html"];
							
							if( [[NSFileManager defaultManager] fileExistsAtPath: htmlpath] == NO)
							{
								NSTask *aTask = [[[NSTask alloc] init] autorelease];		
								[aTask setEnvironment:[NSDictionary dictionaryWithObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/dicom.dic"] forKey:@"DCMDICTPATH"]];
								[aTask setLaunchPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: @"/dsr2html"]];
								[aTask setArguments: [NSArray arrayWithObjects: srcFile, htmlpath, nil]];		
								[aTask launch];
								[aTask waitUntilExit];		
								[aTask interrupt];
							}
							
							if( [[NSFileManager defaultManager] fileExistsAtPath: [htmlpath stringByAppendingPathExtension: @"pdf"]] == NO)
							{
								NSTask *aTask = [[[NSTask alloc] init] autorelease];
								[aTask setLaunchPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/Decompress"]];
								[aTask setArguments: [NSArray arrayWithObjects: htmlpath, @"pdfFromURL", nil]];		
								[aTask launch];
								[aTask waitUntilExit];		
								[aTask interrupt];
							}
							
							NSPDFImageRep *rep = [NSPDFImageRep imageRepWithData: [NSData dataWithContentsOfFile: [htmlpath stringByAppendingPathExtension: @"pdf"]]];
                            
							[rep setCurrentPage: frameNo];	
							
							NSImage *pdfImage = [[[NSImage alloc] init] autorelease];
							[pdfImage addRepresentation: rep];
							
							NSSize newSize;
							
							newSize.width = ceil( [rep bounds].size.width * 1.5);		// Increase PDF resolution to 72 * X DPI !
							newSize.height = ceil( [rep bounds].size.height * 1.5);		// KEEP THIS VALUE IN SYNC WITH DICOMFILE.M
							
							[pdfImage setScalesWhenResized:YES];
							[pdfImage setSize: newSize];
							
							[self getDataFromNSImage: pdfImage];
							
							returnValue = YES;
						}
						@catch (NSException * e)
						{
							NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
						}
#else
                        [self getDataFromNSImage: [NSImage imageNamed: @"NSIconViewTemplate"]];
                        returnValue = YES;
#endif
#else
                        [self getDataFromNSImage: [NSImage imageNamed: @"NSIconViewTemplate"]];
                        returnValue = YES;
#endif
                        
					}
					else
					{
						// position the file pointer to the begining of the data set 
						err = Papy3GotoNumber (fileNb, (PapyShort) imageNb, DataSetID);
						
						// then goto group 0x7FE0 
						if ((err = Papy3GotoGroupNb0x7FE0 (fileNb, &theGroupP)) > 0) 
						{
                            if( bitsStored == 8 && bitsAllocated == 16 && gArrPhotoInterpret[ fileNb] == RGB)
                                bitsAllocated = 8;
                            
                            oImage = (short*) Papy3GetPixelData (fileNb, imageNb, theGroupP, gUseJPEGColorSpace, &fPlanarConf);
                            
                            [PapyrusLock unlock];
                            toBeUnlocked = NO;
                            
                            if( oImage == nil)
                            {
                                NSLog(@"This is really bad..... Please send this file to rossetantoine@bluewin.ch");
                                goImageSize[ fileNb] = height * width * 8; // *8 in case of a 16-bit RGB encoding....
                                oImage = malloc( goImageSize[ fileNb]);
                                
                                long yo = 0;
                                for( i = 0 ; i < height * width * 4; i++)
                                {
                                    oImage[ i] = yo++;
                                    if( yo>= width) yo = 0;
                                }
                            }
                            
                            if( gArrPhotoInterpret [fileNb] == MONOCHROME1) // INVERSE IMAGE!
                            {
                                if( [modalityString isEqualToString:@"PT"] == YES || ([[NSUserDefaults standardUserDefaults] boolForKey:@"OpacityTableNM"] == YES && [modalityString isEqualToString:@"NM"] == YES))
                                {
                                    inverseVal = NO;
                                }
                                else
                                {
                                    inverseVal = YES;
                                    savedWL = -savedWL;
                                }
                            }
                            else inverseVal = NO;
                            
                            isRGB = NO;
                            
                            if (gArrPhotoInterpret [fileNb] == YBR_FULL ||
                                gArrPhotoInterpret [fileNb] == YBR_FULL_422 ||
                                gArrPhotoInterpret [fileNb] == YBR_PARTIAL_422)
                            {
                                //							NSLog(@"YBR WORLD");
                                
                                char *rgbPixel = (char*) [self ConvertYbrToRgb:(unsigned char *) oImage :width :height :gArrPhotoInterpret [fileNb] :(char) fPlanarConf];
                                fPlanarConf = 0;	//ConvertYbrToRgb -> planar is converted
                                
                                efree3 ((void **) &oImage);
                                oImage = (short*) rgbPixel;
                                goImageSize[ fileNb] = width * height * 3;
                            }
                            
                            // This image has a palette -> Convert it to a RGB image !
                            if( fSetClut)
                            {
                                if( clutRed != nil && clutGreen != nil && clutBlue != nil)
                                {
                                    unsigned char   *bufPtr = (unsigned char*) oImage;
                                    unsigned short	*bufPtr16 = (unsigned short*) oImage;
                                    unsigned char   *tmpImage;
                                    int				totSize, pixelR, pixelG, pixelB, x, y;
                                    
                                    totSize = (int) ((int) height * (int) width * 3L);
                                    tmpImage = malloc( totSize);
                                    
                                    fPlanarConf = NO;
                                    
                                    //	if( bitsAllocated != 8) NSLog(@"Palette with a non-8 bit image???");
                                    
                                    switch( bitsAllocated)
                                    {
                                        case 8:
                                            for( y = 0; y < height; y++)
                                            {
                                                for( x = 0; x < width; x++)
                                                {
                                                    pixelR = pixelG = pixelB = bufPtr[y*width + x];
                                                    
                                                    if( pixelR > clutEntryR) {	pixelR = clutEntryR-1;}
                                                    if( pixelG > clutEntryG) {	pixelG = clutEntryG-1;}
                                                    if( pixelB > clutEntryB) {	pixelB = clutEntryB-1;}
                                                    
                                                    tmpImage[y*width*3 + x*3 + 0] = clutRed[ pixelR];
                                                    tmpImage[y*width*3 + x*3 + 1] = clutGreen[ pixelG];
                                                    tmpImage[y*width*3 + x*3 + 2] = clutBlue[ pixelB];
                                                }
                                            }
                                            break;
                                            
                                        case 16:
#if __BIG_ENDIAN__
                                            InverseShorts( (vector unsigned short*) oImage, height * width);
#endif
                                            
                                            for( y = 0; y < height; y++)
                                            {
                                                for( x = 0; x < width; x++)
                                                {
                                                    pixelR = pixelG = pixelB = bufPtr16[y*width + x];
                                                    
                                                    //	if( pixelR > clutEntryR) {	pixelR = clutEntryR-1;}
                                                    //	if( pixelG > clutEntryG) {	pixelG = clutEntryG-1;}
                                                    //	if( pixelB > clutEntryB) {	pixelB = clutEntryB-1;}
                                                    
                                                    tmpImage[y*width*3 + x*3 + 0] = clutRed[ pixelR];
                                                    tmpImage[y*width*3 + x*3 + 1] = clutGreen[ pixelG];
                                                    tmpImage[y*width*3 + x*3 + 2] = clutBlue[ pixelB];
                                                }
                                            }
                                            bitsAllocated = 8;
                                            break;
                                    }
                                    
                                    isRGB = YES;
                                    
                                    efree3 ((void **) &oImage);
                                    oImage = (short*) tmpImage;
                                    goImageSize[ fileNb] = width * height * 3;
                                }
                            }
                            
                            if( fSetClut16)
                            {
                                unsigned short	*bufPtr = (unsigned short*) oImage;
                                unsigned char   *tmpImage;
                                int				totSize, x, y, ii;
                                unsigned short pixel;
                                
                                fPlanarConf = NO;
                                
                                totSize = (int) ((int) height * (int) width * 3L);
                                tmpImage = malloc( totSize);
                                
                                if( bitsAllocated != 16) NSLog(@"Segmented Palette with a non-16 bit image???");
                                
                                ii = height * width;
                                
#if __ppc__ || __ppc64__
                                if( Altivec)
                                {
                                    InverseShorts( (vector unsigned short*) oImage, ii);
                                }
                                else
#endif
                                    
#if __BIG_ENDIAN__
                                {
                                    PapyUShort	 *theUShortP = (PapyUShort *) oImage;
                                    PapyUShort val;
                                    
                                    while( ii-- > 0)
                                    {
                                        val = *theUShortP;
                                        *theUShortP++ = (val >> 8) | (val << 8);   // & 0x00FF  --  & 0xFF00
                                    }
                                }
#endif
                                
                                for( y = 0; y < height; y++)
                                {
                                    for( x = 0; x < width; x++)
                                    {
                                        pixel = bufPtr[y*width + x];
                                        tmpImage[y*width*3 + x*3 + 0] = shortRed[ pixel];
                                        tmpImage[y*width*3 + x*3 + 1] = shortGreen[ pixel];
                                        tmpImage[y*width*3 + x*3 + 2] = shortBlue[ pixel];
                                    }
                                }
                                
                                isRGB = YES;
                                bitsAllocated = 8;
                                
                                efree3 ((void **) &oImage);
                                oImage = (short*) tmpImage;
                                goImageSize[ fileNb] = width * height * 3;
                                
                                free( shortRed);
                                free( shortGreen);
                                free( shortBlue);
                            }
                            
                            // we need to know how the pixels are stored
                            if (isRGB == YES ||
                                gArrPhotoInterpret [fileNb] == RGB ||
                                gArrPhotoInterpret [fileNb] == YBR_FULL ||
                                gArrPhotoInterpret [fileNb] == YBR_FULL_422 ||
                                gArrPhotoInterpret [fileNb] == YBR_PARTIAL_422 ||
                                gArrPhotoInterpret [fileNb] == YBR_ICT ||
                                gArrPhotoInterpret [fileNb] == YBR_RCT)
                            {
                                unsigned char   *ptr, *tmpImage;
                                int				loop, totSize;
                                
                                isRGB = YES;
                                
                                // CONVERT RGB TO ARGB FOR BETTER PERFORMANCE THRU VIMAGE
                                {
                                    totSize = (int) ((int) height * (int) width * 4L);
                                    tmpImage = malloc( totSize);
                                    if( tmpImage)
                                    {
                                        ptr    = tmpImage;
                                        
                                        if( bitsAllocated > 8) // RGB - 16 bits
                                        {
                                            unsigned short   *bufPtr;
                                            bufPtr = (unsigned short*) oImage;
                                            
#if __BIG_ENDIAN__
                                            InverseShorts( (vector unsigned short*) oImage, height * width * 3);
#endif
                                            
                                            if( fPlanarConf > 0)	// PLANAR MODE
                                            {
                                                int imsize = (int) height * (int) width;
                                                int x = 0;
                                                
                                                loop = totSize/4;
                                                while( loop-- > 0)
                                                {
                                                    *ptr++	= 255;			//ptr++;
                                                    *ptr++	= bufPtr[ 0 * imsize + x];		//ptr++;  bufPtr++;
                                                    *ptr++	= bufPtr[ 1 * imsize + x];		//ptr++;  bufPtr++;
                                                    *ptr++	= bufPtr[ 2 * imsize + x];		//ptr++;  bufPtr++;
                                                    
                                                    x++;
                                                }
                                            }
                                            else
                                            {
                                                loop = totSize/4;
                                                while( loop-- > 0)
                                                {
                                                    *ptr++	= 255;			//ptr++;
                                                    *ptr++	= *bufPtr++;		//ptr++;  bufPtr++;
                                                    *ptr++	= *bufPtr++;		//ptr++;  bufPtr++;
                                                    *ptr++	= *bufPtr++;		//ptr++;  bufPtr++;
                                                }
                                            }
                                        }
                                        else
                                        {
                                            unsigned char   *bufPtr;
                                            bufPtr = (unsigned char*) oImage;
                                            
                                            if( fPlanarConf > 0)	// PLANAR MODE
                                            {
                                                int imsize = (int) height * (int) width;
                                                int x = 0;
                                                
                                                loop = totSize/4;
                                                while( loop-- > 0)
                                                {
                                                    *ptr++	= 255;			//ptr++;
                                                    *ptr++	= bufPtr[ 0 * imsize + x];		//ptr++;  bufPtr++;
                                                    *ptr++	= bufPtr[ 1 * imsize + x];		//ptr++;  bufPtr++;
                                                    *ptr++	= bufPtr[ 2 * imsize + x];		//ptr++;  bufPtr++;
                                                    
                                                    x++;
                                                }
                                            }
                                            else
                                            {
                                                loop = totSize/4;
                                                while( loop-- > 0)
                                                {
                                                    *ptr++	= 255;
                                                    *ptr++	= *bufPtr++;
                                                    *ptr++	= *bufPtr++;
                                                    *ptr++	= *bufPtr++;
                                                }
                                            }
                                        }
                                        efree3 ((void **) &oImage);
                                        oImage = (short*) tmpImage;
                                        goImageSize[ fileNb] = width * height * 4;
                                    }
                                }
                            }
                            else if( bitsAllocated == 8)	// Black & White 8 bit image -> 16 bits image
                            {
                                unsigned char   *bufPtr;
                                short			*ptr, *tmpImage;
                                int				loop, totSize;
                                
                                totSize = (int) ((int) height * (int) width * 2L);
                                tmpImage = malloc( totSize);
                                
                                bufPtr = (unsigned char*) oImage;
                                ptr    = tmpImage;
                                
                                loop = totSize/2;
                                while( loop-- > 0)
                                {
                                    *ptr++ = *bufPtr++;
                                }
                                
                                efree3 ((void **) &oImage);
                                oImage =  (short*) tmpImage;
                                goImageSize[ fileNb] = height * (int) width * 2L;
                            }
                            
                            //if( fIsSigned == YES && 
                            
                            [PapyrusLock lock];
                            // free group 7FE0 
                            err = Papy3GroupFree (&theGroupP, TRUE);
                            [PapyrusLock unlock];
						}
                        
#pragma mark RGB or fPlanar
                        
						//***********
						if( isRGB)
						{
							if( fExternalOwnedImage)
							{
								fImage = fExternalOwnedImage;
								memcpy( fImage, oImage, width*height*sizeof(float));
								free(oImage);
							}
							else fImage = (float*) oImage;
							oImage = nil;
							
							if( oData && gDisplayDICOMOverlays)
							{
								unsigned char	*rgbData = (unsigned char*) fImage;
								int				y, x;
								
								for( y = 0; y < oRows; y++)
								{
									for( x = 0; x < oColumns; x++)
									{
										if( oData[ y * oColumns + x])
										{
											rgbData[ y * width*4 + x*4 + 1] = 0xFF;
											rgbData[ y * width*4 + x*4 + 2] = 0xFF;
											rgbData[ y * width*4 + x*4 + 3] = 0xFF;
										}
									}
								}
							}
						}
						else
						{
							if( bitsAllocated == 32)  // 32-bit float or 32-bit integers
							{
                                NSLog(@"Swizzle loadDICOMPapyrus self:%@", self);
								if( fExternalOwnedImage)
									fImage = fExternalOwnedImage;
								else
									fImage = malloc(width*height*sizeof(float) + 100);
								
								if( fImage)
								{
									memcpy( fImage, oImage, height * width * sizeof( float));
									
									if( slope != 1.0 || offset != 0 || [[NSUserDefaults standardUserDefaults] boolForKey: @"32bitDICOMAreAlwaysIntegers"])
									{
										unsigned int *usint = (unsigned int*) oImage;
										int *sint = (int*) oImage;
										float *tDestF = fImage;
										double dOffset = offset, dSlope = slope;
                                        
                                        
										if([[NSUserDefaults standardUserDefaults] integerForKey:@"PreclinicalAnalysis"]){
											float *sfloat = (float *)oImage;
											unsigned long x = height * width;
											while(x-- > 0)
												*tDestF++ = (*sfloat++)*slope + offset;
										}
										else if( fIsSigned > 0)
										{
											unsigned long x = height * width;
											while( x-- > 0)
												*tDestF++ = (((double) (*sint++)) + dOffset) * dSlope;
										}
										else
										{
											unsigned long x = height * width;
											while( x-- > 0)
												*tDestF++ = (((double) (*usint++)) + dOffset) * dSlope;
										}
									}
								}
								else
									NSLog( @"*** Not enough memory - malloc failed");
                                
								free(oImage);
								oImage = nil;
							}
							else
							{
								if( oImage)
								{
									vImage_Buffer src16, dstf;
									
									dstf.height = src16.height = height;
									dstf.width = src16.width = width;
									src16.rowBytes = width*2;
									dstf.rowBytes = width*sizeof(float);
									
									src16.data = oImage;
									
									if( VOILUT_number != 0 && VOILUT_depth != 0 && VOILUT_table != nil)
									{
										[self setVOILUT:VOILUT_first number:VOILUT_number depth:VOILUT_depth table:VOILUT_table image:(unsigned short*) oImage isSigned: fIsSigned];
										
										free( VOILUT_table);
										VOILUT_table = nil;
									}
									
									if( fExternalOwnedImage)
										fImage = fExternalOwnedImage;
									else
										fImage = malloc(width*height*sizeof(float) + 100);
									
									dstf.data = fImage;
									
									if( dstf.data)
									{
										if( fIsSigned)
											vImageConvert_16SToF( &src16, &dstf, offset, slope, 0);
										else
											vImageConvert_16UToF( &src16, &dstf, offset, slope, 0);
										
										if( inverseVal)
										{
											float neg = -1;
											vDSP_vsmul( fImage, 1, &neg, fImage, 1, height * width);
										}
									}
									else NSLog( @"*** Not enough memory - malloc failed");
									
									free(oImage);
								}
								oImage = nil;
							}
							
							if( oData && gDisplayDICOMOverlays && fImage)
							{
								int y, x;
								float maxValue = 0;
								
								if( inverseVal)
									maxValue = -offset;
								else
								{
									maxValue = pow( 2, bitsStored);
									maxValue *= slope;
									maxValue += offset;
								}
								
								if( oColumns == width)
								{
									register unsigned long x = oRows * oColumns;
									register unsigned char *d = oData;
									register float *ffI = fImage;
									
									while( x-- > 0)
									{
										if( *d++)
											*ffI = maxValue;
										ffI++;
									}
								}
								else
								{
									NSLog( @"-- oColumns != width");
									
									for( int y = 0; y < oRows; y++)
									{
										for( int x = 0; x < oColumns; x++)
										{
											if( oData[ y * oColumns + x]) fImage[ y * width + x] = maxValue;
										}
									}
									
								}
							}
						}
					}
					//***********
					
					//	endTime = MyGetTime();
					//	NSLog([ NSString stringWithFormat: @"%d", ((long) (endTime - startTime))/1000 ]);
					
					wl = 0;
					ww = 0; //Computed later, only if needed
					
					if( isRGB)
					{
						savedWL = 0;
						savedWW = 0;
					}
					
					if( savedWW != 0)
					{
						wl = savedWL;
						ww = savedWW;
					}
					
					if( clutRed) free( clutRed);
					if( clutGreen) free( clutGreen);
					if( clutBlue) free( clutBlue);
				}
				
				if( toBeUnlocked)
					[PapyrusLock unlock];
				
#ifdef OSIRIX_VIEWER
				[self loadCustomImageAnnotationsPapyLink: fileNb DCMLink:nil];
#endif
				
				if( pixelSpacingY != 0)
				{
					if( fabs(pixelSpacingX) / fabs(pixelSpacingY) > 10000 || fabs(pixelSpacingX) / fabs(pixelSpacingY) < 0.0001)
					{
						pixelSpacingX = 1;
						pixelSpacingY = 1;
					}
				}
				
				if( pixelSpacingX < 0) pixelSpacingX = -pixelSpacingX;
				if( pixelSpacingY < 0) pixelSpacingY = -pixelSpacingY;
				if( pixelSpacingY != 0 && pixelSpacingX != 0) pixelRatio = pixelSpacingY / pixelSpacingX;
				
				if( err >= 0)
					returnValue = YES;
			}
			else NSLog( @"[self getPapyGroup: 0x0028] failed");
		}
		else NSLog( @"[self getPapyGroup: 0] failed");
	}
	@catch (NSException *e)
	{
		NSLog( @"***load DICOM Papyrus exeption: %@", e);
		returnValue = NO;
	}
	
	[purgeCacheLock lock];
	[purgeCacheLock unlockWithCondition: [purgeCacheLock condition]-1];
	
    
    NSLog(@"Swizzle self at the end:%@",self);
	return returnValue;
}



@end
