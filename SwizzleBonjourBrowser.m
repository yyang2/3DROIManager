//
//  SwizzleBonjourBrowser.m
//  3DROIManager
//
//  Created by Yang Yang on 3/21/11.
//  Copyright 2011 UCLA School of Medicine. All rights reserved.
//

#import "SwizzleBonjourBrowser.h"
#import <Osirix/DCMNetServiceDelegate.h>

@implementation SwizzleBonjourBrowser

-(void) buildDICOMDestinationsList
{
	int			i;
	NSArray		*dbArray = [DCMNetServiceDelegate DICOMServersListSendOnly:YES QROnly:NO];
	
	if( dbArray == nil) dbArray = [NSArray array];

	for( i = 0; i < [services count]; i++)
	{
		if( [[[services objectAtIndex: i] valueForKey:@"type"] isEqualToString:@"dicomDestination"])
		{
			[services removeObjectAtIndex: i];
			i--;
		}
	}
	
	for( i = 0; i < [dbArray count]; i++)
	{
		NSMutableDictionary	*dict = [NSMutableDictionary dictionaryWithDictionary: [dbArray objectAtIndex: i]];
		
		//removing bonjour name and replacing with AETitle
		[dict removeObjectForKey:@"Description"];
		[dict setObject:[dict objectForKey:@"AETitle"] forKey:@"Description"];

		[dict setValue:@"dicomDestination" forKey:@"type"];
		[services addObject: dict];
	}
	
}

@end
