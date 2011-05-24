//
//  CramMD5Authenticator.m
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import "CramMD5Authenticator.h"


@implementation CramMD5Authenticator

@synthesize user, password;

- (id) initWithUser:(NSString *)aUser password:(NSString *)aPassword {
    if ((self = [super init])) {
        self.user = aUser;
        self.password = aPassword;
    }
    return self;
}

#define CRAM_BUFSIZE 64
#define IMASK 0x36
#define OMASK 0x5c

- (NSString *) HMACMD5:(NSString *)text key:(NSString *)key {
    if ([key length] > CRAM_BUFSIZE) {
        key = [key MD5Digest];
    }
    NSString *kIPad = [key stringByPaddingToLength:CRAM_BUFSIZE withString:@"\0" startingAtIndex:0];
    NSString *kOPad = [key stringByPaddingToLength:CRAM_BUFSIZE withString:@"\0" startingAtIndex:0];
    NSMutableString *iBuf = [NSMutableString string];
    NSMutableString *oBuf = [NSMutableString string];
    for (int i = 0; i < [key length]; i++) {
        int iNum = (int)[key characterAtIndex:i] ^ IMASK;
        int oNum = (int)[key characterAtIndex:i] ^ OMASK;
        [iBuf appendFormat:@"%c", iNum];
        [oBuf appendFormat:@"%c", oNum];
    }
    NSString *digest = [[NSString stringWithFormat:@"%@%@", kIPad, text] MD5Digest];
    return [[NSString stringWithFormat:@"%@%@", kOPad, digest] MD5HexDigest];
}

- (NSString *) process:(NSString *)challenge {
    NSString *digest = [self HMACMD5:challenge key:self.password];
    return [NSString stringWithFormat:@"%@ %@", self.user, digest];
}

@end