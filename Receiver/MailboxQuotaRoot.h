//
//  MailboxQuotaRoot.h
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MailboxQuotaRoot : NSObject {
    
    NSString *mailbox;
    NSArray *quotaRoots;
    
}

@property (copy) NSString *mailbox;
@property (copy) NSArray *quotaRoots;

@end