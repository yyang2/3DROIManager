//
//  3DROIManagerFilter.h
//  3DROIManager
//
//  Copyright (c) 2010 UCLA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OsiriX Headers/PluginFilter.h>

@interface ThreeDROIManagerFilter : PluginFilter {

}

- (long) filterImage:(NSString*) menuName;

@end
