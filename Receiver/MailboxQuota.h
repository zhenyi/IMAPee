//
//  MailboxQuota.h
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MailboxQuota : NSObject {
    
    NSString *mailbox;
    int usage;
    int quota;
    
}

@property (copy) NSString *mailbox;
@property (assign) int usage;
@property (assign) int quota;

@end