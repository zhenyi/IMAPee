//
//  RawData.h
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMAPee.h"

@interface RawData : NSObject {
    
    NSString *data;
    
}

@property (copy) NSString *data;

- (id) initWithData:(NSString *)aData;
- (void) sendData:(IMAPee *)imap;
- (void) validate;

@end