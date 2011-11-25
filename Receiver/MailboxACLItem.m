//
//  MailboxACLItem.m
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import "MailboxACLItem.h"

@implementation MailboxACLItem

@synthesize user;
@synthesize rights;

- (void) dealloc {
    [user release];
    [rights release];
    [super dealloc];
}

@end