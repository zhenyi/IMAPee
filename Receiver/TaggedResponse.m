//
//  TaggedResponse.m
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import "TaggedResponse.h"

@implementation TaggedResponse

@synthesize tag;
@synthesize name;
@synthesize data;
@synthesize rawData;

- (void) dealloc {
    [tag release];
    [name release];
    [data release];
    [rawData release];
    [super dealloc];
}

@end