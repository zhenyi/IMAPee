//
//  IMAPee.m
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import "IMAPee.h"

@interface IMAPee()

@property (retain) NSMutableString *responseString;
@property (retain) NSMutableArray *responseBuffer;

- (void) sendData:(id)data;

@end

@implementation IMAPee

@synthesize host, port;
@synthesize tagPrefix, tagNo;
@synthesize useSSL;
@synthesize authenticators;
@synthesize parser;
@synthesize responses;
@synthesize taggedResponses;
@synthesize isIdleDone;
@synthesize continuationRequestArrived;
@synthesize responseHandlers;
@synthesize logoutCommandTag;
@synthesize responseString;
@synthesize responseBuffer;
@synthesize exception;
@synthesize greeting;

- (void) putString:(NSString *)str {
    NSLog(@"C: %@", str);
    NSData *dataToSend = [str dataUsingEncoding:NSUTF8StringEncoding];
    int remainingToWrite = [dataToSend length];
    void *marker = (void *)[dataToSend bytes];
    while (0 < remainingToWrite) {
        int actuallyWritten = 0;
        actuallyWritten = [oStream write:marker maxLength:remainingToWrite];
        remainingToWrite -= actuallyWritten;
        marker += actuallyWritten;
    }
}

- (NSString *) stringToFlag:(NSString *)data {
    return [NSString stringWithFormat:@"\\\\%@", data];
}

- (NSString *) generateTag {
    self.tagNo++;
    return [NSString stringWithFormat:@"%@%04d", self.tagPrefix, self.tagNo];
}

