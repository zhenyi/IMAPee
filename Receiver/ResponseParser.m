//
//  ResponseParser.m
//  Receiver
//
//  Created by Zhenyi Tan on 5/25/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import "ResponseParser.h"

@implementation ResponseParser

@synthesize str;
@synthesize pos;
@synthesize lexState;
@synthesize token;
@synthesize flagSymbols;

#define EXPR_NIL 0
#define EXPR_BEG 1
#define EXPR_DATA 2
#define EXPR_TEXT 3
#define EXPR_RTEXT 4
#define EXPR_CTEXT 5

#define T_SPACE 1
#define T_NIL 2
#define T_NUMBER 3
#define T_ATOM 4
#define T_QUOTED 5
#define T_LPAR 6
#define T_RPAR 7
#define T_BSLASH 8
#define T_STAR 9
#define T_LBRA 10
#define T_RBRA 11
#define T_LITERAL 12
#define T_PLUS 13
#define T_PERCENT 14
#define T_CRLF 15
#define T_EOF 16
#define T_TEXT 17

- (id) init {
    if ((self = [super init])) {
        self.str = nil;
        self.pos = 0;
        self.lexState = EXPR_NIL;
        self.token = nil;
        self.flagSymbols = [NSDictionary dictionary];
    }
    return self;
}

- (Token *) nextToken {
    //TODO
    return nil;
}

- (Token *) lookahead {
    if (!self.token) {
        self.token = [self nextToken];
    }
    return self.token;
}

- (void) shiftToken {
    self.token = nil;
}

- (NSString *) tokenIdToName:(int)tokenId {
    if (tokenId == 1) {
        return @"T_SPACE";
    } else if (tokenId == 2) {
        return @"T_NIL";
    } else if (tokenId == 3) {
        return @"T_NUMBER";
    } else if (tokenId == 4) {
        return @"T_ATOM";
    } else if (tokenId == 5) {
        return @"T_QUOTED";
    } else if (tokenId == 6) {
        return @"T_LPAR";
    } else if (tokenId == 7) {
        return @"T_RPAR";
    } else if (tokenId == 8) {
        return @"T_BSLASH";
    } else if (tokenId == 9) {
        return @"T_STAR";
    } else if (tokenId == 10) {
        return @"T_LBRA";
    } else if (tokenId == 11) {
        return @"T_RBRA";
    } else if (tokenId == 12) {
        return @"T_LITERAL";
    } else if (tokenId == 13) {
        return @"T_PLUS";
    } else if (tokenId == 14) {
        return @"T_PERCENT";
    } else if (tokenId == 15) {
        return @"T_CRLF";
    } else if (tokenId == 16) {
        return @"T_EOF";
    } else if (tokenId == 17) {
        return @"T_TEXT";
    } else {
        return nil;
    }
}

- (void) parseError:(NSString *)error {
    NSLog(@"str: %@", self.str);
    NSLog(@"pos: %d", self.pos);
    NSLog(@"lexState: %d", self.lexState);
    if (self.token) {
        NSLog(@"token.symbol: %@", [self tokenIdToName:self.token.symbol]);
        NSLog(@"token.value: %@", self.token.value);
    }
    @throw [NSException exceptionWithName:@"ResponseParseError" reason:error userInfo:nil];
}

- (Token *) match:(int)arg {
    Token *aToken = [self lookahead];
    if (arg != aToken.symbol) {
        [self parseError:[NSString stringWithFormat:@"unexpected token %@ (expected %@)", [self tokenIdToName:aToken.symbol], [self tokenIdToName:arg]]];
    }
    [self shiftToken];
    return aToken;
}

- (Token *) matches:(NSArray *)args {
    Token *aToken = [self lookahead];
    if ([args containsObject:[NSNumber numberWithInt:aToken.symbol]]) {
        NSMutableArray *array = [NSMutableArray array];
        for (NSNumber *number in args) {
            [array addObject:[self tokenIdToName:[number intValue]]];
        }
        [self parseError:[NSString stringWithFormat:@"unexpected token %@ (expected %@)",
                          [self tokenIdToName:aToken.symbol],
                          [array componentsJoinedByString:@" or "]]];
    }
    [self shiftToken];
    return aToken;
}

