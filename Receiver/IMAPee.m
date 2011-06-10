//
//  IMAPee.m
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import "IMAPee.h"

@implementation IMAPee

@synthesize host, port;
@synthesize tagPrefix, tagNo;
@synthesize useSSL;
@synthesize parser;
@synthesize responses;
@synthesize taggedResponses;
@synthesize responseHandlers;
@synthesize logoutCommandTag;
@synthesize exception;
@synthesize greeting;

- (TaggedResponse *) sendCommand:(NSString *)cmd withArray:(NSArray *)argList {
    //TODO
    return nil;
}

- (TaggedResponse *) sendCommand:(NSString *)cmd, ... {
    //TODO
    return nil;
}

- (TaggedResponse *) sendCommand:(NSString *)cmd withBlock:(void(^)(id))block {
    //TODO
    return nil;
}

- (void) startTLSSession {
    //TODO
}

- (id) getResponse {
    //TODO
    return nil;
}

- (void) receiveResponses {
    //TODO
}

- (id) initWithHost:(NSString *)aHost port:(int)aPort useSSL:(BOOL)isUsingSSL {
    if ((self = [super init])) {
        self.host = aHost;
        if (port) {
            self.port = port;
        } else {
            self.port = isUsingSSL ? 993 : 143;
        }
        self.tagPrefix = @"PEE";
        self.tagNo = 0;
        self.parser = [[ResponseParser alloc] init];
        //TODO: sock open
        if (isUsingSSL) {
            [self startTLSSession];
            self.useSSL = YES;
        } else {
            self.useSSL = NO;
        }
        self.responses = [NSMutableDictionary dictionary];
        self.taggedResponses = [NSMutableDictionary dictionary];
        self.responseHandlers = [NSMutableArray array];
        self.logoutCommandTag = nil;
        self.exception = nil;
        self.greeting = [self getResponse];
        if ([greeting.name isEqualToString:@"BYE"]) {
            //TODO: close sock
            @throw [NSException exceptionWithName:@"ByeResponseError" reason:self.greeting.data.text userInfo:nil];
        }
        @try {
            [self receiveResponses];
        }
        @catch (NSException *exception) {
        }
    }
    return self;
}

- (NSArray *) capability {
    [self sendCommand:@"CAPABILITY", nil];
    NSArray *capabilities = [[self.responses objectForKey:@"CAPABILITY"] lastObject];
    [self.responses removeObjectForKey:@"CAPABILITY"];
    return capabilities;
}

- (TaggedResponse *) noop {
    return [self sendCommand:@"NOOP", nil];
}

- (TaggedResponse *) logout {
    return [self sendCommand:@"LOGOUT", nil];
}

- (TaggedResponse *) login:(NSString *)user password:(NSString *)password {
    return [self sendCommand:@"LOGIN", user, password, nil];
}

- (TaggedResponse *) select:(NSString *)mailbox {
    [self.responses removeAllObjects];
    return [self sendCommand:@"SELECT", mailbox, nil];
}

- (TaggedResponse *) examine:(NSString *)mailbox {
    [self.responses removeAllObjects];
    return [self sendCommand:@"EXAMINE", mailbox, nil];
}

- (TaggedResponse *) create:(NSString *)mailbox {
    return [self sendCommand:@"CREATE", mailbox, nil];
}

- (TaggedResponse *) del:(NSString *)mailbox {
    return [self sendCommand:@"DELETE", mailbox, nil];
}

- (TaggedResponse *) rename:(NSString *)mailbox to:(NSString *)newName {
    return [self sendCommand:@"RENAME", mailbox, newName, nil];
}

- (TaggedResponse *) subscribe:(NSString *)mailbox {
    return [self sendCommand:@"SUBSCRIBE", mailbox, nil];
}

- (TaggedResponse *) unsubscribe:(NSString *)mailbox {
    return [self sendCommand:@"UNSUBSCRIBE", mailbox, nil];
}

- (NSArray *) list:(NSString *)refName mailbox:(NSString *)mailbox {
    [self sendCommand:@"LIST", refName, mailbox, nil];
    NSArray *mailboxes = [self.responses objectForKey:@"LIST"];
    [self.responses removeObjectForKey:@"LIST"];
    return mailboxes;
}

