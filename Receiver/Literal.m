//
//  Literal.m
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import "Literal.h"

@implementation Literal

@synthesize data;

- (id) initWithData:(NSString *)aData {
    if ((self = [super init])) {
        self.data = aData;
    }
    return self;
}

- (void) sendData:(IMAPee *)imap {
    [imap performSelector:@selector(sendLiteral:) withObject:self.data];
}

- (void) validate {
}

@end