#define MAX_FLAG_COUNT 10000

- (NSArray *) flagList {
    NSMutableArray *flags = [NSMutableArray array];
    NSError *error = NULL;
    NSRegularExpression *bracketRegex = [NSRegularExpression regularExpressionWithPattern:@"\\(([^)]*)\\)"
                                                                                  options:NSRegularExpressionCaseInsensitive error:&error];
    if ([bracketRegex numberOfMatchesInString:self.str options:0 range:NSMakeRange(self.pos, [self.str length])]) {
        NSRange rangeOfFirstMatch = [bracketRegex rangeOfFirstMatchInString:self.str options:0 range:NSMakeRange(self.pos, [self.str length])];
        self.pos = rangeOfFirstMatch.location + rangeOfFirstMatch.length;
        NSString *matchedString = [self.str substringWithRange:rangeOfFirstMatch];
        NSRegularExpression *flagRegex = [NSRegularExpression regularExpressionWithPattern:@"\\\\([^\\x80-\\xff(){ \\x00-\\x1f\\x7f%\"\\\\]+)|([^\\x80-\\xff(){ \\x00-\\x1f\\x7f%*\"\\\\]+)"
                                                                                   options:0 error:&error];
        NSArray *matches = [flagRegex matchesInString:matchedString options:0 range:NSMakeRange(0, [matchedString length])];
        for (NSTextCheckingResult *match in matches) {
            NSRange flagRange = [match rangeAtIndex:1];
            NSRange atomRange = [match rangeAtIndex:2];
            NSString *flag = nil;
            NSString *atom = nil;
            if (!NSEqualRanges(flagRange, NSMakeRange(NSNotFound, 0))) {
                flag = [matchedString substringWithRange:flagRange];
            }
            if (!NSEqualRanges(atomRange, NSMakeRange(NSNotFound, 0))) {
                atom = [matchedString substringWithRange:atomRange];
            }
            if (atom) {
                [flags addObject:atom];
            } else {
                NSString *symbol = [flag uppercaseString];
                [self.flagSymbols setObject:@"YES" forKey:symbol];
                if ([self.flagSymbols count] > MAX_FLAG_COUNT) {
                    @throw [NSException exceptionWithName:@"FlagCountError" reason:@"number of flag symbols exceeded" userInfo:nil];
                }
                [flags addObject:symbol];
            }
        }
        return flags;
    } else {
        [self parseError:@"invalid flag list"];
        return flags;
    }
}

- (NSNumber *) number {
    Token *aToken = [self lookahead];
    if (aToken.symbol == T_NIL) {
        [self shiftToken];
        return nil;
    }
    aToken = [self match:T_NUMBER];
    return [NSNumber numberWithInt:[aToken.value intValue]];
}

- (ResponseCode *) responseTextCode {
    self.lexState = EXPR_BEG;
    [self match:T_LBRA];
    Token *aToken = [self match:T_ATOM];
    NSString *aName = [aToken.value uppercaseString];
    ResponseCode *result = nil;
    NSError *error = NULL;
    NSRegularExpression *nilRegex = [NSRegularExpression regularExpressionWithPattern:@"\\A(?:ALERT|PARSE|READ-ONLY|READ-WRITE|TRYCREATE|NOMODSEQ)\\z" 
                                                                              options:0 error:&error];
    NSRegularExpression *flagRegex = [NSRegularExpression regularExpressionWithPattern:@"\\A(?:PERMANENTFLAGS)\\z"
                                                                               options:0 error:&error];
    NSRegularExpression *numberRegex = [NSRegularExpression regularExpressionWithPattern:@"\\A(?:UIDVALIDITY|UIDNEXT|UNSEEN)\\z"
                                                                                 options:0 error:&error];
    if ([nilRegex numberOfMatchesInString:aName options:0 range:NSMakeRange(0, [aName length])]) {
        result = [[ResponseCode alloc] init];
        result.name = aName;
        result.data = nil;
    } else if ([flagRegex numberOfMatchesInString:aName options:0 range:NSMakeRange(0, [aName length])]) {
        [self match:T_SPACE];
        result = [[ResponseCode alloc] init];
        result.name = aName;
        result.data = [self flagList];
    } else if ([numberRegex numberOfMatchesInString:aName options:0 range:NSMakeRange(0, [aName length])]) {
        [self match:T_SPACE];
        result = [[ResponseCode alloc] init];
        result.name = aName;
        result.data = [self number];
    } else {
        aToken = [self lookahead];
        if (aToken.symbol == T_SPACE) {
            [self shiftToken];
            self.lexState = EXPR_CTEXT;
            aToken = [self match:T_TEXT];
            self.lexState = EXPR_BEG;
            result = [[ResponseCode alloc] init];
            result.name = aName;
            result.data = aToken.value;
        } else {
            result = [[ResponseCode alloc] init];
            result.name = aName;
            result.data = nil;
        }
    }
    [self match:T_RBRA];
    self.lexState = EXPR_RTEXT;
    return [result autorelease];
}

