//
//  Token.m
//  Receiver
//
//  Created by Zhenyi Tan on 5/25/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import "Token.h"

@implementation Token

@synthesize symbol;
@synthesize value;

- (id) initWithSymbol:(int)aSymbol value:(NSString *)aValue {
    if ((self = [super init])) {
        self.symbol = aSymbol;
        self.value = aValue;
    }
    return self;
}

- (void) dealloc {
    [value release];
    [super dealloc];
}

@end