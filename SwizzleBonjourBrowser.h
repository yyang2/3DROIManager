//
//  SwizzleBonjourBrowser.h
//  3DROIManager
//
//  Created by Yang Yang on 3/21/11.
//  Copyright 2011 UCLA School of Medicine. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OsirixAPI/BonjourBrowser.h>

@interface SwizzleBonjourBrowser : BonjourBrowser {

}

-(void) buildDICOMDestinationsList;

@end