- (ResponseText *) responseText {
    self.lexState = EXPR_RTEXT;
    Token *aToken = [self lookahead];
    ResponseCode *code = nil;
    if (token.symbol == T_LBRA) {
        code = [self responseTextCode];
    }
    aToken = [self match:T_TEXT];
    self.lexState = EXPR_BEG;
    ResponseText *text = [[ResponseText alloc] init];
    text.code = code;
    text.text = aToken.value;
    return [text autorelease];
}

- (ContinuationRequest *) continueReq {
    [self match:T_PLUS];
    [self match:T_SPACE];
    ContinuationRequest *request = [[ContinuationRequest alloc] init];
    request.data = [self responseText];
    request.rawData = self.str;
    return [request autorelease];
}

- (NSArray *) addressList {
    //TODO
    return nil;
}

- (NSString *) string {
    Token *aToken = [self lookahead];
    if (aToken.symbol == T_NIL) {
        [self shiftToken];
        return nil;
    }
    aToken = [self matches:[NSArray arrayWithObjects:[NSNumber numberWithInt:T_QUOTED], [NSNumber numberWithInt:T_LITERAL], nil]];
    return aToken.value;
}

- (NSString *) nString {
    Token *aToken = [self lookahead];
    if (aToken.symbol == T_NIL) {
        [self shiftToken];
        return nil;
    } else {
        return [self string];
    }
}

- (Envelope *) envelope {
    self.lexState = EXPR_DATA;
    Token *aToken = [self lookahead];
    Envelope *result = nil;
    if (aToken.symbol == T_NIL) {
        [self shiftToken];
        result = nil;
    } else {
        [self match:T_LPAR];
        NSString *date = [self nString];
        [self match:T_SPACE];
        NSString *subject = [self nString];
        [self match:T_SPACE];
        NSArray *from = [self addressList];
        [self match:T_SPACE];
        NSArray *sender = [self addressList];
        [self match:T_SPACE];
        NSArray *replyTo = [self addressList];
        [self match:T_SPACE];
        NSArray *to = [self addressList];
        [self match:T_SPACE];
        NSArray *cc = [self addressList];
        [self match:T_SPACE];
        NSArray *bcc = [self addressList];
        [self match:T_SPACE];
        NSString *inReplyTo = [self nString];
        [self match:T_SPACE];
        NSString *messageId = [self nString];
        [self match:T_RPAR];
        result.date = date;
        result.subject = subject;
        result.from = from;
        result.sender = sender;
        result.replyTo = replyTo;
        result.to = to;
        result.cc = cc;
        result.bcc = bcc;
        result.inReplyTo = inReplyTo;
        result.messageId = messageId;
    }
    self.lexState = EXPR_BEG;
    return [result autorelease];
}

- (NSDictionary *) envelopeData {
    Token *aToken = [self match:T_ATOM];
    NSString *aName = [aToken.value uppercaseString];
    [self match:T_SPACE];
    return [NSDictionary dictionaryWithObjects:[NSArray arrayWithObject:[self envelope]] forKeys:[NSArray arrayWithObject:aName]];
}

