//
//  IMAPee.h
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSString+Additions.h"
#import "TaggedResponse.h"

@interface IMAPee : NSObject {
    
    NSMutableDictionary *responses;
    
}

@property (retain) NSMutableDictionary *responses;

- (NSArray *) capability;
- (TaggedResponse *) noop;
- (TaggedResponse *) logout;
- (TaggedResponse *) login:(NSString *)user password:(NSString *)password;
- (TaggedResponse *) select:(NSString *)mailbox;
- (TaggedResponse *) examine:(NSString *)mailbox;
- (TaggedResponse *) create:(NSString *)mailbox;
- (TaggedResponse *) delete:(NSString *)mailbox;
- (TaggedResponse *) rename:(NSString *)mailbox to:(NSString *)newName;
- (TaggedResponse *) subscribe:(NSString *)mailbox;
- (TaggedResponse *) unsubscribe:(NSString *)mailbox;
- (NSArray *) list:(NSString *)refName mailbox:(NSString *)mailbox;
+ (NSString *) decodeUTF7:(NSString *)aString;
+ (NSString *) encodeUTF7:(NSString *)aString;
+ (NSString *) formatDate:(NSDate *)someDate;
+ (NSString *) formatDateTime:(NSDate *)someDate;

/*
 add_authenticator
 add_response_handler
 append
 authenticate
 check
 close
 copy
 debug
 debug=
 disconnect
 disconnected?
 expunge
 fetch
 getacl
 getquota
 getquotaroot
 idle
 idle_done
 lsub
 max_flag_count
 max_flag_count=
 new
 remove_response_handler
 search
 setacl
 setquota
 sort
 starttls
 status
 store
 thread
 uid_copy
 uid_fetch
 uid_search
 uid_sort
 uid_store
 uid_thread
*/

@end