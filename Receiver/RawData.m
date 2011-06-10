//
//  RawData.m
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import "RawData.h"

@implementation RawData

@synthesize data;

- (id) initWithSomeData:(NSString *)someData {
    if ((self = [super init])) {
        self.data = someData;
    }
    return self;
}

- (void) sendData:(IMAPee *)imap {
    [imap performSelector:@selector(putString:) withObject:self.data];
}

- (void) validate {
}

@end