- (NSDictionary *) flagsData {
    Token *aToken = [self match:T_ATOM];
    NSString *aName = [aToken.value uppercaseString];
    [self match:T_SPACE];
    return [NSDictionary dictionaryWithObjects:[NSArray arrayWithObject:[self flagList]] forKeys:[NSArray arrayWithObject:aName]];
}

- (NSDictionary *) internalDateData {
    Token *aToken = [self match:T_ATOM];
    NSString *aName = [aToken.value uppercaseString];
    [self match:T_SPACE];
    aToken = [self match:T_QUOTED];
    return [NSDictionary dictionaryWithObjects:[NSArray arrayWithObject:aToken.value] forKeys:[NSArray arrayWithObject:aName]];
}

- (NSDictionary *) rfc822Text {
    Token *aToken = [self match:T_ATOM];
    NSString *aName = [aToken.value uppercaseString];
    [self match:T_SPACE];
    return [NSDictionary dictionaryWithObjects:[NSArray arrayWithObject:[self nString]] forKeys:[NSArray arrayWithObject:aName]];
}

- (NSDictionary *) rfc822Size {
    Token *aToken = [self match:T_ATOM];
    NSString *aName = [aToken.value uppercaseString];
    [self match:T_SPACE];
    return [NSDictionary dictionaryWithObjects:[NSArray arrayWithObject:[self number]] forKeys:[NSArray arrayWithObject:aName]];
}

- (NSDictionary *) bodyData {
    //TODO
    return nil;
}

- (NSDictionary *) uidData {
    Token *aToken = [self match:T_ATOM];
    NSString *aName = [aToken.value uppercaseString];
    [self match:T_SPACE];
    return [NSDictionary dictionaryWithObjects:[NSArray arrayWithObject:[self number]] forKeys:[NSArray arrayWithObject:aName]];
}

- (NSDictionary *) msgAtt {
    [self match:T_LPAR];
    NSDictionary *attr = nil;
    while (YES) {
        Token *aToken = [self lookahead];
        switch (aToken.symbol) {
            case T_RPAR: {
                [self shiftToken];
                break;
            }
            case T_SPACE: {
                [self shiftToken];
                aToken = [self lookahead];
            }
        }
        NSError *error = NULL;
        NSRegularExpression *envelopeRegex = [NSRegularExpression regularExpressionWithPattern:@"\\A(?:ENVELOPE)\\z"
                                                                                       options:NSRegularExpressionCaseInsensitive
                                                                                         error:&error];
        NSRegularExpression *flagsRegex = [NSRegularExpression regularExpressionWithPattern:@"\\A(?:FLAGS)\\z"
                                                                                    options:NSRegularExpressionCaseInsensitive
                                                                                      error:&error];
        NSRegularExpression *internalDateRegex = [NSRegularExpression regularExpressionWithPattern:@"\\A(?:INTERNALDATE)\\z"
                                                                                           options:NSRegularExpressionCaseInsensitive
                                                                                             error:&error];
        NSRegularExpression *rfc822TextRegex = [NSRegularExpression regularExpressionWithPattern:@"\\A(?:RFC822(?:\\.HEADER|\\.TEXT)?)\\z"
                                                                                         options:NSRegularExpressionCaseInsensitive
                                                                                           error:&error];
        NSRegularExpression *rfc822SizeRegex = [NSRegularExpression regularExpressionWithPattern:@"\\A(?:RFC822\\.SIZE)\\z"
                                                                                         options:NSRegularExpressionCaseInsensitive
                                                                                           error:&error];
        NSRegularExpression *bodyRegex = [NSRegularExpression regularExpressionWithPattern:@"\\A(?:BODY(?:STRUCTURE)?)\\z"
                                                                                   options:NSRegularExpressionCaseInsensitive
                                                                                     error:&error];
        NSRegularExpression *uidRegex = [NSRegularExpression regularExpressionWithPattern:@"\\A(?:UID)\\z"
                                                                                  options:NSRegularExpressionCaseInsensitive
                                                                                    error:&error];
        if ([envelopeRegex numberOfMatchesInString:aToken.value options:0 range:NSMakeRange(0, [aToken.value length])]) {
            attr = [self envelopeData];
        } else if ([flagsRegex numberOfMatchesInString:aToken.value options:0 range:NSMakeRange(0, [aToken.value length])]) {
            attr = [self flagsData];
        } else if ([internalDateRegex numberOfMatchesInString:aToken.value options:0 range:NSMakeRange(0, [aToken.value length])]) {
            attr = [self internalDateData];
        } else if ([rfc822TextRegex numberOfMatchesInString:aToken.value options:0 range:NSMakeRange(0, [aToken.value length])]) {
            attr = [self rfc822Text];
        } else if ([rfc822SizeRegex numberOfMatchesInString:aToken.value options:0 range:NSMakeRange(0, [aToken.value length])]) {
            attr = [self rfc822Size];
        } else if ([bodyRegex numberOfMatchesInString:aToken.value options:0 range:NSMakeRange(0, [aToken.value length])]) {
            attr = [self bodyData];
        } else if ([uidRegex numberOfMatchesInString:aToken.value options:0 range:NSMakeRange(0, [aToken.value length])]) {
            attr = [self uidData];
        } else {
            [self parseError:[NSString stringWithFormat:@"unknown attribute %@", aToken.value]];
        }
    }
    return attr;
}