- (NSArray *) getQuotaRoot:(NSString *)mailbox {
    [self sendCommand:@"GETQUOTAROOT", mailbox, nil];
    NSMutableArray *result = [NSMutableArray array];
    [result addObjectsFromArray:[self.responses objectForKey:@"QUOTAROOT"]];
    [result addObjectsFromArray:[self.responses objectForKey:@"QUOTA"]];
    [self.responses removeObjectForKey:@"QUOTAROOT"];
    [self.responses removeObjectForKey:@"QUOTA"];
    return result;
}

- (NSArray *) getQuota:(NSString *)mailbox {
    [self sendCommand:@"GETQUOTA", mailbox, nil];
    NSArray *quota = [self.responses objectForKey:@"QUOTA"];
    [self.responses removeObjectForKey:@"QUOTA"];
    return quota;
}

- (TaggedResponse *) setQuota:(NSString *)mailbox quota:(NSString *)quota {
    NSString *data = nil;
    if (quota == nil) {
        data = @"()";
    } else {
        data = [NSString stringWithFormat:@"(STORAGE %@)", quota];
    }
    return [self sendCommand:@"SETQUOTA", mailbox, [[[RawData alloc] initWithSomeData:data] autorelease], nil];
}

- (TaggedResponse *) setACL:(NSString *)mailbox user:(NSString *)user rights:(NSString *)rights {
    if (rights == nil) {
        return [self sendCommand:@"SETACL", mailbox, user, @"", nil];
    } else {
        return [self sendCommand:@"SETACL", mailbox, user, rights, nil];
    }
}

- (NSArray *) getACL:(NSString *)mailbox {
    [self sendCommand:@"GETACL", mailbox, nil];
    NSArray *ACLItems = [[self.responses objectForKey:@"ACL"] lastObject];
    [self.responses removeObjectForKey:@"ACL"];
    return ACLItems;
}

- (NSArray *) lsub:(NSString *)refName mailbox:(NSString *)mailbox {
    [self sendCommand:@"LSUB", refName, mailbox, nil];
    NSArray *mailboxes = [self.responses objectForKey:@"LSUB"];
    [self.responses removeObjectForKey:@"LSUB"];
    return mailboxes;
}

- (NSDictionary *) status:(NSString *)mailbox attr:(NSArray *)attr {
    [self sendCommand:@"STATUS", mailbox, attr, nil];
    StatusData *data = [[self.responses objectForKey:@"STATUS"] lastObject];
    NSDictionary *attrs = data.attr;
    [self.responses removeObjectForKey:@"STATUS"];
    return attrs;
}

- (TaggedResponse *) append:(NSString *)mailbox message:(NSString *)message flags:(NSArray *)flags time:(NSDate *)time {
    NSMutableArray *args = [NSMutableArray array];
    [args addObject:mailbox];
    if (flags) {
        [args addObject:flags];
    }
    if (time) {
        [args addObject:time];
    }
    Literal *literal = [[[Literal alloc] initWithSomeData:message] autorelease];
    [args addObject:literal];
    return [self sendCommand:@"APPEND" withArray:args];
}

- (TaggedResponse *) check {
    return [self sendCommand:@"CHECK", nil];
}

- (TaggedResponse *) close {
    return [self sendCommand:@"CLOSE", nil];
}

- (NSArray *) expunge {
    [self sendCommand:@"EXPUNGE", nil];
    NSArray *expunged = [self.responses objectForKey:@"EXPUNGE"];
    [self.responses removeObjectForKey:@"EXPUNGE"];
    return expunged;
}

- (NSArray *) searchInternal:(NSString *)cmd key:(NSString *)key charset:(NSString *)charset {
    //TODO
    return nil;
}

- (NSArray *) search:(NSString *)key charset:(NSString *)charset {
    return [self searchInternal:@"SEARCH" key:key charset:charset];
}

- (NSArray *) UIDSearch:(NSString *)key charset:(NSString *)charset {
    return [self searchInternal:@"UID SEARCH" key:key charset:charset];
}

