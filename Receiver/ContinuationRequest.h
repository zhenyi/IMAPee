//
//  ContinuationRequest.h
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseText.h"

@interface ContinuationRequest : NSObject {
    
    ResponseText *data;
    NSString *rawData;
    
}

@property (retain) ResponseText *data;
@property (copy) NSString *rawData;

@end