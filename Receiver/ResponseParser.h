//
//  ResponseParser.h
//  Receiver
//
//  Created by Zhenyi Tan on 5/25/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Token.h"
#import "ContinuationRequest.h"
#import "UntaggedResponse.h"
#import "TaggedResponse.h"
#import "ResponseText.h"
#import "ResponseCode.h"
#import "FetchData.h"
#import "MailboxList.h"
#import "Envelope.h"
#import "MailboxQuota.h"
#import "MailboxQuotaRoot.h"
#import "MailboxACLItem.h"

@interface ResponseParser : NSObject {
    
    NSString *str;
    int pos;
    int lexState;
    Token *token;
    NSMutableDictionary *flagSymbols;
    
}

@property (copy) NSString *str;
@property (assign)int pos;
@property (assign) int lexState;
@property (retain) Token *token;
@property (retain) NSMutableDictionary *flagSymbols;

- (id) init;
- (id) parse:(NSString *)someString;

@end