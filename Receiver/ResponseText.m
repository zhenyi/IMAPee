//
//  ResponseText.m
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import "ResponseText.h"

@implementation ResponseText

@synthesize code;
@synthesize text;

- (void) dealloc {
    [code release];
    [text release];
    [super dealloc];
}

@end