- (NSArray *) fetchInternal:(NSString *)cmd set:(NSArray *)set attr:(NSArray *)attr {
    //TODO
    return nil;
}

- (NSArray *) fetch:(NSArray *)set attr:(NSArray *)attr {
    return [self fetchInternal:@"FETCH" set:set attr:attr];
}

- (NSArray *) UIDFetch:(NSArray *)set attr:(NSArray *)attr {
    return [self fetchInternal:@"UID FETCH" set:set attr:attr];
}

+ (NSString *) decodeUTF7:(NSString *)aString {
    NSError *error = NULL;
    NSRegularExpression *decodeUTF7Regex = [NSRegularExpression regularExpressionWithPattern:@"&(.*?)-"
                                                                                     options:0
                                                                                       error:&error];
    NSTextCheckingResult *match = [decodeUTF7Regex firstMatchInString:aString options:0 range:NSMakeRange(0, [aString length])];
    NSString *matchedString = nil;
    if (match) {
        NSRange matchedRange = [match rangeAtIndex:1];
        if (!NSEqualRanges(matchedRange, NSMakeRange(NSNotFound, 0))) {
            matchedString = [aString substringWithRange:matchedRange];
        }
        if ([matchedString length] == 0) {
            return @"&";
        } else {
            NSString *base64 = [matchedString stringByReplacingOccurrencesOfString:@"," withString:@"/"];
            int x = [base64 length] % 4;
            if (x > 0) {
                base64 = [base64 stringByPaddingToLength:([base64 length] + 4 - x) withString:@"=" startingAtIndex:0];
            }
            NSString *decoded = [NSString stringFromBase64String:base64];
            NSString *u16tou8 = [NSString stringWithCString:[decoded cStringUsingEncoding:NSUTF8StringEncoding] encoding:NSUTF16BigEndianStringEncoding];
            return u16tou8;
        }
    } else {
        return aString;
    }
}

+ (NSString *) encodeUTF7:(NSString *)aString {
    NSError *error = NULL;
    NSRegularExpression *encodeUTF7Regex = [NSRegularExpression regularExpressionWithPattern:@"(&)|([^\\x20-\\x25\\x27-\\x7e]+)"
                                                                                     options:0
                                                                                       error:&error];
    NSTextCheckingResult *match = [encodeUTF7Regex firstMatchInString:aString options:0 range:NSMakeRange(0, [aString length])];
    NSString *ampersand = nil;
    if (match) {
        NSRange ampersandRange = [match rangeAtIndex:1];
        if (!NSEqualRanges(ampersandRange, NSMakeRange(NSNotFound, 0))) {
            ampersand = [aString substringWithRange:ampersandRange];
        }
        if (ampersand) {
            return @"&-";
        } else {
            NSString *matchedString = [aString substringWithRange:[match range]];
            NSString *u8tou16 = [NSString stringWithCString:[matchedString cStringUsingEncoding:NSUTF16BigEndianStringEncoding]
                                                   encoding:NSUTF8StringEncoding];
            NSString *base64 = [NSString base64StringFromString:u8tou16];
            NSString *stringWithoutEquals = [base64 stringByReplacingOccurrencesOfString:@"=" withString:@""];
            NSString *stringWithoutEqualsAndNewLines = [stringWithoutEquals stringByReplacingOccurrencesOfString:@"\n" withString:@""];
            NSString *utf7 = [stringWithoutEqualsAndNewLines stringByReplacingOccurrencesOfString:@"/" withString:@","];
            return [NSString stringWithFormat:@"&%@-", utf7];
        }
    } else {
        return aString;
    }
}

+ (NSString *) formatDate:(NSDate *)someDate {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd-MMM-yyyy"];
    NSString *formatted = [dateFormatter stringFromDate:someDate];
    [dateFormatter release];
    return formatted;
}

+ (NSString *) formatDateTime:(NSDate *)someDate {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd-MMM-yyyy HH:mm Z"];
    NSString *formatted = [dateFormatter stringFromDate:someDate];
    [dateFormatter release];
    return formatted;
}

@end