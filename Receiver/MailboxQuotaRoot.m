//
//  MailboxQuotaRoot.m
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import "MailboxQuotaRoot.h"

@implementation MailboxQuotaRoot

@synthesize mailbox;
@synthesize quotaRoots;

- (void) dealloc {
    [mailbox release];
    [quotaRoots release];
    [super dealloc];
}

@end