- (UntaggedResponse *) numericResponse {
    NSNumber *n = [self number];
    [self match:T_SPACE];
    Token *aToken = [self match:T_ATOM];
    NSString *aName = [aToken.value uppercaseString];
    if ([aName isEqualToString:@"EXISTS"] || [aName isEqualToString:@"RECENT"] || [aName isEqualToString:@"EXPUNGE"]) {
        UntaggedResponse *response = [[UntaggedResponse alloc] init];
        response.name = aName;
        response.data = n;
        response.rawData = self.str;
        return [response autorelease];
    } else if ([aName isEqualToString:@"FETCH"]) {
        [self shiftToken];
        [self match:T_SPACE];
        FetchData *data = [[FetchData alloc] init];
        data.seqno = [n intValue];
        data.attr = [self msgAtt];
        UntaggedResponse *response = [[UntaggedResponse alloc] init];
        response.name = aName;
        response.data = [data autorelease];
        response.rawData = self.str;
        return [response autorelease];
    } else {
        return nil;
    }
}

- (UntaggedResponse *) responseCond {
    Token *aToken = [self match:T_ATOM];
    NSString *aName = [aToken.value uppercaseString];
    [self match:T_SPACE];
    UntaggedResponse *response = [[UntaggedResponse alloc] init];
    response.name = aName;
    response.data = [self responseText];
    response.rawData = self.str;
    return [response autorelease];   
}

- (UntaggedResponse *) flagsResponse {
    Token *aToken = [self match:T_ATOM];
    NSString *aName = [aToken.value uppercaseString];
    [self match:T_SPACE];
    UntaggedResponse *response = [[UntaggedResponse alloc] init];
    response.name = aName;
    response.data = [self flagList];
    response.rawData = self.str;
    return [response autorelease];   
}

- (BOOL) isAtomToken:(Token *)aToken {
    NSArray *atomTokens = [NSArray arrayWithObjects:[NSNumber numberWithInt:T_ATOM], [NSNumber numberWithInt:T_NUMBER], [NSNumber numberWithInt:T_NIL], [NSNumber numberWithInt:T_LBRA], [NSNumber numberWithInt:T_RBRA], [NSNumber numberWithInt:T_PLUS], nil];
    return [atomTokens containsObject:[NSNumber numberWithInt:aToken.symbol]];
}

- (NSString *) atom {
    NSString *result = @"";
    while (YES) {
        Token *aToken = [self lookahead];
        if ([self isAtomToken:aToken]) {
            result = [result stringByAppendingString:aToken.value];
            [self shiftToken];
        } else {
            if ([result isEqualToString:@""]) {
                [self parseError:[NSString stringWithFormat:@"unexpected token %@", [self tokenIdToName:aToken.symbol]]];
            } else {
                return result;
            }
        }
    }
}

