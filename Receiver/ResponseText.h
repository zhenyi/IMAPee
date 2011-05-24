//
//  ResponseText.h
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseCode.h"

@interface ResponseText : NSObject {
    
    ResponseCode *code;
    NSString *text;
    
}

@property (retain) ResponseCode *code;
@property (copy) NSString *text;

@end