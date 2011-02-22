//
//  SwizzleViewerController.m
//  3DROIManager
//
//  Created by Yang Yang on 1/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SwizzleViewerController.h"


@implementation SwizzleViewerController

-(void) blendWindows:(id) sender
{
	NSMutableArray *viewersCT = [ViewerController getDisplayed2DViewers];
	NSMutableArray *viewersPET = [ViewerController getDisplayed2DViewers];
	int		i, x;
	BOOL	fused = NO;
	
	if( sender && blendingController)
	{
		[self ActivateBlending: nil];
		return;
	}
	
	if([[NSUserDefaults standardUserDefaults] integerForKey:@"PreclinicalAnalysis"]){
//		NSLog(@"Swizzling Out this stuff");
		
		for( ViewerController *vPET in viewersPET)
		{
			if( [[vPET modality] isEqualToString:@"PT"] || [[vPET modality] isEqualToString:@"NM"])
			{
				for( ViewerController *vCT in viewersCT)
				{
 					if( vCT != vPET)
 					{
 						if( [[vCT modality] isEqualToString:@"CT"] && [[vCT studyInstanceUID] isEqualToString: [vPET studyInstanceUID]])
 						{
 							ViewerController* a = vPET;
 							
 							if( [a blendingController] == nil)
 							{
 								ViewerController* b = vCT;
 								
 								float orientA[ 9], orientB[ 9], result[ 9];
 								
 								[[[a imageView] curDCM] orientation:orientA];
 								[[[b imageView] curDCM] orientation:orientB];
 								
 								// normal vector of planes
 								
 								result[0] = fabs( orientB[ 6] - orientA[ 6]);
 								result[1] = fabs( orientB[ 7] - orientA[ 7]);
 								result[2] = fabs( orientB[ 8] - orientA[ 8]);
 								
 								if( result[0] + result[1] + result[2] < 0.01) 
								{
 									[[a imageView] sendSyncMessage: 0];
 									[a ActivateBlending: b];
 									
 									fused = YES;
								}
							}
						}
					}
				}
			}
		}
	}
	else{
		
		for( ViewerController *vCT in viewersCT)
		{
			if( [[vCT modality] isEqualToString:@"CT"])
			{
				for( ViewerController *vPET in viewersPET)
				{
					if( vPET != vCT)
					{
						if( ([[vPET modality] isEqualToString:@"PT"] || [[vPET modality] isEqualToString:@"NM"]) && [[vPET studyInstanceUID] isEqualToString: [vCT studyInstanceUID]])
						{
							ViewerController* a = vCT;
							
							if( [a blendingController] == nil)
							{
								ViewerController* b = vPET;
								
								float orientA[ 9], orientB[ 9], result[ 9];
								
								[[[a imageView] curDCM] orientation:orientA];
								[[[b imageView] curDCM] orientation:orientB];
								
								// normal vector of planes
								
								result[0] = fabs( orientB[ 6] - orientA[ 6]);
								result[1] = fabs( orientB[ 7] - orientA[ 7]);
								result[2] = fabs( orientB[ 8] - orientA[ 8]);
								
								if( result[0] + result[1] + result[2] < 0.01) 
								{
									[[a imageView] sendSyncMessage: 0];
									[a ActivateBlending: b];
									
									fused = YES;
								}
							}
						}
					}
				}
			}
		}
	}
	if( fused == NO && sender != nil)
	{
		NSRunCriticalAlertPanel(NSLocalizedString(@"PET-CT Fusion", nil), NSLocalizedString(@"This function requires a PET series and a CT series in the same study.", nil) , NSLocalizedString(@"OK", nil), nil, nil);
	}
}
@end
