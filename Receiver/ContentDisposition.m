//
//  ContentDisposition.m
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import "ContentDisposition.h"

@implementation ContentDisposition

@synthesize dspType;
@synthesize param;

- (void) dealloc {
    [dspType release];
    [param release];
    [super dealloc];
}

- (NSString *) description {
    return [NSString stringWithFormat:@"ContentDisposition: dspType=%@, param=%@", self.dspType, self.param];
}

@end