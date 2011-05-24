//
//  MailboxACLItem.h
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MailboxACLItem : NSObject {
    
    NSString *user;
    NSString *rights;
    
}

@property (copy) NSString *user;
@property (copy) NSString *rights;

@end