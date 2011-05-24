//
//  MessageSet.m
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import "MessageSet.h"

@implementation MessageSet

@synthesize data;

- (id) initWithData:(NSString *)aData {
    if ((self = [super init])) {
        self.data = aData;
    }
    return self;
}

- (NSString *) formatInternal:(id)aData {
    if ([aData isKindOfClass:[NSString class]]) {
        return aData;
    } else if ([aData isKindOfClass:[NSNumber class]]) {
        int intData = [aData intValue];
        if (intData == -1) {
            return @"*";
        } else {
            return [NSString stringWithFormat:@"%d", intData];
        }
    } else if ([aData isKindOfClass:[NSArray class]]) {
        NSMutableArray *tempArray = [NSMutableArray array];
        for (int i = 0; i < [aData count]; i++) {
            [tempArray addObject:[self formatInternal:[aData objectAtIndex:i]]];
        }
        return [tempArray componentsJoinedByString:@","];
    } else if ([aData isKindOfClass:[ThreadMember class]]) {
        NSString *seqno = [NSString stringWithFormat:@"%d", [aData seqno]];
        NSMutableArray *tempArray = [NSMutableArray array];
        for (int i = 0; i < [[aData children] count]; i++) {
            [tempArray addObject:[self formatInternal:[[aData children] objectAtIndex:i]]];
        }
        NSString *children = [tempArray componentsJoinedByString:@","];
        return [NSString stringWithFormat:@"%@:%@", seqno, children];
    } else {
        return @"";
    }
}

- (void) sendData:(IMAPee *)imap {
    [imap performSelector:@selector(putString:) withObject:[self formatInternal:self.data]];
}

- (void) ensureNZNumber:(int)num {
    if (num < -1 || num == 0 || num >= 4294967296) {
        @throw [NSException exceptionWithName:@"DataFormatError"
                                       reason:[NSString stringWithFormat:@"nz_number must be non-zero unsigned 32-bit integer: %d", num]
                                     userInfo:nil];
    }
}

- (void) validateInternal:(id)aData {
    if ([aData isKindOfClass:[NSNumber class]]) {
        [self ensureNZNumber:[aData intValue]];
    } else if ([aData isKindOfClass:[NSArray class]]) {
        for (int i = 0; i < [aData count]; i++) {
            [self ensureNZNumber:[[aData objectAtIndex:i] intValue]];
        }
    } else if ([aData isKindOfClass:[ThreadMember class]]) {
        for (int i = 0; i < [[aData children] count]; i++) {
            [self ensureNZNumber:[[[aData children] objectAtIndex:i] intValue]];
        }
    } else {
        @throw [NSException exceptionWithName:@"DataFormatError" reason:[NSString stringWithFormat:@"%@", aData] userInfo:nil];
    }
}

- (void) validate {
    [self validateInternal:self.data];
}

@end