- (BOOL) isStringToken:(Token *)aToken {
    NSArray *stringTokens = [NSArray arrayWithObjects:[NSNumber numberWithInt:T_QUOTED],
                             [NSNumber numberWithInt:T_LITERAL],
                             [NSNumber numberWithInt:T_NIL],
                             nil];
    return [stringTokens containsObject:[NSNumber numberWithInt:aToken.symbol]];
}

- (NSString *) aString {
    Token *aToken = [self lookahead];
    if ([self isStringToken:aToken]) {
        return [self string];
    } else {
        return [self atom];
    }
}

- (MailboxList *) mailboxList {
    NSArray *attr = [self flagList];
    [self match:T_SPACE];
    Token *aToken = [self matches:[NSArray arrayWithObjects:[NSNumber numberWithInt:T_QUOTED], [NSNumber numberWithInt:T_NIL], nil]];
    NSString *delim = nil;
    if (aToken.symbol == T_NIL) {
        delim = nil;
    } else {
        delim = aToken.value;
    }
    [self match:T_SPACE];
    NSString *aName = [self aString];
    MailboxList *list = [[MailboxList alloc] init];
    list.attr = attr;
    list.delim = delim;
    list.name = aName;
    return [list autorelease];
}

- (UntaggedResponse *) listResponse {
    Token *aToken = [self match:T_ATOM];
    NSString *aName = [aToken.value uppercaseString];
    [self match:T_SPACE];
    UntaggedResponse *response = [[UntaggedResponse alloc] init];
    response.name = aName;
    response.data = [self mailboxList];
    response.rawData = self.str;
    return [response autorelease];
}

- (UntaggedResponse *) getQuotaResponse {
    //TODO
    return nil;
}

- (UntaggedResponse *) getQuotaRootResponse {
    //TODO
    return nil;
}

- (UntaggedResponse *) getAclResponse {
    //TODO
    return nil;
}

- (UntaggedResponse *) searchResponse {
    //TODO
    return nil;
}

- (UntaggedResponse *) threadResponse {
    //TODO
    return nil;
}

- (UntaggedResponse *) statusResponse {
    //TODO
    return nil;
}

- (UntaggedResponse *) capabilityResponse {
    //TODO
    return nil;
}

- (UntaggedResponse *) textResponse {
    Token *aToken = [self match:T_ATOM];
    NSString *aName = [aToken.value uppercaseString];
    [self match:T_SPACE];
    self.lexState = EXPR_TEXT;
    aToken = [self match:T_TEXT];
    self.lexState = EXPR_BEG;
    UntaggedResponse *response = [[UntaggedResponse alloc] init];
    response.name = aName;
    response.data = aToken.value;
    return [response autorelease];
}

