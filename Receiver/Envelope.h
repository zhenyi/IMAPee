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
    NSArray *from;
    NSArray *sender;
    NSArray *replyTo;
    NSArray *to;
    NSArray *cc;
    NSArray *bcc;
    NSString *inReplyTo;
    NSString *messageId;

}

@property (copy) NSString *date;
@property (copy) NSString *subject;
@property (copy) NSArray *from;
@property (copy) NSArray *sender;
@property (copy) NSArray *replyTo;
@property (copy) NSArray *to;
@property (copy) NSArray *cc;
@property (copy) NSArray *bcc;
@property (copy) NSString *inReplyTo;
@property (copy) NSString *messageId;

@end