//
//  UIImage+iphone5.m
//  Demo
//
//  Copyright (c) 2014 loopmemedia. All rights reserved.
//

#import "UIImage+iphone5.h"

@implementation UIImage (iphone5)

+ (UIImage*)imageNamedForDevice:(NSString*)name {
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        if (([UIScreen mainScreen].bounds.size.height * [UIScreen mainScreen].scale) >= 1136.0f)
        {
            //Check if is there a path extension or not
            if (name.pathExtension.length) {
                name = [name stringByReplacingOccurrencesOfString: [NSString stringWithFormat:@".%@", name.pathExtension]
                                                       withString: [NSString stringWithFormat:@"-568h@2x.%@", name.pathExtension ] ];
                
            } else {
                name = [name stringByAppendingString:@"-568h@2x"];
            }
            
            //load the image e.g from disk or cache
            UIImage *image = [UIImage imageNamed: name ];
            if (image) {
                //strange Bug in iOS, the image name have a "@2x" but the scale isn't 2.0f
                return [UIImage imageWithCGImage: image.CGImage scale:2.0f orientation:image.imageOrientation];
            }
            
        }
    }
    
    return [UIImage imageNamed: name ];
    
}

@end