- (TaggedResponse *) getTaggedResponse:(NSString *)tag cmd:(NSString *)cmd {
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    while (![self.taggedResponses objectForKey:tag] && [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    if (self.exception) {
        @throw self.exception;
    }
    TaggedResponse *resp = [[self.taggedResponses objectForKey:tag] retain];
    [self.taggedResponses removeObjectForKey:tag];
    NSError *error = NULL;
    NSRegularExpression *noRespRegex = [NSRegularExpression regularExpressionWithPattern:@"\\A(?:NO)\\z"
                                                                                 options:NSRegularExpressionCaseInsensitive
                                                                                   error:&error];
    NSRegularExpression *badRespRegex = [NSRegularExpression regularExpressionWithPattern:@"\\A(?:BAD)\\z"
                                                                                  options:NSRegularExpressionCaseInsensitive
                                                                                    error:&error];
    if ([noRespRegex numberOfMatchesInString:resp.name options:0 range:NSMakeRange(0, [resp.name length])]) {
        ResponseText *text = (ResponseText *) resp.data;
        @throw [NSException exceptionWithName:@"NoResponseError" reason:text.text userInfo:nil];
    } else if ([badRespRegex numberOfMatchesInString:resp.name options:0 range:NSMakeRange(0, [resp.name length])]) {
        ResponseText *text = (ResponseText *) resp.data;
        @throw [NSException exceptionWithName:@"BadResponseError" reason:text.text userInfo:nil];
    } else {
        return [resp autorelease];
    }
}

- (void) sendSymbol:(NSString *)str {
    NSError *error = NULL;
    NSRegularExpression *symbolRegex = [NSRegularExpression regularExpressionWithPattern:@"^\\\\"
                                                                                 options:0
                                                                                   error:&error];
    NSString *replaced = [symbolRegex stringByReplacingMatchesInString:str
                                                               options:0
                                                                 range:NSMakeRange(0, [str length])
                                                          withTemplate:@""];
    [self putString:replaced];
}

- (void) sendLiteral:(NSString *)str {
    [self putString:[NSString stringWithFormat:@"{%d}\r\n", [str length]]];
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    while (!self.continuationRequestArrived && [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    self.continuationRequestArrived = NO;
    if (self.exception) {
        @throw self.exception;
    }
    [self putString:str];
}

- (void) sendQuotedString:(NSString *)str {
    NSError *error = NULL;
    NSRegularExpression *quotedRegex = [NSRegularExpression regularExpressionWithPattern:@"([\"\\\\])"
                                                                                 options:0
                                                                                   error:&error];
    NSString *replaced = [quotedRegex stringByReplacingMatchesInString:str
                                                               options:0
                                                                 range:NSMakeRange(0, [str length])
                                                          withTemplate:@"\\\\$1"];
    [self putString:[NSString stringWithFormat:@"\"%@\"", replaced]];
}

- (void) sendStringData:(NSString *)str {
    NSError *error = NULL;
    NSRegularExpression *symbolRegex = [NSRegularExpression regularExpressionWithPattern:@"^\\\\\\\\"
                                                                                 options:0
                                                                                   error:&error];
    NSRegularExpression *literalRegex = [NSRegularExpression regularExpressionWithPattern:@"[\\x80-\\xff\\r\\n]"
                                                                                  options:0
                                                                                    error:&error];
    NSRegularExpression *quotedRegex = [NSRegularExpression regularExpressionWithPattern:@"[(){ \\x00-\\x1f\\x7f%*\"\\\\]"
                                                                                 options:0
                                                                                   error:&error];
    if ([str length] == 0) {
        [self putString:@"\"\""];
    } else if ([symbolRegex numberOfMatchesInString:str options:0 range:NSMakeRange(0, [str length])]) {
        [self sendSymbol:str];
    } else if ([literalRegex numberOfMatchesInString:str options:0 range:NSMakeRange(0, [str length])]) {
        [self sendLiteral:str];
    } else if ([quotedRegex numberOfMatchesInString:str options:0 range:NSMakeRange(0, [str length])]) {
        [self sendQuotedString:str];
    } else {
        [self putString:str];
    }
}

- (void) sendNumberData:(NSNumber *)num {
    int i = [num intValue];
    [self putString:[NSString stringWithFormat:@"%d", i]];
}

- (void) sendListData:(NSArray *)list {
    [self putString:@"("];
    BOOL first = YES;
    for (id item in list) {
        if (first) {
            first = NO;
        } else {
            [self putString:@" "];
        }
        [self sendData:item];
    }
    [self putString:@")"];
}

- (void) sendTimeData:(NSDate *)time {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    [dateFormatter setDateFormat:@"dd-MMM-yyyy HH:mm:ss Z"];
    NSString *formatted = [dateFormatter stringFromDate:[NSDate date]];
    [dateFormatter release];
    [self putString:formatted];
}

- (void) sendData:(id)data {
    if (data == nil) {
        [self putString:@"NIL"];
    } else if ([data isKindOfClass:[NSString class]]) {
        [self sendStringData:data];
    } else if ([data isKindOfClass:[NSNumber class]]) {
        [self sendNumberData:data];
    } else if ([data isKindOfClass:[NSArray class]]) {
        [self sendListData:data];
    } else if ([data isKindOfClass:[NSDate class]]) {
        [self sendTimeData:data];
    } else {
        [data sendData:self];
    }
}

- (void) validateData:(id)data {
    if (data == nil) {
    } else if ([data isKindOfClass:[NSString class]]) {
    } else if ([data isKindOfClass:[NSNumber class]]) {
        NSInteger i = [data intValue];
        if (i < 0) {
            @throw [NSException exceptionWithName:@"DataFormatError" reason:[NSString stringWithFormat:@"%d", i] userInfo:nil];
        }
    } else if ([data isKindOfClass:[NSArray class]]) {
        for (id item in data) {
            [self validateData:item];
        }
    } else if ([data isKindOfClass:[NSDate class]]) {
    } else {
        [data validate];
    }
}

- (TaggedResponse *) sendCommand:(NSString *)cmd withArray:(NSArray *)argList {
    for (id arg in argList) {
        [self validateData:arg];
    }
    NSString *tag = [self generateTag];
    [self putString:[NSString stringWithFormat:@"%@ %@", tag, cmd]];
    for (id arg in argList) {
        [self putString:@" "];
        [self sendData:arg];
    }
    [self putString:@"\r\n"];
    if ([cmd isEqualToString:@"LOGOUT"]) {
        self.logoutCommandTag = tag;
    }
    return [self getTaggedResponse:tag cmd:cmd];
}

- (TaggedResponse *) sendCommand:(NSString *)cmd, ... {
    NSMutableArray *argList = [NSMutableArray array];
    va_list args;
    va_start(args, cmd);
    for (id arg = cmd; arg != nil; arg = va_arg(args, id)) {
        [argList addObject:arg];
    }
    va_end(args);
    [argList removeObjectAtIndex:0];
    return [self sendCommand:cmd withArray:argList];
}

- (TaggedResponse *) sendCommand:(NSString *)cmd withBlock:(void(^)(id))block {
    NSString *tag = [self generateTag];
    [self putString:[NSString stringWithFormat:@"%@ %@", tag, cmd]];
    [self putString:@"\r\n"];
    if ([cmd isEqualToString:@"LOGOUT"]) {
        self.logoutCommandTag = tag;
    }
    [self addResponseHandler:block];
    @try {
        return [self getTaggedResponse:tag cmd:cmd];
    }
    @finally {
        [self removeResponseHandler:block];
    }
}

- (void) addAuthenticator:(NSString *)authType authenticator:(Class)authenticator {
    [self.authenticators setObject:authenticators forKey:authType];
}

- (void) disconnect {
    [iStream close];
    [oStream close];
    [iStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [oStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [iStream setDelegate:nil];
    [oStream setDelegate:nil];
    [iStream release];
    [oStream release];
    iStream = nil;
    oStream = nil;
}

- (void) authenticate:(NSString *)authType user:(NSString *)user password:(NSString *)password {
    authType = [authType uppercaseString];
    if (![self.authenticators objectForKey:authType]) {
        @throw [NSException exceptionWithName:@"ArgumentError"
                                       reason:[NSString stringWithFormat:@"unknown auth type - \"%@\"", authType]
                                     userInfo:nil];
    }
    Class authenticatorClass = [self.authenticators objectForKey:authType];
    id authenticator = [[authenticatorClass alloc] initWithUser:user password:password];
    [self sendCommand:[NSString stringWithFormat:@"%@ %@", @"AUTHENTICATE", authType] withBlock:^(id resp) {
        if ([resp isKindOfClass:[ContinuationRequest class]]) {
            ContinuationRequest *request = (ContinuationRequest *) resp;
            NSString *data = [authenticator process:[NSString stringFromBase64String:request.data.text]];
            NSString *s = [[NSString base64StringFromString:data] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
            [self sendStringData:s];
            [self putString:@"\r\n"];
        }
    }];
}

- (void) recordResponse:(NSString *)name data:(id)data {
    if (![self.responses objectForKey:name]) {
        [self.responses setObject:[NSMutableArray array] forKey:name];
    }
    NSMutableArray *array = [self.responses objectForKey:name];
    [array addObject:data];
}

- (void) receiveResponses:(NSString *)resp {
    /* DEBUG
    @try {
    */
        id response = [self.parser parse:resp];
        if ([response isKindOfClass:[TaggedResponse class]]) {
            TaggedResponse *tagged = (TaggedResponse *)response;
            [self.taggedResponses setObject:tagged forKey:tagged.tag];
            if (tagged.tag == self.logoutCommandTag) {
                return;
            }
        } else if ([response isKindOfClass:[UntaggedResponse class]]) {
            UntaggedResponse *untagged = (UntaggedResponse *)response;
            [self recordResponse:untagged.name data:untagged.data];
            if ([untagged.data isKindOfClass:[ResponseText class]]) {
                ResponseText *text = (ResponseText *) untagged.data;
                ResponseCode *code = text.code;
                if (code) {
                    [self recordResponse:code.name data:code.data];
                }
            }
            if ([untagged.name isEqualToString:@"BYE"] && self.logoutCommandTag == nil) {
                [iStream close];
                [oStream close];
                [iStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
                [oStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
                [iStream setDelegate:nil];
                [oStream setDelegate:nil];
                [iStream release];
                [oStream release];
                iStream = nil;
                oStream = nil;
                ResponseText *text = (ResponseText *) untagged.data;
                @throw [NSException exceptionWithName:@"ByeResponseError" reason:text.text userInfo:nil];
            }
        } else if ([response isKindOfClass:[ContinuationRequest class]]) {
            self.continuationRequestArrived = YES;
        }
        for (void(^handler)(id) in self.responseHandlers) {
            handler(response);
        }
    /* DEBUG
    }
    @catch (NSException *anException) {
        self.exception = anException;
    }
    */
}

- (void) getResponse {
    if ([self.responseBuffer count] > 0) {
        NSString *first = [[self.responseBuffer objectAtIndex:0] copy];
        [self.responseBuffer removeObjectAtIndex:0];
        [self receiveResponses:first];
    }
}

- (UntaggedResponse *) getGreeting {
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    while ([self.responseBuffer count] == 0 && [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    NSString *first = [[self.responseBuffer objectAtIndex:0] copy];
    [self.responseBuffer removeObjectAtIndex:0];
    return [self.parser parse:first];
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
        self.authenticators = [NSMutableDictionary dictionary];
        [self addAuthenticator:@"LOGIN" authenticator:[LoginAuthenticator class]];
        [self addAuthenticator:@"PLAIN" authenticator:[PlainAuthenticator class]];
        [self addAuthenticator:@"CRAM-MD5" authenticator:[CramMD5Authenticator class]];
        self.parser = [[ResponseParser alloc] init];
        [NSStream getStreamsToHostNamed:self.host port:self.port inputStream:&iStream outputStream:&oStream];
        [iStream retain];
        [oStream retain];
        [iStream setDelegate:self];
        [oStream setDelegate:self];
        [iStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [oStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        if (isUsingSSL) {
            [iStream setProperty:NSStreamSocketSecurityLevelNegotiatedSSL forKey:NSStreamSocketSecurityLevelKey];
            [oStream setProperty:NSStreamSocketSecurityLevelNegotiatedSSL forKey:NSStreamSocketSecurityLevelKey];
            self.useSSL = YES;
        } else {
            self.useSSL = NO;
        }
        [iStream open];
        [oStream open];
        self.responses = [NSMutableDictionary dictionary];
        self.taggedResponses = [NSMutableDictionary dictionary];
        self.responseHandlers = [NSMutableArray array];
        self.isIdleDone = NO;
        self.continuationRequestArrived = NO;
        self.logoutCommandTag = nil;
        self.responseString = [NSMutableString string];
        self.responseBuffer = [NSMutableArray array];
        self.exception = nil;
        self.greeting = nil;
        self.greeting = [self getGreeting];        
        if ([self.greeting.name isEqualToString:@"BYE"]) {
            [iStream close];
            [oStream close];
            [iStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [oStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [iStream setDelegate:nil];
            [oStream setDelegate:nil];
            [iStream release];
            [oStream release];
            iStream = nil;
            oStream = nil;
            ResponseText *data = self.greeting.data;
            @throw [NSException exceptionWithName:@"ByeResponseError" reason:data.text userInfo:nil];
        }
    }
    return self;
}

- (void) addResponseHandler:(void(^)(id))block {
    [self.responseHandlers addObject:block];
}

- (void) removeResponseHandler:(void(^)(id))block {
    [self.responseHandlers removeObject:block];
}

- (NSArray *) capability {
    [self sendCommand:@"CAPABILITY", nil];
    NSArray *capabilities = [[[self.responses objectForKey:@"CAPABILITY"] lastObject] copy];
    [self.responses removeObjectForKey:@"CAPABILITY"];
    return [capabilities autorelease];
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
    NSArray *mailboxes = [[self.responses objectForKey:@"LIST"] copy];
    [self.responses removeObjectForKey:@"LIST"];
    return [mailboxes autorelease];
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
    NSArray *quota = [[self.responses objectForKey:@"QUOTA"] copy];
    [self.responses removeObjectForKey:@"QUOTA"];
    return [quota autorelease];
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
    NSArray *ACLItems = [[[self.responses objectForKey:@"ACL"] lastObject] copy];
    [self.responses removeObjectForKey:@"ACL"];
    return [ACLItems autorelease];
}

- (NSArray *) lsub:(NSString *)refName mailbox:(NSString *)mailbox {
    [self sendCommand:@"LSUB", refName, mailbox, nil];
    NSArray *mailboxes = [[self.responses objectForKey:@"LSUB"] copy];
    [self.responses removeObjectForKey:@"LSUB"];
    return [mailboxes autorelease];
}

- (NSDictionary *) status:(NSString *)mailbox attr:(NSArray *)attr {
    [self sendCommand:@"STATUS", mailbox, attr, nil];
    StatusData *data = [[[[self.responses objectForKey:@"STATUS"] lastObject] retain] autorelease];
    NSDictionary *attrs = data.attr;
    [self.responses removeObjectForKey:@"STATUS"];
    return attrs;
}

- (TaggedResponse *) append:(NSString *)mailbox message:(NSString *)message flags:(NSArray *)flags time:(NSDate *)time {
    NSMutableArray *args = [NSMutableArray array];
    [args addObject:mailbox];
    if (flags) {
        NSMutableArray *flagsArray = [NSMutableArray array];
        for (NSString *flag in flags) {
            [flagsArray addObject:[self stringToFlag:flag]];
        }
        [args addObject:flagsArray];
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
    NSArray *expunged = [[self.responses objectForKey:@"EXPUNGE"] copy];
    [self.responses removeObjectForKey:@"EXPUNGE"];
    return [expunged autorelease];
}

- (NSArray *) searchInternal:(NSString *)cmd key:(NSString *)key charset:(NSString *)charset {
    RawData *dataKeys = [[[RawData alloc] initWithSomeData:key] autorelease];
    if (charset) {
        [self sendCommand:cmd, "CHARSET", charset, dataKeys, nil];
    } else {
        [self sendCommand:cmd, dataKeys, nil];
    }
    NSArray *results = [[[self.responses objectForKey:@"SEARCH"] lastObject] copy];
    [self.responses removeObjectForKey:@"SEARCH"];
    return [results autorelease];
}

- (NSArray *) search:(NSString *)key charset:(NSString *)charset {
    return [self searchInternal:@"SEARCH" key:key charset:charset];
}

- (NSArray *) UIDSearch:(NSString *)key charset:(NSString *)charset {
    return [self searchInternal:@"UID SEARCH" key:key charset:charset];
}

- (NSArray *) fetchInternal:(NSString *)cmd set:(NSArray *)set attr:(NSArray *)attr {
    NSMutableArray *rawDataArray = [NSMutableArray array];
    for (NSString *arg in attr) {
        RawData *data = [[[RawData alloc] initWithSomeData:arg] autorelease];
        [rawDataArray addObject:data];
    }
    [self.responses removeObjectForKey:@"FETCH"];
    MessageSet *messageSet = [[[MessageSet alloc] initWithSetData:set] autorelease];
    [self sendCommand:cmd, messageSet, rawDataArray, nil];
    NSArray *results = [[self.responses objectForKey:@"FETCH"] copy];
    [self.responses removeObjectForKey:@"FETCH"];
    return [results autorelease];
}

- (NSArray *) fetch:(NSArray *)set attr:(NSArray *)attr {
    return [self fetchInternal:@"FETCH" set:set attr:attr];
}

- (NSArray *) UIDFetch:(NSArray *)set attr:(NSArray *)attr {
    return [self fetchInternal:@"UID FETCH" set:set attr:attr];
}

- (NSArray *) storeInternal:(NSString *)cmd set:(NSArray *)set attr:(NSString *)attr flags:(NSArray *)flags {
    NSMutableArray *flagsArray = [NSMutableArray array];
    for (NSString *flag in flags) {
        [flagsArray addObject:[self stringToFlag:flag]];
    }
    [self.responses removeObjectForKey:@"FETCH"];
    MessageSet *messageSet = [[[MessageSet alloc] initWithSetData:set] autorelease];
    [self sendCommand:cmd, messageSet, attr, flagsArray, nil];
    NSArray *results = [[self.responses objectForKey:@"FETCH"] copy];
    [self.responses removeObjectForKey:@"FETCH"];
    return [results autorelease];
}

- (NSArray *) store:(NSArray *)set attr:(NSString *)attr flags:(NSArray *)flags {
    return [self storeInternal:@"STORE" set:set attr:attr flags:flags];
}
- (NSArray *) UIDStore:(NSArray *)set attr:(NSString *)attr flags:(NSArray *)flags {
    return [self storeInternal:@"UID STORE" set:set attr:attr flags:flags];
}

- (void) copyInternal:(NSString *)cmd set:(NSArray *)set mailbox:(NSString *)mailbox {
    MessageSet *messageSet = [[[MessageSet alloc] initWithSetData:set] autorelease];
    [self sendCommand:cmd, messageSet, mailbox, nil];
}

- (void) copy:(NSArray *)set mailbox:(NSString *)mailbox {
    [self copyInternal:@"COPY" set:set mailbox:mailbox];
}

- (void) UIDCopy:(NSArray *)set mailbox:(NSString *)mailbox {
    [self copyInternal:@"UID COPY" set:set mailbox:mailbox];
}

- (NSArray *) normalizeSearchingCritirea:(NSArray *)keys {
    NSMutableArray *normalizedArray = [NSMutableArray array];
    for (id item in keys) {
        if ([item isKindOfClass:[NSNumber class]]) {
            int i = [(NSNumber *) item intValue];
            if (i == -1) {
                MessageSet *messageSet = [[[MessageSet alloc] initWithSetData:item] autorelease];
                [normalizedArray addObject:messageSet];
            }
        } else if ([item isKindOfClass:[NSArray class]]) {
            MessageSet *messageSet = [[[MessageSet alloc] initWithSetData:item] autorelease];
            [normalizedArray addObject:messageSet];
        } else {
            [normalizedArray addObject:item];
        }
    }
    return normalizedArray;
}

- (NSArray *) sortInternal:(NSString *)cmd sortKeys:(NSArray *)sortKeys searchKeys:(NSArray *)searchKeys charset:(NSString *)charset {
    searchKeys = [self normalizeSearchingCritirea:searchKeys];
    searchKeys = [self normalizeSearchingCritirea:searchKeys];
    NSMutableArray *arguments = [NSMutableArray array];
    [arguments addObject:sortKeys];
    [arguments addObject:charset];
    for (id key in searchKeys) {
        [arguments addObject:key];
    }
    [self sendCommand:cmd withArray:arguments];
    NSArray *results = [[[self.responses objectForKey:@"SORT"] lastObject] copy];
    [self.responses removeObjectForKey:@"SORT"];
    return [results autorelease];
}

- (NSArray *) sort:(NSArray *)sortKeys searchKeys:(NSArray *)searchKeys charset:(NSString *)charset {
    return [self sortInternal:@"SORT" sortKeys:sortKeys searchKeys:searchKeys charset:charset];
}

- (NSArray *) UIDSort:(NSArray *)sortKeys searchKeys:(NSArray *)searchKeys charset:(NSString *)charset {
    return [self sortInternal:@"UID SORT" sortKeys:sortKeys searchKeys:searchKeys charset:charset];
}

- (NSArray *) threadInternal:(NSString *)cmd algorithm:(NSString *)algorithm searchKeys:(NSArray *)searchKeys charset:(NSString *)charset {
    searchKeys = [self normalizeSearchingCritirea:searchKeys];
    searchKeys = [self normalizeSearchingCritirea:searchKeys];
    NSMutableArray *arguments = [NSMutableArray array];
    [arguments addObject:algorithm];
    [arguments addObject:charset];
    for (id key in searchKeys) {
        [arguments addObject:key];
    }
    [self sendCommand:cmd withArray:arguments];
    NSArray *results = [[[self.responses objectForKey:@"THREAD"] lastObject] copy];
    [self.responses removeObjectForKey:@"THREAD"];
    return [results autorelease];
}

- (NSArray *) thread:(NSString *)algorithm searchKeys:(NSArray *)searchKeys charset:(NSString *)charset {
    return [self threadInternal:@"THREAD" algorithm:algorithm searchKeys:searchKeys charset:charset];
}

- (NSArray *) UIDThread:(NSString *)algorithm searchKeys:(NSArray *)searchKeys charset:(NSString *)charset {
    return [self threadInternal:@"UID THREAD" algorithm:algorithm searchKeys:searchKeys charset:charset];
}

- (TaggedResponse *) idleWithBlock:(void(^)(id))block {
    TaggedResponse *response = nil;
    NSString *tag = [self generateTag];
    [self putString:[NSString stringWithFormat:@"%@ IDLE\r\n", tag]];
    @try {
        [self addResponseHandler:block];
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        while (!self.isIdleDone && [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
        self.isIdleDone = NO;
    }
    @finally {
        [self removeResponseHandler:block];
        [self putString:@"DONE\r\n"];
        response = [self getTaggedResponse:tag cmd:@"IDLE"];
    }
    return response;
}

- (void) idleDone {
    if (self.isIdleDone) {
        @throw [NSException exceptionWithName:@"IMAPError" reason:@"not during IDLE" userInfo:nil];
    }
    self.isIdleDone = YES;
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

- (void) parseInputStream {
    uint8_t buffer[1024];
    int len;
    NSError *error = NULL;
    NSRegularExpression *crlfRegex = [NSRegularExpression regularExpressionWithPattern:@"^([^\\r\\n]*?\\r\\n)"
                                                                               options:0
                                                                                 error:&error];
    while ([iStream hasBytesAvailable]) {
        len = [iStream read:buffer maxLength:sizeof(buffer)];
        if (len > 0) {
            NSString *res = [[NSString alloc] initWithBytes:buffer 
                                                     length:len 
                                                   encoding:NSASCIIStringEncoding];
            if (res) {
                NSLog(@"S: %@", res);
                [self.responseString appendString:res];
                BOOL goOn = YES;
                while (goOn) {
                    NSTextCheckingResult *match = [crlfRegex firstMatchInString:self.responseString options:0
                                                                          range:NSMakeRange(0, [self.responseString length])];
                    if (match) {
                        NSRange crlfRange = [match range];
                        NSString *resultString = [self.responseString substringWithRange:crlfRange];
                        [self.responseBuffer addObject:resultString];
                        [self.responseString deleteCharactersInRange:crlfRange];
                        if (self.greeting) {
                            [self getResponse];
                        }
                    } else {
                        goOn = NO;
                    }
                }
            }
        }
    }
}

- (void) stream:(NSStream *)stream handleEvent:(NSStreamEvent)event {
    switch (event) {
        case NSStreamEventHasBytesAvailable: {
            if (stream == iStream) {
                [self parseInputStream];
            }
            break;
        }
    }
}

@end