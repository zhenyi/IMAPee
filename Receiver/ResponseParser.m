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

- (ResponseCode *) responseTextCode {
    //TODO
    return nil;
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

- (UntaggedResponse *) responseUntagged {
    //TODO
    return nil;
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

- (id) parse:(NSString *)aString {
    self.str = aString;
    self.pos = 0;
    self.lexState = EXPR_BEG;
    self.token = nil;
    return [self response];
}

@end