- (UntaggedResponse *) responseUntagged {
    [self match:T_STAR];
    [self match:T_SPACE];
    Token *aToken = [self lookahead];
    if (aToken.symbol == T_NUMBER) {
        return [self numericResponse];
    } else if (aToken.symbol == T_ATOM) {
        NSError *error = NULL;
        NSRegularExpression *condRegex = [NSRegularExpression regularExpressionWithPattern:@"\\A(?:OK|NO|BAD|BYE|PREAUTH)\\z"
                                                                                   options:NSRegularExpressionCaseInsensitive error:&error];
        NSRegularExpression *flagsRegex = [NSRegularExpression regularExpressionWithPattern:@"\\A(?:FLAGS)\\z"
                                                                                    options:NSRegularExpressionCaseInsensitive error:&error];
        NSRegularExpression *listRegex = [NSRegularExpression regularExpressionWithPattern:@"\\A(?:LIST|LSUB)\\z"
                                                                                   options:NSRegularExpressionCaseInsensitive error:&error];
        NSRegularExpression *quotaRegex = [NSRegularExpression regularExpressionWithPattern:@"\\A(?:QUOTA)\\z"
                                                                                   options:NSRegularExpressionCaseInsensitive error:&error];
        NSRegularExpression *quotaRootRegex = [NSRegularExpression regularExpressionWithPattern:@"\\A(?:QUOTAROOT)\\z"
                                                                                    options:NSRegularExpressionCaseInsensitive error:&error];
        NSRegularExpression *aclRegex = [NSRegularExpression regularExpressionWithPattern:@"\\A(?:ACL)\\z"
                                                                                        options:NSRegularExpressionCaseInsensitive error:&error];
        NSRegularExpression *searchRegex = [NSRegularExpression regularExpressionWithPattern:@"\\A(?:SEARCH|SORT)\\z"
                                                                                  options:NSRegularExpressionCaseInsensitive error:&error];
        NSRegularExpression *threadRegex = [NSRegularExpression regularExpressionWithPattern:@"\\A(?:THREAD)\\z"
                                                                                     options:NSRegularExpressionCaseInsensitive error:&error];
        NSRegularExpression *statusRegex = [NSRegularExpression regularExpressionWithPattern:@"\\A(?:STATUS)\\z"
                                                                                     options:NSRegularExpressionCaseInsensitive error:&error];
        NSRegularExpression *capabilityRegex = [NSRegularExpression regularExpressionWithPattern:@"\\A(?:CAPABILITY)\\z"
                                                                                     options:NSRegularExpressionCaseInsensitive error:&error];
        if ([condRegex numberOfMatchesInString:aToken.value options:0 range:NSMakeRange(0, [aToken.value length])]) {
            return [self responseCond];
        } else if ([flagsRegex numberOfMatchesInString:aToken.value options:0 range:NSMakeRange(0, [aToken.value length])]) {
            return [self flagsResponse];
        } else if ([listRegex numberOfMatchesInString:aToken.value options:0 range:NSMakeRange(0, [aToken.value length])]) {
            return [self listResponse];
        } else if ([quotaRegex numberOfMatchesInString:aToken.value options:0 range:NSMakeRange(0, [aToken.value length])]) {
            return [self getQuotaResponse];
        } else if ([quotaRootRegex numberOfMatchesInString:aToken.value options:0 range:NSMakeRange(0, [aToken.value length])]) {
            return [self getQuotaRootResponse];
        } else if ([aclRegex numberOfMatchesInString:aToken.value options:0 range:NSMakeRange(0, [aToken.value length])]) {
            return [self getAclResponse];
        } else if ([searchRegex numberOfMatchesInString:aToken.value options:0 range:NSMakeRange(0, [aToken.value length])]) {
            return [self searchResponse];
        } else if ([threadRegex numberOfMatchesInString:aToken.value options:0 range:NSMakeRange(0, [aToken.value length])]) {
            return [self threadResponse];
        } else if ([statusRegex numberOfMatchesInString:aToken.value options:0 range:NSMakeRange(0, [aToken.value length])]) {
            return [self statusResponse];
        } else if ([capabilityRegex numberOfMatchesInString:aToken.value options:0 range:NSMakeRange(0, [aToken.value length])]) {
            return [self capabilityResponse];
        } else {
            return [self textResponse];
        }
    } else {
        [self parseError:[NSString stringWithFormat:@"unexpected token %@", aToken.symbol]];
        return nil;
    }
}

- (TaggedResponse *) responseTagged {
    NSString *tag = [self atom];
    [self match:T_SPACE];
    Token *aToken = [self match:T_ATOM];
    NSString *name = [aToken.value uppercaseString];
    [self match:T_SPACE];
    TaggedResponse *response = [[TaggedResponse alloc] init];
    response.tag = tag;
    response.name = name;
    response.data = [self responseText];
    response.rawData = self.str;
    return [response autorelease];
}

- (id) response {
    Token *aToken = [self lookahead];
    id result = nil;
    switch (aToken.symbol) {
        case T_PLUS: {
            result = [self continueReq];
            break;
        }
        case T_STAR: {
            result = [self responseUntagged];
            break;
        }
        default: {
            result = [self responseTagged];
            break;
        }
    }
    [self match:T_CRLF];
    [self match:T_EOF];
    return result;
}

- (id) parse:(NSString *)someString {
    self.str = someString;
    self.pos = 0;
    self.lexState = EXPR_BEG;
    self.token = nil;
    return [self response];
}

@end