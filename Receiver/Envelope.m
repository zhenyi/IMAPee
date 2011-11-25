//
//  Envelope.m
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import "Envelope.h"

@implementation Envelope

@synthesize date;
@synthesize subject;
@synthesize from;
@synthesize sender;
@synthesize replyTo;
@synthesize to;
@synthesize cc;
@synthesize bcc;
@synthesize inReplyTo;
@synthesize messageId;

- (void) dealloc {
    [date release];
    [subject release];
    [from release];
    [sender release];
    [replyTo release];
    [to release];
    [cc release];
    [bcc release];
    [inReplyTo release];
    [messageId release];
    [super dealloc];
}

@end