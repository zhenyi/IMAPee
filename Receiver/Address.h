//
//  Address.h
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Address : NSObject {
    
    NSString *name;
    NSString *route;
    NSString *mailbox;
    NSString *host;
    
}

@property (copy) NSString *name;
@property (copy) NSString *route;
@property (copy) NSString *mailbox;
@property (copy) NSString *host;

@end