//
//  IMAPee.h
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSString+Additions.h"

@interface IMAPee : NSObject {
    
}

+ (NSString *) decodeUTF7:(NSString *)aString;
+ (NSString *) encodeUTF7:(NSString *)aString;
+ (NSString *) formatDate:(NSDate *)someDate;
+ (NSString *) formatDateTime:(NSDate *)someDate;

/*
 add_authenticator
 add_response_handler
 append
 authenticate
 capability
 check
 close
 copy
 create
 debug
 debug=
 delete
 disconnect
 disconnected?
 examine
 expunge
 fetch
 getacl
 getquota
 getquotaroot
 idle
 idle_done
 list
 login
 logout
 lsub
 max_flag_count
 max_flag_count=
 new
 noop
 remove_response_handler
 rename
 search
 select
 setacl
 setquota
 sort
 starttls
 status
 store
 subscribe
 thread
 uid_copy
 uid_fetch
 uid_search
 uid_sort
 uid_store
 uid_thread
 unsubscribe
*/

@end