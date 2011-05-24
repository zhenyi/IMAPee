//
//  PlainAuthenticator.m
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import "PlainAuthenticator.h"


@implementation PlainAuthenticator

@synthesize user, password;

- (id) initWithUser:(NSString *)aUser password:(NSString *)aPassword {
    if ((self = [super init])) {
        self.user = aUser;
        self.password = aPassword;
    }
    return self;
}

- (NSString *) process:(NSString *)data {
    return [NSString stringWithFormat:@"\0%@\0%@", self.user, self.password];
}

@end
