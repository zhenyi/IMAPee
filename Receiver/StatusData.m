//
//  StatusData.m
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import "StatusData.h"

@implementation StatusData

@synthesize mailbox;
@synthesize attr;

- (void) dealloc {
    [mailbox release];
    [attr release];
    [super dealloc];
}

@end