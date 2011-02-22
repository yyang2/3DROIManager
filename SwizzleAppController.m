//
//  SwizzleAppController.m
//  3DROIManager
//
//  Created by Yang Yang on 1/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SwizzleAppController.h"
#import <Osirix Headers/AppController.h>

@implementation SwizzleAppController

static NSDate *lastWarningDate = nil;

+ (void) displayImportantNotice:(id) sender
{
	
	if( lastWarningDate == nil || [lastWarningDate timeIntervalSinceNow] < -60*60*16) // 16 hours
	{
		if(![[NSUserDefaults standardUserDefaults] boolForKey:@"PassedWarning"]){
			int result = NSRunCriticalAlertPanel( NSLocalizedString( @"Important Notice", nil), NSLocalizedString( @"This version of OsiriX, being a free open-source software (FOSS), has been modified for preclinical image analysis and is not intended for primary diagnostic imaging.\r\rFor the  FDA / CE-1 certified version, please check the official OsiriX web page:\r\r http://www.osirix-viewer.com/Certifications.html\r", nil),  NSLocalizedString( @"I agree", nil), NSLocalizedString( @"Quit", nil),  NSLocalizedString( @"Certifications", nil));
			
			
			if( result == NSAlertOtherReturn)
				[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.osirix-viewer.com/Certifications.html"]];
			
			else if( result != NSAlertDefaultReturn)
				[[AppController sharedAppController] terminate: self];
			
			[[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"PassedWarning"];
		}
	}
	
	[lastWarningDate release];
	lastWarningDate = [[NSDate date] retain];
}

@end
