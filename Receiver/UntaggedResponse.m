//
//  UntaggedResponse.m
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import "UntaggedResponse.h"

@implementation UntaggedResponse

@synthesize name;
@synthesize data;
@synthesize rawData;

- (void) dealloc {
    [name release];
    [data release];
    [rawData release];
    [super dealloc];
}

@end