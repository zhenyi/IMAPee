//
//  MailboxList.m
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import "MailboxList.h"

@implementation MailboxList

@synthesize attr;
@synthesize delim;
@synthesize name;

- (void) dealloc {
    [attr release];
    [delim release];
    [name release];
    [super dealloc];
}

@end