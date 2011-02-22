//
//  DMCPix+Yang.m
//  DynamicROI
//
//  Created by Yang Yang on 3/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Osirix Headers/DCMPix.h>
#import "Papyrus3/Papyrus3.h"

@implementation DCMPix (Yang)

-(int) frameDuration
{
	int				elemType;
	PapyULong		nbVal;
	SElement		*theGroupP;
	UValue_T		*val;
	theGroupP = [self getPapyGroup: 0x0018];
	if( theGroupP)
	{
		val = Papy3GetElement (theGroupP, papActualFrameDurationGr, &nbVal, &elemType);
	}
	//papActualFrameDurationGr
	int duration;
	
	if(val)
	 duration = atof(val->a);
	else duration = 1;
	
	return duration;
}

-(NSString *) modalityName
{
	int				elemType;
	PapyULong		nbVal;
	SElement		*theGroupP;
	UValue_T		*val;
	theGroupP = [self getPapyGroup: 0x0008];
	NSString *modalityName;
	if( theGroupP)
	{
	val = Papy3GetElement (theGroupP, papModalityGr, &nbVal, &elemType);
	if (val != NULL) modalityName = [NSString stringWithCString:val->a encoding: NSASCIIStringEncoding];
	else return @"NONE";
	}
	else return @"NONE";
	return modalityName;
}
-(NSString*) returnUnits
{
	return units;
}

@end
