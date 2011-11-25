//
//  Address.m
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import "Address.h"

@implementation Address

@synthesize name;
@synthesize route;
@synthesize mailbox;
@synthesize host;

- (void) dealloc {
    [name release];
    [route release];
    [mailbox release];
    [host release];
    [super dealloc];
}

@end