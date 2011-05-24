//
//  ContentDisposition.h
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ContentDisposition : NSObject {
    
    NSString *dspType;
    NSDictionary *param;
    
}

@property (copy) NSString *dspType;
@property (copy) NSDictionary *param;

@end