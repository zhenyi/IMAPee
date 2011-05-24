//
//  LoginAuthenticator.m
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import "LoginAuthenticator.h"

@implementation LoginAuthenticator

@synthesize user, password;
@synthesize state;

#define STATE_USER 1
#define STATE_PASSWORD 2

- (id) initWithUser:(NSString *)aUser password:(NSString *)aPassword {
    if ((self = [super init])) {
        self.user = aUser;
        self.password = aPassword;
        self.state = STATE_USER;
    }
    return self;
}

- (NSString *) process:(NSString *)data {
    switch (self.state) {
        case STATE_USER: {
            self.state = STATE_PASSWORD;
            return self.user;
        }
        case STATE_PASSWORD: {
            return self.password;
        }
        default: {
            return @"";
        }
    }
}

@end
