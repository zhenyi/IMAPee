//
//  Literal.h
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMAPee.h"

@class IMAPee;

@interface Literal : NSObject {
    
    NSString *data;
    
}

@property (copy) NSString *data;

- (id) initWithSomeData:(NSString *)someData;
- (void) sendData:(IMAPee *)imap;
- (void) validate;

@end