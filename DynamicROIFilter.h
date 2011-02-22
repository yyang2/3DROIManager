//
//  DynamicROIFilter.h
//  DynamicROI
//
//  Copyright (c) 2010 Yang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OsiriX Headers/PluginFilter.h>

@interface DynamicROIFilter : PluginFilter {
}

- (long) filterImage:(NSString*) menuName;

@end
