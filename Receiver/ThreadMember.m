//
//  ThreadMember.m
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import "ThreadMember.h"

@implementation ThreadMember

@synthesize seqno;
@synthesize children;

- (void) dealloc {
    [children release];
    [super dealloc];
}

@end