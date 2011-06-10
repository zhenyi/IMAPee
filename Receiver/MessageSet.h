//
//  MessageSet.h
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMAPee.h"
#import "ThreadMember.h"

@interface MessageSet : NSObject {
    
    id data;
    
}

@property (retain) id data;

- (id) initWithSomeData:(NSString *)someData;
- (void) sendData:(IMAPee *)imap;
- (void) validate;

@end