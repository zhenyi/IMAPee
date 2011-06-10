//
//  IMAPee.h
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSString+Additions.h"
#import "ResponseParser.h"
#import "TaggedResponse.h"
#import "RawData.h"
#import "StatusData.h"
#import "Literal.h"

@interface IMAPee : NSObject {

    NSString *host;
    int port;
    NSString *tagPrefix;
    int tagNo;
    BOOL useSSL;
    ResponseParser *parser;
    NSMutableDictionary *responses;
    NSMutableDictionary *taggedResponses;
    NSMutableArray *responseHandlers;
    NSString *logoutCommandTag;
    NSException *exception;
    TaggedResponse *greeting;
}

@property (copy) NSString *host;
@property (assign) int port;
@property (copy) NSString *tagPrefix;
@property (assign) int tagNo;
@property (assign) BOOL useSSL;
@property (retain) ResponseParser *parser;
@property (retain) NSMutableDictionary *responses;
@property (retain) NSMutableDictionary *taggedResponses;
@property (retain) NSMutableArray *responseHandlers;
@property (copy) NSString *logoutCommandTag;
@property (retain) NSException *exception;
@property (retain) TaggedResponse *greeting;

- (id) initWithHost:(NSString *)aHost port:(int)aPort useSSL:(BOOL)isUsingSSL;
- (NSArray *) capability;
- (TaggedResponse *) noop;
- (TaggedResponse *) logout;
- (TaggedResponse *) login:(NSString *)user password:(NSString *)password;
- (TaggedResponse *) select:(NSString *)mailbox;
- (TaggedResponse *) examine:(NSString *)mailbox;
- (TaggedResponse *) create:(NSString *)mailbox;
- (TaggedResponse *) del:(NSString *)mailbox;
- (TaggedResponse *) rename:(NSString *)mailbox to:(NSString *)newName;
- (TaggedResponse *) subscribe:(NSString *)mailbox;
- (TaggedResponse *) unsubscribe:(NSString *)mailbox;
- (NSArray *) list:(NSString *)refName mailbox:(NSString *)mailbox;
- (NSArray *) getQuotaRoot:(NSString *)mailbox;
- (NSArray *) getQuota:(NSString *)mailbox;
- (TaggedResponse *) setQuota:(NSString *)mailbox quota:(NSString *)quota;
- (TaggedResponse *) setACL:(NSString *)mailbox user:(NSString *)user rights:(NSString *)rights;
- (NSArray *) getACL:(NSString *)mailbox;
- (NSArray *) lsub:(NSString *)refName mailbox:(NSString *)mailbox;
- (NSDictionary *) status:(NSString *)mailbox attr:(NSArray *)attr;
- (TaggedResponse *) append:(NSString *)mailbox message:(NSString *)message flags:(NSArray *)flags time:(NSDate *)time;
- (TaggedResponse *) check;
- (TaggedResponse *) close;
- (NSArray *) expunge;
- (NSArray *) search:(NSString *)key charset:(NSString *)charset;
- (NSArray *) UIDSearch:(NSString *)key charset:(NSString *)charset;
- (NSArray *) fetch:(NSArray *)set attr:(NSArray *)attr;
- (NSArray *) UIDFetch:(NSArray *)set attr:(NSArray *)attr;
+ (NSString *) decodeUTF7:(NSString *)aString;
+ (NSString *) encodeUTF7:(NSString *)aString;
+ (NSString *) formatDate:(NSDate *)someDate;
+ (NSString *) formatDateTime:(NSDate *)someDate;

/*
 add_authenticator
 add_response_handler
 authenticate
 copy
 disconnect
 disconnected?
 idle
 idle_done
 new
 remove_response_handler
 sort
 starttls
 store
 thread
 uid_copy
 uid_sort
 uid_store
 uid_thread
*/

@end