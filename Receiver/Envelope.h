//
//  Envelope.h
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Address.h"

@interface Envelope : NSObject {
    
    NSString *date;
    NSString *subject;
    Address *from;
    Address *sender;
    Address *replyTo;
    Address *to;
    Address *cc;
    Address *bcc;
    NSString *inReplyTo;
    NSString *messageId;

}

@property (copy) NSString *date;
@property (copy) NSString *subject;
@property (retain) Address *from;
@property (retain) Address *sender;
@property (retain) Address *replyTo;
@property (retain) Address *to;
@property (retain) Address *cc;
@property (retain) Address *bcc;
@property (copy) NSString *inReplyTo;
@property (copy) NSString *messageId;

@end