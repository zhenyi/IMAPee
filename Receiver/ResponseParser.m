//
//  ResponseParser.m
//  Receiver
//
//  Created by Zhenyi Tan on 5/25/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import "ResponseParser.h"

@interface ResponseParser()
- (Token *) nextToken;
- (id) body;
- (NSArray *) bodyExtentions;
@end

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
        self.flagSymbols = [NSMutableDictionary dictionary];
    }
    return self;
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
    if (![args containsObject:[NSNumber numberWithInt:aToken.symbol]]) {
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
    if ([bracketRegex numberOfMatchesInString:self.str options:0 range:NSMakeRange(self.pos, [self.str length] - self.pos)]) {
        NSRange rangeOfFirstMatch = [bracketRegex rangeOfFirstMatchInString:self.str options:0 range:NSMakeRange(self.pos, [self.str length] - self.pos)];
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

- (NSString *) string {
    Token *aToken = [self lookahead];
    if (aToken.symbol == T_NIL) {
        [self shiftToken];
        return nil;
    }
    aToken = [self matches:[NSArray arrayWithObjects:[NSNumber numberWithInt:T_QUOTED], [NSNumber numberWithInt:T_LITERAL], nil]];
    return aToken.value;
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

- (NSString *) nString {
    Token *aToken = [self lookahead];
    if (aToken.symbol == T_NIL) {
        [self shiftToken];
        return nil;
    } else {
        return [self string];
    }
}

- (Address *) address {
    [self match:T_LPAR];
    NSError *error = NULL;
    NSRegularExpression *addressRegex = [NSRegularExpression regularExpressionWithPattern:@"\\G(?:NIL|\"((?:[^\\x80-\\xff\\x00\\r\\n\"\\\\]|\\\\[\"\\\\])*)\") (?:NIL|\"((?:[^\\x80-\\xff\\x00\\r\\n\"\\\\]|\\\\[\"\\\\])*)\") (?:NIL|\"((?:[^\\x80-\\xff\\x00\\r\\n\"\\\\]|\\\\[\"\\\\])*)\") (?:NIL|\"((?:[^\\x80-\\xff\\x00\\r\\n\"\\\\]|\\\\[\"\\\\])*)\")\\)"
                                                                                  options:NSRegularExpressionCaseInsensitive
                                                                                    error:&error];
    NSTextCheckingResult *match = [addressRegex firstMatchInString:self.str options:0 range:NSMakeRange(self.pos, [self.str length] - self.pos)];
    NSString *aName = nil;
    NSString *aRoute = nil;
    NSString *aMailbox = nil;
    NSString *aHost = nil;
    if (match) {
        self.pos = match.range.location + match.range.length;
        NSRegularExpression *slashRegex = [NSRegularExpression regularExpressionWithPattern:@"\\\\([\"\\\\])"
                                                                                    options:0
                                                                                      error:&error];
        NSRange nameRange = [match rangeAtIndex:1];
        NSRange routeRange = [match rangeAtIndex:2];
        NSRange mailboxRange = [match rangeAtIndex:3];
        NSRange hostRange = [match rangeAtIndex:4];
        if (!NSEqualRanges(nameRange, NSMakeRange(NSNotFound, 0))) {
            aName = [self.str substringWithRange:nameRange];
            aName = [slashRegex stringByReplacingMatchesInString:aName options:0 range:NSMakeRange(0, [aName length]) withTemplate:@"$1"];
        }
        if (!NSEqualRanges(routeRange, NSMakeRange(NSNotFound, 0))) {
            aRoute = [self.str substringWithRange:routeRange];
            aRoute = [slashRegex stringByReplacingMatchesInString:aRoute options:0 range:NSMakeRange(0, [aRoute length]) withTemplate:@"$1"];
        }
        if (!NSEqualRanges(mailboxRange, NSMakeRange(NSNotFound, 0))) {
            aMailbox = [self.str substringWithRange:mailboxRange];
            aMailbox = [slashRegex stringByReplacingMatchesInString:aMailbox options:0 range:NSMakeRange(0, [aMailbox length]) withTemplate:@"$1"];
        }
        if (!NSEqualRanges(hostRange, NSMakeRange(NSNotFound, 0))) {
            aHost = [self.str substringWithRange:hostRange];
            aHost = [slashRegex stringByReplacingMatchesInString:aHost options:0 range:NSMakeRange(0, [aHost length]) withTemplate:@"$1"];
        }
    } else {
        aName = [self nString];
        [self match:T_SPACE];
        aRoute = [self nString];
        [self match:T_SPACE];
        aMailbox = [self nString];
        [self match:T_SPACE];
        aHost = [self nString];
        [self match:T_RPAR];
    }
    Address *someAddress = [[Address alloc] init];
    someAddress.name = aName;
    someAddress.route = aRoute;
    someAddress.mailbox = aMailbox;
    someAddress.host = aHost;
    return [someAddress autorelease];
}

- (NSArray *) addressList {
    Token *aToken = [self lookahead];
    if (aToken.symbol == T_NIL) {
        [self shiftToken];
        return nil;
    } else {
        NSMutableArray *result = [NSMutableArray array];
        [self match:T_LPAR];
        BOOL goOn = YES;
        while (goOn) {
            aToken = [self lookahead];
            switch (aToken.symbol) {
                case T_RPAR: {
                    [self shiftToken];
                    goOn = NO;
                    break;
                }
                case T_SPACE: {
                    [self shiftToken];
                    break;
                }
            }
            if (goOn) {
                [result addObject:[self address]];
            }
        }
        return result;
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

- (NSString *) formatString:(NSString *)someString {
    if ([someString isEqualToString:@""]) {
        return @"\"\"";
    } else {
        NSError *error = NULL;
        NSRegularExpression *literalRegex = [NSRegularExpression regularExpressionWithPattern:@"[\\x80-\\xff\\r\\n]"
                                                                                      options:0
                                                                                        error:&error];
        NSRegularExpression *quotedRegex = [NSRegularExpression regularExpressionWithPattern:@"[(){ \\x00-\\x1f\\x7f%*\"\\\\]"
                                                                                     options:0
                                                                                       error:&error];
        if ([literalRegex numberOfMatchesInString:someString options:0 range:NSMakeRange(0, [someString length])]) {
            return [NSString stringWithFormat:@"{%d}\r\n%@", [someString length], someString];
        } else if ([quotedRegex numberOfMatchesInString:someString options:0 range:NSMakeRange(0, [someString length])]) {
            NSRegularExpression *slashRegex = [NSRegularExpression regularExpressionWithPattern:@"([\"\\\\])"
                                                                                        options:0
                                                                                          error:&error];
            NSString *quotedString = [slashRegex stringByReplacingMatchesInString:someString
                                                                          options:0
                                                                            range:NSMakeRange(0, [someString length])
                                                                     withTemplate:@"\\\\$1"];
            return [NSString stringWithFormat:@"\"%@\"", quotedString];
        } else {
            return someString;
        }
    }
}

- (NSString *) section {
    NSMutableString *someString = [NSMutableString string];
    Token *aToken = [self match:T_LBRA];
    [someString appendString:aToken.value];
    aToken = [self matches:[NSArray arrayWithObjects:[NSNumber numberWithInt:T_ATOM],
                            [NSNumber numberWithInt:T_NUMBER],
                            [NSNumber numberWithInt:T_RBRA],
                            nil]];
    if (aToken.symbol == T_RBRA) {
        [someString appendString:aToken.value];
        return someString;
    }
    [someString appendString:aToken.value];
    aToken = [self lookahead];
    if (aToken.symbol == T_SPACE) {
        [self shiftToken];
        [someString appendString:aToken.value];
        aToken = [self match:T_LPAR];
        [someString appendString:aToken.value];
        BOOL goOn = YES;
        while (goOn) {
            aToken = [self lookahead];
            switch (aToken.symbol) {
                case T_RPAR: {
                    [someString appendString:aToken.value];
                    [self shiftToken];
                    goOn = NO;
                    break;
                }
                case T_SPACE: {
                    [self shiftToken];
                    [someString appendString:aToken.value];
                    break;
                }
            }
            if (goOn) {
                [someString appendString:[self formatString:[self aString]]];
            }
        }
    }
    aToken = [self match:T_RBRA];
    [someString appendString:aToken.value];
    return someString;
}

- (NSString *) caseInsensitiveString {
    Token *aToken = [self lookahead];
    if (aToken.symbol == T_NIL) {
        [self shiftToken];
        return nil;
    }
    aToken = [self matches:[NSArray arrayWithObjects:[NSNumber numberWithInt:T_QUOTED], [NSNumber numberWithInt:T_LITERAL], nil]];
    return [aToken.value uppercaseString];
}

- (NSArray *) mediaType {
    NSString *mType = [self caseInsensitiveString];
    [self match:T_SPACE];
    NSString *mSubType = [self caseInsensitiveString];
    return [NSArray arrayWithObjects:mType, mSubType, nil];
}

- (NSDictionary *) bodyFldParam {
    Token *aToken = [self lookahead];
    if (aToken.symbol == T_NIL) {
        [self shiftToken];
        return nil;
    }
    [self match:T_LPAR];
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    BOOL goOn = YES;
    while (goOn) {
        aToken = [self lookahead];
        switch (aToken.symbol) {
            case T_RPAR: {
                [self shiftToken];
                goOn = NO;
                break;
            }
            case T_SPACE: {
                [self shiftToken];
                break;
            }
        }
        if (goOn) {
            NSString *aName = [self caseInsensitiveString];
            [self match:T_SPACE];
            NSString *aVal = [self string];
            [param setObject:aVal forKey:aName];
        }
    }
    return param;
}

- (NSArray *) bodyFields {
    NSDictionary *param = [self bodyFldParam];
    [self match:T_SPACE];
    NSString *contentId = [self nString];
    [self match:T_SPACE];
    NSString *desc = [self nString];
    [self match:T_SPACE];
    NSString *enc = [self caseInsensitiveString];
    [self match:T_SPACE];
    NSNumber *size = [self number];
    return [NSArray arrayWithObjects:param, contentId, desc, enc, size, nil];
}

- (ContentDisposition *) bodyFldDsp {
    Token *aToken = [self lookahead];
    if (aToken.symbol == T_NIL) {
        [self shiftToken];
        return nil;
    }
    [self match:T_LPAR];
    NSString *dspType = [self caseInsensitiveString];
    [self match:T_SPACE];
    NSDictionary *param = [self bodyFldParam];
    [self match:T_RPAR];
    ContentDisposition *disposition = [[ContentDisposition alloc] init];
    disposition.dspType = dspType;
    disposition.param = param;
    return [disposition autorelease];
}

- (NSArray *) bodyFldLang {
    Token *aToken = [self lookahead];
    if (aToken.symbol == T_LPAR) {
        [self shiftToken];
        NSMutableArray *result = [NSMutableArray array];
        while (YES) {
            aToken = [self lookahead];
            switch (aToken.symbol) {
                case T_RPAR: {
                    [self shiftToken];
                    return result;
                }
                case T_SPACE: {
                    [self shiftToken];
                    break;
                }
            }
            [result addObject:[self caseInsensitiveString]];
        }
    } else {
        NSString *lang = [self nString];
        if (lang) {
            return [NSArray arrayWithObject:[lang uppercaseString]];
        } else {
            return nil;
        }
    }
}

- (id) bodyExtention {
    Token *aToken = [self lookahead];
    switch (aToken.symbol) {
        case T_LPAR: {
            [self shiftToken];
            NSArray *result = [self bodyExtentions];
            [self match:T_RPAR];
            return result;
        }
        case T_NUMBER: {
            return [self number];
        }            
        default: {
            return [self nString];
        }
    }
}

- (NSArray *) bodyExtentions {
    NSMutableArray *result = [NSMutableArray array];
    Token *aToken = nil;
    while (YES) {
        aToken = [self lookahead];
        switch (aToken.symbol) {
            case T_RPAR: {
                return result;
            }
            case T_SPACE: {
                [self shiftToken];
                break;
            }
        }
        [result addObject:[self bodyExtention]];
    }
}

- (NSArray *) bodyExt1Part {
    Token *aToken = [self lookahead];
    if (aToken.symbol == T_SPACE) {
        [self shiftToken];
    } else {
        return nil;
    }
    NSString *md5 = [self nString];
    aToken = [self lookahead];
    if (aToken.symbol == T_SPACE) {
        [self shiftToken];
    } else {
        return [NSArray arrayWithObject:md5];
    }
    ContentDisposition *disposition = [self bodyFldDsp];
    aToken = [self lookahead];
    if (aToken.symbol == T_SPACE) {
        [self shiftToken];
    } else {
        return [NSArray arrayWithObjects:md5, disposition, nil];
    }
    NSArray *languages = [self bodyFldLang];
    aToken = [self lookahead];
    if (aToken.symbol == T_SPACE) {
        [self shiftToken];
    } else {
        return [NSArray arrayWithObjects:md5, disposition, languages, nil];
    }
    NSArray *extentions = [self bodyExtentions];
    return [NSArray arrayWithObjects:md5, disposition, languages, extentions, nil];
}

- (BodyTypeText *) bodyTypeText {
    NSArray *mediaType = [self mediaType];
    NSString *mType = [mediaType objectAtIndex:0];
    NSString *mSubType = [mediaType objectAtIndex:1];
    [self match:T_SPACE];
    NSArray *bodyFields = [self bodyFields];
    NSDictionary *param = [bodyFields objectAtIndex:0];
    NSString *contentId = [bodyFields objectAtIndex:1];
    NSString *desc = [bodyFields objectAtIndex:2];
    NSString *enc = [bodyFields objectAtIndex:3];
    NSNumber *size = [bodyFields objectAtIndex:4];
    [self match:T_SPACE];
    NSNumber *lines = [self number];
    NSArray *ext1Part = [self bodyExt1Part];
    NSString *md5 = nil;
    ContentDisposition *disposition = nil;
    NSArray *languages = nil;
    NSArray *extentions = nil;
    if ([ext1Part count] > 0) {
        md5 = [ext1Part objectAtIndex:0];
    }
    if ([ext1Part count] > 1) {
        disposition = [ext1Part objectAtIndex:1];
    }
    if ([ext1Part count] > 2) {
        languages = [ext1Part objectAtIndex:2];
    }
    if ([ext1Part count] > 3) {
        extentions = [ext1Part objectAtIndex:3];
    }
    return [[[BodyTypeText alloc] initWithMediaType:mType subtype:mSubType param:param contentId:contentId description:desc encoding:enc size:size lines:lines MD5:md5 disposition:disposition languages:languages extentions:extentions] autorelease];
}

- (BodyTypeMessage *) bodyTypeMessage {
    NSArray *mediaType = [self mediaType];
    NSString *mType = [mediaType objectAtIndex:0];
    NSString *mSubType = [mediaType objectAtIndex:1];
    [self match:T_SPACE];
    NSArray *bodyFields = [self bodyFields];
    NSDictionary *param = [bodyFields objectAtIndex:0];
    NSString *contentId = [bodyFields objectAtIndex:1];
    NSString *desc = [bodyFields objectAtIndex:2];
    NSString *enc = [bodyFields objectAtIndex:3];
    NSNumber *size = [bodyFields objectAtIndex:4];
    [self match:T_SPACE];
    Envelope *env = [self envelope];
    [self match:T_SPACE];
    id b = [self body];
    [self match:T_SPACE];
    NSNumber *lines = [self number];
    NSArray *ext1Part = [self bodyExt1Part];
    NSString *md5 = nil;
    ContentDisposition *disposition = nil;
    NSArray *languages = nil;
    NSArray *extentions = nil;
    if ([ext1Part count] > 0) {
        md5 = [ext1Part objectAtIndex:0];
    }
    if ([ext1Part count] > 1) {
        disposition = [ext1Part objectAtIndex:1];
    }
    if ([ext1Part count] > 2) {
        languages = [ext1Part objectAtIndex:2];
    }
    if ([ext1Part count] > 3) {
        extentions = [ext1Part objectAtIndex:3];
    }
    return [[[BodyTypeMessage alloc] initWithMediaType:mType subtype:mSubType param:param contentId:contentId description:desc encoding:enc size:size envelope:env body:b lines:lines MD5:md5 disposition:disposition languages:languages extentions:extentions] autorelease];
}

- (BodyTypeBasic *) bodyTypeBasic {
    NSArray *mediaType = [self mediaType];
    NSString *mType = [mediaType objectAtIndex:0];
    NSString *mSubType = [mediaType objectAtIndex:1];
    Token *aToken = [self lookahead];
    if (aToken.symbol == T_RPAR) {
        return [[[BodyTypeBasic alloc] initWithMediaType:mType subtype:mSubType] autorelease];
    }
    [self match:T_SPACE];
    NSArray *bodyFields = [self bodyFields];
    NSDictionary *param = [bodyFields objectAtIndex:0];
    NSString *contentId = [bodyFields objectAtIndex:1];
    NSString *desc = [bodyFields objectAtIndex:2];
    NSString *enc = [bodyFields objectAtIndex:3];
    NSNumber *size = [bodyFields objectAtIndex:4];
    NSArray *ext1Part = [self bodyExt1Part];
    NSString *md5 = nil;
    ContentDisposition *disposition = nil;
    NSArray *languages = nil;
    NSArray *extentions = nil;
    if ([ext1Part count] > 0) {
        md5 = [ext1Part objectAtIndex:0];
    }
    if ([ext1Part count] > 1) {
        disposition = [ext1Part objectAtIndex:1];
    }
    if ([ext1Part count] > 2) {
        languages = [ext1Part objectAtIndex:2];
    }
    if ([ext1Part count] > 3) {
        extentions = [ext1Part objectAtIndex:3];
    }
    return [[[BodyTypeBasic alloc] initWithMediaType:mType subtype:mSubType param:param contentId:contentId description:desc encoding:enc size:size MD5:md5 disposition:disposition languages:languages extentions:extentions] autorelease];
}

- (id) bodyType1Part {
    Token *aToken = [self lookahead];
    NSError *error = NULL;
    NSRegularExpression *textRegex = [NSRegularExpression regularExpressionWithPattern:@"\\A(?:TEXT)\\z"
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:&error];
    NSRegularExpression *messageRegex = [NSRegularExpression regularExpressionWithPattern:@"\\A(?:MESSAGE)\\z"
                                                                              options:NSRegularExpressionCaseInsensitive
                                                                                error:&error];
    if ([textRegex numberOfMatchesInString:aToken.value options:0 range:NSMakeRange(0, [aToken.value length])]) {
        return [self bodyTypeText];
    } else if ([messageRegex numberOfMatchesInString:aToken.value options:0 range:NSMakeRange(0, [aToken.value length])]) {
        return [self bodyTypeMessage];
    } else {
        return [self bodyTypeBasic];
    }
}

- (NSArray *) bodyExtMPart {
    Token *aToken = [self lookahead];
    if (aToken.symbol == T_SPACE) {
        [self shiftToken];
    } else {
        return nil;
    }
    NSDictionary *param = [self bodyFldParam];
    aToken = [self lookahead];
    if (aToken.symbol == T_SPACE) {
        [self shiftToken];
    } else {
        return [NSArray arrayWithObject:param];
    }
    ContentDisposition *disposition = [self bodyFldDsp];
    [self match:T_SPACE];
    NSArray *languages = [self bodyFldLang];
    aToken = [self lookahead];
    if (aToken.symbol == T_SPACE) {
        [self shiftToken];
    } else {
        return [NSArray arrayWithObjects:param, disposition, languages, nil];
    }
    NSArray *extentions = [self bodyExtentions];
    return [NSArray arrayWithObjects:param, disposition, languages, extentions, nil];
}

- (BodyTypeMultipart *) bodyTypeMPart {
    NSMutableArray *parts = [NSMutableArray array];
    Token *aToken = nil;
    BOOL goOn = YES;
    while (goOn) {
        aToken = [self lookahead];
        if (aToken.symbol == T_SPACE) {
            [self shiftToken];
            goOn = NO;
        }
        if (goOn) {
            [parts addObject:[self body]];
        }
    }
    NSString *mType = @"MULTIPART";
    NSString *mSubType = [self caseInsensitiveString];
    NSArray *extArray = [self bodyExtMPart];
    NSDictionary *param = [extArray objectAtIndex:0];
    ContentDisposition *disposition = nil;
    NSArray *languages = nil;
    NSArray *extentions = nil;
    if ([extArray count] > 2) {
        disposition = [extArray objectAtIndex:1];
        languages = [extArray objectAtIndex:2];
    }
    if ([extArray count] > 3) {
        extentions = [extArray objectAtIndex:3];
    }
    return [[[BodyTypeMultipart alloc] initWithMediaType:mType subtype:mSubType parts:parts param:param disposition:disposition languages:languages extentions:extentions] autorelease];
}

- (id) body {
    self.lexState = EXPR_DATA;
    Token *aToken = [self lookahead];
    id result = nil;
    if (aToken.symbol == T_NIL) {
        [self shiftToken];
        result = nil;
    } else {
        [self match:T_LPAR];
        aToken = [self lookahead];
        if (aToken.symbol == T_LPAR) {
            result = [self bodyTypeMPart];
        } else {
            result = [self bodyType1Part];
        }
        [self match:T_RPAR];
    }
    self.lexState = EXPR_BEG;
    return result;
}

- (NSDictionary *) bodyData {
    Token *aToken = [self match:T_ATOM];
    NSString *aName = [aToken.value uppercaseString];
    aToken = [self lookahead];
    if (aToken.symbol == T_SPACE) {
        [self shiftToken];
        return [NSDictionary dictionaryWithObjects:[NSArray arrayWithObject:[self body]] forKeys:[NSArray arrayWithObject:aName]];
    }
    aName = [aName stringByAppendingString:[self section]];
    aToken = [self lookahead];
    if (aToken.symbol == T_ATOM) {
        aName = [aName stringByAppendingString:aToken.value];
        [self shiftToken];
    }
    [self match:T_SPACE];
    NSString *data = [self nString];
    return [NSDictionary dictionaryWithObjects:[NSArray arrayWithObject:data] forKeys:[NSArray arrayWithObject:aName]];
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
    BOOL goOn = YES;
    while (goOn) {
        Token *aToken = [self lookahead];
        switch (aToken.symbol) {
            case T_RPAR: {
                [self shiftToken];
                goOn = NO;
                break;
            }
            case T_SPACE: {
                [self shiftToken];
                aToken = [self lookahead];
                break;
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
    Token *aToken = [self match:T_ATOM];
    NSString *aName = [aToken.value uppercaseString];
    [self match:T_SPACE];
    NSString *mailbox = [self aString];
    [self match:T_SPACE];
    [self match:T_LPAR];
    aToken = [self lookahead];
    switch (aToken.symbol) {
        case T_RPAR: {
            [self shiftToken];
            MailboxQuota *data = [[MailboxQuota alloc] init];
            data.mailbox = mailbox;
            UntaggedResponse *response = [[UntaggedResponse alloc] init];
            response.name = aName;
            response.data = data;
            [data release];
            response.rawData = self.str;
            return [response autorelease];
        }
        case T_ATOM: {
            [self shiftToken];
            [self match:T_SPACE];
            aToken = [self match:T_NUMBER];
            NSString *usage = aToken.value;
            [self match:T_SPACE];
            aToken = [self match:T_NUMBER];
            NSString *quota = aToken.value;
            [self match:T_RPAR];
            MailboxQuota *data = [[MailboxQuota alloc] init];
            data.mailbox = mailbox;
            data.usage = [usage intValue];
            data.quota = [quota intValue];
            UntaggedResponse *response = [[UntaggedResponse alloc] init];
            response.name = aName;
            response.data = data;
            [data release];
            response.rawData = self.str;
            return [response autorelease];
        }
        default: {
            [self parseError:[NSString stringWithFormat:@"unexpected token %@", [self tokenIdToName:aToken.symbol]]];
            return nil;
        }
    }
}

- (UntaggedResponse *) getQuotaRootResponse {
    Token *aToken = [self match:T_ATOM];
    NSString *aName = [aToken.value uppercaseString];
    [self match:T_SPACE];
    NSString *mailbox = [self aString];
    NSMutableArray *quotaRoots = [NSMutableArray array];
    BOOL goOn = YES;
    while (goOn) {
        token = [self lookahead];
        if (aToken.symbol != T_SPACE) {
            goOn = NO;
        }
        if (goOn) {
            [self shiftToken];
            [quotaRoots addObject:[self aString]];
        }
    }
    MailboxQuotaRoot *data = [[MailboxQuotaRoot alloc] init];
    data.mailbox = mailbox;
    data.quotaRoots = quotaRoots;
    UntaggedResponse *response = [[UntaggedResponse alloc] init];
    response.name = aName;
    response.data = data;
    [data release];
    response.rawData = self.str;
    return [response autorelease];
}

- (UntaggedResponse *) getAclResponse {
    Token *aToken = [self match:T_ATOM];
    NSString *aName = [aToken.value uppercaseString];
    [self match:T_SPACE];
    // NSString *mailbox = [self aString];
    [self aString];
    NSMutableArray *data = [NSMutableArray array];
    aToken = [self lookahead];
    if (aToken.symbol == T_SPACE) {
        [self shiftToken];
        BOOL goOn = YES;
        while (goOn) {
            aToken = [self lookahead];
            switch (aToken.symbol) {
                case T_CRLF: {
                    goOn = NO;
                    break;
                }
                case T_SPACE: {
                    [self shiftToken];
                    break;
                }
            }
            if (goOn) {
                NSString *user = [self aString];
                [self match:T_SPACE];
                NSString *rights = [self aString];
                MailboxACLItem *aclItem = [[MailboxACLItem alloc] init];
                aclItem.user = user;
                aclItem.rights = rights;
                [data addObject:aclItem];
                [aclItem release];
            }
        }
    }
    UntaggedResponse *response = [[UntaggedResponse alloc] init];
    response.name = aName;
    response.data = data;
    response.rawData = self.str;
    return [response autorelease];
}

- (UntaggedResponse *) searchResponse {
    Token *aToken = [self match:T_ATOM];
    NSString *aName = [aToken.value uppercaseString];
    aToken = [self lookahead];
    NSMutableArray *data = [NSMutableArray array];
    if (aToken.symbol == T_SPACE) {
        [self shiftToken];
        BOOL goOn = YES;
        while (goOn) {
            aToken = [self lookahead];
            switch (aToken.symbol) {
                case T_CRLF: {
                    goOn = NO;
                    break;
                }
                case T_SPACE: {
                    [self shiftToken];
                    break;
                }
            }
            if (goOn) {
                [data addObject:[self number]];
            }
        }
    }
    UntaggedResponse *response = [[UntaggedResponse alloc] init];
    response.name = aName;
    response.data = data;
    response.rawData = self.str;
    return [response autorelease];
}

- (ThreadMember *) threadBranch:(Token *)aToken {
    ThreadMember *rootMember = nil;
    ThreadMember *lastMember = nil;
    BOOL goOn = YES;
    while (goOn) {
        [self shiftToken];
        aToken = [self lookahead];
        switch (aToken.symbol) {
            case T_NUMBER: {
                ThreadMember *newMember = [[ThreadMember alloc] init];
                newMember.seqno = [[self number] intValue];
                newMember.children = [NSMutableArray array];
                if (rootMember == nil) {
                    rootMember = newMember;
                } else {
                    [lastMember.children addObject:newMember];
                }
                lastMember = newMember;
                break;
            }
            case T_SPACE: {
                break;
            }
            case T_LPAR: {
                if (rootMember == nil) {
                    ThreadMember *dummyMember = [[ThreadMember alloc] init];
                    dummyMember.seqno = 0;
                    dummyMember.children = [NSMutableArray array];
                    lastMember = rootMember = dummyMember;
                }
                [lastMember.children addObject:[self threadBranch:aToken]];
                break;
            }
            case T_RPAR: {
                goOn = NO;
                break;
            }
        }
    }
    return [rootMember autorelease];
}

- (UntaggedResponse *) threadResponse {
    Token *aToken = [self match:T_ATOM];
    NSString *aName = [aToken.value uppercaseString];
    aToken = [self lookahead];
    NSMutableArray *threads = [NSMutableArray array];
    if (aToken.symbol == T_SPACE) {
        BOOL goOn = YES;
        while (goOn) {
            [self shiftToken];
            aToken = [self lookahead];
            switch (aToken.symbol) {
                case T_LPAR: {
                    [threads addObject:[self threadBranch:aToken]];
                    break;
                }
                case T_CRLF: {
                    goOn = NO;
                    break;
                }
            }
        }
    }
    UntaggedResponse *response = [[UntaggedResponse alloc] init];
    response.name = aName;
    response.data = threads;
    response.rawData = self.str;
    return [response autorelease];
}

- (UntaggedResponse *) statusResponse {
    Token *aToken = [self match:T_ATOM];
    NSString *aName = [aToken.value uppercaseString];
    [self match:T_SPACE];
    NSString *mailbox = [self aString];
    [self match:T_SPACE];
    [self match:T_LPAR];
    NSMutableDictionary *attr = [NSMutableDictionary dictionary];
    BOOL goOn = YES;
    while (goOn) {
        aToken = [self lookahead];
        switch (aToken.symbol) {
            case T_RPAR: {
                [self shiftToken];
                goOn = NO;
                break;
            }
            case T_SPACE: {
                [self shiftToken];
                break;
            }
        }
        if (goOn) {
            aToken = [self match:T_ATOM];
            NSString *key = [aToken.value uppercaseString];
            [self match:T_SPACE];
            NSNumber *val = [self number];
            [attr setObject:val forKey:key];
        }
    }
    StatusData *data = [[StatusData alloc] init];
    data.mailbox = mailbox;
    data.attr = attr;
    UntaggedResponse *response = [[UntaggedResponse alloc] init];
    response.name = aName;
    response.data = data;
    [data release];
    response.rawData = self.str;
    return [response autorelease];
}

- (UntaggedResponse *) capabilityResponse {
    Token *aToken = [self match:T_ATOM];
    NSString *aName = [aToken.value uppercaseString];
    [self match:T_SPACE];
    NSMutableArray *data = [NSMutableArray array];
    BOOL goOn = YES;
    while (goOn) {
        aToken = [self lookahead];
        switch (aToken.symbol) {
            case T_CRLF: {
                goOn = NO;
                break;
            }
            case T_SPACE: {
                [self shiftToken];
                break;
            }
        }
        if (goOn) {
            [data addObject:[[self atom] uppercaseString]];
        }
    }
    UntaggedResponse *response = [[UntaggedResponse alloc] init];
    response.name = aName;
    response.data = data;
    response.rawData = self.str;
    return [response autorelease];
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
        [self parseError:[NSString stringWithFormat:@"unexpected token %@", [self tokenIdToName:aToken.symbol]]];
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

- (Token *) tokenForBeg {
    NSError *error = NULL;
    NSRegularExpression *begRegex = [NSRegularExpression regularExpressionWithPattern:@"\\G(?:( +)|(NIL)(?=[\\x80-\\xff(){ \\x00-\\x1f\\x7f%*\"\\\\\\[\\]+])|(\\d+)(?=[\\x80-\\xff(){ \\x00-\\x1f\\x7f%*\"\\\\\\[\\]+])|([^\\x80-\\xff(){ \\x00-\\x1f\\x7f%*\"\\\\\\[\\]+]+)|\"((?:[^\\x00\\r\\n\"\\\\]|\\\\[\"\\\\])*)\"|(\\()|(\\))|(\\\\)|(\\*)|(\\[)|(\\])|\\{(\\d+)\\}\\r\\n|(\\+)|(%)|(\\r\\n)|(\\z))"
                                                                                  options:NSRegularExpressionCaseInsensitive
                                                                                    error:&error];
    NSTextCheckingResult *match = [begRegex firstMatchInString:self.str
                                                       options:0
                                                         range:NSMakeRange(self.pos, [self.str length] - self.pos)];
    NSString *spaceString = nil;
    NSString *nilString = nil;
    NSString *numberString = nil;
    NSString *atomString = nil;
    NSString *quotedString = nil;
    NSString *lparString = nil;
    NSString *rparString = nil;
    NSString *bslashString = nil;
    NSString *starString = nil;
    NSString *lbraString = nil;
    NSString *rbraString = nil;
    NSString *literalString = nil;
    NSString *plusString = nil;
    NSString *percentString = nil;
    NSString *crlfString = nil;
    NSString *eofString = nil;
    if (match) {
        self.pos = match.range.location + match.range.length;
        NSRange spaceRange = [match rangeAtIndex:1];
        NSRange nilRange = [match rangeAtIndex:2];
        NSRange numberRange = [match rangeAtIndex:3];
        NSRange atomRange = [match rangeAtIndex:4];
        NSRange quotedRange = [match rangeAtIndex:5];
        NSRange lparRange = [match rangeAtIndex:6];
        NSRange rparRange = [match rangeAtIndex:7];
        NSRange bslashRange = [match rangeAtIndex:8];
        NSRange starRange = [match rangeAtIndex:9];
        NSRange lbraRange = [match rangeAtIndex:10];
        NSRange rbraRange = [match rangeAtIndex:11];
        NSRange literalRange = [match rangeAtIndex:12];
        NSRange plusRange = [match rangeAtIndex:13];
        NSRange percentRange = [match rangeAtIndex:14];
        NSRange crlfRange = [match rangeAtIndex:15];
        NSRange eofRange = [match rangeAtIndex:16];
        int numberOfRanges = 0;
        if (!NSEqualRanges(spaceRange, NSMakeRange(NSNotFound, 0))) {
            spaceString = [self.str substringWithRange:spaceRange];
            numberOfRanges++;
        }
        if (!NSEqualRanges(nilRange, NSMakeRange(NSNotFound, 0))) {
            nilString = [self.str substringWithRange:nilRange];
            numberOfRanges++;
        }
        if (!NSEqualRanges(numberRange, NSMakeRange(NSNotFound, 0))) {
            numberString = [self.str substringWithRange:numberRange];
            numberOfRanges++;
        }
        if (!NSEqualRanges(atomRange, NSMakeRange(NSNotFound, 0))) {
            atomString = [self.str substringWithRange:atomRange];
            numberOfRanges++;
        }
        if (!NSEqualRanges(quotedRange, NSMakeRange(NSNotFound, 0))) {
            quotedString = [self.str substringWithRange:quotedRange];
            numberOfRanges++;
        }
        if (!NSEqualRanges(lparRange, NSMakeRange(NSNotFound, 0))) {
            lparString = [self.str substringWithRange:lparRange];
            numberOfRanges++;
        }
        if (!NSEqualRanges(rparRange, NSMakeRange(NSNotFound, 0))) {
            rparString = [self.str substringWithRange:rparRange];
            numberOfRanges++;
        }
        if (!NSEqualRanges(bslashRange, NSMakeRange(NSNotFound, 0))) {
            bslashString = [self.str substringWithRange:bslashRange];
            numberOfRanges++;
        }
        if (!NSEqualRanges(starRange, NSMakeRange(NSNotFound, 0))) {
            starString = [self.str substringWithRange:starRange];
            numberOfRanges++;
        }
        if (!NSEqualRanges(lbraRange, NSMakeRange(NSNotFound, 0))) {
            lbraString = [self.str substringWithRange:lbraRange];
            numberOfRanges++;
        }
        if (!NSEqualRanges(rbraRange, NSMakeRange(NSNotFound, 0))) {
            rbraString = [self.str substringWithRange:rbraRange];
            numberOfRanges++;
        }
        if (!NSEqualRanges(literalRange, NSMakeRange(NSNotFound, 0))) {
            literalString = [self.str substringWithRange:literalRange];
            numberOfRanges++;
        }
        if (!NSEqualRanges(plusRange, NSMakeRange(NSNotFound, 0))) {
            plusString = [self.str substringWithRange:plusRange];
            numberOfRanges++;
        }
        if (!NSEqualRanges(percentRange, NSMakeRange(NSNotFound, 0))) {
            percentString = [self.str substringWithRange:percentRange];
            numberOfRanges++;
        }
        if (!NSEqualRanges(crlfRange, NSMakeRange(NSNotFound, 0))) {
            crlfString = [self.str substringWithRange:crlfRange];
            numberOfRanges++;
        }
        if (!NSEqualRanges(eofRange, NSMakeRange(NSNotFound, 0))) {
            eofString = [self.str substringWithRange:eofRange];
            numberOfRanges++;
        }
        if (spaceString) {
            return [[[Token alloc] initWithSymbol:T_SPACE
                                            value:[self.str substringWithRange:[match rangeAtIndex:(numberOfRanges - 1)]]] autorelease];
        } else if (nilString) {
            return [[[Token alloc] initWithSymbol:T_NIL
                                            value:[self.str substringWithRange:[match rangeAtIndex:(numberOfRanges - 1)]]] autorelease];
        } else if (numberString) {
            return [[[Token alloc] initWithSymbol:T_NUMBER
                                            value:[self.str substringWithRange:[match rangeAtIndex:(numberOfRanges - 1)]]] autorelease];
        } else if (atomString) {
            return [[[Token alloc] initWithSymbol:T_ATOM
                                            value:[self.str substringWithRange:[match rangeAtIndex:(numberOfRanges - 1)]]] autorelease];
        } else if (quotedString) {
            NSRegularExpression *slashRegex = [NSRegularExpression regularExpressionWithPattern:@"\\\\([\"\\\\])"
                                                                                        options:0
                                                                                          error:&error];
            NSString *lastMatch = [self.str substringWithRange:[match rangeAtIndex:(numberOfRanges - 1)]];
            lastMatch = [slashRegex stringByReplacingMatchesInString:lastMatch options:0 range:NSMakeRange(0, [lastMatch length]) withTemplate:@"$1"];
            return [[[Token alloc] initWithSymbol:T_QUOTED
                                            value:lastMatch] autorelease];
        } else if (lparString) {
            return [[[Token alloc] initWithSymbol:T_LPAR
                                            value:[self.str substringWithRange:[match rangeAtIndex:(numberOfRanges - 1)]]] autorelease];
        } else if (rparString) {
            return [[[Token alloc] initWithSymbol:T_RPAR
                                            value:[self.str substringWithRange:[match rangeAtIndex:(numberOfRanges - 1)]]] autorelease];
        } else if (bslashString) {
            return [[[Token alloc] initWithSymbol:T_BSLASH
                                            value:[self.str substringWithRange:[match rangeAtIndex:(numberOfRanges - 1)]]] autorelease];
        } else if (starString) {
            return [[[Token alloc] initWithSymbol:T_STAR
                                            value:[self.str substringWithRange:[match rangeAtIndex:(numberOfRanges - 1)]]] autorelease];
        } else if (lbraString) {
            return [[[Token alloc] initWithSymbol:T_LBRA
                                            value:[self.str substringWithRange:[match rangeAtIndex:(numberOfRanges - 1)]]] autorelease];
        } else if (rbraString) {
            return [[[Token alloc] initWithSymbol:T_RBRA
                                            value:[self.str substringWithRange:[match rangeAtIndex:(numberOfRanges - 1)]]] autorelease];
        } else if (literalString) {
            int len = [[self.str substringWithRange:[match rangeAtIndex:(numberOfRanges - 1)]] intValue];
            NSString *val = [self.str substringWithRange:NSMakeRange(self.pos, len)];
            self.pos += len;
            return [[[Token alloc] initWithSymbol:T_LITERAL
                                            value:val] autorelease];
        } else if (plusString) {
            return [[[Token alloc] initWithSymbol:T_PLUS
                                            value:[self.str substringWithRange:[match rangeAtIndex:(numberOfRanges - 1)]]] autorelease];
        } else if (percentString) {
            return [[[Token alloc] initWithSymbol:T_PERCENT
                                            value:[self.str substringWithRange:[match rangeAtIndex:(numberOfRanges - 1)]]] autorelease];
        } else if (crlfString) {
            return [[[Token alloc] initWithSymbol:T_CRLF
                                            value:[self.str substringWithRange:[match rangeAtIndex:(numberOfRanges - 1)]]] autorelease];
        } else if (eofString) {
            return [[[Token alloc] initWithSymbol:T_EOF
                                            value:[self.str substringWithRange:[match rangeAtIndex:(numberOfRanges - 1)]]] autorelease];
        } else {
            [self parseError:@"[IMAP BUG] BEG_REGEXP is invalid"];
            return nil;
        }
    } else {
        NSRegularExpression *errorRegex = [NSRegularExpression regularExpressionWithPattern:@"\\S*"
                                                                                  options:0
                                                                                    error:&error];
        NSTextCheckingResult *errorMatch = [errorRegex firstMatchInString:self.str
                                                                  options:0
                                                                    range:NSMakeRange(self.pos, [self.str length] - self.pos)];
        [self parseError:[NSString stringWithFormat:@"unknown token - %@", [self.str substringWithRange:[errorMatch range]]]];
        return nil;
    }
}

- (Token *) tokenForData {
    NSError *error = NULL;
    NSRegularExpression *dataRegex = [NSRegularExpression regularExpressionWithPattern:@"\\G(?:( )|(NIL)|(\\d+)|\"((?:[^\\x00\\r\\n\"\\\\]|\\\\[\"\\\\])*)\"|\\{(\\d+)\\}\\r\\n|(\\()|(\\)))"
                                                                              options:NSRegularExpressionCaseInsensitive
                                                                                error:&error];
    NSTextCheckingResult *match = [dataRegex firstMatchInString:self.str
                                                        options:0
                                                          range:NSMakeRange(self.pos, [self.str length] - self.pos)];
    NSString *spaceString = nil;
    NSString *nilString = nil;
    NSString *numberString = nil;
    NSString *quotedString = nil;
    NSString *literalString = nil;
    NSString *lparString = nil;
    NSString *rparString = nil;
    if (match) {
        self.pos = match.range.location + match.range.length;
        NSRange spaceRange = [match rangeAtIndex:1];
        NSRange nilRange = [match rangeAtIndex:2];
        NSRange numberRange = [match rangeAtIndex:3];
        NSRange quotedRange = [match rangeAtIndex:4];
        NSRange literalRange = [match rangeAtIndex:5];
        NSRange lparRange = [match rangeAtIndex:6];
        NSRange rparRange = [match rangeAtIndex:7];
        int numberOfRanges = 0;
        if (!NSEqualRanges(spaceRange, NSMakeRange(NSNotFound, 0))) {
            spaceString = [self.str substringWithRange:spaceRange];
            numberOfRanges++;
        }
        if (!NSEqualRanges(nilRange, NSMakeRange(NSNotFound, 0))) {
            nilString = [self.str substringWithRange:nilRange];
            numberOfRanges++;
        }
        if (!NSEqualRanges(numberRange, NSMakeRange(NSNotFound, 0))) {
            numberString = [self.str substringWithRange:numberRange];
            numberOfRanges++;
        }
        if (!NSEqualRanges(quotedRange, NSMakeRange(NSNotFound, 0))) {
            quotedString = [self.str substringWithRange:quotedRange];
            numberOfRanges++;
        }
        if (!NSEqualRanges(literalRange, NSMakeRange(NSNotFound, 0))) {
            literalString = [self.str substringWithRange:literalRange];
            numberOfRanges++;
        }
        if (!NSEqualRanges(lparRange, NSMakeRange(NSNotFound, 0))) {
            lparString = [self.str substringWithRange:lparRange];
            numberOfRanges++;
        }
        if (!NSEqualRanges(rparRange, NSMakeRange(NSNotFound, 0))) {
            rparString = [self.str substringWithRange:rparRange];
            numberOfRanges++;
        }
        if (spaceString) {
            return [[[Token alloc] initWithSymbol:T_SPACE
                                            value:[self.str substringWithRange:[match rangeAtIndex:(numberOfRanges - 1)]]] autorelease];
        } else if (nilString) {
            return [[[Token alloc] initWithSymbol:T_NIL
                                            value:[self.str substringWithRange:[match rangeAtIndex:(numberOfRanges - 1)]]] autorelease];
        } else if (numberString) {
            return [[[Token alloc] initWithSymbol:T_NUMBER
                                            value:[self.str substringWithRange:[match rangeAtIndex:(numberOfRanges - 1)]]] autorelease];
        } else if (quotedString) {
            NSRegularExpression *slashRegex = [NSRegularExpression regularExpressionWithPattern:@"\\\\([\"\\\\])"
                                                                                        options:0
                                                                                          error:&error];
            NSString *lastMatch = [self.str substringWithRange:[match rangeAtIndex:(numberOfRanges - 1)]];
            lastMatch = [slashRegex stringByReplacingMatchesInString:lastMatch options:0 range:NSMakeRange(0, [lastMatch length]) withTemplate:@"$1"];
            return [[[Token alloc] initWithSymbol:T_QUOTED
                                            value:lastMatch] autorelease];
        } else if (literalString) {
            int len = [[self.str substringWithRange:[match rangeAtIndex:(numberOfRanges - 1)]] intValue];
            NSString *val = [self.str substringWithRange:NSMakeRange(self.pos, len)];
            self.pos += len;
            return [[[Token alloc] initWithSymbol:T_LITERAL
                                            value:val] autorelease];
        } else if (lparString) {
            return [[[Token alloc] initWithSymbol:T_LPAR
                                            value:[self.str substringWithRange:[match rangeAtIndex:(numberOfRanges - 1)]]] autorelease];
        } else if (rparString) {
            return [[[Token alloc] initWithSymbol:T_RPAR
                                            value:[self.str substringWithRange:[match rangeAtIndex:(numberOfRanges - 1)]]] autorelease];
        } else {
            [self parseError:@"[IMAP BUG] DATA_REGEXP is invalid"];
            return nil;
        }
    } else {
        NSRegularExpression *errorRegex = [NSRegularExpression regularExpressionWithPattern:@"\\S*"
                                                                                    options:0
                                                                                      error:&error];
        NSTextCheckingResult *errorMatch = [errorRegex firstMatchInString:self.str
                                                                  options:0
                                                                    range:NSMakeRange(self.pos, [self.str length] - self.pos)];
        [self parseError:[NSString stringWithFormat:@"unknown token - %@", [self.str substringWithRange:[errorMatch range]]]];
        return nil;
    }
}

- (Token *) tokenForText {
    NSError *error = NULL;
    NSRegularExpression *textRegex = [NSRegularExpression regularExpressionWithPattern:@"\\G(?:([^\\x00\\r\\n]*))"
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:&error];
    NSTextCheckingResult *match = [textRegex firstMatchInString:self.str
                                                        options:0
                                                          range:NSMakeRange(self.pos, [self.str length] - self.pos)];
    NSString *textString = nil;
    if (match) {
        self.pos = match.range.location + match.range.length;
        NSRange textRange = [match rangeAtIndex:1];
        int numberOfRanges = 0;
        if (!NSEqualRanges(textRange, NSMakeRange(NSNotFound, 0))) {
            textString = [self.str substringWithRange:textRange];
            numberOfRanges++;
        }
        if (textString) {
            return [[[Token alloc] initWithSymbol:T_TEXT
                                            value:[self.str substringWithRange:[match rangeAtIndex:(numberOfRanges - 1)]]] autorelease];
        } else {
            [self parseError:@"[IMAP BUG] TEXT_REGEXP is invalid"];
            return nil;
        }
    } else {
        NSRegularExpression *errorRegex = [NSRegularExpression regularExpressionWithPattern:@"\\S*"
                                                                                    options:0
                                                                                      error:&error];
        NSTextCheckingResult *errorMatch = [errorRegex firstMatchInString:self.str
                                                                  options:0
                                                                    range:NSMakeRange(self.pos, [self.str length] - self.pos)];
        [self parseError:[NSString stringWithFormat:@"unknown token - %@", [self.str substringWithRange:[errorMatch range]]]];
        return nil;
    }
}

- (Token *) tokenForRText {
    NSError *error = NULL;
    NSRegularExpression *rTextRegex = [NSRegularExpression regularExpressionWithPattern:@"\\G(?:(\\[)|([^\\x00\\r\\n]*))"
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:&error];
    NSTextCheckingResult *match = [rTextRegex firstMatchInString:self.str
                                                         options:0
                                                           range:NSMakeRange(self.pos, [self.str length] - self.pos)];
    NSString *lbraString = nil;
    NSString *textString = nil;
    if (match) {
        self.pos = match.range.location + match.range.length;
        NSRange lbraRange = [match rangeAtIndex:1];
        NSRange textRange = [match rangeAtIndex:2];
        int numberOfRanges = 0;
        if (!NSEqualRanges(lbraRange, NSMakeRange(NSNotFound, 0))) {
            lbraString = [self.str substringWithRange:lbraRange];
            numberOfRanges++;
        }
        if (!NSEqualRanges(textRange, NSMakeRange(NSNotFound, 0))) {
            textString = [self.str substringWithRange:textRange];
            numberOfRanges++;
        }
        if (lbraString) {
            return [[[Token alloc] initWithSymbol:T_LBRA
                                            value:[self.str substringWithRange:[match rangeAtIndex:(numberOfRanges - 1)]]] autorelease];
        } else if (textString) {
            return [[[Token alloc] initWithSymbol:T_TEXT
                                            value:[self.str substringWithRange:[match rangeAtIndex:(numberOfRanges - 1)]]] autorelease];
        } else {
            [self parseError:@"[IMAP BUG] RTEXT_REGEXP is invalid"];
            return nil;
        }
    } else {
        NSRegularExpression *errorRegex = [NSRegularExpression regularExpressionWithPattern:@"\\S*"
                                                                                    options:0
                                                                                      error:&error];
        NSTextCheckingResult *errorMatch = [errorRegex firstMatchInString:self.str
                                                                  options:0
                                                                    range:NSMakeRange(self.pos, [self.str length] - self.pos)];
        [self parseError:[NSString stringWithFormat:@"unknown token - %@", [self.str substringWithRange:[errorMatch range]]]];
        return nil;
    }
}

- (Token *) tokenForCText {
    NSError *error = NULL;
    NSRegularExpression *cTextRegex = [NSRegularExpression regularExpressionWithPattern:@"\\G(?:([^\\x00\\r\\n\\]]*))"
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:&error];
    NSTextCheckingResult *match = [cTextRegex firstMatchInString:self.str
                                                         options:0
                                                           range:NSMakeRange(self.pos, [self.str length] - self.pos)];
    NSString *textString = nil;
    if (match) {
        self.pos = match.range.location + match.range.length;
        NSRange textRange = [match rangeAtIndex:1];
        int numberOfRanges = 0;
        if (!NSEqualRanges(textRange, NSMakeRange(NSNotFound, 0))) {
            textString = [self.str substringWithRange:textRange];
            numberOfRanges++;
        }
        if (textString) {
            return [[[Token alloc] initWithSymbol:T_TEXT
                                            value:[self.str substringWithRange:[match rangeAtIndex:(numberOfRanges - 1)]]] autorelease];
        } else {
            [self parseError:@"[IMAP BUG] CTEXT_REGEXP is invalid"];
            return nil;
        }
    } else {
        NSRegularExpression *errorRegex = [NSRegularExpression regularExpressionWithPattern:@"\\S*"
                                                                                    options:0
                                                                                      error:&error];
        NSTextCheckingResult *errorMatch = [errorRegex firstMatchInString:self.str
                                                                  options:0
                                                                    range:NSMakeRange(self.pos, [self.str length] - self.pos)];
        [self parseError:[NSString stringWithFormat:@"unknown token - %@", [self.str substringWithRange:[errorMatch range]]]];
        return nil;
    }
}

- (Token *) nextToken {
    switch (self.lexState) {
        case EXPR_BEG: {
            return [self tokenForBeg];
        }
        case EXPR_DATA: {
            return [self tokenForData];
        }
        case EXPR_TEXT: {
            return [self tokenForText];
        }
        case EXPR_RTEXT: {
            return [self tokenForRText];
        }
        case EXPR_CTEXT: {
            return [self tokenForCText];
        }            
        default: {
            [self parseError:[NSString stringWithFormat:@"invalid self.lexState - %d", self.lexState]];
            return nil;
        }
    }
}

@end